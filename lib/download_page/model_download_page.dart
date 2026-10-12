// download_page/model_download_page.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:blind_vision_assistant/chat_page/gemma_vision_chat.dart';
import 'package:blind_vision_assistant/chat_page/services/remote_settings_manager.dart';

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

  // ── Dev/testing: custom URL override ─────────────────────────────────────
  // Remove this block before submission — only for emulator testing.
  final TextEditingController _customUrlCtrl = TextEditingController();
  bool _showCustomUrlField = false;

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
    _customUrlCtrl.dispose();
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
                      () => _logic.startDownload(
                        customUrl: _customUrlCtrl.text.trim().isEmpty
                            ? null
                            : _customUrlCtrl.text.trim(),
                      ),
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

                    const SizedBox(height: 20),

                    // ── Dev/testing: custom URL field ──────────────────
                    _buildCustomUrlSection(),

                    const SizedBox(height: 12),

                    // ── Skip to remote model ───────────────────────────
                    _buildSkipToRemoteButton(),

                    const SizedBox(height: 12),
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

  // ── Dev/testing: custom URL section ────────────────────────────────────────
  // TAP the label to expand/collapse. Remove before submission.
  Widget _buildCustomUrlSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tap to toggle
        GestureDetector(
          onTap: () => setState(() => _showCustomUrlField = !_showCustomUrlField),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFEDE8DF),
              border: Border.all(color: const Color(0xFF1A1A1A), width: 1.5),
            ),
            child: Row(
              children: [
                const Icon(Icons.developer_mode_rounded,
                    size: 14, color: Color(0xFF888070)),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'DEV: Use custom URL  (tap to expand)',
                    style: TextStyle(
                      fontSize: 11,
                      fontFamily: 'monospace',
                      color: Color(0xFF888070),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(
                  _showCustomUrlField
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  size: 16,
                  color: const Color(0xFF888070),
                ),
              ],
            ),
          ),
        ),

        if (_showCustomUrlField) ...[
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFEDE8DF),
              border: Border.all(color: const Color(0xFF1A1A1A), width: 2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0xFF1A1A1A),
                  offset: Offset(3, 3),
                  blurRadius: 0,
                ),
              ],
            ),
            child: TextField(
              controller: _customUrlCtrl,
              style: const TextStyle(
                color: Color(0xFF1A1A1A),
                fontSize: 13,
                fontFamily: 'monospace',
              ),
              cursorColor: const Color(0xFFE8441A),
              decoration: InputDecoration(
                hintText:
                    'https://xxxx.trycloudflare.com/gemma-3n-E2B-it-int4.task',
                hintStyle: const TextStyle(
                  color: Color(0xFF888070),
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.all(12),
                suffixIcon: _customUrlCtrl.text.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          _customUrlCtrl.clear();
                          setState(() {});
                        },
                        child: const Icon(Icons.close_rounded,
                            size: 16, color: Color(0xFF888070)),
                      )
                    : null,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(height: 6),
          // Show active URL hint
          if (_customUrlCtrl.text.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                '✓ Will download from custom URL instead of HuggingFace',
                style: const TextStyle(
                  fontSize: 10,
                  fontFamily: 'monospace',
                  color: Color(0xFFE8441A),
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'Leave empty to use default HuggingFace source',
                style: const TextStyle(
                  fontSize: 10,
                  fontFamily: 'monospace',
                  color: Color(0xFF888070),
                ),
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildSkipToRemoteButton() {
    // Only show when a custom URL has been entered
    final url = _customUrlCtrl.text.trim();
    if (url.isEmpty) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () async {
        // Save remote settings so app opens directly next time
        await RemoteSettingsManager.save(useRemote: true, url: url);
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const ChatPage()),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A1A),
          border: Border.fromBorderSide(
            BorderSide(color: Color(0xFFE8441A), width: 2),
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0xFFE8441A),
              offset: Offset(3, 3),
              blurRadius: 0,
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bolt_rounded, color: Color(0xFFE8441A), size: 16),
            SizedBox(width: 8),
            Text(
              'SKIP DOWNLOAD — USE REMOTE MODEL',
              style: TextStyle(
                color: Color(0xFFF5F0E8),
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                fontFamily: 'monospace',
              ),
            ),
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
