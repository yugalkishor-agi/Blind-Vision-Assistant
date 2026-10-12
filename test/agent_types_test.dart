import 'package:flutter_test/flutter_test.dart';
import 'package:blind_vision_assistant/chat_page/agent/agent_types.dart';

void main() {
  group('agent action parsing', () {
    test('accepts every allowlisted action', () {
      for (final action in kAllowedActions) {
        expect(agentActionFromString(action), isNotNull);
      }
    });

    test('rejects unsupported actions', () {
      expect(agentActionFromString('delete_everything'), isNull);
      expect(agentActionFromString(''), isNull);
    });
  });

  group('deterministic fallback', () {
    test('marks only visual actions as image-dependent', () {
      expect(actionNeedsImage(AgentAction.runOcr), isTrue);
      expect(actionNeedsImage(AgentAction.detectScene), isTrue);
      expect(actionNeedsImage(AgentAction.analyzeBoth), isTrue);
      expect(actionNeedsImage(AgentAction.finalAnswer), isFalse);
      expect(actionNeedsImage(AgentAction.askUser), isFalse);
    });

    test('uses final answer for general knowledge queries', () {
      expect(determineFallbackAction('What is the capital of France?'),
          AgentAction.finalAnswer);
      expect(determineFallbackAction('Explain gravity'),
          AgentAction.finalAnswer);
      expect(determineFallbackAction('Hello, how are you?'),
          AgentAction.finalAnswer);
    });

    test('keeps visual clue queries image-dependent', () {
      expect(determineFallbackAction('What does this sign say?'),
          AgentAction.runOcr);
      expect(determineFallbackAction('What do you see in front of me?'),
          AgentAction.detectScene);
    });

    test('uses OCR for reading queries', () {
      expect(determineFallbackAction('Please read the price on this label'),
          AgentAction.runOcr);
    });

    test('uses scene detection for spatial queries', () {
      expect(determineFallbackAction('Where is the door?'),
          AgentAction.detectScene);
    });

    test('never defaults to analyze both', () {
      expect(determineFallbackAction('Help me understand this'),
          isNot(AgentAction.analyzeBoth));
    });
  });
}
