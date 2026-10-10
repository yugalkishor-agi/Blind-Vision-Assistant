import 'dart:async';
import 'dart:isolate';
import 'dart:ui';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:path_provider/path_provider.dart';
import '../config/constants.dart';
import '../models/enums.dart';
import '../models/models.dart';
import 'download_state_manager.dart';
import 'logger.dart';

class DownloadManager {
  static const _portName = 'downloader_send_port';
  final _port = ReceivePort();
  StreamController<DownloadState>? _controller;
  DownloadState _state = const DownloadState();

  Stream<DownloadState> get stateStream => _controller!.stream;
  DownloadState get currentState => _state;

  Future<void> initialize() async {
    _controller = StreamController<DownloadState>.broadcast();
    IsolateNameServer.registerPortWithName(_port.sendPort, _portName);
    _port.listen(_onProgress);
    final saved = await DownloadStateManager.loadState();
    _updateState(saved);
  }

  void _onProgress(dynamic data) {
    final id = data[0] as String;
    final status = DownloadTaskStatus.values[data[1] as int];
    final progress = data[2] as int;
    if (_state.taskId != null && _state.taskId != id) return;
    DownloadStatus downloadStatus;
    switch (status) {
      case DownloadTaskStatus.running: downloadStatus = DownloadStatus.downloading; break;
      case DownloadTaskStatus.complete: downloadStatus = DownloadStatus.completed; break;
      case DownloadTaskStatus.failed: downloadStatus = DownloadStatus.failed; break;
      case DownloadTaskStatus.paused: downloadStatus = DownloadStatus.paused; break;
      case DownloadTaskStatus.canceled: downloadStatus = DownloadStatus.cancelled; break;
      default: downloadStatus = DownloadStatus.notStarted;
    }
    _updateState(_state.copyWith(status: downloadStatus, progress: progress));
  }

  void _updateState(DownloadState newState) {
    _state = newState;
    _controller?.add(_state);
    DownloadStateManager.saveState(_state);
  }

  Future<void> startDownload(String authToken) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final taskId = await FlutterDownloader.enqueue(
        url: downloadUrl,
        savedDir: dir.path,
        fileName: modelName,
        headers: {'Authorization': 'Bearer $authToken'},
        showNotification: true,
        openFileFromNotification: false,
      );
      _updateState(_state.copyWith(status: DownloadStatus.downloading, taskId: taskId, progress: 0));
      AppLogger.log('Download started: $taskId');
    } catch (e) {
      AppLogger.error('Failed to start download', e);
      _updateState(_state.copyWith(status: DownloadStatus.failed, errorMessage: e.toString()));
    }
  }

  Future<void> pauseDownload() async {
    if (_state.taskId == null) return;
    await FlutterDownloader.pause(taskId: _state.taskId!);
  }

  Future<void> resumeDownload() async {
    if (_state.taskId == null) return;
    final newId = await FlutterDownloader.resume(taskId: _state.taskId!);
    if (newId != null) _updateState(_state.copyWith(taskId: newId));
  }

  Future<void> cancelDownload() async {
    if (_state.taskId == null) return;
    await FlutterDownloader.cancel(taskId: _state.taskId!);
    await DownloadStateManager.clearState();
    _updateState(const DownloadState());
  }

  void dispose() {
    IsolateNameServer.removePortNameMapping(_portName);
    _port.close();
    _controller?.close();
  }
}
