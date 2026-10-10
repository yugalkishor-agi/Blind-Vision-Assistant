// lib/chat_page/widgets/semantic_button_registry.dart
import 'package:flutter/foundation.dart';

/// Global registry for managing iOS VoiceOver button activation
/// Handles the pattern where iOS VoiceOver focuses a button but activation comes through keyboard shortcuts
class SemanticButtonRegistry {
  /// Currently focused button's callback - only one button can be "current" at a time
  static VoidCallback? _currentSemanticTap;

  /// Public getter for accessing current semantic tap (used by keyboard handler)
  static VoidCallback? get currentSemanticTap => _currentSemanticTap;

  /// Public setter for updating current semantic tap (used by semantic buttons)
  static set currentSemanticTap(VoidCallback? callback) {
    _currentSemanticTap = callback;
  }

  /// Check if there's a currently registered semantic tap target
  static bool get hasSemanticTap => _currentSemanticTap != null;

  /// Register a button as the current semantic target (when it gains accessibility focus)
  static void registerSemanticTap(VoidCallback callback) {
    _currentSemanticTap = callback;
  }

  /// Unregister a specific button when it loses focus (safety check)
  static void unregisterSemanticTap(VoidCallback callback) {
    if (_currentSemanticTap == callback) {
      _currentSemanticTap = null;
    }
  }

  /// Invoke the currently registered semantic tap and return success status
  static bool invokeCurrentSemanticTap() {
    final hasCallback = _currentSemanticTap != null;
    if (hasCallback) {
      _currentSemanticTap!.call();
    }
    return hasCallback;
  }

  /// Clear all registrations (called during cleanup or app state reset)
  static void clear() {
    _currentSemanticTap = null;
  }
}
