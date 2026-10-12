import 'package:flutter_test/flutter_test.dart';
import 'package:blind_vision_assistant/chat_page/agent/agent_types.dart';
import 'package:blind_vision_assistant/chat_page/config/system_prompts.dart';

void main() {
  test('scene prompt includes OCR text when available', () {
    final prompt = SystemPrompts.buildScenePrompt(
      'What does this sign say?',
      'EXIT 200M',
    );

    expect(prompt, contains('EXIT 200M'));
    expect(prompt, contains('Using the image'));
  });

  test('no-image prompt stays text-only', () {
    final prompt = SystemPrompts.buildNoImageAnswerPrompt(
      'What is the capital of France?',
    );

    expect(prompt, contains('What is the capital of France?'));
    expect(prompt, isNot(contains('camera')));
  });

  test('scene prompt omits OCR section when unavailable', () {
    final prompt = SystemPrompts.buildScenePrompt('What is ahead?', null);

    expect(prompt, isNot(contains('Text was extracted')));
    expect(prompt, contains('What is ahead?'));
  });

  test('final prompt includes OCR grounding instructions', () {
    final prompt = SystemPrompts.buildFinalAnswerPrompt(
      const AgentContext(
        userQuery: 'What is the expiry date?',
        ocrText: 'EXP 2027',
        toolCallsUsed: 1,
        inferenceCallsUsed: 2,
      ),
    );

    expect(prompt, contains('EXP 2027'));
    expect(prompt, contains('Do NOT invent'));
  });
}
