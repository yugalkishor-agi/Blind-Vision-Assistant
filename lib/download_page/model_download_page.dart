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
class ModelDownloadPage extends StatefulWidget {
  const ModelDownloadPage({Key? key}) : super(key: key);

  @override
  State<ModelDownloadPage> createState() => _ModelDownloadPageState();
}

class _ModelDownloadPageState extends State<ModelDownloadPage> {
  DownloadStatus _downloadStatus = DownloadStatus.notStarted;
  DownloadProgress? _progress;
  List<String> _errorMessages = [];
  bool _showAgreementSheet = false;
  late StreamSubscription _logSubscription;
  late DownloadPageLogic _logic;

  @override
  void initState() {
    super.initState();
    _initializeLogic();
    _initializeDownloader();
    _checkDownloadState();
    _setupLogListener();
  }

  @override
  void dispose() {
    _logSubscription.cancel();
    _logic.dispose();
    super.dispose();
  }

  void _initializeLogic() {
    _logic = DownloadPageLogic(
      setDownloadStatus: (status) => setState(() => _downloadStatus = status),
      setProgress: (progress) => setState(() => _progress = progress),
      setErrorMessages: (messages) => setState(() => _errorMessages = messages),
      setShowAgreementSheet: (show) => setState(() => _showAgreementSheet = show),
    );
  }

  void _setupLogListener() {
    _logSubscription = Logger.logStream.listen((logEntry) {
      setState(() {});
    });
  }

  Future<void> _initializeDownloader() async {
    await DownloadManager.initialize();
    Logger.info('Download manager initialized');
  }

  Future<void> _checkDownloadState() async {
    await _logic.checkForOngoingDownloads(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0E8),
      body: SafeArea(
        child: Column(
          children: [
            // ── Brutalist top bar ─────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 16, 16),
              decoration: const BoxDecoration(
                color: Color(0xFFF5F0E8),
                border: Border(bottom: BorderSide(color: Color(0xFF1A1A1A), width: 2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'BLIND VISION',
                        style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w900,
                          color: Color(0xFF1A1A1A), letterSpacing: 2.0,
                        ),
                      ),
                      Text(
                        'ASSISTANT',
                        style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w900,
                          color: Color(0xFFE8441A), letterSpacing: 2.0,
                        ),
                      ),
                    ],
                  ),
                  ModernUIWidgets.buildLogsButton(
                    context,
                    () => UIHelpers.showLogsDialog(context),
                  ),
                ],
              ),
            ),

            // ── Scrollable body ───────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    // Animated status icon
                    ModernUIWidgets.buildDownloadIcon(_downloadStatus, _progress),

                    const SizedBox(height: 32),

                    // Editorial headline + body
                    ModernUIWidgets.buildStatusMessage(
                      _downloadStatus, _progress, _errorMessages,
                    ),

                    const SizedBox(height: 28),

                    // Thick bordered progress bar
                    ModernUIWidgets.buildProgressBar(_progress, _downloadStatus),

                    if (_progress != null &&
                        (_downloadStatus == DownloadStatus.downloading ||
                         _downloadStatus == DownloadStatus.paused))
                      const SizedBox(height: 28)
                    else
                      const SizedBox(height: 20),

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

                    // Error banner
                    if (_errorMessages.isNotEmpty &&
                        _downloadStatus == DownloadStatus.failed) ...[
                      const SizedBox(height: 16),
                      _buildErrorBanner(),
                    ],

                    const SizedBox(height: 32),
                    _buildFooterNote(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomSheet: _showAgreementSheet
          ? ModernUIWidgets.buildLicenseBottomSheet(
              context,
              () => _logic.cancelLicenseAgreement(),
              () => _logic.openLicenseAgreement(),
            )
          : null,
    );
  }

  Widget _buildErrorBanner() {
    return GestureDetector(
      onTap: () => UIHelpers.showErrorDialog(context, _errorMessages),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: const BoxDecoration(
          color: Color(0xFFFFF0EC),
          border: Border.fromBorderSide(
            BorderSide(color: Color(0xFFE8441A), width: 2),
          ),
          boxShadow: [
            BoxShadow(color: Color(0xFFE8441A), offset: Offset(3, 3), blurRadius: 0),
          ],
        ),
        child: const Row(
          children: [
            Icon(Icons.error_outline_rounded, color: Color(0xFFE8441A), size: 18),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Error occurred — tap to view details',
                style: TextStyle(
                  color: Color(0xFFE8441A), fontWeight: FontWeight.w700,
                  fontSize: 13, fontFamily: 'monospace',
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Color(0xFFE8441A), size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildFooterNote() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEDE8DF),
        border: Border.all(color: const Color(0xFF1A1A1A), width: 1.5),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lock_outline_rounded, size: 13, color: Color(0xFF888070)),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Runs fully offline. No data sent anywhere after setup.',
              style: TextStyle(
                fontSize: 11, fontFamily: 'monospace',
                color: Color(0xFF888070), height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
