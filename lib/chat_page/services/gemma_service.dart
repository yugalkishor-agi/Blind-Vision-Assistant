import 'dart:async';
import 'dart:io';
import 'package:flutter_gemma/core/model.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma/pigeon.g.dart';
import 'package:path_provider/path_provider.dart';
import '../models/message_models.dart';

class GemmaService {
  GemmaService._internal();
  static final GemmaService instance = GemmaService._internal();

  final _gemma = FlutterGemmaPlugin.instance;
  InferenceModel? _model;
  InferenceChat? _chat;
  bool _initialised = false;

  Future<void> init(PreferredBackend backend) async {
    if (_initialised) return;
    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/gemma-3n-E2B-it-int4.task';
    if (!await _gemma.modelManager.isModelInstalled && File(path).existsSync()) {
      await _gemma.modelManager.setModelPath(path);
    }
    _model ??= await _gemma.createModel(
      preferredBackend: backend, modelType: ModelType.gemmaIt,
      supportImage: true, maxTokens: 8192, maxNumImages: 1,
    );
    _chat ??= await _model!.createChat(
      randomSeed: 1, temperature: 1, topK: 64,
      topP: 0.95, supportImage: true, tokenBuffer: 512,
    );
    _initialised = true;
  }

  Future<void> sendWithStreaming({
    required String text, File? image,
    required Function(String) onToken,
    required Function(MessageStats) onComplete,
  }) async {
    if (!_initialised) throw Exception('GemmaService not initialized');
    if (_chat == null) throw Exception('Chat not available');

    final startTime = DateTime.now();
    DateTime? firstTokenTime;
    int tokenCount = 0;

    if (image != null) {
      final bytes = await image.readAsBytes();
      await _chat!.addQuery(Message.withImage(text: text, imageBytes: bytes, isUser: true));
    } else {
      await _chat!.addQuery(Message.text(text: text, isUser: true));
    }

    final completer = Completer<void>();
    _chat!.generateChatResponseAsync().listen(
      (ModelResponse res) {
        if (res is TextResponse) {
          firstTokenTime ??= DateTime.now();
          tokenCount++;
          try { onToken(res.token); } catch (_) {}
        }
      },
      onDone: () {
        final endTime = DateTime.now();
        final firstMs = firstTokenTime?.difference(startTime).inMilliseconds;
        final totalMs = endTime.difference(startTime).inMilliseconds;
        final decodeMs = firstTokenTime != null ? endTime.difference(firstTokenTime!).inMilliseconds : null;
        final stats = MessageStats(
          timeToFirstToken: firstMs != null ? firstMs / 1000.0 : null,
          totalLatency: totalMs / 1000.0,
          tokenCount: tokenCount,
          prefillSpeed: firstMs != null && firstMs > 0 ? 1000.0 / firstMs : null,
          decodeSpeed: decodeMs != null && decodeMs > 0 && tokenCount > 1 ? (tokenCount - 1) * 1000.0 / decodeMs : null,
        );
        try { onComplete(stats); } catch (_) {}
        completer.complete();
      },
      onError: (error) => completer.completeError(error),
    );

    await completer.future;
  }

  Future<void> resetChatSession() async {
    if (!_initialised) return;
    await _chat?.clearHistory();
  }

  Future<void> dispose() async {
    await _model?.close();
    await _gemma.modelManager.deleteModel();
    _model = null;
    _chat = null;
    _initialised = false;
  }
}
