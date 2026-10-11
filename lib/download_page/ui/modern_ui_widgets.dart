// download_page/ui/modern_ui_widgets.dart
// ── BRUTALIST EDITORIAL DESIGN ──────────────────────────────────────────────
// Cream bg · near-black text · orange-red accent · thick borders · bold type

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/enums.dart';
import '../models/models.dart';

// ─── Design tokens ─────────────────────────────────────────────────────────
abstract class BV {
  static const cream   = Color(0xFFF5F0E8);
  static const ink     = Color(0xFF1A1A1A);
  static const inkSoft = Color(0xFF3A3530);
  static const inkMute = Color(0xFF888070);
  static const accent  = Color(0xFFE8441A); // orange-red
  static const accentDim = Color(0xFFF2C5B5);
  static const paper   = Color(0xFFEDE8DF); // slightly darker cream for cards
  static const border  = Color(0xFF1A1A1A);
  static const borderW = 2.0;
  static const borderWThick = 3.0;

  // Text styles
  static const monoSm = TextStyle(
    fontFamily: 'monospace', fontSize: 11,
    color: inkMute, letterSpacing: 0.5,
  );
  static const monoMd = TextStyle(
    fontFamily: 'monospace', fontSize: 13,
    color: inkSoft, fontWeight: FontWeight.w600,
  );
  static const labelSm = TextStyle(
    fontSize: 10, fontWeight: FontWeight.w700,
    color: inkMute, letterSpacing: 1.2,
  );
}
// ──────────────────────────────────────────────────────────────────────────

class ModernUIWidgets {

  // ── Thick-bordered button (brutalist style) ───────────────────────────────
  static Widget _buildGradientButton({
    required VoidCallback? onPressed,
    required String text,
    required IconData icon,
    bool isAccent = true,
    bool isSecondary = false,
    double? width,
  }) {
    final enabled = onPressed != null;

    final bg = enabled
        ? (isAccent ? BV.accent : BV.ink)
        : const Color(0xFFCCC8BE);
    final fg = enabled ? BV.cream : BV.inkMute;

    return GestureDetector(
      onTap: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: width,
        height: 56,
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: enabled ? BV.ink : const Color(0xFFCCC8BE), width: BV.borderWThick),
          // Brutalist offset shadow
          boxShadow: enabled
              ? const [BoxShadow(color: BV.ink, offset: Offset(4, 4), blurRadius: 0)]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: fg, size: 18),
            const SizedBox(width: 10),
            Text(
              text,
              style: TextStyle(
                color: fg,
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Download icon ─────────────────────────────────────────────────────────
  static Widget buildDownloadIcon(DownloadStatus status, DownloadProgress? progress) {
    Widget iconWidget;

    switch (status) {
      case DownloadStatus.notStarted:
      case DownloadStatus.cancelled:
        iconWidget = _EditorialIcon(icon: Icons.download_rounded, key: const ValueKey('dl'));
        break;
      case DownloadStatus.failed:
        iconWidget = _EditorialIcon(icon: Icons.error_outline_rounded, accentFill: true, key: const ValueKey('err'));
        break;
      case DownloadStatus.checkingAccess:
      case DownloadStatus.authenticating:
        iconWidget = _SpinningEditorialIcon(key: const ValueKey('spin'));
        break;
      case DownloadStatus.downloading:
        iconWidget = _PulsingEditorialIcon(key: const ValueKey('pdl'));
        break;
      case DownloadStatus.paused:
        iconWidget = _EditorialIcon(icon: Icons.pause_rounded, key: const ValueKey('pause'));
        break;
      case DownloadStatus.completed:
        iconWidget = _EditorialIcon(icon: Icons.check_rounded, accentFill: true, key: const ValueKey('done'));
        break;
      case DownloadStatus.awaitingLicenseAcceptance:
        iconWidget = _EditorialIcon(icon: Icons.assignment_rounded, key: const ValueKey('lic'));
        break;
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: iconWidget,
    );
  }

  // ── Status message ────────────────────────────────────────────────────────
  static Widget buildStatusMessage(
    DownloadStatus status,
    DownloadProgress? progress,
    List<String> errorMessages,
  ) {
    String eyebrow;
    String headline;
    String body;

    switch (status) {
      case DownloadStatus.notStarted:
        eyebrow  = 'STEP 01 — GET READY';
        headline = 'Download\nthe model.';
        body     = 'Requires a free Hugging Face account to accept the license. ~4 GB storage needed.';
        break;
      case DownloadStatus.checkingAccess:
        eyebrow  = 'WORKING —';
        headline = 'Checking\naccess.';
        body     = 'Verifying model availability and permissions…';
        break;
      case DownloadStatus.authenticating:
        eyebrow  = 'WORKING —';
        headline = 'Connecting\naccount.';
        body     = 'Authenticating with Hugging Face…';
        break;
      case DownloadStatus.awaitingLicenseAcceptance:
        eyebrow  = 'ACTION NEEDED —';
        headline = 'Accept the\nlicense.';
        body     = 'Review and accept the model license on Hugging Face to proceed.';
        break;
      case DownloadStatus.downloading:
        eyebrow  = 'IN PROGRESS —';
        headline = 'Downloading\nmodel.';
        body     = 'Do not close the app. May take a few minutes to half an hour on slower connections.';
        break;
      case DownloadStatus.paused:
        eyebrow  = 'PAUSED —';
        headline = 'Download\npaused.';
        body     = 'Tap Resume to continue downloading your model.';
        break;
      case DownloadStatus.completed:
        eyebrow  = 'ALL DONE —';
        headline = 'Model is\nready.';
        body     = 'Your AI vision assistant is loaded and ready to use.';
        break;
      case DownloadStatus.failed:
        eyebrow  = 'ERROR —';
        headline = 'Download\nfailed.';
        body     = errorMessages.isNotEmpty
            ? errorMessages.last
            : 'Something went wrong. Please check your connection and try again.';
        break;
      case DownloadStatus.cancelled:
        eyebrow  = 'STEP 01 — GET READY';
        headline = 'Download\nthe model.';
        body     = 'Requires a free Hugging Face account to accept the license. ~4 GB storage needed.';
        break;
    }

    final isActive = status == DownloadStatus.downloading || status == DownloadStatus.paused;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Eyebrow label — monospace
        Text(eyebrow, style: BV.monoSm.copyWith(color: BV.accent, fontWeight: FontWeight.w700, letterSpacing: 1.0)),
        const SizedBox(height: 8),
        // Big editorial headline
        Text(
          headline,
          style: const TextStyle(
            fontSize: 42,
            fontWeight: FontWeight.w900,
            color: BV.ink,
            height: 0.95,
            letterSpacing: -1.5,
          ),
        ),
        const SizedBox(height: 14),
        // Thin rule
        Container(height: 2, width: 40, color: BV.accent),
        const SizedBox(height: 14),
        // Body text
        Text(
          body,
          style: const TextStyle(
            fontSize: 14,
            color: BV.inkSoft,
            height: 1.6,
            fontFamily: 'monospace',
          ),
        ),
        // Percentage display during download
        if (progress != null && isActive) ...[
          const SizedBox(height: 20),
          _PercentDisplay(percent: progress.progressPercent),
        ],
      ],
    );
  }

  // ── Progress bar ──────────────────────────────────────────────────────────
  static Widget buildProgressBar(DownloadProgress? progress, DownloadStatus status) {
    final isActive = status == DownloadStatus.downloading || status == DownloadStatus.paused;
    if (progress == null || !isActive) return const SizedBox.shrink();

    final isPaused = status == DownloadStatus.paused;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Track — thick bordered
        Container(
          width: double.infinity,
          height: 16,
          decoration: BoxDecoration(
            color: BV.paper,
            border: Border.all(color: BV.ink, width: BV.borderW),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: progress.progress,
              child: Container(
                color: isPaused ? const Color(0xFFD4A017) : BV.accent,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Speed / ETA row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (progress.downloadRate > 0)
              Text(
                '${(progress.downloadRate / 1024 / 1024).toStringAsFixed(1)} MB/s',
                style: BV.monoSm,
              ),
            if (progress.remainingTime.inSeconds > 0)
              Text(
                _fmt(progress.remainingTime),
                style: BV.monoSm,
              ),
          ],
        ),
      ],
    );
  }

  static String _fmt(Duration d) {
    if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes.remainder(60)}m remaining';
    if (d.inMinutes > 0) return '${d.inMinutes}m ${d.inSeconds.remainder(60)}s remaining';
    return '${d.inSeconds}s remaining';
  }

  // ── Action buttons ────────────────────────────────────────────────────────
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
          text: 'Download Model  →',
          icon: Icons.download_rounded,
          width: double.infinity,
        );
      case DownloadStatus.awaitingLicenseAcceptance:
        return _buildGradientButton(
          onPressed: onStartDownload,
          text: 'Start Download  →',
          icon: Icons.download_rounded,
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
                isAccent: false,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildGradientButton(
                onPressed: onCancelDownload,
                text: 'Cancel',
                icon: Icons.close_rounded,
                isAccent: false,
              ),
            ),
          ],
        );
      case DownloadStatus.paused:
        return _buildGradientButton(
          onPressed: onResumeDownload,
          text: 'Resume Download  →',
          icon: Icons.play_arrow_rounded,
          width: double.infinity,
        );
      case DownloadStatus.completed:
        WidgetsBinding.instance.addPostFrameCallback((_) => onGoToChat());
        return const SizedBox.shrink();
      default:
        return const SizedBox.shrink();
    }
  }

  // ── Logs button ───────────────────────────────────────────────────────────
  static Widget buildLogsButton(BuildContext context, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: BV.cream,
          border: Border.all(color: BV.ink, width: BV.borderW),
          boxShadow: const [BoxShadow(color: BV.ink, offset: Offset(2, 2), blurRadius: 0)],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.list_alt_rounded, color: BV.ink, size: 15),
            SizedBox(width: 6),
            Text('LOGS', style: BV.labelSm),
          ],
        ),
      ),
    );
  }

  // ── License bottom sheet ──────────────────────────────────────────────────
  static Widget buildLicenseBottomSheet(
    BuildContext context,
    VoidCallback onCancel,
    VoidCallback onViewLicense,
  ) {
    return Container(
      decoration: const BoxDecoration(
        color: BV.cream,
        border: Border(top: BorderSide(color: BV.ink, width: BV.borderWThick)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36, height: 3,
              color: BV.inkMute,
            ),
          ),
          const SizedBox(height: 24),
          // Eyebrow
          const Text('ACTION NEEDED —', style: BV.monoSm),
          const SizedBox(height: 6),
          const Text(
            'License\nrequired.',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: BV.ink, height: 0.95, letterSpacing: -1),
          ),
          const SizedBox(height: 14),
          Container(height: 2, width: 32, color: BV.accent),
          const SizedBox(height: 14),
          const Text(
            'This model requires you to review and accept license terms on Hugging Face before downloading.',
            style: TextStyle(fontSize: 13, color: BV.inkSoft, fontFamily: 'monospace', height: 1.6),
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: _buildGradientButton(
                  onPressed: onCancel,
                  text: 'Cancel',
                  icon: Icons.close_rounded,
                  isAccent: false,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildGradientButton(
                  onPressed: onViewLicense,
                  text: 'View License',
                  icon: Icons.open_in_new_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Internal editorial widgets ───────────────────────────────────────────────

/// Square icon with thick border — the brutalist icon unit
class _EditorialIcon extends StatelessWidget {
  final IconData icon;
  final bool accentFill;
  const _EditorialIcon({required this.icon, this.accentFill = false, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        color: accentFill ? BV.accent : BV.cream,
        border: Border.all(color: BV.ink, width: BV.borderWThick),
        boxShadow: const [BoxShadow(color: BV.ink, offset: Offset(5, 5), blurRadius: 0)],
      ),
      child: Icon(icon, size: 44, color: accentFill ? BV.cream : BV.ink),
    );
  }
}

/// Spinning icon for auth/checking states
class _SpinningEditorialIcon extends StatefulWidget {
  const _SpinningEditorialIcon({super.key});
  @override
  State<_SpinningEditorialIcon> createState() => _SpinningEditorialIconState();
}
class _SpinningEditorialIconState extends State<_SpinningEditorialIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(duration: const Duration(seconds: 2), vsync: this)..repeat();
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96, height: 96,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 96, height: 96,
            decoration: BoxDecoration(
              color: BV.cream,
              border: Border.all(color: BV.ink, width: BV.borderWThick),
              boxShadow: const [BoxShadow(color: BV.ink, offset: Offset(5, 5), blurRadius: 0)],
            ),
          ),
          RotationTransition(
            turns: _ctrl,
            child: CustomPaint(size: const Size(72, 72), painter: _DashedCirclePainter()),
          ),
          const Icon(Icons.cloud_rounded, size: 32, color: BV.ink),
        ],
      ),
    );
  }
}

/// Pulsing download icon
class _PulsingEditorialIcon extends StatefulWidget {
  const _PulsingEditorialIcon({super.key});
  @override
  State<_PulsingEditorialIcon> createState() => _PulsingEditorialIconState();
}
class _PulsingEditorialIconState extends State<_PulsingEditorialIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(duration: const Duration(milliseconds: 900), vsync: this)..repeat(reverse: true);
    _scale = Tween<double>(begin: 1.0, end: 1.06).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scale,
      builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
      child: Container(
        width: 96, height: 96,
        decoration: BoxDecoration(
          color: BV.accent,
          border: Border.all(color: BV.ink, width: BV.borderWThick),
          boxShadow: const [BoxShadow(color: BV.ink, offset: Offset(5, 5), blurRadius: 0)],
        ),
        child: const Icon(Icons.download_rounded, size: 44, color: BV.cream),
      ),
    );
  }
}

/// Large percentage counter
class _PercentDisplay extends StatelessWidget {
  final int percent;
  const _PercentDisplay({required this.percent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: BV.paper,
        border: Border.all(color: BV.ink, width: BV.borderW),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '$percent',
            style: const TextStyle(
              fontSize: 56, fontWeight: FontWeight.w900,
              color: BV.accent, height: 1.0, letterSpacing: -2,
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text('%', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: BV.ink)),
          ),
        ],
      ),
    );
  }
}

/// Dashed circle painter for the spinning icon
class _DashedCirclePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = BV.accent
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    final r = size.width / 2;
    const dashes = 12;
    const dashAngle = math.pi * 2 / dashes;
    for (int i = 0; i < dashes; i++) {
      final start = i * dashAngle;
      canvas.drawArc(Rect.fromCircle(center: Offset(r, r), radius: r - 2), start, dashAngle * 0.55, false, paint);
    }
  }
  @override
  bool shouldRepaint(_) => false;
}
