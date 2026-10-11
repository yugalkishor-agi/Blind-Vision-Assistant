// download_page/model_download_page.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:blind_vision_assistant/chat_page/gemma_vision_chat.dart';

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
      backgroundColor: const Color(0xFF0A0A14),
      body: Stack(
        children: [
          // ── Ambient background radial glows ──────────────────────────────
          Positioned(
            top: -120,
            left: -80,
            child: _ambientBlob(const Color(0xFF7C3AED), 340),
          ),
          Positioned(
            bottom: -80,
            right: -60,
            child: _ambientBlob(const Color(0xFF06B6D4), 260),
          ),

          // ── Main content ─────────────────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                // ── Top bar with logs button ──────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 16, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // App badge
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF7C3AED), Color(0xFF06B6D4)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.visibility_rounded, color: Colors.white, size: 18),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Vision AI',
                            style: TextStyle(
                              color: Color(0xFFF1F5F9),
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                      // Logs button
                      ModernUIWidgets.buildLogsButton(
                        context,
                        () => UIHelpers.showLogsDialog(context),
                      ),
                    ],
                  ),
                ),

                // ── Scrollable body ───────────────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Animated icon
                        ModernUIWidgets.buildDownloadIcon(_downloadStatus, _progress),

                        const SizedBox(height: 36),

                        // Status headline + subtitle
                        ModernUIWidgets.buildStatusMessage(
                          _downloadStatus,
                          _progress,
                          _errorMessages,
                        ),

                        const SizedBox(height: 28),

                        // Progress bar
                        ModernUIWidgets.buildProgressBar(_progress, _downloadStatus),

                        const SizedBox(height: 44),

                        // Action buttons
                        ModernUIWidgets.buildActionButtons(
                          _downloadStatus,
                          () => _logic.startDownload(),
                          () => _logic.pauseDownload(),
                          () => _logic.resumeDownload(),
                          () => _logic.showCancelConfirmation(context),
                          () => Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (context) => ChatPage()),
                          ),
                        ),

                        // Error details button
                        if (_errorMessages.isNotEmpty &&
                            _downloadStatus == DownloadStatus.failed) ...[
                          const SizedBox(height: 20),
                          _buildErrorBanner(),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      // License agreement bottom sheet - shown when model requires acceptance
      bottomSheet: _showAgreementSheet
          ? ModernUIWidgets.buildLicenseBottomSheet(
              context,
              () => _logic.cancelLicenseAgreement(),
              () => _logic.openLicenseAgreement(),
            )
          : null,
    );
  }

  /// Soft ambient radial glow blob for background depth
  Widget _ambientBlob(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withOpacity(0.18), Colors.transparent],
        ),
      ),
    );
  }

  /// Glassmorphic error banner
  Widget _buildErrorBanner() {
    return GestureDetector(
      onTap: () => UIHelpers.showErrorDialog(context, _errorMessages),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444).withOpacity(0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.35)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'View Error Details',
                style: TextStyle(
                  color: const Color(0xFFEF4444).withOpacity(0.9),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: const Color(0xFFEF4444).withOpacity(0.6), size: 18),
          ],
        ),
      ),
    );
  }
}
