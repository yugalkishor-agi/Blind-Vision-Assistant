// download_page/model_download_page.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:gemma_chat/chat_page/gemma_vision_chat.dart';

import 'models/enums.dart';
import 'models/models.dart';
import 'services/logger.dart';
import 'services/download_manager.dart';
import 'logic/download_logic.dart';
import 'ui/modern_ui_widgets.dart';
import 'ui/ui_helpers.dart';

/// Main page widget that handles the model download UI and state management.
/// This is a StatefulWidget that manages the download process for ML models,
/// including authentication, progress tracking, error handling, and user interactions.
class ModelDownloadPage extends StatefulWidget {
  const ModelDownloadPage({Key? key}) : super(key: key);

  @override
  State<ModelDownloadPage> createState() => _ModelDownloadPageState();
}

class _ModelDownloadPageState extends State<ModelDownloadPage> {
  // Current status of the download process (notStarted, downloading, completed, etc.)
  DownloadStatus _downloadStatus = DownloadStatus.notStarted;

  // Progress information including bytes downloaded, speed, and estimated time
  DownloadProgress? _progress;

  // List of error messages to display to the user when downloads fail
  List<String> _errorMessages = [];

  // Controls visibility of the license agreement bottom sheet
  bool _showAgreementSheet = false;

  // Subscription to listen for log updates and refresh UI accordingly
  late StreamSubscription _logSubscription;

  // Business logic handler that manages all download operations
  late DownloadPageLogic _logic;

  @override
  void initState() {
    super.initState();
    // Initialize all components in the correct order
    _initializeLogic();
    _initializeDownloader();
    _checkDownloadState();
    _setupLogListener();
  }

  @override
  void dispose() {
    // Clean up resources to prevent memory leaks
    _logSubscription.cancel();
    _logic.dispose(); // Dispose the logic to clean up timers
    super.dispose();
  }

  /// Initializes the download logic with callback functions that update the UI state.
  /// This separates business logic from UI concerns by passing state setters as callbacks.
  void _initializeLogic() {
    _logic = DownloadPageLogic(
      // Callback to update download status (triggers UI rebuilds)
      setDownloadStatus: (status) => setState(() => _downloadStatus = status),
      // Callback to update progress information (updates progress bars/text)
      setProgress: (progress) => setState(() => _progress = progress),
      // Callback to update error messages (shows error dialogs/messages)
      setErrorMessages: (messages) => setState(() => _errorMessages = messages),
      // Callback to show/hide license agreement sheet
      setShowAgreementSheet: (show) =>
          setState(() => _showAgreementSheet = show),
    );
  }

  /// Sets up a listener for log entries to refresh the UI when new logs are added.
  /// This ensures the logs dialog shows real-time updates without manual refresh.
  void _setupLogListener() {
    _logSubscription = Logger.logStream.listen((logEntry) {
      setState(() {}); // Trigger rebuild to update logs display
    });
  }

  /// Initializes the download manager system.
  /// This prepares the underlying download infrastructure for use.
  Future<void> _initializeDownloader() async {
    await DownloadManager.initialize();
    Logger.info('Download manager initialized');
  }

  /// Checks if there are any ongoing downloads from previous app sessions.
  /// This handles app restarts gracefully by resuming interrupted downloads.
  Future<void> _checkDownloadState() async {
    await _logic.checkForOngoingDownloads(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Light background for modern look
      body: SafeArea(
        child: Stack(
          children: [
            // Main content area with padding and centered layout
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Top spacer to center the main content vertically
                  const Spacer(flex: 1),

                  // Main content area - centered vertically
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Animated download icon that changes based on status
                      ModernUIWidgets.buildDownloadIcon(
                        _downloadStatus,
                        _progress,
                      ),

                      const SizedBox(height: 32),

                      // Status message text that explains current download state
                      ModernUIWidgets.buildStatusMessage(
                        _downloadStatus,
                        _progress,
                        _errorMessages,
                      ),

                      const SizedBox(height: 24),

                      // Progress bar showing download completion percentage
                      ModernUIWidgets.buildProgressBar(
                        _progress,
                        _downloadStatus,
                      ),

                      const SizedBox(height: 40),

                      // Action buttons (Start, Pause, Resume, Cancel, Continue)
                      // Different buttons appear based on current download status
                      ModernUIWidgets.buildActionButtons(
                        _downloadStatus,
                        () => _logic.startDownload(), // Start new download
                        () => _logic.pauseDownload(), // Pause active download
                        () => _logic.resumeDownload(), // Resume paused download
                        () => _logic.showCancelConfirmation(
                          context,
                        ), // Cancel with confirmation
                        // Navigate to chat page when download is complete
                        () => Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (context) => ChatPage()),
                        ),
                      ),
                    ],
                  ),

                  // Bottom spacer to balance the layout
                  const Spacer(flex: 1),

                  // Error details button - only shown when there are errors
                  if (_errorMessages.isNotEmpty &&
                      _downloadStatus == DownloadStatus.failed) ...[
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.red[50], // Light red background
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red[200]!),
                      ),
                      child: TextButton.icon(
                        onPressed: () =>
                            UIHelpers.showErrorDialog(context, _errorMessages),
                        icon: Icon(Icons.error_outline, color: Colors.red[600]),
                        label: Text(
                          'View Error Details',
                          style: TextStyle(color: Colors.red[600]),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            ),

            // Logs button positioned at top right corner for debugging
            ModernUIWidgets.buildLogsButton(
              context,
              () => UIHelpers.showLogsDialog(context),
            ),
          ],
        ),
      ),
      // License agreement bottom sheet - shown when model requires acceptance
      bottomSheet: _showAgreementSheet
          ? ModernUIWidgets.buildLicenseBottomSheet(
              context,
              () => _logic.cancelLicenseAgreement(), // Cancel agreement
              () => _logic.openLicenseAgreement(), // Open license in browser
            )
          : null,
    );
  }
}
