import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_gemma/pigeon.g.dart';
import 'gemma_service.dart';
import 'streaming_tts_service.dart';
import 'chat_helpers.dart';
import 'speech_service.dart';
import 'text_recognition_service.dart';
import '../handlers/keyboard_handler.dart';
import '../widgets/prompt_bar.dart';
class BootstrapManager {
  static bool _bootstrapping = false;
  static Completer<void>? _completer;
  static Future<BootstrapResult> bootstrap({
    required BuildContext context, required String systemContext, required PreferredBackend backend,
    required GlobalKey<PromptBarState> promptBarKey, required VoidCallback onToggleMessages,
    required VoidCallback onToggleCamera, required VoidCallback onToggleSettings, required VoidCallback onToggleVoice,
    required Future<void> Function() onNewChat, required Future<void> Function() onQuickAction1,
    required Future<void> Function() onQuickAction2, required Future<void> Function() onQuickAction3,
    required Future<void> Function() onQuickAction4, required bool Function() isMounted,
    required bool Function() isDisposed, required void Function(VoidCallback) setState,
  }) async {
    if (_bootstrapping) {
      try {
        await _completer?.future.timeout(const Duration(seconds: 30),
            onTimeout: () { _bootstrapping = false; _completer = null; });
      } catch (_) { _bootstrapping = false; _completer = null; }
      if (_bootstrapping) { _bootstrapping = false; _completer = null; }
    }
    if (isDisposed()) throw BootstrapException('Widget disposed');
    _bootstrapping = true;
    _completer = Completer<void>();
    try {
      await Future.delayed(const Duration(milliseconds: 100));
      final tts = FlutterTts();
      await tts.setSpeechRate(0.5);
      final streamingTts = StreamingTtsService(tts);
      if (!isMounted() || isDisposed()) { _completer!.complete(); throw BootstrapException('Not mounted'); }
      final textRecognition = TextRecognitionService.instance;
      await textRecognition.initialize();
      if (!isMounted() || isDisposed()) { _completer!.complete(); throw BootstrapException('Not mounted'); }
      final speechService = SpeechService(
        tts: tts,
        onStateChanged: () { if (isMounted() && !isDisposed()) setState(() {}); },
        promptBarKey: promptBarKey,
        isGenerating: () => false,
      );
      await speechService.initialize();
      if (!isMounted() || isDisposed()) { _completer!.complete(); throw BootstrapException('Not mounted'); }
      final chatHelpers = ChatHelpers(
        service: GemmaService.instance,
        streamingTts: streamingTts,
        speechService: speechService,
        textRecognition: textRecognition,
        onStateChanged: () { if (isMounted() && !isDisposed()) setState(() {}); },
        showSnackBar: (msg) {
          if (isMounted() && !isDisposed()) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
        },
        systemContext: systemContext,
      );
      speechService.updateIsGeneratingCallback(() => chatHelpers.isGenerating);
      final keyboardHandler = KeyboardHandler(
        context: context, promptBarKey: promptBarKey,
        onToggleMessages: onToggleMessages, onToggleCamera: onToggleCamera, onToggleSettings: onToggleSettings,
        onNewChat: onNewChat, onQuickAction1: onQuickAction1, onQuickAction2: onQuickAction2,
        onQuickAction3: onQuickAction3, onQuickAction4: onQuickAction4, onToggleVoice: onToggleVoice,
      );
      await GemmaService.instance.init(backend);
      if (!isMounted() || isDisposed()) { _completer!.complete(); throw BootstrapException('Not mounted'); }
      if (!_completer!.isCompleted) _completer!.complete();
      return BootstrapResult(tts: tts, streamingTts: streamingTts, chatHelpers: chatHelpers,
          speechService: speechService, keyboardHandler: keyboardHandler, textRecognition: textRecognition);
    } catch (e) {
      if (e is PlatformException) debugPrint('Platform error: ${e.code} ${e.message}');
      if (!_completer!.isCompleted) _completer!.completeError(e);
      rethrow;
    } finally {
      _bootstrapping = false; _completer = null;
    }
  }
  static void reset() { _bootstrapping = false; _completer = null; }
}
class BootstrapResult {
  final FlutterTts tts; final StreamingTtsService streamingTts; final ChatHelpers chatHelpers;
  final SpeechService speechService; final KeyboardHandler keyboardHandler; final TextRecognitionService textRecognition;
  BootstrapResult({
    required this.tts, required this.streamingTts, required this.chatHelpers,
    required this.speechService, required this.keyboardHandler, required this.textRecognition,
  });
}
class BootstrapException implements Exception {
  final String message;
  BootstrapException(this.message);
  @override String toString() => 'BootstrapException: $message';
}
