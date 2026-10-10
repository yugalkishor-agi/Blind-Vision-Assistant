// services/gemma_service.dart - Further Optimized Version
import 'dart:async';
import 'dart:io';
import 'package:flutter_gemma/core/model.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma/pigeon.g.dart';
import 'package:path_provider/path_provider.dart';

import '../models/message_models.dart';

/// Singleton service for Google's Gemma AI model - optimized for performance and memory efficiency
/// Handles model loading, chat sessions, and streaming responses with minimal overhead
class GemmaService {
  GemmaService._internal();
  static final GemmaService instance = GemmaService._internal();

  final _gemma = FlutterGemmaPlugin.instance;
  InferenceModel? _model;
  InferenceChat? _chat;
  bool _initialised = false;

  /// Initialize model with selected backend (CPU/GPU) - idempotent operation
  /// Uses local model file if available to avoid redundant downloads
  Future<void> init(PreferredBackend backend) async {
    if (_initialised) return; // Prevent duplicate initialization

    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/gemma-3n-E2B-it-int4.task';

    // Point plugin to local model file if it exists and plugin hasn't loaded one yet
    if (!await _gemma.modelManager.isModelInstalled &&
        File(path).existsSync()) {
      await _gemma.modelManager.setModelPath(path);
    }

    // Create model instance with vision support and performance settings
    _model ??= await _gemma.createModel(
      preferredBackend: backend,
      modelType: ModelType.gemmaIt, // Instruction-tuned variant
      supportImage: true, // Enable vision capabilities
      maxTokens: 8192, // Context window size
      maxNumImages: 1, // Single image per message
    );

    // Create persistent chat session with optimized parameters
    _chat ??= await _model!.createChat(
      randomSeed: 1, // Deterministic for testing
      temperature: 1, // Balanced creativity vs consistency
      topK: 64, // Token sampling diversity
      topP: 0.95, // Nucleus sampling threshold
      supportImage: true,
      tokenBuffer: 512, // Reserve tokens for system prompts
    );

    _initialised = true;
  }

  /// Provides detailed performance statistics and error handling
  Future<void> sendWithStreaming({
    required String text,
    File? image,
    required Function(String) onToken,
    required Function(MessageStats) onComplete,
  }) async {
    if (!_initialised) {
      throw Exception('GemmaService not initialized');
    }
    if (_chat == null) {
      throw Exception('Chat not available');
    }

    // Performance tracking variables
    final startTime = DateTime.now();
    DateTime? firstTokenTime;
    int tokenCount = 0;
    final responseBuffer = StringBuffer();

    // Add user message with optional image to chat history
    if (image != null) {
      final bytes = await image.readAsBytes();
      await _chat!.addQuery(
        Message.withImage(text: text, imageBytes: bytes, isUser: true),
      );
    } else {
      await _chat!.addQuery(Message.text(text: text, isUser: true));
    }

    final completer = Completer<void>();
    bool streamStarted = false;

    // Process streaming response with performance metrics
    _chat!.generateChatResponseAsync().listen(
      (ModelResponse res) {
        if (!streamStarted) {
          streamStarted = true;
        }

        if (res is TextResponse) {
          // Record timing for first token (important latency metric)
          firstTokenTime ??= DateTime.now();
          tokenCount++;
          responseBuffer.write(res.token);

          // Forward token to caller (swallow any callback errors)
          try {
            onToken(res.token);
          } catch (_) {
            // Ignore callback errors - caller's responsibility
          }
        }
        // Note: Non-text responses (metadata, etc.) are ignored
      },
      onDone: () {
        final endTime = DateTime.now();

        // Calculate comprehensive performance statistics
        final stats = MessageStats(
          timeToFirstToken: firstTokenTime != null
              ? firstTokenTime!.difference(startTime).inMilliseconds / 1000.0
              : null,
          totalLatency: endTime.difference(startTime).inMilliseconds / 1000.0,
          tokenCount: tokenCount,
          // Tokens per second during initial processing
          prefillSpeed: firstTokenTime != null && tokenCount > 0
              ? 1000.0 / firstTokenTime!.difference(startTime).inMilliseconds
              : null,
          // Tokens per second during generation (excluding first token)
          decodeSpeed: firstTokenTime != null && tokenCount > 1
              ? (tokenCount - 1) *
                    1000.0 /
                    endTime.difference(firstTokenTime!).inMilliseconds
              : null,
        );

        // Deliver final statistics (ignore callback errors)
        try {
          onComplete(stats);
        } catch (_) {
          // Silent fallback
        }

        completer.complete();
      },
      onError: (error) {
        completer.completeError(error);
      },
    );

    await completer.future;
  }

  /// Fast chat reset - clears conversation history but keeps model loaded in memory
  /// Much faster than full reinitialization for "new chat" functionality
  Future<void> resetChatSession() async {
    if (!_initialised) return;
    await _chat?.clearHistory();
  }

  /// Complete cleanup - disposes model and resets all state
  /// Use when switching backends or completely shutting down
  Future<void> dispose() async {
    await _model?.close();
    await _gemma.modelManager.deleteModel();
    _model = null;
    _chat = null;
    _initialised = false;
  }
}
