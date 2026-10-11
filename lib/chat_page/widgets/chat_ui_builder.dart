// lib/chat_page/widgets/chat_ui_builder.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/message_models.dart';
import 'chat_bubble.dart';
import 'prompt_bar.dart';
import 'semantic_material_button.dart';

// ─── Design tokens (mirrors main.dart / modern_ui_widgets) ───────────────────
class _C {
  static const bg        = Color(0xFF0A0A14);
  static const surface   = Color(0xFF12121E);
  static const surface2  = Color(0xFF1A1A2E);
  static const border    = Color(0xFF2D2D3F);
  static const violet    = Color(0xFF7C3AED);
  static const cyan      = Color(0xFF06B6D4);
  static const pink      = Color(0xFFEC4899);
  static const green     = Color(0xFF10B981);
  static const amber     = Color(0xFFF59E0B);
  static const textHi    = Color(0xFFF1F5F9);
  static const textMid   = Color(0xFF94A3B8);
  static const textLo    = Color(0xFF475569);
}
// ─────────────────────────────────────────────────────────────────────────────

/// Static UI builder for chat interface components with accessibility integration
class ChatUIBuilder {

  // ── App bar ────────────────────────────────────────────────────────────────
  static PreferredSizeWidget buildCleanAppBar({
    required VoidCallback onNewChat,
    required VoidCallback onToggleSettings,
    required bool isResetting,
  }) {
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: _C.bg,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Logo glyph
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_C.violet, _C.cyan],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(Icons.visibility_rounded, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 10),
          const Text(
            'Gemma Vision',
            style: TextStyle(
              color: _C.textHi,
              fontSize: 19,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
            ),
          ),
        ],
      ),
      actions: [
        // Settings button
        SemanticMaterialButton(
          label: 'Settings',
          hint: 'Double-tap to open settings page',
          onPressed: onToggleSettings,
          child: Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: _C.surface2,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _C.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.tune_rounded, size: 15, color: _C.textMid),
                SizedBox(width: 5),
                Text(
                  'Settings',
                  style: TextStyle(
                    color: _C.textMid,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: _C.border),
      ),
    );
  }

  // ── View toggle buttons ────────────────────────────────────────────────────
  static Widget buildViewToggleButtons({
    required bool showMessages,
    required VoidCallback onToggleMessages,
    required VoidCallback onNewChat,
    required bool isResetting,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: FocusTraversalGroup(
        policy: WidgetOrderTraversalPolicy(),
        child: Row(
          children: [
            Expanded(
              child: _buildToggleButton(
                icon: Icons.add_circle_outline_rounded,
                label: 'New Chat',
                hint: isResetting
                    ? 'New chat is currently processing'
                    : 'Double-tap to start a new chat conversation',
                isActive: true,
                primaryColor: _C.green,
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
                primaryColor: _C.violet,
                onPressed: onToggleMessages,
                disabled: false,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildToggleButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required Color primaryColor,
    required VoidCallback? onPressed,
    required String hint,
    bool disabled = false,
  }) {
    Color bgColor;
    Color fgColor;

    if (disabled) {
      bgColor = _C.surface2;
      fgColor = _C.textLo;
    } else if (isActive) {
      bgColor = primaryColor;
      fgColor = Colors.white;
    } else {
      bgColor = _C.surface;
      fgColor = primaryColor;
    }

    return SemanticMaterialButton(
      label: label,
      hint: hint,
      onPressed: disabled ? null : onPressed,
      disabled: disabled,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        height: 48,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isActive && !disabled ? primaryColor.withOpacity(0.4) : _C.border,
          ),
          boxShadow: isActive && !disabled
              ? [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: fgColor, size: 17),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                color: fgColor,
                fontWeight: FontWeight.w600,
                fontSize: 13,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Messages list ──────────────────────────────────────────────────────────
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
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          itemCount: messages.length,
          semanticChildCount: messages.length,
          itemBuilder: (_, i) => Semantics(
            label: messages[i].isUser
                ? 'Your message ${i + 1} of ${messages.length}'
                : 'AI response ${i + 1} of ${messages.length}',
            child: ChatBubble(msg: messages[i]),
          ),
        ),
      ),
    );
  }

  // ── Prompt bar container ───────────────────────────────────────────────────
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
    if (isGenerating || isSpeaking) {
      return _buildStatusWidget(isGenerating: isGenerating, isSpeaking: isSpeaking);
    }

    return Container(
      decoration: const BoxDecoration(
        color: _C.bg,
        border: Border(top: BorderSide(color: _C.border)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
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

  // ── Status widget (generating / speaking) ─────────────────────────────────
  static Widget _buildStatusWidget({
    required bool isGenerating,
    required bool isSpeaking,
  }) {
    final label = isGenerating
        ? (isSpeaking ? 'Generating response and speaking' : 'Generating response')
        : 'Speaking response';

    final displayText = isGenerating
        ? (isSpeaking ? 'Generating & Speaking…' : 'Generating Response…')
        : 'Speaking…';

    return Container(
      height: 76,
      width: double.infinity,
      decoration: BoxDecoration(
        color: _C.bg,
        border: const Border(top: BorderSide(color: _C.border)),
      ),
      child: Semantics(
        label: label,
        hint: 'Please wait while the AI processes your request',
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_C.violet.withOpacity(0.18), _C.cyan.withOpacity(0.12)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _C.violet.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              // Animated dots indicator
              _ThinkingDots(),
              const SizedBox(width: 14),
              Text(
                displayText,
                style: const TextStyle(
                  color: _C.textHi,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Loading screen ─────────────────────────────────────────────────────────
  static Widget buildLoadingScreen() {
    return Scaffold(
      backgroundColor: _C.bg,
      body: Stack(
        children: [
          // Ambient glow
          Positioned(
            top: -100,
            left: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [_C.violet.withOpacity(0.2), Colors.transparent],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            right: -60,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [_C.cyan.withOpacity(0.15), Colors.transparent],
                ),
              ),
            ),
          ),
          const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                _LoadingLogo(),
                SizedBox(height: 36),
                Text(
                  'Initializing Gemma',
                  style: TextStyle(
                    fontSize: 22,
                    color: _C.textHi,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Preparing your AI vision assistant…',
                  style: TextStyle(
                    fontSize: 14,
                    color: _C.textMid,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Internal animated helpers ────────────────────────────────────────────────

/// Three animated dots for the generating indicator
class _ThinkingDots extends StatefulWidget {
  @override
  State<_ThinkingDots> createState() => _ThinkingDotsState();
}

class _ThinkingDotsState extends State<_ThinkingDots> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(duration: const Duration(milliseconds: 1200), vsync: this)..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) {
            final phase = ((_ctrl.value * 3 - i).clamp(0.0, 1.0));
            final scale = 0.6 + 0.4 * (1.0 - (phase - 0.5).abs() * 2).clamp(0.0, 1.0);
            final opacity = 0.3 + 0.7 * (1.0 - (phase - 0.5).abs() * 2).clamp(0.0, 1.0);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              child: Transform.scale(
                scale: scale,
                child: Opacity(
                  opacity: opacity,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF7C3AED),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}

/// Animated logo for loading screen
class _LoadingLogo extends StatefulWidget {
  const _LoadingLogo();

  @override
  State<_LoadingLogo> createState() => _LoadingLogoState();
}

class _LoadingLogoState extends State<_LoadingLogo> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(duration: const Duration(milliseconds: 1800), vsync: this)..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, child) => Transform.scale(scale: _pulse.value, child: child),
      child: Container(
        width: 88,
        height: 88,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFF7C3AED), Color(0xFF06B6D4)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7C3AED).withOpacity(0.5),
              blurRadius: 40,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: const Icon(Icons.visibility_rounded, color: Colors.white, size: 40),
      ),
    );
  }
}
