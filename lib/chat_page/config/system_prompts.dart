// lib/chat_page/config/system_prompts.dart
//
// All prompt templates in one place.
// Agent prompts are kept separate from the existing navigation prompt
// so existing quick-action paths are completely unaffected.

import '../agent/agent_types.dart';

class SystemPrompts {
  // ── Existing prompts (unchanged) ─────────────────────────────────────────

  static const String blindUserNavigation = '''
You are helping a blind user navigate and read text. Be FAST and USEFUL only, only write the absolute essential information. Answer immediately!
''';

  static const String describeRoom =
      'Describe the room layout, furniture placement, exits, and any hazards';

  static const String tellMeWhatYouSee = 'Tell me what you see';

  static const String whatIsThis = 'What is this?';

  static const String readText = 'Read all visible text exactly as written';

  // ── Agent decision prompts ────────────────────────────────────────────────

  /// Standard decision prompt — first attempt.
  static String buildDecisionPrompt(String userQuery) => '''
You are an AI assistant helping a blind user. Given their query, decide which single action to take.

User query: "$userQuery"

Actions:
- run_ocr       — user wants to READ TEXT in the environment (signs, labels, menus, prices, barcodes)
- detect_scene  — user wants to UNDERSTAND SURROUNDINGS (navigation, objects, colors, people, layout)
- analyze_both  — query needs BOTH text reading AND scene understanding
- ask_user      — query is too vague to act on without more information from the user
- final_answer  — query can be answered from GENERAL KNOWLEDGE with NO camera needed (e.g. general questions, GK, math, definitions, conversational)

IMPORTANT: Use final_answer whenever the query does NOT require looking at anything. Do not open the camera for general knowledge questions.

Reply with ONLY valid JSON, nothing else:
{"action": "run_ocr", "reason": "brief reason"}
''';

  /// Stricter decision prompt — used on the second attempt after a parse failure.
  static String buildStrictDecisionPrompt(String userQuery) => '''
Query: "$userQuery"

Does this query need a camera? Choose action:
- final_answer  if NO camera needed (general knowledge, math, conversation)
- run_ocr       if user wants to read TEXT in the environment
- detect_scene  if user wants to understand the SCENE/SURROUNDINGS
- analyze_both  if BOTH text and scene are needed
- ask_user      if query is too vague

Output exactly one JSON object, no other text:
{"action":"final_answer","reason":"general question"}

Your response:
''';

  // ── No-image answer prompt ────────────────────────────────────────────────

  /// Used when Gemma chose final_answer — no camera involved at all.
  /// Just answer the query directly from knowledge.
  static String buildNoImageAnswerPrompt(String userQuery) => '''
$blindUserNavigation
User: $userQuery
''';

  // ── Scene analysis prompt ─────────────────────────────────────────────────

  /// Builds the prompt sent to Gemma for scene detection.
  /// If [ocrText] is provided (from a prior OCR run), it is included so
  /// Gemma can use it as grounded evidence instead of guessing at text.
  static String buildScenePrompt(String userQuery, String? ocrText) {
    if (ocrText != null && ocrText.trim().isNotEmpty) {
      return '''
$blindUserNavigation
The following text was extracted from the image by OCR (treat this as accurate):
---
$ocrText
---
Using the image and the above extracted text, answer the user's question concisely.
User: $userQuery
''';
    }
    return '''
$blindUserNavigation
User: $userQuery
''';
  }

  // ── OCR-grounded final answer prompt ─────────────────────────────────────
  //
  // KEY HALLUCINATION CONTROL:
  // When OCR has already extracted text, Gemma must use only that text
  // as the primary source. It is explicitly forbidden from inventing text
  // that was not in the OCR output. If the extracted text is insufficient,
  // it must say so rather than guess.

  static String buildFinalAnswerPrompt(AgentContext context) {
    final sb = StringBuffer();
    sb.writeln(blindUserNavigation);

    if (context.ocrText != null && context.ocrText!.trim().isNotEmpty) {
      sb.writeln(
          'Text extracted from the image by ML Kit OCR (this is ground truth):');
      sb.writeln('---');
      sb.writeln(context.ocrText!.trim());
      sb.writeln('---');
      sb.writeln(
          'IMPORTANT: Use ONLY the above extracted text when answering questions about '
          'what is written. Do NOT invent, guess, or assume any text that is not in '
          'the extracted text above. If the question cannot be answered from the '
          'extracted text, say so clearly.');
      sb.writeln();
    }

    if (context.ocrRanAndFailed) {
      sb.writeln(
          'Note: OCR was attempted but found no readable text in the image.');
    }

    sb.writeln('User question: ${context.userQuery}');
    sb.writeln('Answer concisely and directly:');

    return sb.toString();
  }
}
