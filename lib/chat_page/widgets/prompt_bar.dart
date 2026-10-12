// lib/chat_page/widgets/prompt_bar.dart
// ── BRUTALIST EDITORIAL DESIGN ──────────────────────────────────────────────

import 'dart:io';
import 'package:flutter/material.dart';
import 'semantic_material_button.dart';

const _cream = Color(0xFFF5F0E8);
const _ink = Color(0xFF1A1A1A);
const _inkMute = Color(0xFF888070);
const _accent = Color(0xFFE8441A);
const _paper = Color(0xFFEDE8DF);
const _borderW = 2.0;

class PromptBar extends StatefulWidget {
  final Future<void> Function(String) onPromptWithPhoto;
  final Future<void> Function(String) onPromptTextOnly;
  final Future<void> Function(String)? onPromptWithAgent; // NEW
  final bool disabled;
  final bool speechEnabled;
  final bool listening;
  final VoidCallback onToggleListening;
  final Future<void> Function()? onStopTts;

  const PromptBar({
    Key? key,
    required this.onPromptWithPhoto,
    required this.onPromptTextOnly,
    this.onPromptWithAgent,
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
  bool _focused = false;

  late AnimationController _pressCtrl;
  late Animation<double> _pressAnim;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _pressAnim = Tween<double>(begin: 1.0, end: 0.97).animate(_pressCtrl);
    _ctrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  // ── Public API ──────────────────────────────────────────────────────────────
  String get currentText => _ctrl.text;
  void clear() => _ctrl.clear();
  Future<void> sendTextOnly() async => _sendText(_ctrl.text);
  Future<void> sendWithPhoto() async => _sendWithPhoto(_ctrl.text);
  Future<void> sendWithAgent() async => _sendWithAgent(_ctrl.text); // NEW

  void updateText(String text) {
    setState(() {
      _ctrl.text = text;
      _ctrl.selection = TextSelection.fromPosition(
        TextPosition(offset: text.length),
      );
    });
  }

  void _stopVoice() {
    if (widget.listening) widget.onToggleListening();
  }

  Future<void> _handleDictation() async {
    if (widget.disabled || _sending) return;
    if (widget.listening) {
      widget.onToggleListening();
    } else {
      widget.onToggleListening();
    }
  }

  Future<void> _sendWithPhoto(String prompt) async {
    if (widget.disabled || _sending) return;
    final txt = prompt.trim();
    if (txt.isEmpty) return;
    await widget.onStopTts?.call();
    _stopVoice();
    _ctrl.clear();
    setState(() => _sending = true);
    try {
      await widget.onPromptWithPhoto(txt);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _sendWithAgent(String prompt) async {
    if (widget.disabled || _sending || widget.onPromptWithAgent == null) return;
    final txt = prompt.trim();
    if (txt.isEmpty) return;
    await widget.onStopTts?.call();
    _stopVoice();
    _ctrl.clear();
    setState(() => _sending = true);
    try {
      await widget.onPromptWithAgent!(txt);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _sendText(String prompt) async {
    if (widget.disabled || _sending) return;
    final txt = prompt.trim();
    if (txt.isEmpty) return;
    await widget.onStopTts?.call();
    _stopVoice();
    _ctrl.clear();
    setState(() => _sending = true);
    try {
      await widget.onPromptTextOnly(txt);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  // ── Brutalist button ─────────────────────────────────────────────────────
  Widget _buildBtn({
    required String label,
    required VoidCallback? onPressed,
    required IconData icon,
    required bool isAccent,
    bool isExpanded = true,
    String? hint,
  }) {
    final enabled = onPressed != null && !widget.disabled && !_sending;
    final bg = enabled ? (isAccent ? _accent : _ink) : const Color(0xFFCCC8BE);
    final fg = enabled ? _cream : _inkMute;

    Widget btn = AnimatedBuilder(
      animation: _pressAnim,
      builder: (_, child) =>
          Transform.scale(scale: _pressAnim.value, child: child),
      child: GestureDetector(
        onTapDown: enabled ? (_) => _pressCtrl.forward() : null,
        onTapUp: enabled ? (_) => _pressCtrl.reverse() : null,
        onTapCancel: enabled ? () => _pressCtrl.reverse() : null,
        onTap: enabled ? onPressed : null,
        child: Platform.isAndroid
            ? Semantics(
                button: true,
                enabled: enabled,
                label: label,
                hint: hint,
                onTap: enabled ? onPressed : null,
                child: _btnBody(bg, fg, icon, label, enabled),
              )
            : _btnBody(bg, fg, icon, label, enabled),
      ),
    );

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

  Widget _btnBody(
    Color bg,
    Color fg,
    IconData icon,
    String label,
    bool enabled,
  ) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(
          color: enabled ? _ink : const Color(0xFFCCC8BE),
          width: _borderW,
        ),
        boxShadow: enabled
            ? const [
                BoxShadow(color: _ink, offset: Offset(3, 3), blurRadius: 0),
              ]
            : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_sending)
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: fg),
            )
          else
            Icon(icon, color: fg, size: 16),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                color: fg,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
                fontFamily: 'monospace',
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasText = _ctrl.text.trim().isNotEmpty;
    final disabled = widget.disabled || _sending;

    return SafeArea(
      child: FocusTraversalGroup(
        policy: WidgetOrderTraversalPolicy(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Text input ──────────────────────────────────────────────
            Focus(
              onFocusChange: (f) => setState(() => _focused = f),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  color: _paper,
                  border: Border.all(
                    color: _focused ? _accent : _ink,
                    width: _focused ? 2.5 : _borderW,
                  ),
                  boxShadow: _focused
                      ? const [
                          BoxShadow(
                            color: _accent,
                            offset: Offset(3, 3),
                            blurRadius: 0,
                          ),
                        ]
                      : const [
                          BoxShadow(
                            color: _ink,
                            offset: Offset(3, 3),
                            blurRadius: 0,
                          ),
                        ],
                ),
                child: TextField(
                  controller: _ctrl,
                  enabled: !disabled,
                  minLines: 1,
                  maxLines: 4,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    height: 1.45,
                  ),
                  cursorColor: _accent,
                  textInputAction: TextInputAction.newline,
                  decoration: InputDecoration(
                    hintText: 'Type your message here…',
                    hintStyle: const TextStyle(
                      color: _inkMute,
                      fontSize: 14,
                      fontFamily: 'monospace',
                    ),
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
                    suffixIcon: hasText
                        ? GestureDetector(
                            onTap: () {
                              _ctrl.clear();
                              setState(() {});
                            },
                            child: const Padding(
                              padding: EdgeInsets.only(right: 4),
                              child: Icon(
                                Icons.close_rounded,
                                color: _inkMute,
                                size: 16,
                              ),
                            ),
                          )
                        : null,
                  ),
                  onSubmitted: hasText ? (t) => _sendWithPhoto(t) : null,
                ),
              ),
            ),

            const SizedBox(height: 10),

            // ── Voice button ────────────────────────────────────────────
            // Keep this visible even when the platform speech engine is not
            // available, so users always know where voice input lives.
            _buildBtn(
              label: widget.listening ? 'STOP VOICE' : 'VOICE INPUT',
              hint: widget.speechEnabled
                  ? (widget.listening
                        ? 'Double-tap to stop recording'
                        : 'Double-tap to start recording')
                  : 'Voice input is unavailable on this device',
              icon: widget.listening
                  ? Icons.mic_off_rounded
                  : Icons.mic_rounded,
              onPressed: widget.speechEnabled ? _handleDictation : null,
              isAccent: widget.listening,
              isExpanded: false,
            ),
            const SizedBox(height: 10),

            // ── Send buttons ────────────────────────────────────────────
            Row(
              children: [
                _buildBtn(
                  label: 'SEND TEXT',
                  hint: hasText
                      ? 'Double-tap to send as text only'
                      : 'Type a message first',
                  icon: Icons.send_rounded,
                  onPressed: hasText ? () => _sendText(_ctrl.text) : null,
                  isAccent: false,
                ),
                const SizedBox(width: 10),
                _buildBtn(
                  label: 'SEND + PHOTO',
                  hint: hasText
                      ? 'Double-tap to send with camera photo'
                      : 'Type a message first',
                  icon: Icons.camera_alt_rounded,
                  onPressed: hasText ? () => _sendWithPhoto(_ctrl.text) : null,
                  isAccent: true,
                ),
              ],
            ),

            // ── Agent button (shown only when callback is wired) ────────
            if (widget.onPromptWithAgent != null) ...[
              const SizedBox(height: 10),
              _buildBtn(
                label: 'AGENT',
                hint: hasText
                    ? 'Double-tap to send with AI agent — auto-selects best tool'
                    : 'Type a message first',
                icon: Icons.auto_awesome_rounded,
                onPressed: hasText ? () => _sendWithAgent(_ctrl.text) : null,
                isAccent: false,
                isExpanded: false,
              ),
            ],

            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }
}
