// lib/chat_page/services/chat_helpers.dart
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/message_models.dart';
import '../widgets/prompt_bar.dart';
import '../config/system_prompts.dart';
import 'gemma_service.dart';
import 'speech_service.dart';
import 'streaming_tts_service.dart';
import 'text_recognition_service.dart';

/// Core chat operations with vision AI - handles camera, OCR, streaming responses, and TTS
class ChatHelpers {
  final GemmaService _service;
  final StreamingTtsService _streamingTts;
  final SpeechService _speechService;
  final TextRecognitionService _textRecognition;
  final VoidCallback _onStateChanged;
  final Function(String) _showSnackBar;

  String _systemCtx;
  bool _resetting = false;
  bool _isGenerating = false;

  ChatHelpers({
    required GemmaService service,
    required StreamingTtsService streamingTts,
    required SpeechService speechService,
    required TextRecognitionService textRecognition,
    required VoidCallback onStateChanged,
    required Function(String) showSnackBar,
    required String systemContext,
  }) : _service = service,
       _streamingTts = streamingTts,
       _speechService = speechService,
       _textRecognition = textRecognition,
       _onStateChanged = onStateChanged,
       _showSnackBar = showSnackBar,
       _systemCtx = systemContext {
    // Listen for TTS state changes to update UI
    _streamingTts.isSpeaking.addListener(_onStateChanged);
  }

  void dispose() {
    _streamingTts.isSpeaking.removeListener(_onStateChanged);
  }

  // State getters for UI
  bool get resetting => _resetting;
  bool get isGenerating => _isGenerating;
  bool get isSpeaking => _streamingTts.isSpeaking.value;
  String get systemContext => _systemCtx;

  void updateSystemContext(String newContext) => _systemCtx = newContext;

  /// Clean error messages for TTS (remove technical prefixes)
  Future<void> _announceError(String error) async {
    try {
      final cleanError = error
          .replaceAll('Exception:', '')
          .replaceAll('Error:', '')
          .replaceAll('_', ' ')
          .trim();
      await _speechService.speak('Error: $cleanError');
    } catch (e) {
      // Silent fallback if TTS fails
    }
  }

  /// Announce state changes for blind users
  Future<void> _announceStateChange(String message) async {
    try {
      await _speechService.speak(message);
    } catch (e) {
      // Silent fallback
    }
  }

  /// Reset chat session and clean up all state
  Future<void> newChat(
    List<ChatMessage> messages,
    GlobalKey<PromptBarState>? promptBarKey,
  ) async {
    if (_resetting) return;

    try {
      _streamingTts.reset();
      _resetting = true;
      _onStateChanged();

      await _announceStateChange('Starting new chat');

      messages.clear();
      promptBarKey?.currentState?.clear();

      await _service.resetChatSession();

      _resetting = false;
      _onStateChanged();

      await _announceStateChange('New chat ready');
    } catch (e) {
      _resetting = false;
      _onStateChanged();

      final errorMsg = 'Failed to start new chat: $e';
      _showSnackBar(errorMsg);
      await _announceError(errorMsg);
    }
  }

  /// Toggle message visibility with accessibility announcements
  Future<void> showMessages(List<ChatMessage> messages, bool show) async {
    try {
      if (show) {
        await _announceStateChange('Showing ${messages.length} messages');
      } else {
        await _announceStateChange('Hiding messages');
      }
    } catch (e) {
      await _announceError('Failed to toggle message visibility');
    }
  }

  /// Optimized camera capture - initialize only when needed, dispose immediately
  Future<File?> _captureWithEfficientCamera() async {
    if (kIsWeb) {
      throw Exception('Camera not supported on web');
    }

    CameraController? controller;
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw Exception('No cameras available');
      }

      // Prefer back camera for environment scanning
      final description = cameras.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      controller = CameraController(
        description,
        ResolutionPreset.high,
        enableAudio: false, // No audio needed for vision AI
      );

      await controller.initialize();
      final image = await controller.takePicture();
      return File(image.path);
    } catch (e) {
      await _announceError('Camera error: $e');
      rethrow;
    } finally {
      // Always dispose controller to free camera resource
      await controller?.dispose();
    }
  }

  /// Capture image + process text prompt with OCR integration and streaming response
  Future<void> captureAndSend(
    String prompt,
    List<ChatMessage> messages, {
    bool isQuickAction = false,
  }) async {
    try {
      final imageFile = await _captureWithEfficientCamera();

      // Add user message immediately for responsive UI
      final userMsg = ChatMessage.withImageFile(
        prompt,
        isUser: true,
        imageFile: imageFile,
      );
      messages.add(userMsg);
      _onStateChanged();

      // Add streaming AI placeholder
      final aiMsg = ChatMessage.text('', isUser: false, isStreaming: true);
      messages.add(aiMsg);
      _onStateChanged();

      await _speechService.playWooshSound();
      _isGenerating = true;
      _onStateChanged();

      // Skip message type announcement for quick actions (reduce verbosity)
      if (!isQuickAction) {
        await _speechService.announceMessageType(true);
      }
      await _streamingTts.startLoading();

      // Run OCR on captured image in parallel with AI processing
      String extractedText = '';
      try {
        extractedText = await _textRecognition.extractTextFromImage(imageFile!);
        // Uncomment for OCR feedback: _showSnackBar('Text detected in image');
      } catch (e) {
        await _announceError('Text recognition failed: $e');
      }

      // Enhance prompt with OCR results if text was found
      String enhancedPrompt = prompt;
      if (extractedText.isNotEmpty) {
        enhancedPrompt = '''$prompt

[TEXT DETECTED IN IMAGE: $extractedText]''';
      }

      // Stream AI response with optimized UI updates
      final responseBuffer = StringBuffer();
      int tokenCounter = 0;

      await _service.sendWithStreaming(
        text: '$_systemCtx\nUser: $enhancedPrompt',
        image: imageFile,
        onToken: (tok) {
          responseBuffer.write(tok);
          tokenCounter++;

          final currentText = responseBuffer.toString();
          _streamingTts.addText(tok, currentText); // Real-time TTS

          // Throttle UI updates: only update every 3 tokens for performance
          if (tokenCounter % 3 == 0) {
            aiMsg.text = currentText;
            _onStateChanged();
          }
        },
        onComplete: (stats) async {
          final finalText = responseBuffer.toString();
          aiMsg
            ..text = finalText
            ..isStreaming = false
            ..stats = stats;
          _isGenerating = false;
          _onStateChanged();
          await _streamingTts.onMessageComplete();
        },
      );
    } catch (e) {
      await _streamingTts.stopLoading();
      final errorMsg = 'Failed to process image and text: $e';

      // Add or update error message in chat
      if (messages.isEmpty || !messages.last.isUser) {
        messages.add(ChatMessage.text('Error: $e', isUser: false));
      } else {
        final lastAiIndex = messages.lastIndexWhere((m) => !m.isUser);
        if (lastAiIndex != -1) {
          messages[lastAiIndex] = ChatMessage.text('Error: $e', isUser: false);
        } else {
          messages.add(ChatMessage.text('Error: $e', isUser: false));
        }
      }
      _isGenerating = false;
      _onStateChanged();
      await _announceError(errorMsg);
    }
  }

  /// Send text-only message with streaming response and optimized performance
  Future<void> sendTextOnly(String prompt, List<ChatMessage> messages) async {
    try {
      // Immediate UI feedback
      messages.add(ChatMessage.text(prompt, isUser: true));
      _onStateChanged();

      final aiMsg = ChatMessage.text('', isUser: false, isStreaming: true);
      messages.add(aiMsg);
      _onStateChanged();

      await _speechService.playWooshSound();
      _isGenerating = true;
      _onStateChanged();
      await _speechService.announceMessageType(false);

      await _streamingTts.startLoading();

      // High-performance response handling with StringBuffer
      final responseBuffer = StringBuffer();
      int tokenCounter = 0;

      final fullPrompt = '$_systemCtx\nUser: $prompt';

      await _service.sendWithStreaming(
        text: fullPrompt,
        onToken: (tok) {
          responseBuffer.write(tok); // Efficient string building
          tokenCounter++;

          final currentText = responseBuffer.toString();
          _streamingTts.addText(tok, currentText); // Stream to TTS

          // Performance optimization: throttle UI updates to every 3 tokens
          if (tokenCounter % 3 == 0) {
            aiMsg.text = currentText;
            _onStateChanged();
          }
        },
        onComplete: (stats) async {
          final finalText = responseBuffer.toString();

          aiMsg
            ..text = finalText
            ..isStreaming = false
            ..stats = stats;
          _isGenerating = false;
          _onStateChanged();

          await _streamingTts.onMessageComplete();
        },
      );
    } catch (e) {
      await _streamingTts.stopLoading();
      final errorMsg = 'Failed to send text message: $e';
      messages.add(ChatMessage.text('Error: $e', isUser: false));
      _isGenerating = false;
      _onStateChanged();
      await _announceError(errorMsg);
    }
  }

  /* Quick action shortcuts for common blind user navigation tasks */

  /// Quick action: Analyze room layout and furniture placement
  Future<void> quickAction1(List<ChatMessage> messages) async {
    await _announceStateChange('Describing room');
    await captureAndSend(
      SystemPrompts.describeRoom,
      messages,
      isQuickAction: true,
    );
  }

  /// Quick action: General scene description
  Future<void> quickAction2(List<ChatMessage> messages) async {
    await _announceStateChange('Analyzing what I can see');
    await captureAndSend(
      SystemPrompts.tellMeWhatYouSee,
      messages,
      isQuickAction: true,
    );
  }

  /// Quick action: Object identification
  Future<void> quickAction3(List<ChatMessage> messages) async {
    await _announceStateChange('What is this?');
    await captureAndSend(
      SystemPrompts.whatIsThis,
      messages,
      isQuickAction: true,
    );
  }

  /// Quick action: OCR text reading
  Future<void> quickAction4(List<ChatMessage> messages) async {
    await _announceStateChange('Reading text');
    await captureAndSend(SystemPrompts.readText, messages, isQuickAction: true);
  }

  /// Clear all messages with accessibility feedback
  Future<void> clearMessages(List<ChatMessage> messages) async {
    try {
      final messageCount = messages.length;
      messages.clear();
      _onStateChanged();
      await _announceStateChange('Cleared $messageCount messages');
    } catch (e) {
      await _announceError('Failed to clear messages: $e');
    }
  }
}
