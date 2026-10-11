// lib/chat_page/widgets/prompt_bar.dart
import 'dart:io';
import 'package:flutter/material.dart';
import '../services/sound_manager.dart';
import 'semantic_material_button.dart';

// ─── Design tokens ────────────────────────────────────────────────────────────
class _C {
  static const bg        = Color(0xFF0A0A14);
  static const surface   = Color(0xFF12121E);
  static const surface2  = Color(0xFF1A1A2E);
  static const border    = Color(0xFF2D2D3F);
  static const borderFocus = Color(0xFF7C3AED);
  static const violet    = Color(0xFF7C3AED);
  static const cyan      = Color(0xFF06B6D4);
  static const pink      = Color(0xFFEC4899);
  static const green     = Color(0xFF10B981);
  static const red       = Color(0xFFEF4444);
  static const textHi    = Color(0xFFF1F5F9);
  static const textMid   = Color(0xFF94A3B8);
  static const textLo    = Color(0xFF475569);
}
// ─────────────────────────────────────────────────────────────────────────────

/// Frosted-glass prompt bar — text input + voice + send buttons
class PromptBar extends StatefulWidget {
  final Future<void> Function(String) onPromptWithPhoto;
  final Future<void> Function(String) onPromptTextOnly;
  final bool disabled;
  final bool speechEnabled;
  final bool listening;
  final VoidCallback onToggleListening;
  final Future<void> Function()? onStopTts;

  const PromptBar({
    Key? key,
    required this.onPromptWithPhoto,
    required this.onPromptTextOnly,
    this.disabled = false,
    required this.speechEnabled,
    required this.listening,
    required this.onToggleListening,
    this.onStopTts,
  }) : super(key: key);

  @override
  State<PromptBar> createState() => PromptBarState();
}

class PromptBarState extends State<PromptBar> with TickerProviderStateMixin {
  final _ctrl = TextEditingController();
  bool _sending = false;
  bool _isFocused = false;

  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 140),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
    _ctrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  // ── Public API ──────────────────────────────────────────────────────────────
  String get currentText => _ctrl.text;
  void clear() => _ctrl.clear();

  Future<void> sendTextOnly() async => _sendText(_ctrl.text);
  Future<void> sendWithPhoto() async => _sendWithPhoto(_ctrl.text);

  void updateText(String text) {
    setState(() {
      _ctrl.text = text;
      _ctrl.selection = TextSelection.fromPosition(
        TextPosition(offset: _ctrl.text.length),
      );
    });
  }

  // ── Internal helpers ────────────────────────────────────────────────────────
  void _stopVoiceIfListening() {
    if (widget.listening) widget.onToggleListening();
  }

  Future<void> _handleDictationToggle() async {
    if (widget.disabled || _sending) return;
    if (widget.listening) {
      widget.onToggleListening();
      await SoundManager.instance.playDictationStop();
    } else {
      await SoundManager.instance.playDictationStart();
      widget.onToggleListening();
    }
  }

  Future<void> _sendWithPhoto(String prompt) async {
    if (widget.disabled || _sending) return;
    final txt = prompt.trim();
    if (txt.isEmpty) return;
    if (widget.onStopTts != null) await widget.onStopTts!();
    _stopVoiceIfListening();
    _ctrl.clear();
    setState(() => _sending = true);
    try {
      await widget.onPromptWithPhoto(txt);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _sendText(String prompt) async {
    if (widget.disabled || _sending) return;
    final txt = prompt.trim();
    if (txt.isEmpty) return;
    if (widget.onStopTts != null) await widget.onStopTts!();
    _stopVoiceIfListening();
    _ctrl.clear();
    setState(() => _sending = true);
    try {
      await widget.onPromptTextOnly(txt);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  // ── Build helpers ───────────────────────────────────────────────────────────

  /// Frosted glass text field
  Widget _buildTextField() {
    final disabled = widget.disabled || _sending;
    final hasText = _ctrl.text.trim().isNotEmpty;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _isFocused ? _C.violet.withOpacity(0.6) : _C.border,
          width: _isFocused ? 1.5 : 1,
        ),
        boxShadow: _isFocused
            ? [BoxShadow(color: _C.violet.withOpacity(0.15), blurRadius: 16, offset: const Offset(0, 4))]
            : null,
      ),
      child: Focus(
        onFocusChange: (hasFocus) => setState(() => _isFocused = hasFocus),
        child: TextField(
          controller: _ctrl,
          enabled: !disabled,
          minLines: 1,
          maxLines: 4,
          style: const TextStyle(
            color: _C.textHi,
            fontSize: 15,
            fontWeight: FontWeight.w400,
            height: 1.4,
          ),
          cursorColor: _C.violet,
          textInputAction: TextInputAction.newline,
          decoration: InputDecoration(
            hintText: 'Ask about what you see…',
            hintStyle: const TextStyle(color: _C.textLo, fontSize: 15),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.fromLTRB(18, 14, 8, 14),
            suffixIcon: hasText
                ? GestureDetector(
                    onTap: () {
                      _ctrl.clear();
                      setState(() {});
                    },
                    child: const Padding(
                      padding: EdgeInsets.only(right: 4),
                      child: Icon(Icons.cancel_rounded, color: _C.textLo, size: 18),
                    ),
                  )
                : null,
          ),
          onSubmitted: hasText ? (t) => _sendWithPhoto(t) : null,
        ),
      ),
    );
  }

  /// Dark neon gradient action button
  Widget _buildActionButton({
    required String label,
    required VoidCallback? onPressed,
    required List<Color> gradientColors,
    required IconData icon,
    bool isExpanded = true,
    bool isEnabled = true,
    String? hint,
  }) {
    final enabled = isEnabled && onPressed != null;

    Widget btn = AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: enabled ? 1.0 : 0.38,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (_, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            gradient: enabled
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: gradientColors,
                  )
                : const LinearGradient(colors: [Color(0xFF1A1A2E), Color(0xFF1A1A2E)]),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: enabled ? gradientColors.first.withOpacity(0.35) : _C.border,
            ),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: gradientColors.first.withOpacity(0.3),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    )
                  ]
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: Platform.isAndroid
                ? Semantics(
                    button: true,
                    enabled: enabled,
                    label: label,
                    hint: hint,
                    onTap: enabled ? onPressed : null,
                    child: InkWell(
                      onTap: enabled
                          ? () {
                              _scaleController.forward().then((_) => _scaleController.reverse());
                              onPressed?.call();
                            }
                          : null,
                      onTapDown: enabled ? (_) => _scaleController.forward() : null,
                      onTapUp: enabled ? (_) => _scaleController.reverse() : null,
                      onTapCancel: enabled ? () => _scaleController.reverse() : null,
                      borderRadius: BorderRadius.circular(14),
                      splashColor: Colors.white10,
                      child: _buttonContent(label, icon, enabled),
                    ),
                  )
                : InkWell(
                    onTap: enabled
                        ? () {
                            _scaleController.forward().then((_) => _scaleController.reverse());
                            onPressed?.call();
                          }
                        : null,
                    borderRadius: BorderRadius.circular(14),
                    child: _buttonContent(label, icon, enabled),
                  ),
          ),
        ),
      ),
    );

    // iOS: wrap in SemanticMaterialButton
    if (!Platform.isAndroid && enabled) {
      btn = SemanticMaterialButton(
        label: label,
        hint: hint,
        onPressed: onPressed,
        disabled: !enabled,
        child: btn,
      );
    }

    return isExpanded ? Expanded(child: btn) : btn;
  }

  Widget _buttonContent(String label, IconData icon, bool enabled) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (_sending)
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          )
        else
          Icon(icon, color: enabled ? Colors.white : _C.textLo, size: 18),
        const SizedBox(width: 7),
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              color: enabled ? Colors.white : _C.textLo,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.1,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final disabled = widget.disabled || _sending;
    final hasText = _ctrl.text.trim().isNotEmpty;

    return SafeArea(
      child: FocusTraversalGroup(
        policy: WidgetOrderTraversalPolicy(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Text field ──────────────────────────────────────────────
            _buildTextField(),

            const SizedBox(height: 12),

            // ── Voice button ────────────────────────────────────────────
            if (widget.speechEnabled) ...[
              _buildActionButton(
                label: widget.listening ? 'Stop Listening' : 'Voice Input',
                hint: widget.listening
                    ? 'Double-tap to stop recording'
                    : 'Double-tap to start recording',
                icon: widget.listening ? Icons.mic_off_rounded : Icons.mic_rounded,
                onPressed: _handleDictationToggle,
                gradientColors: widget.listening
                    ? [_C.red, const Color(0xFFDC2626)]
                    : [_C.green, const Color(0xFF059669)],
                isExpanded: false,
                isEnabled: !widget.disabled,
              ),
              const SizedBox(height: 10),
            ],

            // ── Send buttons ────────────────────────────────────────────
            Row(
              children: [
                _buildActionButton(
                  label: 'Send Text',
                  hint: hasText
                      ? 'Double-tap to send as text only'
                      : 'Type a message first',
                  icon: Icons.send_rounded,
                  onPressed: hasText ? () => _sendText(_ctrl.text) : null,
                  gradientColors: [_C.cyan, const Color(0xFF0891B2)],
                  isEnabled: hasText && !disabled,
                ),
                const SizedBox(width: 10),
                _buildActionButton(
                  label: 'Send + Photo',
                  hint: hasText
                      ? 'Double-tap to send with camera photo'
                      : 'Type a message first',
                  icon: Icons.camera_alt_rounded,
                  onPressed: hasText ? () => _sendWithPhoto(_ctrl.text) : null,
                  gradientColors: [_C.violet, _C.pink],
                  isEnabled: hasText && !disabled,
                ),
              ],
            ),

            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }
}
