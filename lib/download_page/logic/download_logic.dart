// download_page/logic/download_logic.dart

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:gemma_chat/chat_page/gemma_vision_chat.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/constants.dart';
import '../models/enums.dart';
import '../models/models.dart';
import '../services/logger.dart';
import '../services/download_state_manager.dart';
import '../services/download_manager.dart';
import '../services/token_manager.dart';
import '../services/huggingface_oauth.dart';

/// Business logic class that handles all download-related operations.
class DownloadPageLogic {
  // Callback functions to update UI state
  final Function(DownloadStatus) setDownloadStatus;
  final Function(DownloadProgress?) setProgress;
  final Function(List<String>) setErrorMessages;
  final Function(bool) setShowAgreementSheet;

  // Timer for monitoring download progress - needs to be tracked for cleanup
  Timer? _monitoringTimer;

  DownloadPageLogic({
    required this.setDownloadStatus,
    required this.setProgress,
    required this.setErrorMessages,
    required this.setShowAgreementSheet,
  });

  /// Clean up resources when this logic instance is no longer needed.
  /// Prevents memory leaks by canceling any active timers.
  void dispose() {
    _monitoringTimer?.cancel();
    _monitoringTimer = null;
  }

  /// Checks if the model file already exists on the device and is valid.
  /// Returns true when the model file is present and > 0 bytes.
  /// Also updates the UI state to `DownloadStatus.completed` if found.
  Future<bool> checkIfModelExists() async {
    // Step 1: Find a completed download task that matches our model filename
    final tasks = await DownloadManager.getAllTasks();
    DownloadTask? task;
    for (final t in tasks) {
      if (t.filename == modelName && t.status == DownloadTaskStatus.complete) {
        task = t;
        break;
      }
    }

    // Step 2: Determine the file path - prefer the exact path from flutter_downloader
    // If no task found, fall back to the standard app documents directory
    final String filePath = task != null && task.filename != null
        ? '${task.savedDir}/${task.filename}'
        : '${(await getApplicationDocumentsDirectory()).path}/$modelName';

    // Step 3: Validate that the file exists and has content
    final file = File(filePath);
    if (await file.exists()) {
      final size = await file.length();
      if (size > 0) {
        Logger.info('Found model file ($size bytes) at $filePath');
        setDownloadStatus(DownloadStatus.completed);
        return true;
      }
    }

    Logger.debug('Model file not found at $filePath');
    return false;
  }

  /// Checks for downloads that were in progress when the app was last closed.
  /// This enables graceful handling of app restarts during downloads.
  Future<void> checkForOngoingDownloads(BuildContext context) async {
    try {
      // Retrieve saved download state from persistent storage
      final savedState = await DownloadStateManager.getDownloadState();
      final savedTaskId = await DownloadStateManager.getDownloadTaskId();

      Logger.info(
        'Checking download state - saved: $savedState, taskId: $savedTaskId',
      );

      // If we had a download in progress, try to resume it
      if (savedState == 'in_progress' && savedTaskId != null) {
        Logger.info(
          'Found saved download in progress with task ID: $savedTaskId',
        );

        // Re-attach the download manager to the existing task
        // This is crucial for pause/resume functionality to work
        DownloadManager.attachToTask(savedTaskId);

        // Query the current status of the saved task
        final tasks = await DownloadManager.getAllTasks();
        final task = tasks.firstWhere(
          (t) => t.taskId == savedTaskId,
          // Return empty task if not found (handles cleanup scenarios)
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

        // Handle case where task was cleaned up by system
        if (task.taskId.isEmpty) {
          Logger.warning('Task ID not found in download manager');
          await DownloadStateManager.clearDownloadState();
          return;
        }

        Logger.info(
          'Found download task: ${task.taskId}, '
          'status: ${task.status}, progress: ${task.progress}%',
        );

        // Resume appropriate behavior based on the task's current status
        switch (task.status) {
          case DownloadTaskStatus.paused:
            setDownloadStatus(DownloadStatus.paused);
            monitorDownload(task.taskId, context);
            Logger.info('Found paused download, showing resume option');
            break;
          case DownloadTaskStatus.running:
          case DownloadTaskStatus.enqueued:
            setDownloadStatus(DownloadStatus.downloading);
            monitorDownload(task.taskId, context);
            break;
          case DownloadTaskStatus.complete:
            // Verify the file actually exists before declaring success
            if (await checkIfModelExists()) {
              await DownloadStateManager.saveDownloadCompleted();
              // Navigate to chat page since download is complete
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => ChatPage()),
                );
              });
            } else {
              // File missing despite completion - clean up state
              await DownloadStateManager.clearDownloadState();
            }
            break;
          case DownloadTaskStatus.failed:
            setDownloadStatus(DownloadStatus.failed);
            await DownloadStateManager.clearDownloadState();
            handleError('Download failed while app was in background');
            break;
          case DownloadTaskStatus.canceled:
          default:
            // Clean up any stale state for canceled/unknown tasks
            await DownloadStateManager.clearDownloadState();
            break;
        }
      } else if (savedState == 'completed') {
        // Check if completed file still exists (user might have deleted it)
        if (await checkIfModelExists()) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => ChatPage()),
            );
          });
        } else {
          // File was deleted - reset state
          await DownloadStateManager.clearDownloadState();
        }
      } else {
        // No saved state - check if file exists anyway (manual installation)
        await checkIfModelExists();
      }
    } catch (e) {
      Logger.error('Error checking for ongoing downloads: $e');
      await DownloadStateManager.clearDownloadState();
    }
  }

  /// Initiates the download process, handling authentication if required.
  /// This is the main entry point for starting a new download.
  Future<void> startDownload() async {
    setDownloadStatus(DownloadStatus.checkingAccess);
    setErrorMessages([]); // Clear any previous errors

    Logger.info('Starting download process for $modelFullName');

    // First, check if the model requires authentication
    final responseCode = await DownloadManager.checkModelAccess(downloadUrl);

    if (responseCode == 200) {
      // Public model - can download directly without authentication
      await downloadModel(null);
      return;
    } else if (responseCode < 0) {
      // Network error occurred during access check
      handleError('Network error. Please check your connection.');
      return;
    }

    // Model requires authentication - proceed with auth flow
    await handleAuthentication();
  }

  /// Handles the authentication process for protected models.
  /// Determines the appropriate authentication method based on stored tokens.
  Future<void> handleAuthentication() async {
    setDownloadStatus(DownloadStatus.authenticating);

    Logger.info('Model requires authentication');

    // Check the status of any previously stored authentication tokens
    final tokenStatus = await TokenManager.getTokenStatus();

    switch (tokenStatus) {
      case TokenStatus.notStored:
      case TokenStatus.expired:
        // No valid token - start OAuth flow to get a new one
        await startOAuthFlow();
        break;
      case TokenStatus.valid:
        // We have a valid token - try using it
        final token = await TokenManager.getStoredToken();
        final responseCode = await DownloadManager.checkModelAccess(
          downloadUrl,
          token?.accessToken,
        );

        if (responseCode == 200) {
          // Token works - proceed with download
          await downloadModel(token?.accessToken);
        } else if (responseCode == 403) {
          // Token is valid but user needs to accept license agreement
          showUserAgreement();
        } else {
          // Token might be invalid - retry OAuth flow
          await startOAuthFlow();
        }
        break;
    }
  }

  /// Initiates the OAuth authentication flow with HuggingFace.
  /// Uses web authentication to get user consent and authorization code.
  Future<void> startOAuthFlow() async {
    try {
      Logger.info('Starting OAuth flow');
      // Generate the authorization URL with proper scopes and redirect
      final authUrl = await HuggingFaceOAuth.generateAuthUrl();

      // Launch web authentication flow - this opens a browser
      final result = await FlutterWebAuth2.authenticate(
        url: authUrl,
        callbackUrlScheme: 'com.tommasogiovannini.gemma', // Custom URL scheme
      );

      // Parse the callback URL to extract the authorization code
      final uri = Uri.parse(result);
      final code = uri.queryParameters['code'];

      if (code != null) {
        // Successfully got authorization code - exchange it for access token
        await handleAuthorizationCode(code);
      } else {
        // OAuth flow completed but no code received - this shouldn't happen
        handleError('Authorization failed: No code received');
      }
    } catch (e) {
      // Handle user cancellation gracefully vs actual errors
      if (e.toString().contains('CANCELED') ||
          e.toString().contains('USER_CANCELED')) {
        setDownloadStatus(DownloadStatus.notStarted);
        Logger.info('OAuth flow cancelled by user');
      } else {
        handleError('Authentication failed: $e');
      }
    }
  }

  /// Exchanges the OAuth authorization code for an access token.
  /// Then attempts to use the token to access the model.
  Future<void> handleAuthorizationCode(String code) async {
    setDownloadStatus(DownloadStatus.authenticating);

    try {
      // Exchange authorization code for access token
      final tokenData = await HuggingFaceOAuth.exchangeCodeForToken(code);
      if (tokenData != null) {
        // Test the new token by checking model access
        final responseCode = await DownloadManager.checkModelAccess(
          downloadUrl,
          tokenData.accessToken,
        );

        if (responseCode == 200) {
          // Token works - start download
          await downloadModel(tokenData.accessToken);
        } else if (responseCode == 403) {
          // Token is valid but user needs to accept license
          showUserAgreement();
        } else {
          // Token doesn't work for some reason
          handleError('Failed to access model with token');
        }
      } else {
        // Token exchange failed
        handleError('Failed to exchange authorization code for token');
      }
    } catch (e) {
      handleError('Authentication error: $e');
    }
  }

  /// Shows the license agreement UI when the model requires user acceptance.
  /// This happens for some models that have specific licensing terms.
  void showUserAgreement() {
    setDownloadStatus(DownloadStatus.awaitingLicenseAcceptance);
    setShowAgreementSheet(true);
    Logger.info('Model requires license acceptance');
  }

  /// Actually starts the file download process.
  /// This is called after authentication is complete (if required).
  Future<void> downloadModel(String? accessToken) async {
    setDownloadStatus(DownloadStatus.downloading);

    // Clean up any failed downloads from previous attempts
    await DownloadManager.cleanupFailedDownloads();

    // Start the actual download with flutter_downloader
    final taskId = await DownloadManager.startDownload(
      url: downloadUrl,
      fileName: modelName,
      accessToken: accessToken,
    );

    if (taskId != null) {
      // Save that we have a download in progress for crash recovery
      await DownloadStateManager.saveDownloadInProgress(taskId);
      monitorDownload(taskId, null); // Start monitoring progress
    } else {
      handleError('Failed to start download');
    }
  }

  /// Monitors the progress of an ongoing download using a periodic timer.
  /// Updates UI with progress and handles status changes.
  void monitorDownload(String taskId, BuildContext? context) {
    // Cancel any existing monitoring timer to prevent duplicates
    _monitoringTimer?.cancel();

    Logger.info('Starting download monitoring for task: $taskId');

    // Create a timer that checks download status every second
    _monitoringTimer = Timer.periodic(const Duration(seconds: 1), (
      timer,
    ) async {
      try {
        // Get current status of all download tasks
        final tasks = await DownloadManager.getAllTasks();
        final task = tasks.firstWhere(
          (task) => task.taskId == taskId,
          // Return empty task if not found
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

        // Stop monitoring if task disappeared (system cleanup)
        if (task.taskId.isEmpty) {
          Logger.warning('Task $taskId not found, stopping monitoring');
          timer.cancel();
          _monitoringTimer = null;
          return;
        }

        // Update UI with current progress information
        setProgress(
          DownloadProgress(
            totalBytes: 100, // Using percentage-based progress
            downloadedBytes: task.progress,
            downloadRate: 0, // Rate calculation not implemented
            remainingTime: Duration.zero, // Time calculation not implemented
            status: task.status,
          ),
        );

        // Handle different download status changes
        switch (task.status) {
          case DownloadTaskStatus.complete:
            Logger.info('Download completed for task: $taskId');
            timer.cancel();
            _monitoringTimer = null;

            // Download successfully completed
            setDownloadStatus(DownloadStatus.completed);
            await DownloadStateManager.saveDownloadCompleted();
            Logger.info('Download completed successfully');

            // Automatically navigate to the chat page
            if (context != null && context.mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => ChatPage()),
              );
            }
            break;

          case DownloadTaskStatus.failed:
            Logger.error('Download failed for task: $taskId');
            timer.cancel();
            _monitoringTimer = null;
            setDownloadStatus(DownloadStatus.failed);
            await DownloadStateManager.clearDownloadState();
            handleError(
              'Download failed - network error or insufficient storage',
            );
            break;

          case DownloadTaskStatus.canceled:
            Logger.info('Download cancelled for task: $taskId');
            timer.cancel();
            _monitoringTimer = null;
            // Reset to initial state instead of showing "cancelled"
            setDownloadStatus(DownloadStatus.notStarted);
            setProgress(null);
            await DownloadStateManager.clearDownloadState();
            Logger.info('Download was cancelled and reset to initial state');
            break;

          case DownloadTaskStatus.paused:
            setDownloadStatus(DownloadStatus.paused);
            break;

          case DownloadTaskStatus.running:
          case DownloadTaskStatus.enqueued:
            // Keep current downloading status
            if (task.status == DownloadTaskStatus.running) {
              setDownloadStatus(DownloadStatus.downloading);
            }
            break;

          case DownloadTaskStatus.undefined:
            Logger.warning(
              'Task $taskId has undefined status, stopping monitoring',
            );
            timer.cancel();
            _monitoringTimer = null;
            break;
        }
      } catch (e) {
        Logger.error('Error monitoring download: $e');
        timer.cancel();
        _monitoringTimer = null;
        handleError('Error monitoring download: $e');
      }
    });
  }

  /// Handles error states by updating UI and logging the error.
  /// Centralizes error handling for consistent behavior.
  void handleError(String error) {
    setDownloadStatus(DownloadStatus.failed);
    setErrorMessages([error]);
    Logger.error(error);
  }

  /// Shows a confirmation dialog before canceling a download.
  /// This prevents accidental cancellation of large downloads.
  Future<void> showCancelConfirmation(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // Force user to choose an option
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Warning icon with gradient background
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Colors.red[400]!, Colors.red[600]!],
                    ),
                  ),
                  child: const Icon(
                    Icons.warning_rounded,
                    size: 32,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),

                // Dialog title
                Text(
                  'Cancel Download?',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // Warning message explaining consequences
                Text(
                  'Are you sure you want to cancel the download? All progress will be lost and any downloaded files will be completely deleted.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),

                // Action buttons
                Row(
                  children: [
                    // "Keep Downloading" button (cancel the cancellation)
                    Expanded(
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 48),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Keep Downloading',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // "Cancel Download" button (confirm the cancellation)
                    Expanded(
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 48),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.red[400]!, Colors.red[600]!],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red[400]!.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Cancel Download',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    // If user confirmed cancellation, proceed with it
    if (result == true) {
      await cancelDownload();
    }
  }

  /// Cancels the current download and cleans up all related state.
  /// This completely removes the download and resets the UI.
  Future<void> cancelDownload() async {
    // Stop monitoring first to prevent timer conflicts
    _monitoringTimer?.cancel();
    _monitoringTimer = null;

    // Cancel the download and delete any partial files
    await DownloadManager.cancelAndDeleteDownload();
    await DownloadStateManager.clearDownloadState();

    // Reset UI to initial state
    setDownloadStatus(DownloadStatus.notStarted);
    setProgress(null);
    Logger.info('Download cancelled and completely cleaned up');
  }

  /// Pauses the current download while preserving progress.
  /// The download can be resumed later from where it left off.
  Future<void> pauseDownload() async {
    await DownloadManager.pauseDownload();
    // Keep the download state as in_progress when paused
    setDownloadStatus(DownloadStatus.paused);
  }

  /// Resumes a previously paused download from where it left off.
  /// Gets a new task ID and restarts monitoring for the resumed download.
  Future<void> resumeDownload() async {
    // Ask the download manager to resume and get the new task ID
    final newTaskId = await DownloadManager.resumeDownload();
    if (newTaskId == null) {
      handleError('Unable to resume download (not resumable?)');
      return;
    }

    // Persist the fresh task ID so we survive app restarts
    await DownloadStateManager.saveDownloadInProgress(newTaskId);

    // Start monitoring progress from the correct task
    monitorDownload(newTaskId, null);

    setDownloadStatus(DownloadStatus.downloading);
  }

  /// Opens the license agreement in the user's browser.
  /// Called when a model requires explicit license acceptance.
  Future<void> openLicenseAgreement() async {
    setShowAgreementSheet(false);

    // Try to open the model's license page in external browser
    if (await canLaunchUrl(Uri.parse(modelCardUrl))) {
      await launchUrl(
        Uri.parse(modelCardUrl),
        mode: LaunchMode.externalApplication, // Force external browser
      );
      Logger.info('Opened license agreement in browser');

      // After opening the license, allow user to manually retry download
      setDownloadStatus(DownloadStatus.awaitingLicenseAcceptance);
    }
  }

  /// Cancels the license agreement process and returns to initial state.
  /// Called when user dismisses the license agreement sheet.
  void cancelLicenseAgreement() {
    setShowAgreementSheet(false);
    setDownloadStatus(DownloadStatus.notStarted);
  }
}
