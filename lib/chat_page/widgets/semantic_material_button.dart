// lib/chat_page/widgets/semantic_material_button.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'semantic_button_registry.dart';

/// Cross-platform accessible button with VoiceOver/TalkBack integration
/// Handles iOS VoiceOver double-tap vs Android TalkBack activation patterns
class SemanticMaterialButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final Widget child;
  final bool disabled;
  final String? hint;

  const SemanticMaterialButton({
    Key? key,
    required this.label,
    required this.child,
    this.onPressed,
    this.disabled = false,
    this.hint,
  }) : super(key: key);

  @override
  State<SemanticMaterialButton> createState() => _SemanticMaterialButtonState();
}

class _SemanticMaterialButtonState extends State<SemanticMaterialButton> {
  late final FocusNode _focusNode;
  bool _hasAccessibilityFocus = false;

  /// Platform detection for accessibility behavior
  bool get _isIOS => !kIsWeb && Platform.isIOS;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode(debugLabel: widget.label);
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    // Clean up registry if this button was the current semantic target
    if (SemanticButtonRegistry.currentSemanticTap == _handlePressed) {
      SemanticButtonRegistry.currentSemanticTap = null;
    }
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  /// Debug logging for focus changes
  void _onFocusChange() {
    debugPrint(
      _focusNode.hasFocus
          ? 'FLUTTER-FOCUS-GAINED: ${widget.label}'
          : 'FLUTTER-FOCUS-LOST  : ${widget.label}',
    );
  }

  /// Core button press handler with disabled state check
  void _handlePressed() {
    debugPrint('BUTTON-PRESSED: ${widget.label}');
    if (!widget.disabled) {
      widget.onPressed?.call();
    }
  }

  /// External API: Allow programmatic accessibility focus (used by keyboard navigation)
  void gainAccessibilityFocus() {
    setState(() {
      _hasAccessibilityFocus = true;
    });

    // Platform-specific focus handling
    if (_isIOS) {
      // iOS VoiceOver: Register for static tap and request Flutter focus
      SemanticButtonRegistry.currentSemanticTap = _handlePressed;
      _focusNode.requestFocus();
    } else {
      // Android TalkBack: Just request Flutter focus
      _focusNode.requestFocus();
    }

    debugPrint('ACCESSIBILITY-FOCUS-GAINED: ${widget.label}');
  }

  /// External API: Remove accessibility focus
  void loseAccessibilityFocus() {
    setState(() {
      _hasAccessibilityFocus = false;
    });

    // Clear iOS registry if this button was the current target
    if (_isIOS && SemanticButtonRegistry.currentSemanticTap == _handlePressed) {
      SemanticButtonRegistry.currentSemanticTap = null;
    }

    debugPrint('ACCESSIBILITY-FOCUS-LOST: ${widget.label}');
  }

  /// External API: Simulate button press (for testing or programmatic activation)
  void simulatePress() {
    _handlePressed();
  }

  @override
  Widget build(BuildContext context) {
    final canPress = !widget.disabled && widget.onPressed != null;

    return Semantics(
      // iOS: Exclude default semantics to use custom handling
      excludeSemantics: _isIOS,
      container: true,
      button: true,
      enabled: canPress,
      focusable: true,
      focused: _hasAccessibilityFocus,
      label: widget.label,
      // Platform-specific hints
      hint: _isIOS ? 'Double tap to activate' : widget.hint,
      onTap: canPress ? _handlePressed : null,
      // iOS VoiceOver focus handlers
      onDidGainAccessibilityFocus: canPress
          ? () {
              debugPrint('SEMANTICS-FOCUS-GAINED: ${widget.label}');
              if (_isIOS) {
                // Register for keyboard activation on iOS
                SemanticButtonRegistry.currentSemanticTap = _handlePressed;
                _focusNode.requestFocus();
              }
              setState(() {
                _hasAccessibilityFocus = true;
              });
            }
          : null,
      onDidLoseAccessibilityFocus: canPress
          ? () {
              debugPrint('SEMANTICS-FOCUS-LOST: ${widget.label}');
              // Clean up iOS registry when losing focus
              if (_isIOS &&
                  SemanticButtonRegistry.currentSemanticTap == _handlePressed) {
                SemanticButtonRegistry.currentSemanticTap = null;
              }
              setState(() {
                _hasAccessibilityFocus = false;
              });
            }
          : null,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          focusNode: _focusNode,
          onTap: canPress ? _handlePressed : null,
          borderRadius: BorderRadius.circular(16),
          child: widget.child,
        ),
      ),
    );
  }
}
