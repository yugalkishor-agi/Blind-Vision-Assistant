// lib/chat_page/widgets/prompt_bar.dart
import 'dart:io';
import 'package:flutter/material.dart';
import '../services/sound_manager.dart';
import 'semantic_material_button.dart';

/// Interactive prompt input bar with text field, voice input, and send buttons
/// Handles both text-only and photo+text message composition with accessibility support
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

  // Button press animation for tactile feedback
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Setup button press animation
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );

    // Rebuild UI when text changes (enables/disables send buttons)
    _ctrl.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  // Public API for external access
  String get currentText => _ctrl.text;
  void clear() => _ctrl.clear();

  /// External API: Send current text without photo (used by keyboard shortcuts)
  Future<void> sendTextOnly() async => _sendText(_ctrl.text);

  /// External API: Send current text with photo (used by keyboard shortcuts)
  Future<void> sendWithPhoto() async => _sendWithPhoto(_ctrl.text);

  /// Update text content programmatically (used by speech recognition)
  void updateText(String text) {
    setState(() {
      _ctrl.text = text;
      // Move cursor to end of text
      _ctrl.selection = TextSelection.fromPosition(
        TextPosition(offset: _ctrl.text.length),
      );
    });
  }

  /// Stop voice input if currently listening (before sending messages)
  void _stopVoiceIfListening() {
    if (widget.listening) {
      widget.onToggleListening();
    }
  }

  /// Handle dictation button with audio feedback and state management
  Future<void> _handleDictationToggle() async {
    if (widget.disabled || _sending) return;

    if (widget.listening) {
      // Stop dictation
      widget.onToggleListening();
      await SoundManager.instance.playDictationStop();
    } else {
      // Start dictation with audio feedback
      await SoundManager.instance.playDictationStart();
      widget.onToggleListening();
    }
  }

  /// Send message with photo capture
  Future<void> _sendWithPhoto(String prompt) async {
    if (widget.disabled || _sending) return;
    final txt = prompt.trim();
    if (txt.isEmpty) return;

    // Stop any ongoing TTS before sending
    if (widget.onStopTts != null) {
      await widget.onStopTts!();
    }

    _stopVoiceIfListening();
    _ctrl.clear();

    setState(() => _sending = true);
    try {
      await widget.onPromptWithPhoto(txt);
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  /// Send text-only message
  Future<void> _sendText(String prompt) async {
    if (widget.disabled || _sending) return;
    final txt = prompt.trim();
    if (txt.isEmpty) return;

    // Stop any ongoing TTS before sending
    if (widget.onStopTts != null) {
      await widget.onStopTts!();
    }

    _stopVoiceIfListening();
    _ctrl.clear();

    setState(() => _sending = true);
    try {
      await widget.onPromptTextOnly(txt);
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  /// Reusable modern container styling
  Widget _buildModernContainer({
    required Widget child,
    EdgeInsets? padding,
    double? height,
    Color? backgroundColor,
  }) {
    return Container(
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.grey.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  /// Platform-aware gradient button with accessibility integration
  Widget _buildModernButton({
    required String label,
    required VoidCallback? onPressed,
    required List<Color> gradientColors,
    bool isExpanded = true,
    bool isEnabled = true,
    IconData? icon,
    String? hint,
  }) {
    // Disabled button styling
    if (!isEnabled || onPressed == null) {
      final disabledButton = Container(
        height: 56,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_sending) ...[
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(width: 8),
              ] else if (icon != null) ...[
                Icon(icon, color: Colors.grey.shade600, size: 20),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      );
      return isExpanded ? Expanded(child: disabledButton) : disabledButton;
    }

    Widget button;

    // Platform-specific button implementation
    if (Platform.isAndroid) {
      // Android: Direct approach without semantic wrapper
      button = AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradientColors,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: gradientColors.first.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: Semantics(
                  button: true,
                  enabled: true,
                  label: label,
                  hint: hint,
                  onTap: onPressed,
                  child: InkWell(
                    onTap: () {
                      _scaleController.forward().then((_) {
                        _scaleController.reverse();
                      });
                      onPressed();
                    },
                    onTapDown: (_) => _scaleController.forward(),
                    onTapUp: (_) => _scaleController.reverse(),
                    onTapCancel: () => _scaleController.reverse(),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_sending) ...[
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ] else if (icon != null) ...[
                            Icon(icon, color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                          ],
                          Flexible(
                            child: Text(
                              label,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
    } else {
      // iOS: Use SemanticMaterialButton for VoiceOver compatibility
      final buttonContent = AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradientColors,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: gradientColors.first.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    _scaleController.forward().then((_) {
                      _scaleController.reverse();
                    });
                    onPressed();
                  },
                  onTapDown: (_) => _scaleController.forward(),
                  onTapUp: (_) => _scaleController.reverse(),
                  onTapCancel: () => _scaleController.reverse(),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_sending) ...[
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ] else if (icon != null) ...[
                          Icon(icon, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                        ],
                        Flexible(
                          child: Text(
                            label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );

      // Wrap with semantic accessibility layer for iOS
      button = SemanticMaterialButton(
        label: label,
        hint: hint,
        onPressed: onPressed,
        disabled: false,
        child: buttonContent,
      );
    }

    return isExpanded ? Expanded(child: button) : button;
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
            // Multi-line text input with clear button
            _buildModernContainer(
              backgroundColor: Colors.white,
              child: Focus(
                canRequestFocus: true,
                child: TextField(
                  controller: _ctrl,
                  enabled: !disabled,
                  minLines: 1,
                  maxLines: 4, // Allow multi-line input
                  style: TextStyle(
                    color: Colors.grey.shade800,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  textInputAction: TextInputAction.newline,
                  decoration: InputDecoration(
                    hintText: 'Type your message here…',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 16,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(20),
                    // Show clear button when text is present
                    suffixIcon: hasText
                        ? IconButton(
                            onPressed: () {
                              _ctrl.clear();
                              setState(() {});
                            },
                            icon: Icon(
                              Icons.clear_rounded,
                              color: Colors.grey.shade500,
                            ),
                          )
                        : null,
                  ),
                  // Enter key sends message with photo
                  onSubmitted: hasText ? (t) => _sendWithPhoto(t) : null,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Voice input toggle button (if speech is enabled)
            if (widget.speechEnabled)
              _buildModernButton(
                label: widget.listening
                    ? 'Stop Voice Input'
                    : 'Start Voice Input',
                hint: widget.listening
                    ? 'Double-tap to stop recording your voice'
                    : 'Double-tap to start recording your voice',
                icon: widget.listening
                    ? Icons.mic_off_rounded
                    : Icons.mic_rounded,
                onPressed: _handleDictationToggle,
                // Dynamic colors based on listening state
                gradientColors: widget.listening
                    ? [Colors.red.shade400, Colors.red.shade600]
                    : [const Color(0xFF4CAF50), const Color(0xFF388E3C)],
                isExpanded: false,
                isEnabled: !widget.disabled,
              ),

            if (widget.speechEnabled) const SizedBox(height: 16),

            // Send buttons row
            Row(
              children: [
                // Text-only send button
                _buildModernButton(
                  label: 'Send Text Only',
                  hint: hasText
                      ? 'Double-tap to send your message as text only'
                      : 'Button disabled - type a message first',
                  onPressed: hasText ? () => _sendText(_ctrl.text) : null,
                  gradientColors: [
                    const Color(0xFF2196F3),
                    const Color(0xFF1976D2),
                  ],
                  isEnabled: hasText && !widget.disabled,
                ),

                const SizedBox(width: 12),

                // Photo + text send button
                _buildModernButton(
                  label: 'Send with Photo',
                  hint: hasText
                      ? 'Double-tap to send your message with a photo from the camera'
                      : 'Button disabled - type a message first',
                  onPressed: hasText ? () => _sendWithPhoto(_ctrl.text) : null,
                  gradientColors: [
                    const Color(0xFFFF6B6B),
                    const Color(0xFFEE5A52),
                  ],
                  isEnabled: hasText && !widget.disabled,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
