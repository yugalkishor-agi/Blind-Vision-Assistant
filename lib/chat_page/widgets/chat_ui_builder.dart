// lib/chat_page/widgets/chat_ui_builder.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/message_models.dart';
import 'chat_bubble.dart';
import 'prompt_bar.dart';
import 'semantic_material_button.dart';

/// Static UI builder for chat interface components with accessibility integration
class ChatUIBuilder {
  /// Clean modern app bar with settings button and proper system overlay
  static PreferredSizeWidget buildCleanAppBar({
    required VoidCallback onNewChat,
    required VoidCallback onToggleSettings,
    required bool isResetting,
  }) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      systemOverlayStyle: SystemUiOverlayStyle.dark, // Dark status bar content
      title: const Text(
        'Gemma Vision',
        style: TextStyle(
          color: Colors.black87,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        // Settings button with accessibility support
        SemanticMaterialButton(
          label: 'Settings',
          hint: 'Double-tap to open settings page',
          onPressed: onToggleSettings,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.tune_rounded, size: 18, color: Colors.blue.shade700),
                const SizedBox(width: 4),
                Text(
                  'Settings',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  /// Toggle buttons for New Chat and Show/Hide Messages with proper focus traversal
  static Widget buildViewToggleButtons({
    required bool showMessages,
    required VoidCallback onToggleMessages,
    required VoidCallback onNewChat,
    required bool isResetting,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: FocusTraversalGroup(
        policy: WidgetOrderTraversalPolicy(),
        child: Row(
          children: [
            Expanded(
              child: _buildToggleButton(
                icon: Icons.refresh_rounded,
                label: 'New Chat',
                hint: isResetting
                    ? 'New chat is currently processing'
                    : 'Double-tap to start a new chat conversation',
                isActive: true,
                activeColor: Colors.teal, // Green theme
                inactiveColor: const Color(0xFFE8F5E8),
                onPressed: isResetting ? null : onNewChat,
                disabled: isResetting,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildToggleButton(
                icon: showMessages
                    ? Icons.chat_bubble_rounded
                    : Icons.chat_bubble_outline_rounded,
                label: showMessages ? 'Hide Messages' : 'Show Messages',
                hint: showMessages
                    ? 'Double-tap to hide the conversation messages'
                    : 'Double-tap to show the conversation messages',
                isActive: showMessages,
                activeColor: Colors.blueAccent, // Blue theme
                inactiveColor: const Color(0xFFE3F2FD),
                onPressed: onToggleMessages,
                disabled: false,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Reusable toggle button with state-based styling and accessibility
  static Widget _buildToggleButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required Color activeColor,
    required Color inactiveColor,
    required VoidCallback? onPressed,
    required String hint,
    bool disabled = false,
  }) {
    Color backgroundColor;
    Color textColor;
    Color iconColor;

    // State-based color scheme
    if (disabled) {
      backgroundColor = const Color(0xFFE0E7FF);
      textColor = const Color(0xFF9CA3AF);
      iconColor = const Color(0xFF9CA3AF);
    } else if (isActive) {
      backgroundColor = activeColor;
      textColor = Colors.white;
      iconColor = Colors.white;
    } else {
      backgroundColor = inactiveColor;
      textColor = activeColor;
      iconColor = activeColor;
    }

    return SemanticMaterialButton(
      label: label,
      hint: hint,
      onPressed: disabled ? null : onPressed,
      disabled: disabled,
      child: SizedBox(
        height: 56,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: null, // Handled by semantic wrapper
            borderRadius: BorderRadius.circular(16),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: iconColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Scrollable message list with accessibility labels and semantic child counting
  static Widget buildMessagesContainer(
    List<ChatMessage> messages,
    ScrollController scrollController,
  ) {
    return Expanded(
      child: Semantics(
        label: 'Chat messages',
        hint: 'Swipe to scroll through conversation history',
        child: ListView.builder(
          controller: scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          itemCount: messages.length,
          semanticChildCount: messages.length, // For screen readers
          itemBuilder: (_, i) => Semantics(
            // Descriptive labels for each message
            label: messages[i].isUser
                ? 'Your message ${i + 1} of ${messages.length}'
                : 'AI response ${i + 1} of ${messages.length}',
            child: ChatBubble(msg: messages[i]),
          ),
        ),
      ),
    );
  }

  /// Container for prompt bar that shows status during AI processing
  static Widget buildPromptBarContainer({
    required GlobalKey<PromptBarState> promptBarKey,
    required Future<void> Function(String) onPromptWithPhoto,
    required Future<void> Function(String) onPromptTextOnly,
    required bool disabled,
    required bool speechEnabled,
    required bool listening,
    required VoidCallback onToggleListening,
    required bool isGenerating,
    required bool isSpeaking,
    Future<void> Function()? onStopTts,
  }) {
    // Show status widget when AI is busy, otherwise show input bar
    if (isGenerating || isSpeaking) {
      return _buildStatusWidget(
        isGenerating: isGenerating,
        isSpeaking: isSpeaking,
      );
    }

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: PromptBar(
        key: promptBarKey,
        onPromptWithPhoto: onPromptWithPhoto,
        onPromptTextOnly: onPromptTextOnly,
        disabled: disabled,
        speechEnabled: speechEnabled,
        listening: listening,
        onToggleListening: onToggleListening,
        onStopTts: onStopTts,
      ),
    );
  }

  /// Visual status indicator during AI processing with accessibility announcements
  static Widget _buildStatusWidget({
    required bool isGenerating,
    required bool isSpeaking,
  }) {
    return Container(
      height: 80,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.orange.shade400, Colors.deepOrange.shade500],
        ),
      ),
      child: Semantics(
        label: isGenerating
            ? (isSpeaking
                  ? 'Generating response and speaking'
                  : 'Generating response')
            : 'Speaking response',
        hint: 'Please wait while the AI processes your request',
        child: Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                isGenerating
                    ? (isSpeaking
                          ? 'Generating and Speaking…'
                          : 'Generating Response…')
                    : 'Speaking…',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Loading screen shown during app initialization
  static Widget buildLoadingScreen() {
    return const Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(color: Color(0xFF2196F3)),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(
                  strokeWidth: 4,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(height: 24),
              Text(
                'Initializing Gemma…',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
