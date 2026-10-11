// download_page/ui/modern_ui_widgets.dart

import 'package:flutter/material.dart';
import '../models/enums.dart';
import '../models/models.dart';

// ─── Design tokens ────────────────────────────────────────────────────────────
class _C {
  static const bg        = Color(0xFF0A0A14);
  static const surface   = Color(0xFF12121E);
  static const surface2  = Color(0xFF1A1A2E);
  static const border    = Color(0xFF2D2D3F);
  static const violet    = Color(0xFF7C3AED);
  static const cyan      = Color(0xFF06B6D4);
  static const pink      = Color(0xFFEC4899);
  static const green     = Color(0xFF10B981);
  static const amber     = Color(0xFFF59E0B);
  static const red       = Color(0xFFEF4444);
  static const textHi    = Color(0xFFF1F5F9);
  static const textMid   = Color(0xFF94A3B8);
  static const textLo    = Color(0xFF475569);
}
// ──────────────────────────────────────────────────────────────────────────────

class ModernUIWidgets {

  // ── Internal gradient button ───────────────────────────────────────────────
  static Widget _buildGradientButton({
    required VoidCallback? onPressed,
    required String text,
    required IconData icon,
    List<Color>? gradientColors,
    bool isSecondary = false,
    double? width,
  }) {
    final enabled = onPressed != null;
    final colors = gradientColors ??
        (isSecondary
            ? [const Color(0xFF374151), const Color(0xFF4B5563)]
            : [_C.violet, const Color(0xFF5B21B6)]);

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: enabled ? 1.0 : 0.45,
      child: Container(
        width: width,
        height: 58,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: enabled ? colors : [const Color(0xFF1E293B), const Color(0xFF1E293B)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: enabled ? colors.first.withOpacity(0.4) : _C.border,
            width: 1,
          ),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: colors.first.withOpacity(0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(16),
            splashColor: Colors.white10,
            highlightColor: Colors.white.withAlpha(13),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Download icon ──────────────────────────────────────────────────────────
  static Widget buildDownloadIcon(DownloadStatus status, DownloadProgress? progress) {
    Widget iconWidget;

    switch (status) {
      case DownloadStatus.notStarted:
      case DownloadStatus.cancelled:
      case DownloadStatus.failed:
        iconWidget = _GlowIcon(
          icon: Icons.download_rounded,
          gradient: [_C.violet, _C.cyan],
          size: 88,
        );
        break;

      case DownloadStatus.checkingAccess:
      case DownloadStatus.authenticating:
        iconWidget = _PulsingRing(color: _C.cyan);
        break;

      case DownloadStatus.downloading:
        iconWidget = _GlowIcon(
          icon: Icons.cloud_download_rounded,
          gradient: [_C.cyan, _C.violet],
          size: 88,
          pulse: true,
        );
        break;

      case DownloadStatus.paused:
        iconWidget = _GlowIcon(
          icon: Icons.pause_circle_rounded,
          gradient: [_C.amber, const Color(0xFFD97706)],
          size: 88,
        );
        break;

      case DownloadStatus.completed:
        iconWidget = _GlowIcon(
          icon: Icons.check_circle_rounded,
          gradient: [_C.green, const Color(0xFF059669)],
          size: 88,
        );
        break;

      case DownloadStatus.awaitingLicenseAcceptance:
        iconWidget = _GlowIcon(
          icon: Icons.assignment_rounded,
          gradient: [_C.amber, _C.pink],
          size: 88,
        );
        break;
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      switchInCurve: Curves.easeOutBack,
      transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: FadeTransition(opacity: anim, child: child)),
      child: iconWidget,
    );
  }

  // ── Status message ─────────────────────────────────────────────────────────
  static Widget buildStatusMessage(
    DownloadStatus status,
    DownloadProgress? progress,
    List<String> errorMessages,
  ) {
    String title;
    String subtitle;
    Color accentColor = _C.violet;

    switch (status) {
      case DownloadStatus.notStarted:
        title = 'Ready to Download';
        subtitle =
            'Create a free Hugging Face account to accept the model license and download. Requires ~4 GB storage.';
        accentColor = _C.violet;
        break;
      case DownloadStatus.checkingAccess:
        title = 'Checking Access';
        subtitle = 'Verifying model availability and permissions…';
        accentColor = _C.cyan;
        break;
      case DownloadStatus.authenticating:
        title = 'Authenticating';
        subtitle = 'Connecting to your Hugging Face account…';
        accentColor = _C.cyan;
        break;
      case DownloadStatus.awaitingLicenseAcceptance:
        title = 'License Required';
        subtitle =
            'Review and accept the model license on Hugging Face to proceed with the download.';
        accentColor = _C.amber;
        break;
      case DownloadStatus.downloading:
        title = 'Downloading Model';
        subtitle =
            'Stay patient — this can take minutes to half an hour on slower connections. Do not close the app.';
        accentColor = _C.cyan;
        break;
      case DownloadStatus.paused:
        title = 'Download Paused';
        subtitle = 'Your download is paused. Tap Resume to continue.';
        accentColor = _C.amber;
        break;
      case DownloadStatus.completed:
        title = 'Model Ready!';
        subtitle = 'The AI model is loaded and ready. Starting your experience…';
        accentColor = _C.green;
        break;
      case DownloadStatus.failed:
        title = 'Download Failed';
        subtitle = errorMessages.isNotEmpty
            ? '${errorMessages.last} Please try again or check your connection.'
            : 'Something went wrong. Please try again.';
        accentColor = _C.red;
        break;
      case DownloadStatus.cancelled:
        title = 'Ready to Download';
        subtitle =
            'Create a free Hugging Face account to accept the model license and download. Requires ~4 GB storage.';
        accentColor = _C.violet;
        break;
    }

    return Column(
      children: [
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [accentColor, _C.textHi],
          ).createShader(bounds),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 15,
            color: _C.textMid,
            height: 1.55,
          ),
          textAlign: TextAlign.center,
        ),
        // Big percentage pill during active download
        if (progress != null &&
            (status == DownloadStatus.downloading || status == DownloadStatus.paused)) ...[
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(40),
              border: Border.all(color: accentColor.withOpacity(0.3)),
            ),
            child: Text(
              '${progress.progressPercent}%',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w900,
                color: accentColor,
                letterSpacing: -1,
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ── Progress bar ───────────────────────────────────────────────────────────
  static Widget buildProgressBar(DownloadProgress? progress, DownloadStatus status) {
    if (progress == null ||
        (status != DownloadStatus.downloading && status != DownloadStatus.paused)) {
      return const SizedBox.shrink();
    }

    final isPaused = status == DownloadStatus.paused;
    final colors = isPaused
        ? [_C.amber, const Color(0xFFD97706)]
        : [_C.violet, _C.cyan];

    return Column(
      children: [
        Stack(
          children: [
            // Track
            Container(
              height: 8,
              width: double.infinity,
              decoration: BoxDecoration(
                color: _C.surface2,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            // Fill
            FractionallySizedBox(
              widthFactor: progress.progress,
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: LinearGradient(colors: colors),
                  boxShadow: [
                    BoxShadow(
                      color: colors.last.withOpacity(0.6),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Speed / ETA info row
        if (progress.downloadRate > 0 || progress.remainingTime.inSeconds > 0)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (progress.downloadRate > 0)
                Text(
                  '${(progress.downloadRate / 1024 / 1024).toStringAsFixed(1)} MB/s',
                  style: const TextStyle(color: _C.textLo, fontSize: 12),
                ),
              if (progress.remainingTime.inSeconds > 0)
                Text(
                  _formatDuration(progress.remainingTime),
                  style: const TextStyle(color: _C.textLo, fontSize: 12),
                ),
            ],
          ),
      ],
    );
  }

  // ── Action buttons ─────────────────────────────────────────────────────────
  static Widget buildActionButtons(
    DownloadStatus status,
    VoidCallback onStartDownload,
    VoidCallback onPauseDownload,
    VoidCallback onResumeDownload,
    VoidCallback onCancelDownload,
    VoidCallback onGoToChat,
  ) {
    switch (status) {
      case DownloadStatus.notStarted:
      case DownloadStatus.failed:
      case DownloadStatus.cancelled:
        return _buildGradientButton(
          onPressed: onStartDownload,
          text: 'Download Model',
          icon: Icons.download_rounded,
          gradientColors: [_C.violet, _C.cyan],
          width: double.infinity,
        );

      case DownloadStatus.awaitingLicenseAcceptance:
        return _buildGradientButton(
          onPressed: onStartDownload,
          text: 'Start Download',
          icon: Icons.download_rounded,
          gradientColors: [_C.amber, _C.pink],
          width: double.infinity,
        );

      case DownloadStatus.downloading:
        return Row(
          children: [
            Expanded(
              child: _buildGradientButton(
                onPressed: onPauseDownload,
                text: 'Pause',
                icon: Icons.pause_rounded,
                gradientColors: [const Color(0xFF374151), const Color(0xFF4B5563)],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildGradientButton(
                onPressed: onCancelDownload,
                text: 'Cancel',
                icon: Icons.close_rounded,
                gradientColors: [_C.red, const Color(0xFFDC2626)],
              ),
            ),
          ],
        );

      case DownloadStatus.paused:
        return _buildGradientButton(
          onPressed: onResumeDownload,
          text: 'Resume Download',
          icon: Icons.play_arrow_rounded,
          gradientColors: [_C.amber, _C.pink],
          width: double.infinity,
        );

      case DownloadStatus.completed:
        WidgetsBinding.instance.addPostFrameCallback((_) => onGoToChat());
        return const SizedBox.shrink();

      default:
        return const SizedBox.shrink();
    }
  }

  // ── Logs button ────────────────────────────────────────────────────────────
  static Widget buildLogsButton(BuildContext context, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        color: _C.surface.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _C.border),
      ),
      child: IconButton(
        icon: const Icon(Icons.list_alt_rounded, color: _C.textMid, size: 20),
        onPressed: onPressed,
        tooltip: 'View Logs',
        padding: const EdgeInsets.all(10),
        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      ),
    );
  }

  // ── License bottom sheet ───────────────────────────────────────────────────
  static Widget buildLicenseBottomSheet(
    BuildContext context,
    VoidCallback onCancel,
    VoidCallback onViewLicense,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: _C.border),
        boxShadow: [
          BoxShadow(
            color: _C.violet.withOpacity(0.15),
            blurRadius: 40,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: _C.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 28),
          // Icon
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [_C.amber, _C.pink],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: _C.amber.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(Icons.assignment_rounded, size: 32, color: Colors.white),
          ),
          const SizedBox(height: 20),
          const Text(
            'License Agreement Required',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: _C.textHi,
              letterSpacing: -0.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const Text(
            'This model requires acceptance of license terms on Hugging Face. Please review and accept to continue.',
            style: TextStyle(fontSize: 15, color: _C.textMid, height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: _buildGradientButton(
                  onPressed: onCancel,
                  text: 'Cancel',
                  icon: Icons.close_rounded,
                  gradientColors: [const Color(0xFF374151), const Color(0xFF4B5563)],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildGradientButton(
                  onPressed: onViewLicense,
                  text: 'View License',
                  icon: Icons.open_in_new_rounded,
                  gradientColors: [_C.amber, _C.pink],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Format a Duration into a human-readable ETA string
  static String _formatDuration(Duration d) {
    if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes.remainder(60)}m left';
    if (d.inMinutes > 0) return '${d.inMinutes}m ${d.inSeconds.remainder(60)}s left';
    return '${d.inSeconds}s left';
  }
}

// ─── Internal animated widgets ────────────────────────────────────────────────

/// Glowing icon with gradient circle backdrop
class _GlowIcon extends StatefulWidget {
  final IconData icon;
  final List<Color> gradient;
  final double size;
  final bool pulse;
  const _GlowIcon({required this.icon, required this.gradient, required this.size, this.pulse = false});

  @override
  State<_GlowIcon> createState() => _GlowIconState();
}

class _GlowIconState extends State<_GlowIcon> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(duration: const Duration(milliseconds: 1600), vsync: this);
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    if (widget.pulse) _ctrl.repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final boxSize = widget.size * 1.2;
    return AnimatedBuilder(
      animation: _scaleAnim,
      builder: (_, child) => Transform.scale(scale: widget.pulse ? _scaleAnim.value : 1.0, child: child),
      child: Container(
        width: boxSize,
        height: boxSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: widget.gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: widget.gradient.first.withOpacity(0.45),
              blurRadius: 36,
              offset: const Offset(0, 12),
            ),
            BoxShadow(
              color: widget.gradient.last.withOpacity(0.25),
              blurRadius: 60,
              spreadRadius: -4,
            ),
          ],
        ),
        child: Icon(widget.icon, color: Colors.white, size: widget.size * 0.48),
      ),
    );
  }
}

/// Spinning ring for auth / checking states
class _PulsingRing extends StatefulWidget {
  final Color color;
  const _PulsingRing({required this.color});

  @override
  State<_PulsingRing> createState() => _PulsingRingState();
}

class _PulsingRingState extends State<_PulsingRing> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(duration: const Duration(seconds: 2), vsync: this)..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 106,
      height: 106,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer glow ring
          Container(
            width: 106,
            height: 106,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: widget.color.withOpacity(0.15), width: 2),
            ),
          ),
          // Spinner
          RotationTransition(
            turns: _ctrl,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: SweepGradient(
                  colors: [widget.color, widget.color.withOpacity(0.0)],
                ),
              ),
            ),
          ),
          // Center dot
          Container(
            width: 70,
            height: 70,
            decoration: const BoxDecoration(
              color: Color(0xFF0A0A14),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.cloud_rounded, color: widget.color, size: 32),
          ),
        ],
      ),
    );
  }
}
