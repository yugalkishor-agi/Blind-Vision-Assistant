import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/prompt_bar.dart';

class _ActionIntent extends Intent {
  const _ActionIntent(this.key);
  final LogicalKeyboardKey key;
}

class KeyboardHandler {
  final BuildContext context;
  final GlobalKey<PromptBarState> promptBarKey;
  final VoidCallback onToggleMessages;
  final VoidCallback onToggleCamera;
  final VoidCallback onToggleSettings;
  final Future<void> Function() onNewChat;
  final Future<void> Function() onQuickAction1;
  final Future<void> Function() onQuickAction2;
  final Future<void> Function() onQuickAction3;
  final Future<void> Function() onQuickAction4;
  final VoidCallback onToggleVoice;

  KeyboardHandler({
    required this.context,
    required this.promptBarKey,
    required this.onToggleMessages,
    required this.onToggleCamera,
    required this.onToggleSettings,
    required this.onNewChat,
    required this.onQuickAction1,
    required this.onQuickAction2,
    required this.onQuickAction3,
    required this.onQuickAction4,
    required this.onToggleVoice,
  });

  Map<ShortcutActivator, Intent> get shortcuts => {
    SingleActivator(LogicalKeyboardKey.f1): const _ActionIntent(LogicalKeyboardKey.f1),
    SingleActivator(LogicalKeyboardKey.f2): const _ActionIntent(LogicalKeyboardKey.f2),
    SingleActivator(LogicalKeyboardKey.f3): const _ActionIntent(LogicalKeyboardKey.f3),
    SingleActivator(LogicalKeyboardKey.f4): const _ActionIntent(LogicalKeyboardKey.f4),
    SingleActivator(LogicalKeyboardKey.f5): const _ActionIntent(LogicalKeyboardKey.f5),
    SingleActivator(LogicalKeyboardKey.f6): const _ActionIntent(LogicalKeyboardKey.f6),
    SingleActivator(LogicalKeyboardKey.f7): const _ActionIntent(LogicalKeyboardKey.f7),
    SingleActivator(LogicalKeyboardKey.f8): const _ActionIntent(LogicalKeyboardKey.f8),
  };

  Map<Type, Action<Intent>> get actions => {
    _ActionIntent: CallbackAction<_ActionIntent>(
      onInvoke: (intent) {
        if (intent.key == LogicalKeyboardKey.f1) onToggleMessages();
        if (intent.key == LogicalKeyboardKey.f2) onToggleVoice();
        if (intent.key == LogicalKeyboardKey.f3) onNewChat();
        if (intent.key == LogicalKeyboardKey.f4) onToggleSettings();
        if (intent.key == LogicalKeyboardKey.f5) onQuickAction1();
        if (intent.key == LogicalKeyboardKey.f6) onQuickAction2();
        if (intent.key == LogicalKeyboardKey.f7) onQuickAction3();
        if (intent.key == LogicalKeyboardKey.f8) onQuickAction4();
        return null;
      },
    ),
  };
}
