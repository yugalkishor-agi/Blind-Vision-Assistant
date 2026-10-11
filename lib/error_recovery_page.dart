// lib/error_recovery_page.dart
import 'package:flutter/material.dart';
import 'package:blind_vision_assistant/download_page/services/download_manager.dart';
import 'package:blind_vision_assistant/download_page/services/download_state_manager.dart';
import 'package:blind_vision_assistant/download_page/model_download_page.dart';

// ─── Design tokens ────────────────────────────────────────────────────────────
class _C {
  static const bg        = Color(0xFF0A0A14);
  static const surface   = Color(0xFF12121E);
  static const surface2  = Color(0xFF1A1A2E);
  static const border    = Color(0xFF2D2D3F);
  static const violet    = Color(0xFF7C3AED);
  static const cyan      = Color(0xFF06B6D4);
  static const red       = Color(0xFFEF4444);
  static const amber     = Color(0xFFF59E0B);
  static const textHi    = Color(0xFFF1F5F9);
  static const textMid   = Color(0xFF94A3B8);
  static const textLo    = Color(0xFF475569);
}
// ─────────────────────────────────────────────────────────────────────────────

class ErrorRecoveryPage extends StatefulWidget {
  const ErrorRecoveryPage({super.key});

  @override
  State<ErrorRecoveryPage> createState() => _ErrorRecoveryPageState();
}

class _ErrorRecoveryPageState extends State<ErrorRecoveryPage>
    with SingleTickerProviderStateMixin {
  bool _isCleaningUp = false;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: Stack(
        children: [
          // ── Red ambient glow (error atmosphere) ───────────────────────────
          Positioned(
            top: -80,
            left: -60,
            child: _ambientBlob(_C.red, 300),
          ),
          Positioned(
            bottom: -60,
            right: -40,
            child: _ambientBlob(_C.violet, 200),
          ),

          // ── Content ───────────────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),

                  // ── Error icon ─────────────────────────────────────────────
                  AnimatedBuilder(
                    animation: _pulseAnim,
                    builder: (_, child) => Transform.scale(
                      scale: _isCleaningUp ? 1.0 : _pulseAnim.value,
                      child: child,
                    ),
                    child: Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [_C.red, Color(0xFFDC2626)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _C.red.withOpacity(0.4),
                            blurRadius: 40,
                            offset: const Offset(0, 16),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.error_outline_rounded,
                        size: 52,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(height: 36),

                  // ── Title ──────────────────────────────────────────────────
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [_C.red, _C.amber],
                    ).createShader(bounds),
                    child: const Text(
                      'Model Failed to Load',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── What happened card ─────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _C.amber.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _C.amber.withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: _C.amber.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.info_outline_rounded, size: 18, color: _C.amber),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'What happened?',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: _C.textHi,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'The AI model file appears to be corrupted or incomplete. This usually happens when the download was interrupted or the file became damaged.',
                          style: TextStyle(
                            fontSize: 14,
                            color: _C.textMid,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(flex: 2),

                  // ── Action section ─────────────────────────────────────────
                  if (_isCleaningUp)
                    _buildCleanupState()
                  else
                    _buildActionState(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ambientBlob(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withOpacity(0.16), Colors.transparent],
        ),
      ),
    );
  }

  Widget _buildCleanupState() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _C.border),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(_C.violet),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Cleaning up…',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _C.textHi,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Removing corrupted files and preparing for a fresh download.',
            style: TextStyle(fontSize: 13, color: _C.textMid, height: 1.5),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActionState() {
    return Column(
      children: [
        // Primary CTA
        GestureDetector(
          onTap: _handleDeleteAndRetry,
          child: Container(
            width: double.infinity,
            height: 58,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_C.violet, _C.cyan],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: _C.violet.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.refresh_rounded, color: Colors.white, size: 22),
                SizedBox(width: 10),
                Text(
                  'Delete & Download Fresh Copy',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Help section
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _C.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _C.border),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.help_outline_rounded, size: 16, color: _C.textLo),
                  SizedBox(width: 7),
                  Text(
                    'Still having issues?',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _C.textMid),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'Force quit the app and try again. If problems persist, delete and reinstall the app for a clean start.',
                style: TextStyle(fontSize: 13, color: _C.textLo, height: 1.5),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _handleDeleteAndRetry() async {
    setState(() {
      _isCleaningUp = true;
    });

    try {
      // Delete the model files
      await DownloadManager.cancelAndDeleteDownload();
      await DownloadStateManager.clearDownloadState();
      await DownloadManager.cleanupAllModelFiles();

      // Navigate to download page
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const ModelDownloadPage()),
        );
      }
    } catch (e) {
      debugPrint('Error cleaning up files: $e');

      // Still navigate even if cleanup failed
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const ModelDownloadPage()),
        );
      }
    }
  }
}
