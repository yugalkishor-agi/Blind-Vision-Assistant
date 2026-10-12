// lib/chat_page/services/gemma_service_interface.dart
//
// Abstract interface that both GemmaService (on-device) and
// RemoteGemmaService (Ollama) implement.
// Everything in the codebase that calls the model should use this type
// so swapping backend is a one-line change.

import 'dart:io';
import 'package:flutter_gemma/pigeon.g.dart';
import '../models/message_models.dart';

abstract class GemmaServiceInterface {
  /// Initialize the service.
  /// [backend] is only relevant for the on-device service — remote ignores it.
  Future<void> init(PreferredBackend backend);

  /// Stream a response token-by-token.
  /// [text]  — full prompt text (already includes system context)
  /// [image] — optional image file (null for text-only queries)
  /// [onToken]    — called for every generated token
  /// [onComplete] — called once when the full response is done
  Future<void> sendWithStreaming({
    required String text,
    File? image,
    required Function(String) onToken,
    required Function(MessageStats) onComplete,
  });

  /// Clear conversation history without reloading the model.
  Future<void> resetChatSession();

  /// Whether this service is the remote (Ollama) implementation.
  bool get isRemote;
}
