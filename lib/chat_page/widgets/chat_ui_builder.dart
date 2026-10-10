import 'package:flutter/material.dart';
import '../models/message_models.dart';
import 'chat_bubble.dart';
import 'prompt_bar.dart';

class ChatUIBuilder {
  static Widget buildLoadingScreen() {
    return const Scaffold(
      backgroundColor: Color(0xFFF8F9FA),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading AI model...', style: TextStyle(fontSize: 16, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  static PreferredSizeWidget buildCleanAppBar({
    required VoidCallback onNewChat, required VoidCallback onToggleSettings, required bool isResetting,
  }) {
    return AppBar(
      title: const Text('Blind Vision Assistant', style: TextStyle(fontWeight: FontWeight.bold)),
      backgroundColor: const Color(0xFF4A90D9),
      foregroundColor: Colors.white,
      actions: [
        Semantics(
          label: 'New chat', button: true,
          child: IconButton(icon: const Icon(Icons.add), onPressed: isResetting ? null : onNewChat),
        ),
        Semantics(
          label: 'Settings', button: true,
          child: IconButton(icon: const Icon(Icons.settings), onPressed: onToggleSettings),
        ),
      ],
    );
  }

  static Widget buildViewToggleButtons({
    required bool showMessages, required VoidCallback onToggleMessages,
    required VoidCallback onNewChat, required bool isResetting,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Semantics(
            label: showMessages ? 'Hide messages' : 'Show messages', button: true,
            child: ElevatedButton.icon(
              onPressed: onToggleMessages,
              icon: Icon(showMessages ? Icons.visibility_off : Icons.visibility),
              label: Text(showMessages ? 'Hide' : 'Messages'),
            ),
          ),
        ],
      ),
    );
  }

  static Widget buildMessagesContainer(List<ChatMessage> messages, ScrollController controller) {
    return Expanded(
      child: ListView.builder(
        controller: controller,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: messages.length,
        itemBuilder: (_, i) => ChatBubble(message: messages[i]),
      ),
    );
  }

  static Widget buildPromptBarContainer({
    required GlobalKey<PromptBarState> promptBarKey,
    required Future<void> Function(String) onPromptWithPhoto,
    required Future<void> Function(String) onPromptTextOnly,
    required bool disabled, required bool speechEnabled, required bool listening,
    required VoidCallback onToggleListening, required bool isGenerating,
    required bool isSpeaking, required VoidCallback onStopTts,
  }) {
    return PromptBar(
      key: promptBarKey,
      onPromptWithPhoto: onPromptWithPhoto,
      onPromptTextOnly: onPromptTextOnly,
      disabled: disabled,
      speechEnabled: speechEnabled,
      listening: listening,
      onToggleListening: onToggleListening,
      isGenerating: isGenerating,
      isSpeaking: isSpeaking,
      onStopTts: onStopTts,
    );
  }
}
