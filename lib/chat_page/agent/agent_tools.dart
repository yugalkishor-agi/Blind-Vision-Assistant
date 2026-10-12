// lib/chat_page/agent/agent_tools.dart
//
// Thin, testable wrappers around existing services.
// Each tool returns a ToolResult — never throws to the caller.
// The orchestrator decides what to do with failures; tools only report them.

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

import '../services/text_recognition_service.dart';
import '../services/gemma_service.dart';
import '../services/gemma_service_interface.dart';
import 'agent_types.dart';

/// Wraps ML Kit OCR (TextRecognitionService).
/// Returns extracted text and a simple confidence estimate based on text length
/// and character density, since ML Kit does not expose per-character confidence
/// in the version used by this project.
class OcrTool {
  final TextRecognitionService _ocr;

  const OcrTool(this._ocr);

  /// Run OCR on [imageFile].
  /// Retries once on failure if [allowRetry] is true.
  /// Never throws — all exceptions are caught and returned as ToolResult.error.
  Future<ToolResult> run(File imageFile, {bool allowRetry = true}) async {
    return _runOnce(imageFile).then((result) async {
      if (result.status == ToolStatus.error && allowRetry) {
        debugPrint('[OcrTool] First attempt failed, retrying once only');
        await Future<void>.delayed(const Duration(milliseconds: 300));
        final retry = await _runOnce(imageFile);
        return ToolResult(
          status: retry.status,
          extractedText: retry.extractedText,
          confidence: retry.confidence,
          errorDetail: retry.errorDetail,
          wasRetried: true,
        );
      }
      return result;
    });
  }

  Future<ToolResult> _runOnce(File imageFile) async {
    try {
      final text = await _ocr
          .extractTextFromImage(imageFile)
          .timeout(kToolTimeout);

      if (text.trim().isEmpty) {
        return const ToolResult(
          status: ToolStatus.emptyResult,
          extractedText: '',
          errorDetail: 'ML Kit found no text in the image.',
        );
      }

      // Simple heuristic confidence: short results with mostly symbols are suspect.
      final confidence = _estimateOcrConfidence(text);
      final status = confidence >= 0.4
          ? ToolStatus.success
          : ToolStatus.lowConfidence;

      return ToolResult(
        status: status,
        extractedText: text.trim(),
        confidence: confidence,
      );
    } on TimeoutException {
      return const ToolResult(
        status: ToolStatus.timeout,
        errorDetail: 'OCR timed out.',
      );
    } catch (e) {
      return ToolResult(
        status: ToolStatus.error,
        errorDetail: e.toString(),
      );
    }
  }

  /// Heuristic: ratio of alphanumeric characters to total gives a rough
  /// signal. Very low ratio usually means noise / image artifacts.
  double _estimateOcrConfidence(String text) {
    if (text.isEmpty) return 0.0;
    final alphanumCount =
        text.runes.where((r) => _isAlphanumeric(r)).length;
    return (alphanumCount / text.length).clamp(0.0, 1.0);
  }

  bool _isAlphanumeric(int rune) =>
      (rune >= 48 && rune <= 57) || // 0-9
      (rune >= 65 && rune <= 90) || // A-Z
      (rune >= 97 && rune <= 122);  // a-z
}

// ─── Scene detection tool ─────────────────────────────────────────────────────

/// Wraps Gemma vision inference (GemmaServiceInterface).
/// Uses a short, focused prompt optimised for scene description rather than
/// the full system context — keeps inference fast.
class SceneDetectionTool {
  final GemmaServiceInterface _gemma;

  const SceneDetectionTool(this._gemma);

  /// Stream scene description tokens into [onToken]; call [onComplete] when done.
  /// Returns a ToolResult reflecting whether useful content was streamed.
  /// Never throws to the caller.
  Future<ToolResult> run({
    required File imageFile,
    required String userQuery,
    required String scenePrompt,
    required void Function(String token) onToken,
    required void Function() onComplete,
    bool allowRetry = true,
  }) async {
    return _runOnce(
      imageFile: imageFile,
      prompt: scenePrompt,
      onToken: onToken,
      onComplete: onComplete,
    ).then((result) async {
      if (result.status == ToolStatus.error && allowRetry) {
        debugPrint(
            '[SceneDetectionTool] First attempt failed, retrying once only');
        await Future<void>.delayed(const Duration(milliseconds: 500));
        final retry = await _runOnce(
          imageFile: imageFile,
          prompt: scenePrompt,
          onToken: onToken,
          onComplete: onComplete,
        );
        return ToolResult(
          status: retry.status,
          extractedText: retry.extractedText,
          errorDetail: retry.errorDetail,
          wasRetried: true,
        );
      }
      return result;
    });
  }

  Future<ToolResult> _runOnce({
    required File imageFile,
    required String prompt,
    required void Function(String) onToken,
    required void Function() onComplete,
  }) async {
    try {
      final responseBuffer = StringBuffer();

      final inferenceTimeout =
          _gemma.isRemote ? kRemoteInferenceTimeout : kInferenceTimeout;
      await _gemma
          .sendWithStreaming(
            text: prompt,
            image: imageFile,
            onToken: (tok) {
              responseBuffer.write(tok);
              onToken(tok);
            },
            onComplete: (_) => onComplete(),
          )
          .timeout(inferenceTimeout);

      final response = responseBuffer.toString().trim();
      if (response.isEmpty) {
        return const ToolResult(
          status: ToolStatus.emptyResult,
          errorDetail: 'Scene analysis produced no response.',
        );
      }

      return ToolResult(
        status: ToolStatus.success,
        extractedText: response,
      );
    } on TimeoutException {
      return const ToolResult(
        status: ToolStatus.timeout,
        errorDetail: 'Scene detection timed out.',
      );
    } catch (e) {
      return ToolResult(
        status: ToolStatus.error,
        errorDetail: e.toString(),
      );
    }
  }
}

// ─── Combined tool ────────────────────────────────────────────────────────────

/// Runs OCR and scene detection together.
/// OCR result is prepended to the scene prompt so Gemma has grounded text.
/// OCR runs first (fast, on-device) and its output enriches the scene prompt —
/// this avoids sending the same image twice for purely additive information.
class CombinedAnalysisTool {
  final OcrTool _ocrTool;
  final SceneDetectionTool _sceneTool;

  const CombinedAnalysisTool(this._ocrTool, this._sceneTool);

  Future<CombinedToolResult> run({
    required File imageFile,
    required String userQuery,
    required String Function(String? ocrText) buildPrompt,
    required void Function(String token) onToken,
    required void Function() onComplete,
  }) async {
    // Step 1: OCR — fast, no inference cost.
    final ocrResult = await _ocrTool.run(imageFile, allowRetry: true);

    final ocrText = ocrResult.isUsable ? ocrResult.extractedText : null;

    // Step 2: Scene detection with OCR text woven into the prompt.
    final prompt = buildPrompt(ocrText);
    final sceneResult = await _sceneTool.run(
      imageFile: imageFile,
      userQuery: userQuery,
      scenePrompt: prompt,
      onToken: onToken,
      onComplete: onComplete,
      allowRetry: true,
    );

    return CombinedToolResult(ocr: ocrResult, scene: sceneResult);
  }
}

/// Holds both sub-results from a combined tool run.
class CombinedToolResult {
  final ToolResult ocr;
  final ToolResult scene;
  const CombinedToolResult({required this.ocr, required this.scene});

  bool get hasUsableOcr => ocr.isUsable;
  bool get hasUsableScene =>
      scene.status == ToolStatus.success && scene.extractedText.isNotEmpty;
}
