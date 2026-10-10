// lib/chat_page/services/bootstrap_manager.dart
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

/// Manages complex multi-service initialization with deadlock prevention and crash recovery
/// Initializes AI model, TTS, speech recognition, camera, and keyboard handlers in correct order
class BootstrapManager {
  /// Global flags to prevent concurrent bootstrap and handle timeouts
  static bool _globalBootstrapping = false;
  static Completer<void>? _globalBootstrapCompleter;

  /// Initialize all services with lifecycle safety and dependency management
  static Future<BootstrapResult> bootstrap({
    required BuildContext context,
    required String systemContext,
    required PreferredBackend backend,
    required GlobalKey<PromptBarState> promptBarKey,
    required VoidCallback onToggleMessages,
    required VoidCallback onToggleCamera,
    required VoidCallback onToggleSettings,
    required Future<void> Function() onNewChat,
    required Future<void> Function() onQuickAction1,
    required Future<void> Function() onQuickAction2,
    required Future<void> Function() onQuickAction3,
    required Future<void> Function() onQuickAction4,
    required VoidCallback onToggleVoice,
    required bool Function() isMounted,
    required bool Function() isDisposed,
    required void Function(VoidCallback) setState,
  }) async {
    // Prevent concurrent bootstrap attempts (causes deadlocks with AI model loading)
    if (_globalBootstrapping) {
      debugPrint(
        "[BootstrapManager] Bootstrap already in progress globally, waiting...",
      );
      try {
        // Wait for existing bootstrap with timeout protection
        await _globalBootstrapCompleter?.future.timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            debugPrint(
              "[BootstrapManager] Bootstrap wait timed out, proceeding anyway",
            );
            _globalBootstrapping = false;
            _globalBootstrapCompleter = null;
          },
        );
      } catch (e) {
        debugPrint("[BootstrapManager] Bootstrap wait error: $e");
        _globalBootstrapping = false;
        _globalBootstrapCompleter = null;
      }

      // Force reset if still bootstrapping (deadlock recovery)
      if (_globalBootstrapping) {
        debugPrint(
          "[BootstrapManager] Forcing bootstrap reset due to deadlock",
        );
        _globalBootstrapping = false;
        _globalBootstrapCompleter = null;
      }
    }

    // Lifecycle safety check
    if (isDisposed()) {
      debugPrint("[BootstrapManager] Widget disposed, skipping bootstrap");
      throw BootstrapException("Widget disposed");
    }

    _globalBootstrapping = true;
    _globalBootstrapCompleter = Completer<void>();

    try {
      debugPrint("[BootstrapManager] Starting bootstrap...");
      await Future.delayed(const Duration(milliseconds: 100));

      // Step 1: Initialize TTS services (needed by other services)
      final tts = FlutterTts();
      await tts.setSpeechRate(0.5);
      final streamingTts = StreamingTtsService(tts);
      debugPrint("[BootstrapManager] TTS initialized");

      if (!isMounted() || isDisposed()) {
        debugPrint("[BootstrapManager] Not mounted after TTS init");
        _globalBootstrapCompleter!.complete();
        throw BootstrapException("Widget not mounted");
      }

      // Step 2: Initialize text recognition (OCR for image analysis)
      final textRecognition = TextRecognitionService.instance;
      await textRecognition.initialize();
      debugPrint("[BootstrapManager] Text recognition initialized");

      if (!isMounted() || isDisposed()) {
        debugPrint(
          "[BootstrapManager] Not mounted after text recognition init",
        );
        _globalBootstrapCompleter!.complete();
        throw BootstrapException("Widget not mounted");
      }

      // Step 3: Initialize speech service (depends on TTS)
      final speechService = SpeechService(
        tts: tts,
        onStateChanged: () {
          if (isMounted() && !isDisposed()) setState(() {});
        },
        promptBarKey: promptBarKey,
        isGenerating: () => false, // Updated after chatHelpers is created
      );
      await speechService.initialize();

      if (!isMounted() || isDisposed()) {
        debugPrint("[BootstrapManager] Not mounted after speech init");
        _globalBootstrapCompleter!.complete();
        throw BootstrapException("Widget not mounted");
      }
      debugPrint("[BootstrapManager] Speech service initialized");

      // Step 4: Initialize chat helpers (depends on all previous services)
      final chatHelpers = ChatHelpers(
        service: GemmaService.instance,
        streamingTts: streamingTts,
        speechService: speechService,
        textRecognition: textRecognition,
        onStateChanged: () {
          if (isMounted() && !isDisposed()) setState(() {});
        },
        showSnackBar: (msg) {
          if (isMounted() && !isDisposed()) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(msg)));
          }
        },
        systemContext: systemContext,
      );
      debugPrint("[BootstrapManager] Chat helpers initialized");

      // Step 5: Update speech service callback now that chatHelpers exists
      speechService.updateIsGeneratingCallback(() => chatHelpers.isGenerating);

      // Step 6: Initialize keyboard handler with all callbacks
      final keyboardHandler = KeyboardHandler(
        context: context,
        promptBarKey: promptBarKey,
        onToggleMessages: onToggleMessages,
        onToggleCamera: onToggleCamera,
        onToggleSettings: onToggleSettings,
        onNewChat: onNewChat,
        onQuickAction1: onQuickAction1,
        onQuickAction2: onQuickAction2,
        onQuickAction3: onQuickAction3,
        onQuickAction4: onQuickAction4,
        onToggleVoice: onToggleVoice,
      );
      debugPrint("[BootstrapManager] Keyboard handler initialized");

      // Step 7: Initialize AI model (heaviest operation, can fail)
      debugPrint("[BootstrapManager] Initializing Gemma service...");
      await GemmaService.instance.init(backend);

      if (!isMounted() || isDisposed()) {
        debugPrint("[BootstrapManager] Not mounted after Gemma init");
        _globalBootstrapCompleter!.complete();
        throw BootstrapException("Widget not mounted");
      }
      debugPrint("[BootstrapManager] Gemma service initialized successfully");

      if (!_globalBootstrapCompleter!.isCompleted) {
        _globalBootstrapCompleter!.complete();
      }

      debugPrint("[BootstrapManager] Bootstrap completed successfully");

      return BootstrapResult(
        tts: tts,
        streamingTts: streamingTts,
        chatHelpers: chatHelpers,
        speechService: speechService,
        keyboardHandler: keyboardHandler,
        textRecognition: textRecognition,
      );
    } catch (e, stackTrace) {
      debugPrint("[BootstrapManager] Bootstrap error: $e");
      debugPrint("[BootstrapManager] Stack trace: $stackTrace");

      // Enhanced error logging for PlatformException (common with AI model loading)
      if (e is PlatformException) {
        debugPrint("[BootstrapManager] Platform error code: ${e.code}");
        debugPrint("[BootstrapManager] Platform error message: ${e.message}");
        debugPrint("[BootstrapManager] Platform error details: ${e.details}");
      }

      if (!_globalBootstrapCompleter!.isCompleted) {
        _globalBootstrapCompleter!.completeError(e);
      }

      rethrow;
    } finally {
      // Always clean up global state to prevent deadlocks
      _globalBootstrapping = false;
      _globalBootstrapCompleter = null;
      debugPrint("[BootstrapManager] Bootstrap finally block - flags reset");
    }
  }

  /// Reset bootstrap state (called when switching backends or recovering from errors)
  static void reset() {
    _globalBootstrapping = false;
    _globalBootstrapCompleter = null;
  }
}

/// Container for all initialized services
class BootstrapResult {
  final FlutterTts tts;
  final StreamingTtsService streamingTts;
  final ChatHelpers chatHelpers;
  final SpeechService speechService;
  final KeyboardHandler keyboardHandler;
  final TextRecognitionService textRecognition;

  BootstrapResult({
    required this.tts,
    required this.streamingTts,
    required this.chatHelpers,
    required this.speechService,
    required this.keyboardHandler,
    required this.textRecognition,
  });
}

/// Custom exception for bootstrap failures
class BootstrapException implements Exception {
  final String message;
  BootstrapException(this.message);

  @override
  String toString() => 'BootstrapException: $message';
}
