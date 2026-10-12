import 'package:flutter_test/flutter_test.dart';
import 'package:blind_vision_assistant/chat_page/agent/agent_orchestrator.dart';
import 'package:blind_vision_assistant/chat_page/agent/agent_types.dart';

void main() {
  final orchestrator = AgentOrchestrator();

  group('agent decision JSON parsing', () {
    test('parses valid JSON', () {
      final result = orchestrator.parseAgentDecision(
        '{"action":"run_ocr","reason":"read text"}',
      );

      expect(result?.action, AgentAction.runOcr);
      expect(result?.reason, 'read text');
      expect(result?.wasFallback, isFalse);
    });

    test('parses JSON surrounded by prose', () {
      final result = orchestrator.parseAgentDecision(
        'Here is the decision: {"action":"detect_scene"} done.',
      );

      expect(result?.action, AgentAction.detectScene);
    });

    test('rejects invalid actions and malformed JSON', () {
      expect(orchestrator.parseAgentDecision('{"action":"unsupported"}'), isNull);
      expect(orchestrator.parseAgentDecision('not json'), isNull);
      expect(orchestrator.parseAgentDecision(''), isNull);
    });

    test('normalizes action casing and whitespace', () {
      final result = orchestrator.parseAgentDecision(
        '{"action":"  RUN_OCR  ","reason":"text"}',
      );

      expect(result?.action, AgentAction.runOcr);
    });
  });
}
