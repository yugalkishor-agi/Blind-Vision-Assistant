// lib/chat_page/handlers/keyboard_handler.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import '../widgets/prompt_bar.dart';
import '../widgets/semantic_button_registry.dart';

/// Custom intent for function key shortcuts that bypass text field focus
class GameIntent extends Intent {
  const GameIntent(this.key);
  final LogicalKeyboardKey key;
}

/// Cross-platform keyboard handler with accessibility support for blind users
/// Handles F-key shortcuts, arrow navigation, and platform-specific activation patterns
class KeyboardHandler {
  final BuildContext _context;
  final GlobalKey<PromptBarState> _promptBarKey;
  final VoidCallback _onToggleMessages;
  final VoidCallback _onToggleSettings;
  final VoidCallback _onNewChat;
  final VoidCallback _onQuickAction1;
  final VoidCallback _onQuickAction2;
  final VoidCallback _onQuickAction3;
  final VoidCallback _onQuickAction4;
  final VoidCallback _onToggleVoice;

  /// Prevent duplicate key event processing
  final Set<LogicalKeyboardKey> _pressedKeys = <LogicalKeyboardKey>{};

  /// Platform-specific behavior flags
  bool get _isIOS => !kIsWeb && Platform.isIOS;

  KeyboardHandler({
    required BuildContext context,
    required GlobalKey<PromptBarState> promptBarKey,
    required VoidCallback onToggleMessages,
    required VoidCallback onToggleCamera,
    required VoidCallback onToggleSettings,
    required VoidCallback onNewChat,
    required VoidCallback onQuickAction1,
    required VoidCallback onQuickAction2,
    required VoidCallback onQuickAction3,
    required VoidCallback onQuickAction4,
    required VoidCallback onToggleVoice,
  }) : _context = context,
       _promptBarKey = promptBarKey,
       _onToggleMessages = onToggleMessages,
       _onToggleSettings = onToggleSettings,
       _onNewChat = onNewChat,
       _onQuickAction1 = onQuickAction1,
       _onQuickAction2 = onQuickAction2,
       _onQuickAction3 = onQuickAction3,
       _onQuickAction4 = onQuickAction4,
       _onToggleVoice = onToggleVoice;

  /// Process keyboard shortcuts with ghost event prevention and state validation
  void onShortcut(LogicalKeyboardKey key) {
    // Prevent processing ghost events (key not actually pressed)
    if (!HardwareKeyboard.instance.logicalKeysPressed.contains(key)) {
      debugPrint('KeyboardHandler: Ignoring ghost key event for $key');
      return;
    }

    // Debounce: prevent rapid duplicate key processing
    if (_pressedKeys.contains(key)) {
      debugPrint('KeyboardHandler: Key $key already being processed');
      return;
    }

    _pressedKeys.add(key);

    try {
      // Function key mappings for blind user navigation
      switch (key) {
        case LogicalKeyboardKey.f10:
          _onToggleMessages(); // Show/hide message history
          break;
        case LogicalKeyboardKey.f9:
          _promptBarKey.currentState?.sendTextOnly(); // Send text prompt
          break;
        case LogicalKeyboardKey.f8:
          _onToggleSettings(); // Open settings
          break;
        case LogicalKeyboardKey.f1:
          _promptBarKey.currentState?.sendWithPhoto(); // Camera + prompt
          break;
        case LogicalKeyboardKey.f2:
          _onToggleVoice(); // Toggle speech recognition
          break;
        case LogicalKeyboardKey.f3:
          _onNewChat(); // Reset chat session
          break;
        case LogicalKeyboardKey.f5:
          _onQuickAction1(); // Describe room layout
          break;
        case LogicalKeyboardKey.f7:
          _onQuickAction2(); // Tell me what you see
          break;
        case LogicalKeyboardKey.f4:
          _onQuickAction3(); // What is this?
          break;
        case LogicalKeyboardKey.f6:
          _onQuickAction4(); // Read text in image
          break;
        // Accessibility navigation
        case LogicalKeyboardKey.arrowUp:
        case LogicalKeyboardKey.arrowLeft:
          FocusScope.of(_context).previousFocus();
          break;
        case LogicalKeyboardKey.arrowDown:
        case LogicalKeyboardKey.arrowRight:
          FocusScope.of(_context).nextFocus();
          break;
        case LogicalKeyboardKey.enter:
        case LogicalKeyboardKey.select:
        case LogicalKeyboardKey.space:
          // Handle button activation with platform-specific requirements
          if (_shouldActivateButton()) {
            _activateCurrentButton();
          }
          break;
      }
    } finally {
      // Debounce cleanup: allow key to be processed again after delay
      Future.delayed(const Duration(milliseconds: 100), () {
        _pressedKeys.remove(key);
      });
    }
  }

  /// Platform-specific button activation logic (iOS VoiceOver vs Android TalkBack)
  bool _shouldActivateButton() {
    if (_isIOS) {
      // iOS VoiceOver requires Ctrl + Alt + Space for activation
      return HardwareKeyboard.instance.isControlPressed &&
          HardwareKeyboard.instance.isAltPressed;
    } else {
      // Android TalkBack: Enter, Space, or Select activate buttons
      return true;
    }
  }

  /// Activate currently focused semantic button
  void _activateCurrentButton() {
    SemanticButtonRegistry.invokeCurrentSemanticTap();
  }

  /// Create validated action handler with error handling
  CallbackAction<GameIntent> _createGameAction() {
    return CallbackAction<GameIntent>(
      onInvoke: (intent) {
        try {
          final key = intent.key;

          // Double-check key validity at action level
          if (!HardwareKeyboard.instance.logicalKeysPressed.contains(key)) {
            debugPrint('GameIntent: Ignoring invalid key event for $key');
            return null;
          }

          onShortcut(key);
          return null;
        } catch (e) {
          debugPrint('GameIntent error: $e');
          return null;
        }
      },
    );
  }

  /// Platform-specific keyboard shortcut mappings
  Map<LogicalKeySet, Intent> get shortcuts => {
    if (_isIOS) ...{
      // iOS: VoiceOver-specific navigation shortcuts
      LogicalKeySet(LogicalKeyboardKey.arrowDown): const NextFocusIntent(),
      LogicalKeySet(LogicalKeyboardKey.arrowRight): const NextFocusIntent(),
      LogicalKeySet(LogicalKeyboardKey.arrowUp): const PreviousFocusIntent(),
      LogicalKeySet(LogicalKeyboardKey.arrowLeft): const PreviousFocusIntent(),
      LogicalKeySet(
        LogicalKeyboardKey.control,
        LogicalKeyboardKey.alt,
        LogicalKeyboardKey.space,
      ): const ActivateIntent(),
    } else ...{
      // Android: TalkBack-compatible navigation
      LogicalKeySet(LogicalKeyboardKey.arrowDown): const NextFocusIntent(),
      LogicalKeySet(LogicalKeyboardKey.arrowRight): const NextFocusIntent(),
      LogicalKeySet(LogicalKeyboardKey.arrowUp): const PreviousFocusIntent(),
      LogicalKeySet(LogicalKeyboardKey.arrowLeft): const PreviousFocusIntent(),
      LogicalKeySet(LogicalKeyboardKey.enter): const ActivateIntent(),
      LogicalKeySet(LogicalKeyboardKey.select): const ActivateIntent(),
      LogicalKeySet(LogicalKeyboardKey.space): const ActivateIntent(),
    },

    // Function key shortcuts (cross-platform)
    LogicalKeySet(LogicalKeyboardKey.f9): const GameIntent(
      LogicalKeyboardKey.f9,
    ),
    LogicalKeySet(LogicalKeyboardKey.f10): const GameIntent(
      LogicalKeyboardKey.f10,
    ),
    LogicalKeySet(LogicalKeyboardKey.f8): const GameIntent(
      LogicalKeyboardKey.f8,
    ),
    LogicalKeySet(LogicalKeyboardKey.f1): const GameIntent(
      LogicalKeyboardKey.f1,
    ),
    LogicalKeySet(LogicalKeyboardKey.f2): const GameIntent(
      LogicalKeyboardKey.f2,
    ),
    LogicalKeySet(LogicalKeyboardKey.f5): const GameIntent(
      LogicalKeyboardKey.f5,
    ),
    LogicalKeySet(LogicalKeyboardKey.f7): const GameIntent(
      LogicalKeyboardKey.f7,
    ),
    LogicalKeySet(LogicalKeyboardKey.f4): const GameIntent(
      LogicalKeyboardKey.f4,
    ),
    LogicalKeySet(LogicalKeyboardKey.f6): const GameIntent(
      LogicalKeyboardKey.f6,
    ),
    LogicalKeySet(LogicalKeyboardKey.f3): const GameIntent(
      LogicalKeyboardKey.f3,
    ),
  };

  /// Platform-specific action handlers with accessibility integration
  Map<Type, Action<Intent>> get actions => {
    if (_isIOS)
      // iOS: Custom ActivateIntent handler for VoiceOver compatibility
      ActivateIntent: CallbackAction<ActivateIntent>(
        onInvoke: (_) {
          try {
            SemanticButtonRegistry.invokeCurrentSemanticTap();
          } catch (e) {
            debugPrint('ActivateIntent error: $e');
          }
          return null;
        },
      )
    else
      // Android: ActivateIntent with fallback to registry
      ActivateIntent: CallbackAction<ActivateIntent>(
        onInvoke: (_) {
          try {
            final activated = SemanticButtonRegistry.invokeCurrentSemanticTap();
            if (!activated) {
              debugPrint('No semantic tap registered, letting system handle');
            }
          } catch (e) {
            debugPrint('ActivateIntent error: $e');
          }
          return null;
        },
      ),

    // Function key handler
    GameIntent: _createGameAction(),
  };

  void dispose() {
    _pressedKeys.clear();
  }
}
