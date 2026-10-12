// lib/chat_page/agent/agent_types.dart
//
// All enums, data classes, and constants for the agent workflow.
// Deliberately kept free of Flutter/platform imports so it is easy to unit-test.

// ─── Limits ──────────────────────────────────────────────────────────────────

/// Hard cap on how many tool executions one agent turn may perform.
/// OCR is cheap; Gemma inference is expensive — keep this small.
const int kMaxToolCalls = 3;

/// Maximum Gemma inference calls per agent turn (decision + final answer).
/// Prevents runaway inference on a resource-constrained device.
const int kMaxInferenceCalls = 4;

/// Maximum retries allowed per individual tool when it fails.
/// This is separate from kMaxToolCalls so a single bad tool
/// does not exhaust the global tool budget.
const int kMaxToolRetries = 1;

/// Maximum attempts to obtain a valid parsable JSON decision from Gemma.
/// First attempt uses the normal prompt; second uses a stricter prompt.
/// After both fail, a deterministic fallback is chosen — never analyze_both.
const int kMaxDecisionAttempts = 2;

/// Hard timeout for a single Gemma inference call (decision or final answer).
const Duration kInferenceTimeout = Duration(seconds: 90);

/// Hosted endpoint returns one complete response and may take up to 300s.
const Duration kRemoteInferenceTimeout = Duration(seconds: 300);

/// Hard timeout for a single tool execution (OCR, scene detect).
const Duration kToolTimeout = Duration(seconds: 30);

// ─── Action allowlist ─────────────────────────────────────────────────────────

/// Every action string Gemma is permitted to select.
/// The orchestrator validates against this set before executing anything.
/// Any string not in this set is rejected and triggers a fallback.
const Set<String> kAllowedActions = {
  'run_ocr',
  'detect_scene',
  'analyze_both',
  'ask_user',
  'final_answer',
};

// ─── Enums ────────────────────────────────────────────────────────────────────

/// The action Gemma chose, after validation and parsing.
enum AgentAction {
  runOcr,
  detectScene,
  analyzeBoth,
  askUser,
  finalAnswer,
}

/// Whether this action requires a camera image to execute.
/// Called BEFORE capturing to avoid opening camera unnecessarily.
bool actionNeedsImage(AgentAction action) {
  switch (action) {
    case AgentAction.runOcr:
    case AgentAction.detectScene:
    case AgentAction.analyzeBoth:
      return true;
    case AgentAction.askUser:
    case AgentAction.finalAnswer:
      return false;
  }
}

/// Maps the raw string from Gemma's JSON to the typed enum.
/// Returns null if the string is not in the allowlist.
AgentAction? agentActionFromString(String raw) {
  switch (raw.trim().toLowerCase()) {
    case 'run_ocr':
      return AgentAction.runOcr;
    case 'detect_scene':
      return AgentAction.detectScene;
    case 'analyze_both':
      return AgentAction.analyzeBoth;
    case 'ask_user':
      return AgentAction.askUser;
    case 'final_answer':
      return AgentAction.finalAnswer;
    default:
      return null;
  }
}

/// The overall state of the agent turn — used to drive UI status messages.
enum AgentState {
  idle,
  deciding,       // Waiting for Gemma's action decision
  executingOcr,   // Running ML Kit OCR
  executingScene, // Running Gemma vision
  validating,     // Checking tool result quality
  answering,      // Streaming final answer
  done,
  failed,
}

/// How a tool execution ended.
enum ToolStatus {
  success,
  emptyResult,    // Tool ran but returned no useful data
  lowConfidence,  // Tool ran but confidence is below threshold
  timeout,        // Tool did not complete in time
  error,          // Tool threw an exception
}

// ─── Data classes ─────────────────────────────────────────────────────────────

/// Parsed decision from Gemma's JSON output.
class AgentDecision {
  final AgentAction action;
  final String reason; // Gemma's explanation (never shown to user, only logged)
  final bool wasFallback; // True if this came from deterministic fallback, not Gemma

  const AgentDecision({
    required this.action,
    required this.reason,
    this.wasFallback = false,
  });

  @override
  String toString() =>
      'AgentDecision(action: $action, reason: "$reason", fallback: $wasFallback)';
}

/// Result returned by any tool execution.
class ToolResult {
  final ToolStatus status;

  /// For OCR: extracted text. For scene: empty (text comes through streaming).
  final String extractedText;

  /// Normalised confidence 0.0–1.0, or null if the tool doesn't provide it.
  final double? confidence;

  /// Human-readable error detail, only set when status != success.
  final String? errorDetail;

  /// True when the tool was retried at least once before this result.
  final bool wasRetried;

  const ToolResult({
    required this.status,
    this.extractedText = '',
    this.confidence,
    this.errorDetail,
    this.wasRetried = false,
  });

  bool get isUsable =>
      status == ToolStatus.success && extractedText.trim().isNotEmpty;

  @override
  String toString() =>
      'ToolResult(status: $status, textLen: ${extractedText.length}, '
      'confidence: $confidence, error: $errorDetail)';
}

/// Aggregated context passed to Gemma when requesting the final answer.
class AgentContext {
  final String userQuery;
  final String? ocrText;        // null if OCR was not run
  final bool ocrRanAndFailed;   // true if OCR ran but returned nothing useful
  final int toolCallsUsed;
  final int inferenceCallsUsed;

  const AgentContext({
    required this.userQuery,
    this.ocrText,
    this.ocrRanAndFailed = false,
    required this.toolCallsUsed,
    required this.inferenceCallsUsed,
  });
}

/// Fallback policy: choose a deterministic action based on query keywords
/// when Gemma fails to produce valid JSON twice in a row.
/// This is intentionally NOT analyze_both — we pick the most likely
/// single tool based on what the user asked.
AgentAction determineFallbackAction(String query) {
  final q = query.toLowerCase();

  // General knowledge / conversational — no image needed at all
  if (_matchesAny(q, [
    'what is', 'who is', 'when did', 'how do', 'how does', 'why does',
    'tell me about', 'explain', 'define', 'meaning of', 'capital of',
    'what year', 'history', 'calculate', 'math', 'weather', 'joke',
    'hello', 'hi', 'thanks', 'thank you', 'help me understand',
  ])) {
    // But only if there are no visual clue words alongside
    final hasVisualClue = _matchesAny(q, [
      'this', 'here', 'front', 'see', 'look', 'image', 'photo',
      'camera', 'picture', 'show', 'read', 'sign', 'board',
    ]);
    if (!hasVisualClue) return AgentAction.finalAnswer;
  }

  // Text/reading queries → OCR is more reliable than Gemma for text
  if (_matchesAny(q, [
    'read', 'text', 'written', 'says', 'write', 'label',
    'sign', 'board', 'price', 'menu', 'number', 'code',
    'barcode', 'qr', 'ingredient', 'expiry', 'date',
  ])) {
    return AgentAction.runOcr;
  }

  // Navigation / spatial queries → scene detection
  if (_matchesAny(q, [
    'where', 'describe', 'see', 'look', 'around',
    'direction', 'room', 'obstacle', 'path', 'door', 'exit',
    'color', 'colour', 'shape', 'person', 'object', 'in front',
  ])) {
    return AgentAction.detectScene;
  }

  // Default safe fallback: scene detection (single tool, not both)
  return AgentAction.detectScene;
}

bool _matchesAny(String query, List<String> keywords) =>
    keywords.any((k) => query.contains(k));
