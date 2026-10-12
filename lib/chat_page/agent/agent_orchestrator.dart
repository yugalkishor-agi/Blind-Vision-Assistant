// lib/chat_page/agent/agent_orchestrator.dart
//
// Application-level tool orchestration for Gemma 3n E2B.
//
// KEY DESIGN: The orchestrator decides FIRST (text-only inference, no camera),
// then opens the camera ONLY if the chosen action requires an image.
// This makes general-knowledge / conversational queries significantly faster
// because the camera never opens for them.
//
// JSON parsing uses a two-pass strategy:
//   1. jsonDecode on the full response
//   2. Extract first{...}last} block if step 1 fails
// Strictly validated against the action allowlist.
// After kMaxDecisionAttempts failures → deterministic keyword fallback.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../services/gemma_service.dart';
import '../services/gemma_service_interface.dart';
import '../services/text_recognition_service.dart';
import '../config/system_prompts.dart';
import 'agent_types.dart';
import 'agent_tools.dart';

// ─── Public callback types ────────────────────────────────────────────────────

typedef OnAgentStateChanged = void Function(AgentState state);
typedef OnAgentStatusMessage = void Function(String message);
typedef OnAgentToken = void Function(String token);
typedef OnAgentComplete = void Function(String fullResponse);
typedef OnAgentError = void Function(String userFacingMessage);

// ─── Orchestrator ─────────────────────────────────────────────────────────────

class AgentOrchestrator {
  final GemmaServiceInterface _gemma;
  final OcrTool _ocrTool;
  final SceneDetectionTool _sceneTool;
  final CombinedAnalysisTool _combinedTool;

  AgentOrchestrator({
    GemmaServiceInterface? gemma,
    TextRecognitionService? ocr,
  })  : _gemma = gemma ?? GemmaService.instance,
        _ocrTool = OcrTool(ocr ?? TextRecognitionService.instance),
        _sceneTool = SceneDetectionTool(gemma ?? GemmaService.instance),
        _combinedTool = CombinedAnalysisTool(
          OcrTool(ocr ?? TextRecognitionService.instance),
          SceneDetectionTool(gemma ?? GemmaService.instance),
        );

  Duration get _inferenceTimeout =>
      _gemma.isRemote ? kRemoteInferenceTimeout : kInferenceTimeout;

  // ─── Main entry point ────────────────────────────────────────────────────

  /// Run one complete agent turn for [userQuery].
  ///
  /// [captureImage] is a LAZY callback — the camera is opened ONLY if the
  /// chosen action actually requires an image. For general knowledge queries
  /// (GK, math, conversation) the camera never opens → much faster response.
  ///
  /// Callbacks:
  /// - [onStateChanged]  — drives UI status label
  /// - [onStatusMessage] — concise spoken status (not shown as AI response)
  /// - [onToken]         — final answer tokens (streamed to existing TTS)
  /// - [onComplete]      — full response assembled
  /// - [onError]         — unrecoverable failure; safe to speak to user
  Future<void> run({
    required String userQuery,
    required Future<File?> Function() captureImage,
    required OnAgentStateChanged onStateChanged,
    required OnAgentStatusMessage onStatusMessage,
    required OnAgentToken onToken,
    required OnAgentComplete onComplete,
    required OnAgentError onError,
  }) async {
    int toolCallsUsed = 0;
    int inferenceCallsUsed = 0;

    // Agent routing/tool stages must not inherit stale router or normal-chat
    // turns. Otherwise the vision request can answer with another action JSON.
    try {
      await _gemma.resetChatSession();
      debugPrint('[Orchestrator] Isolated agent session started');
    } catch (e) {
      debugPrint('[Orchestrator] Could not reset agent session: $e');
    }

    debugPrint('[Orchestrator] INPUT query="${_logPreview(userQuery)}"');

    // ── Step 1: Decide action — text-only inference, NO camera yet ───────────
    onStateChanged(AgentState.deciding);
    // No status message — loading music is already playing

    AgentDecision decision;
    try {
      final outcome = await _obtainDecision(
        userQuery: userQuery,
        inferenceCallsUsed: inferenceCallsUsed,
      );
      decision = outcome.decision;
      inferenceCallsUsed += outcome.inferenceCalls;
    } catch (e) {
      debugPrint('[Orchestrator] Decision phase crashed: $e');
      decision = AgentDecision(
        action: determineFallbackAction(userQuery),
        reason: 'Exception during decision: $e',
        wasFallback: true,
      );
    }

    debugPrint(
        '[Orchestrator] Decision: $decision  needsImage: ${actionNeedsImage(decision.action)}');

    // ── Step 2: No-image fast paths ──────────────────────────────────────────

    if (decision.action == AgentAction.askUser) {
      const msg =
          'Could you be more specific? I am not sure what you would like me to help with.';
      onStateChanged(AgentState.done);
      onStatusMessage(msg);
      for (final word in msg.split(' ')) {
        onToken('$word ');
      }
      onComplete(msg);
      return;
    }

    if (decision.action == AgentAction.finalAnswer) {
      // General knowledge / conversational — camera never opens
      if (inferenceCallsUsed >= kMaxInferenceCalls) {
        _failSafely(onStateChanged, onError,
            'I reached my processing limit. Please try again.');
        return;
      }
      await _resetStageSession();
      onStateChanged(AgentState.answering);
      inferenceCallsUsed++;
      await _streamNoImageAnswer(
        userQuery: userQuery,
        onToken: onToken,
        onComplete: onComplete,
        onError: onError,
        onStateChanged: onStateChanged,
      );
      return;
    }

    // ── Step 3: Capture image (only if action requires it) ───────────────────
    File? imageFile;
    try {
      imageFile = await captureImage();
    } catch (e) {
      debugPrint('[Orchestrator] Camera capture failed: $e');
      _failSafely(onStateChanged, onError,
          'Could not access the camera. Please try again.');
      return;
    }

    if (imageFile == null) {
      _failSafely(onStateChanged, onError,
          'Could not capture an image. Please try again.');
      return;
    }

    debugPrint('[Orchestrator] IMAGE captured path=${imageFile.path}');

    // Do not send the routing JSON/history to OCR/scene/final-answer stages.
    await _resetStageSession();

    // ── Step 4: Execute the chosen tool(s) ───────────────────────────────────
    AgentContext context = AgentContext(
      userQuery: userQuery,
      toolCallsUsed: toolCallsUsed,
      inferenceCallsUsed: inferenceCallsUsed,
    );

    switch (decision.action) {
      case AgentAction.runOcr:
        context = await _executeOcr(
          imageFile: imageFile,
          userQuery: userQuery,
          toolCallsUsed: toolCallsUsed,
          inferenceCallsUsed: inferenceCallsUsed,
          onStateChanged: onStateChanged,
          onStatusMessage: onStatusMessage,
          onToken: onToken,
          onComplete: onComplete,
          onError: onError,
        );
        if (context == _kEarlyReturn) return;
        toolCallsUsed = context.toolCallsUsed;
        inferenceCallsUsed = context.inferenceCallsUsed;
        break;

      case AgentAction.detectScene:
        final completed = await _executeScene(
          imageFile: imageFile,
          userQuery: userQuery,
          ocrText: null,
          toolCallsUsed: toolCallsUsed,
          inferenceCallsUsed: inferenceCallsUsed,
          onStateChanged: onStateChanged,
          onStatusMessage: onStatusMessage,
          onToken: onToken,
          onComplete: onComplete,
          onError: onError,
        );
        if (!completed) return;
        return;

      case AgentAction.analyzeBoth:
        final completed = await _executeBoth(
          imageFile: imageFile,
          userQuery: userQuery,
          toolCallsUsed: toolCallsUsed,
          inferenceCallsUsed: inferenceCallsUsed,
          onStateChanged: onStateChanged,
          onStatusMessage: onStatusMessage,
          onToken: onToken,
          onComplete: onComplete,
          onError: onError,
        );
        if (!completed) return;
        return;

      default:
        break;
    }

    // ── Step 5: Stream final answer with accumulated context ──────────────────
    if (inferenceCallsUsed >= kMaxInferenceCalls) {
      _failSafely(onStateChanged, onError,
          'I used too many processing steps. Please try again.');
      return;
    }

    onStateChanged(AgentState.answering);
    onStatusMessage('Composing answer…');
    await _streamFinalAnswer(
      context: context,
      imageFile: imageFile,
      onToken: onToken,
      onComplete: onComplete,
      onError: onError,
      onStateChanged: onStateChanged,
    );
  }

  // ─── No-image answer ──────────────────────────────────────────────────────

  /// Stream a direct answer from Gemma without any image — for GK, math, etc.
  Future<void> _streamNoImageAnswer({
    required String userQuery,
    required OnAgentToken onToken,
    required OnAgentComplete onComplete,
    required OnAgentError onError,
    required OnAgentStateChanged onStateChanged,
  }) async {
    final prompt = SystemPrompts.buildNoImageAnswerPrompt(userQuery);
    final responseBuffer = StringBuffer();

    try {
      await _gemma
          .sendWithStreaming(
            text: prompt,
            image: null,
            onToken: (tok) {
              responseBuffer.write(tok);
              onToken(tok);
            },
            onComplete: (_) {
              debugPrint(
                  '[Orchestrator] FINAL output="${_logPreview(responseBuffer.toString())}"');
              onStateChanged(AgentState.done);
              onComplete(responseBuffer.toString());
            },
          )
          .timeout(_inferenceTimeout);
    } on TimeoutException {
      _failSafely(onStateChanged, onError,
          'The response took too long. Please retry.');
    } catch (e) {
      debugPrint('[Orchestrator] No-image answer error: $e');
      _failSafely(onStateChanged, onError,
          'I ran into an error. Please try again.');
    }
  }

  // ─── OCR execution path ───────────────────────────────────────────────────

  Future<AgentContext> _executeOcr({
    required File imageFile,
    required String userQuery,
    required int toolCallsUsed,
    required int inferenceCallsUsed,
    required OnAgentStateChanged onStateChanged,
    required OnAgentStatusMessage onStatusMessage,
    required OnAgentToken onToken,
    required OnAgentComplete onComplete,
    required OnAgentError onError,
  }) async {
    if (toolCallsUsed >= kMaxToolCalls) {
      _failSafely(
          onStateChanged, onError, 'I reached my tool limit. Please try again.');
      return _kEarlyReturn;
    }

    onStateChanged(AgentState.executingOcr);
    onStatusMessage('Reading text…');
    toolCallsUsed++;

    final ocrResult = await _ocrTool.run(imageFile, allowRetry: true);
    debugPrint(
        '[Orchestrator] OCR output status=${ocrResult.status} '
        'retried=${ocrResult.wasRetried} '
        'text="${_logPreview(ocrResult.extractedText)}"');

    switch (ocrResult.status) {
      case ToolStatus.success:
        return AgentContext(
          userQuery: userQuery,
          ocrText: ocrResult.extractedText,
          toolCallsUsed: toolCallsUsed,
          inferenceCallsUsed: inferenceCallsUsed,
        );

      case ToolStatus.lowConfidence:
        // Partial text — still usable
        return AgentContext(
          userQuery: userQuery,
          ocrText: ocrResult.extractedText,
          toolCallsUsed: toolCallsUsed,
          inferenceCallsUsed: inferenceCallsUsed,
        );

      case ToolStatus.emptyResult:
        const msg =
            'I could not find any text in the image. Please hold the camera '
            'closer to the text and make sure it is well lit.';
        onStateChanged(AgentState.done);
        onStatusMessage(msg);
        for (final word in msg.split(' ')) onToken('$word ');
        onComplete(msg);
        return _kEarlyReturn;

      case ToolStatus.timeout:
      case ToolStatus.error:
        // OCR failed — fall back to scene detection (not analyze_both)
        debugPrint(
            '[Orchestrator] OCR failed (${ocrResult.status}), falling back to scene');
        onStatusMessage('Text reading failed. Analyzing visually…');
        final completed = await _executeScene(
          imageFile: imageFile,
          userQuery: userQuery,
          ocrText: null,
          toolCallsUsed: toolCallsUsed,
          inferenceCallsUsed: inferenceCallsUsed,
          onStateChanged: onStateChanged,
          onStatusMessage: onStatusMessage,
          onToken: onToken,
          onComplete: onComplete,
          onError: onError,
        );
        if (!completed) return _kEarlyReturn;
        return _kEarlyReturn;
    }
  }

  // ─── Scene detection execution path ──────────────────────────────────────

  Future<bool> _executeScene({
    required File imageFile,
    required String userQuery,
    required String? ocrText,
    required int toolCallsUsed,
    required int inferenceCallsUsed,
    required OnAgentStateChanged onStateChanged,
    required OnAgentStatusMessage onStatusMessage,
    required OnAgentToken onToken,
    required OnAgentComplete onComplete,
    required OnAgentError onError,
  }) async {
    if (toolCallsUsed >= kMaxToolCalls ||
        inferenceCallsUsed >= kMaxInferenceCalls) {
      _failSafely(onStateChanged, onError,
          'I reached my processing limit. Please try again.');
      return false;
    }

    onStateChanged(AgentState.executingScene);
    onStatusMessage('Analyzing the scene…');
    toolCallsUsed++;
    inferenceCallsUsed++;

    final prompt = SystemPrompts.buildScenePrompt(userQuery, ocrText);
    final responseBuffer = StringBuffer();

    final result = await _sceneTool.run(
      imageFile: imageFile,
      userQuery: userQuery,
      scenePrompt: prompt,
      onToken: (tok) {
        responseBuffer.write(tok);
        onToken(tok);
      },
      onComplete: () {
        onStateChanged(AgentState.done);
        onComplete(responseBuffer.toString());
      },
      allowRetry: true,
    );

    if (result.status == ToolStatus.timeout ||
        result.status == ToolStatus.error) {
      _failSafely(onStateChanged, onError,
          'Scene analysis failed. Please try again.');
      return false;
    }

    return true;
  }

  // ─── Combined (analyze_both) execution path ───────────────────────────────

  Future<bool> _executeBoth({
    required File imageFile,
    required String userQuery,
    required int toolCallsUsed,
    required int inferenceCallsUsed,
    required OnAgentStateChanged onStateChanged,
    required OnAgentStatusMessage onStatusMessage,
    required OnAgentToken onToken,
    required OnAgentComplete onComplete,
    required OnAgentError onError,
  }) async {
    if (toolCallsUsed >= kMaxToolCalls ||
        inferenceCallsUsed >= kMaxInferenceCalls) {
      _failSafely(onStateChanged, onError,
          'I reached my processing limit. Please try again.');
      return false;
    }

    onStateChanged(AgentState.executingOcr);
    onStatusMessage('Reading text and analyzing scene…');
    toolCallsUsed++;
    inferenceCallsUsed++;

    final responseBuffer = StringBuffer();

    final combined = await _combinedTool.run(
      imageFile: imageFile,
      userQuery: userQuery,
      buildPrompt: (ocrText) =>
          SystemPrompts.buildScenePrompt(userQuery, ocrText),
      onToken: (tok) {
        responseBuffer.write(tok);
        onToken(tok);
      },
      onComplete: () {
        onStateChanged(AgentState.done);
        onComplete(responseBuffer.toString());
      },
    );

    if (!combined.hasUsableScene) {
      _failSafely(onStateChanged, onError,
          'I could not analyze the image. Please try again.');
      return false;
    }

    return true;
  }

  // ─── Final answer (tool result → synthesis) ───────────────────────────────

  Future<void> _streamFinalAnswer({
    required AgentContext context,
    required File? imageFile,
    required OnAgentToken onToken,
    required OnAgentComplete onComplete,
    required OnAgentError onError,
    required OnAgentStateChanged onStateChanged,
  }) async {
    final prompt = SystemPrompts.buildFinalAnswerPrompt(context);
    final responseBuffer = StringBuffer();

    try {
      await _gemma
          .sendWithStreaming(
            text: prompt,
            // If we have OCR text, the prompt already contains it — skip image
            // to avoid redundant vision inference on the same content.
            image: context.ocrText != null ? null : imageFile,
            onToken: (tok) {
              responseBuffer.write(tok);
              onToken(tok);
            },
            onComplete: (_) {
              debugPrint(
                  '[Orchestrator] FINAL output="${_logPreview(responseBuffer.toString())}"');
              onStateChanged(AgentState.done);
              onComplete(responseBuffer.toString());
            },
          )
          .timeout(_inferenceTimeout);
    } on TimeoutException {
      _failSafely(
          onStateChanged, onError, 'The response took too long. Please retry.');
    } catch (e) {
      debugPrint('[Orchestrator] Final answer error: $e');
      _failSafely(onStateChanged, onError,
          'I ran into an error generating the answer. Please try again.');
    }
  }

  // ─── Decision parsing ─────────────────────────────────────────────────────

  /// Ask Gemma for a JSON action decision — TEXT ONLY, no image.
  /// Decision step never needs the camera; it just classifies the query.
  Future<_DecisionOutcome> _obtainDecision({
    required String userQuery,
    required int inferenceCallsUsed,
  }) async {
    for (int attempt = 0; attempt < kMaxDecisionAttempts; attempt++) {
      if (inferenceCallsUsed >= kMaxInferenceCalls) break;

      final isStrict = attempt > 0;
      final prompt = isStrict
          ? SystemPrompts.buildStrictDecisionPrompt(userQuery)
          : SystemPrompts.buildDecisionPrompt(userQuery);

      debugPrint(
          '[Orchestrator] Decision attempt ${attempt + 1} (strict: $isStrict)');
      inferenceCallsUsed++;

      try {
        final raw = await _collectFullResponse(prompt: prompt)
            .timeout(_inferenceTimeout);

        debugPrint('[Orchestrator] Raw decision response: $raw');

        final decision = parseAgentDecision(raw);
        if (decision != null) {
          return _DecisionOutcome(
            decision: decision,
            inferenceCalls: attempt + 1,
          );
        }

        if (attempt + 1 < kMaxDecisionAttempts) {
          await _resetStageSession();
        }

        debugPrint(
            '[Orchestrator] Parse failed on attempt ${attempt + 1}, '
            '${attempt + 1 < kMaxDecisionAttempts ? "retrying with stricter prompt" : "using deterministic fallback"}');
      } on TimeoutException {
        debugPrint('[Orchestrator] Decision attempt ${attempt + 1} timed out');
        break;
      } catch (e) {
        debugPrint('[Orchestrator] Decision attempt ${attempt + 1} error: $e');
        break;
      }
    }

    // Deterministic fallback — keyword-based, never analyze_both blindly
    final fallbackAction = determineFallbackAction(userQuery);
    debugPrint('[Orchestrator] Using deterministic fallback: $fallbackAction');
    return _DecisionOutcome(
      decision: AgentDecision(
        action: fallbackAction,
        reason:
            'Deterministic fallback after $kMaxDecisionAttempts failed parse attempts',
        wasFallback: true,
      ),
      inferenceCalls: kMaxDecisionAttempts,
    );
  }

  /// Collect all streaming tokens into a single string (non-streaming mode).
  /// Used for the decision step where we need the full response before parsing.
  Future<String> _collectFullResponse({
    required String prompt,
  }) async {
    final buffer = StringBuffer();
    final completer = Completer<String>();

    await _gemma.sendWithStreaming(
      text: prompt,
      image: null, // Decision is always text-only
      onToken: (tok) => buffer.write(tok),
      onComplete: (_) {
        if (!completer.isCompleted) {
          completer.complete(buffer.toString());
        }
      },
    );

    return completer.future;
  }

  Future<void> _resetStageSession() async {
    try {
      await _gemma.resetChatSession();
      debugPrint('[Orchestrator] Stage session reset');
    } catch (e) {
      debugPrint('[Orchestrator] Stage reset failed: $e');
    }
  }

  // ─── JSON parsing ─────────────────────────────────────────────────────────

  /// Two-pass JSON parser:
  /// Pass 1: jsonDecode on the full trimmed response.
  /// Pass 2: Extract from first '{' to last '}' (handles prose wrapping).
  ///
  /// After extraction, validate action against the allowlist.
  /// Returns null if parsing or validation fails.
  AgentDecision? parseAgentDecision(String raw) {
    if (raw.trim().isEmpty) return null;

    // Pass 1: direct decode
    Map<String, dynamic>? json = _tryJsonDecode(raw.trim());

    // Pass 2: extract outermost {...} block
    if (json == null) {
      final first = raw.indexOf('{');
      final last = raw.lastIndexOf('}');
      if (first != -1 && last != -1 && last > first) {
        json = _tryJsonDecode(raw.substring(first, last + 1));
      }
    }

    if (json == null) {
      debugPrint('[Orchestrator] No valid JSON found in response');
      return null;
    }

    final rawAction = json['action'];
    if (rawAction is! String) {
      debugPrint('[Orchestrator] "action" field missing or not a string');
      return null;
    }

    // Strict allowlist check — never execute arbitrary strings
    if (!kAllowedActions.contains(rawAction.trim().toLowerCase())) {
      debugPrint('[Orchestrator] Action "$rawAction" not in allowlist');
      return null;
    }

    final action = agentActionFromString(rawAction);
    if (action == null) return null;

    final reason = (json['reason'] as String?)?.trim() ?? '';
    return AgentDecision(action: action, reason: reason);
  }

  Map<String, dynamic>? _tryJsonDecode(String s) {
    try {
      final decoded = jsonDecode(s);
      if (decoded is Map<String, dynamic>) return decoded;
      return null;
    } catch (_) {
      return null;
    }
  }

  // ─── Utilities ────────────────────────────────────────────────────────────

  void _failSafely(
    OnAgentStateChanged onStateChanged,
    OnAgentError onError,
    String message,
  ) {
    onStateChanged(AgentState.failed);
    onError(message);
  }
}

String _logPreview(String value) {
  final singleLine = value.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (singleLine.length <= 800) return singleLine;
  return '${singleLine.substring(0, 800)}…';
}

class _DecisionOutcome {
  final AgentDecision decision;
  final int inferenceCalls;

  const _DecisionOutcome({
    required this.decision,
    required this.inferenceCalls,
  });
}

/// Sentinel value returned by sub-methods when they have already handled
/// completion/error and the caller should return immediately.
final AgentContext _kEarlyReturn = const AgentContext(
  userQuery: '__early_return__',
  toolCallsUsed: -1,
  inferenceCallsUsed: -1,
);
