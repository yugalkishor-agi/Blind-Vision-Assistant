// lib/chat_page/services/remote_gemma_service.dart
//
// Calls the hosted OpenAI-compatible endpoint for emulator/PC testing.
// Implements GemmaServiceInterface so it is a drop-in for GemmaService.
//
// Supports:
//   • complete JSON responses — the hosted server does not stream
//   • image via base64 content array — only when image != null
//   • graceful fallback to text-only if image encoding fails
//
// NOT for production — on-device GemmaService is used in the final build.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_gemma/pigeon.g.dart';
import 'package:http/http.dart' as http;

import '../models/message_models.dart';
import 'gemma_service_interface.dart';

/// Model name accepted by the hosted server.
const String _kDefaultModel = 'gemma-3n-E2B-it';
const String _kApiKey = 'APNI-SECRET-KEY';

/// Generation is returned only after the server finishes inference.
const Duration _kResponseTimeout = Duration(seconds: 300);

class RemoteGemmaService implements GemmaServiceInterface {
  final String baseUrl;          // e.g. "https://xxxx.trycloudflare.com"
  final String modelName;
  final List<Map<String, dynamic>> _history = [];

  RemoteGemmaService({
    required this.baseUrl,
    this.modelName = _kDefaultModel,
  });

  @override
  bool get isRemote => true;

  /// Remote service needs no heavy init — just validate URL reachability.
  @override
  Future<void> init(PreferredBackend backend) async {
    // Fire a quick health-check so callers know if the server is unreachable.
    try {
      final uri = Uri.parse('${_normalizedBase()}/');
      final resp = await http.get(uri).timeout(const Duration(seconds: 10));
      debugPrint('[RemoteGemma] Health check: ${resp.statusCode}');
    } catch (e) {
      debugPrint('[RemoteGemma] Health check failed (server may still work): $e');
      // Don't throw — let the first real request surface the error.
    }
  }

  @override
  Future<void> resetChatSession() async {
    _history.clear();
    debugPrint('[RemoteGemma] Chat history cleared');
  }

  /// Build a request and deliver the hosted server's complete response.
  /// Mimics GemmaService.sendWithStreaming exactly.
  @override
  Future<void> sendWithStreaming({
    required String text,
    File? image,
    required Function(String) onToken,
    required Function(MessageStats) onComplete,
  }) async {
    final startTime = DateTime.now();

    // ── Build the user message ──────────────────────────────────────────────
    final userMessage = await _buildUserMessage(text: text, image: image);
    // Keep history transactional: failed/timeout requests must not leave a
    // user turn behind, otherwise the retry sends duplicate turns forever.
    final requestMessages = <Map<String, dynamic>>[
      ..._history,
      userMessage,
    ];

    // ── Build request body ──────────────────────────────────────────────────
    final body = jsonEncode({
      'model': modelName,
      'messages': requestMessages,
      'temperature': 0.7,
      'max_tokens': 256,
    });

    final uri = Uri.parse('${_normalizedBase()}/v1/chat/completions');
    debugPrint(
        '[RemoteGemma] INPUT model=$modelName image=${image != null} '
        'history=${requestMessages.length} text="${_logPreview(text)}"');
    debugPrint('[RemoteGemma] POST $uri');

    try {
      final response = await http
          .post(
            uri,
            headers: const {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_kApiKey',
            },
            body: body,
          )
          .timeout(_kResponseTimeout);

      if (response.statusCode != 200) {
        throw Exception(
            'Remote model returned ${response.statusCode}: ${response.body}');
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final choices = decoded['choices'] as List<dynamic>?;
      final firstChoice = choices != null && choices.isNotEmpty
          ? choices.first as Map<String, dynamic>
          : null;
      final message = firstChoice?['message'] as Map<String, dynamic>?;
      final content = message?['content'] as String?;

      if (content == null || content.trim().isEmpty) {
        throw Exception('Remote model returned no assistant content.');
      }

      debugPrint(
          '[RemoteGemma] OUTPUT status=${response.statusCode} '
          'latencyMs=${DateTime.now().difference(startTime).inMilliseconds} '
          'text="${_logPreview(content)}"');

      _history
        ..add(userMessage)
        ..add({'role': 'assistant', 'content': content});
      try {
        onToken(content);
      } catch (_) {}
      try {
        onComplete(MessageStats(
          timeToFirstToken:
              DateTime.now().difference(startTime).inMilliseconds / 1000.0,
          totalLatency:
              DateTime.now().difference(startTime).inMilliseconds / 1000.0,
          tokenCount: 1,
        ));
      } catch (_) {}
    } on TimeoutException {
      throw Exception(
          'Remote model timed out. Check your Cloudflare URL is still active.');
    } catch (e) {
      debugPrint('[RemoteGemma] Error: $e');
      rethrow;
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  /// Build an OpenAI-format user message.
  /// Uses content array (multimodal format) only when image is provided.
  Future<Map<String, dynamic>> _buildUserMessage({
    required String text,
    File? image,
  }) async {
    if (image == null) {
      return {'role': 'user', 'content': text};
    }

    // Try to encode image as base64
    try {
      final bytes = await image.readAsBytes();
      final b64 = base64Encode(bytes);
      return {
        'role': 'user',
        'content': [
          {'type': 'text', 'text': text},
          {
            'type': 'image_url',
            'image_url': {'url': 'data:image/jpeg;base64,$b64'},
          },
        ],
      };
    } catch (e) {
      debugPrint(
          '[RemoteGemma] Image encode failed, falling back to text-only: $e');
      return {'role': 'user', 'content': text};
    }
  }

  /// Accept a host URL, a `/v1` URL, or the full chat endpoint.
  String _normalizedBase() {
    var s = baseUrl.trim();
    while (s.endsWith('/')) {
      s = s.substring(0, s.length - 1);
    }
    for (final suffix in ['/v1/chat/completions', '/v1']) {
      if (s.endsWith(suffix)) {
        s = s.substring(0, s.length - suffix.length);
        break;
      }
    }
    return s;
  }

  String _logPreview(String value) {
    final singleLine = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (singleLine.length <= 800) return singleLine;
    return '${singleLine.substring(0, 800)}…';
  }
}
