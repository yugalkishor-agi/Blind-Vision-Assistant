// download_page/services/download_manager.dart

import 'dart:io';
import 'dart:isolate';
import 'dart:ui';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'logger.dart';

/// Manages background downloads using flutter_downloader plugin with isolate communication
class DownloadManager {
  static String? _currentTaskId;

  /// ReceivePort for getting progress updates from background isolate
  static final ReceivePort _port = ReceivePort();

  /// Attach to existing download task (for app restart recovery)
  static void attachToTask(String taskId) {
    _currentTaskId = taskId;
  }

  /// Setup isolate communication - DON'T call FlutterDownloader.initialize() (done in main())
  static Future<void> initialize() async {
    // Remove any stale port mapping to avoid "already registered" errors
    IsolateNameServer.removePortNameMapping('downloader_send_port');

    // Register our port so background isolate can send us progress updates
    IsolateNameServer.registerPortWithName(
      _port.sendPort,
      'downloader_send_port',
    );

    // Listen for messages from background isolate (id, status, progress)
    _port.listen((dynamic data) {
      final id = data[0] as String;
      final status = DownloadTaskStatus.fromInt(data[1] as int);
      final progress = data[2] as int;
      Logger.debug('Task $id: $status, $progress%');
    });
  }

  /// Callback function for background isolate (must be top-level or static)
  @pragma('vm:entry-point')
  static void downloadCallback(String id, int status, int progress) {
    final SendPort? send = IsolateNameServer.lookupPortByName(
      'downloader_send_port',
    );
    send?.send([id, status, progress]);
  }

  /// Check if model URL is accessible (returns HTTP status code, -1 for network error)
  static Future<int> checkModelAccess(String url, [String? accessToken]) async {
    try {
      Logger.info('Checking model access at: $url');
      final headers = <String, String>{};
      if (accessToken != null) {
        headers['Authorization'] = 'Bearer $accessToken';
        Logger.debug('Using access token for request');
      }

      // Use HEAD request to check access without downloading content
      final response = await http.head(Uri.parse(url), headers: headers);
      Logger.info('Access check response: ${response.statusCode}');
      return response.statusCode;
    } catch (e) {
      Logger.error('Network error during access check: $e');
      return -1;
    }
  }

  /// Start background download with proper Android permissions handling
  static Future<String?> startDownload({
    required String url,
    required String fileName,
    String? accessToken,
  }) async {
    try {
      // Use app-specific directory (no storage permission needed on Android 13+)
      final dir = await getApplicationDocumentsDirectory();

      // Handle Android permissions based on API level
      if (Platform.isAndroid) {
        // Request notification permission for download progress notifications
        final notificationStatus = await Permission.notification.request();
        if (!notificationStatus.isGranted) {
          Logger.warning(
            'Notification permission denied, download will continue without notifications',
          );
        }

        // Only request storage permission for older Android versions
        if (await Permission.storage.isDenied) {
          final storageStatus = await Permission.storage.request();
          if (!storageStatus.isGranted) {
            Logger.warning(
              'Storage permission denied, but will try to download to app directory',
            );
          }
        }
      }

      // Prepare authorization header if token provided
      final headers = <String, String>{};
      if (accessToken != null) {
        headers['Authorization'] = 'Bearer $accessToken';
        Logger.debug('Adding authorization header to download request');
      }

      Logger.info('Starting download: $fileName to ${dir.path}');
      // Enqueue download task with flutter_downloader
      final taskId = await FlutterDownloader.enqueue(
        url: url,
        savedDir: dir.path,
        fileName: fileName,
        headers: headers,
        showNotification: true,
        openFileFromNotification: false,
        saveInPublicStorage: false, // Use app-specific storage
      );

      _currentTaskId = taskId;
      Logger.info('Download task created with ID: $taskId');
      return taskId;
    } catch (e) {
      Logger.error('Failed to start download: $e');
      return null;
    }
  }

  static Future<void> pauseDownload() async {
    if (_currentTaskId != null) {
      await FlutterDownloader.pause(taskId: _currentTaskId!);
      Logger.info('Download paused');
    }
  }

  /// Resume paused download - flutter_downloader creates NEW task ID when resuming
  static Future<String?> resumeDownload() async {
    if (_currentTaskId == null) {
      Logger.warning('No paused task to resume');
      return null;
    }

    try {
      // IMPORTANT: Resume creates a brand-new task ID, not the same one
      final newTaskId = await FlutterDownloader.resume(taskId: _currentTaskId!);

      if (newTaskId != null) {
        _currentTaskId = newTaskId; // Switch to the fresh task ID
        Logger.info('Download resumed with new ID: $newTaskId');
      } else {
        Logger.warning('Resume returned a null taskId');
      }
      return newTaskId;
    } catch (e) {
      Logger.error('Error while resuming download: $e');
      return null;
    }
  }

  static Future<void> cancelDownload() async {
    if (_currentTaskId != null) {
      await FlutterDownloader.cancel(taskId: _currentTaskId!);
      Logger.info('Download cancelled');
      _currentTaskId = null;
    }
  }

  /// Nuclear option: cancel download AND delete all associated files completely
  static Future<void> cancelAndDeleteDownload() async {
    if (_currentTaskId == null) {
      Logger.info('No current task to cancel');
      return;
    }

    try {
      // Get task details before cancelling to find file paths
      final tasks = await getAllTasks();
      final currentTask = tasks.firstWhere(
        (task) => task.taskId == _currentTaskId,
        orElse: () => DownloadTask(
          taskId: '',
          status: DownloadTaskStatus.undefined,
          progress: 0,
          url: '',
          filename: null,
          savedDir: '',
          timeCreated: 0,
          allowCellular: true,
        ),
      );

      // Cancel the active download task
      await FlutterDownloader.cancel(taskId: _currentTaskId!);
      Logger.info('Download task cancelled: $_currentTaskId');

      // Remove from flutter_downloader database AND delete files
      await FlutterDownloader.remove(
        taskId: _currentTaskId!,
        shouldDeleteContent: true,
      );
      Logger.info('Download task removed from database with file deletion');

      // Extra cleanup: manually delete any remaining files
      if (currentTask.taskId.isNotEmpty &&
          currentTask.filename != null &&
          currentTask.savedDir.isNotEmpty) {
        await _deleteDownloadFiles(currentTask.savedDir, currentTask.filename!);
      }

      // Nuclear cleanup: remove any model files that might exist
      await _cleanupModelFiles();

      _currentTaskId = null;
      Logger.info('Download completely cancelled and all files deleted');
    } catch (e) {
      Logger.error('Error during complete download cancellation: $e');
      _currentTaskId = null;
    }
  }

  /// Delete specific download files including common partial file extensions
  static Future<void> _deleteDownloadFiles(
    String savedDir,
    String filename,
  ) async {
    try {
      if (savedDir.isEmpty || filename.isEmpty) return;

      final filePath = '$savedDir/$filename';
      final file = File(filePath);

      if (await file.exists()) {
        await file.delete();
        Logger.info('Manually deleted file: $filePath');
      }

      // Clean up partial download files with common extensions
      final partialExtensions = ['.part', '.tmp', '.download', '.crdownload'];
      for (final ext in partialExtensions) {
        final partialFile = File('$filePath$ext');
        if (await partialFile.exists()) {
          await partialFile.delete();
          Logger.info('Deleted partial file: $filePath$ext');
        }
      }
    } catch (e) {
      Logger.error('Error deleting download files: $e');
    }
  }

  /// Public method to clean up all model files
  static Future<void> cleanupAllModelFiles() async {
    await _cleanupModelFiles();
  }

  /// Nuclear cleanup: find and delete ANY model files in app directory
  static Future<void> _cleanupModelFiles() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final modelExtensions = ['.gguf', '.bin', '.safetensors', '.pt', '.pth'];

      final List<FileSystemEntity> files = dir.listSync();
      for (final file in files) {
        if (file is File) {
          final filename = file.path.split('/').last.toLowerCase();

          // Identify model files by extension or filename patterns
          final isModelFile =
              modelExtensions.any((ext) => filename.endsWith(ext)) ||
              filename.contains('gemma') ||
              filename.contains('model');

          if (isModelFile) {
            await file.delete();
            Logger.info('Cleaned up model file: ${file.path}');
          }
        }
      }
    } catch (e) {
      Logger.error('Error cleaning up model files: $e');
    }
  }

  /// Clean up old failed/canceled downloads to free space and remove clutter
  static Future<void> cleanupFailedDownloads() async {
    try {
      final tasks = await getAllTasks();
      final failedTasks = tasks
          .where(
            (task) =>
                task.status == DownloadTaskStatus.failed ||
                task.status == DownloadTaskStatus.canceled,
          )
          .toList();

      for (final task in failedTasks) {
        // Remove from database and delete associated files
        await FlutterDownloader.remove(
          taskId: task.taskId,
          shouldDeleteContent: true,
        );
        Logger.info('Cleaned up failed/canceled download: ${task.taskId}');

        // Additional manual cleanup if filename exists
        if (task.filename != null && task.savedDir.isNotEmpty) {
          await _deleteDownloadFiles(task.savedDir, task.filename!);
        }
      }
    } catch (e) {
      Logger.error('Error cleaning up failed downloads: $e');
    }
  }

  /// Get all download tasks from flutter_downloader database
  static Future<List<DownloadTask>> getAllTasks() async {
    return await FlutterDownloader.loadTasks() ?? [];
  }
}
