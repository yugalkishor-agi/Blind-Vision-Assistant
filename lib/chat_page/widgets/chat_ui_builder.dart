// lib/chat_page/widgets/chat_ui_builder.dart
// ── BRUTALIST EDITORIAL DESIGN ──────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/message_models.dart';
import 'chat_bubble.dart';
import 'prompt_bar.dart';
import 'semantic_material_button.dart';

// ─── Tokens ─────────────────────────────────────────────────────────────────
const _cream  = Color(0xFFF5F0E8);
const _ink    = Color(0xFF1A1A1A);
const _inkSoft= Color(0xFF3A3530);
const _inkMute= Color(0xFF888070);
const _accent = Color(0xFFE8441A);
const _paper  = Color(0xFFEDE8DF);
const _borderW= 2.0;
// ─────────────────────────────────────────────────────────────────────────────

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
      backgroundColor: _cream,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      titleSpacing: 24,
      title: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'BLIND VISION',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: _ink, letterSpacing: 2.0),
          ),
          Text(
            'ASSISTANT',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: _accent, letterSpacing: 2.0),
          ),
        ],
      ),
      actions: [
        SemanticMaterialButton(
          label: 'Settings',
          hint: 'Double-tap to open settings page',
          onPressed: onToggleSettings,
          child: Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: _cream,
              border: Border.all(color: _ink, width: _borderW),
              boxShadow: const [BoxShadow(color: _ink, offset: Offset(2, 2), blurRadius: 0)],
            ),
            child: const Text(
              'SETTINGS',
              style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.w900,
                color: _ink, letterSpacing: 1.5, fontFamily: 'monospace',
              ),
            ),
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(2),
        child: Container(height: 2, color: _ink),
      ),
    );
  }

  // ── Toggle buttons ─────────────────────────────────────────────────────────
  static Widget buildViewToggleButtons({
    required bool showMessages,
    required VoidCallback onToggleMessages,
    required VoidCallback onNewChat,
    required bool isResetting,
  }) {
    return Container(
      decoration: const BoxDecoration(
        color: _cream,
        border: Border(bottom: BorderSide(color: _ink, width: _borderW)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: FocusTraversalGroup(
        policy: WidgetOrderTraversalPolicy(),
        child: Row(
          children: [
            Expanded(
              child: _buildToggleBtn(
                label: 'NEW CHAT',
                isActive: false,
                useAccent: false,
                hint: isResetting ? 'Processing…' : 'Double-tap to start a new chat',
                onPressed: isResetting ? null : onNewChat,
                disabled: isResetting,
                icon: Icons.add_rounded,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildToggleBtn(
                label: showMessages ? 'HIDE MSGS' : 'SHOW MSGS',
                isActive: showMessages,
                useAccent: showMessages,
                hint: showMessages ? 'Double-tap to hide messages' : 'Double-tap to show messages',
                onPressed: onToggleMessages,
                disabled: false,
                icon: showMessages ? Icons.chat_bubble_rounded : Icons.chat_bubble_outline_rounded,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildToggleBtn({
    required String label,
    required bool isActive,
    required bool useAccent,
    required VoidCallback? onPressed,
    required String hint,
    required IconData icon,
    bool disabled = false,
  }) {
    final bg = disabled ? const Color(0xFFD8D3CA)
        : useAccent ? _accent
        : _cream;
    final fg = disabled ? _inkMute
        : useAccent ? _cream
        : _ink;

    return SemanticMaterialButton(
      label: label,
      hint: hint,
      onPressed: disabled ? null : onPressed,
      disabled: disabled,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 42,
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: disabled ? const Color(0xFFB0AB9E) : _ink, width: _borderW),
          boxShadow: !disabled && !useAccent
              ? const [BoxShadow(color: _ink, offset: Offset(2, 2), blurRadius: 0)]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: fg, size: 14),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: fg, fontSize: 10,
                fontWeight: FontWeight.w900, letterSpacing: 1.2,
                fontFamily: 'monospace',
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
      child: ColoredBox(
        color: _cream,
        child: Semantics(
          label: 'Chat messages',
          hint: 'Swipe to scroll through conversation history',
          child: ListView.builder(
            controller: scrollController,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
    Future<void> Function(String)? onPromptWithAgent, // NEW — agent mode button
  }) {
    if (isGenerating || isSpeaking) {
      return _buildStatusWidget(isGenerating: isGenerating, isSpeaking: isSpeaking);
    }

    return Container(
      color: _cream,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: PromptBar(
        key: promptBarKey,
        onPromptWithPhoto: onPromptWithPhoto,
        onPromptTextOnly: onPromptTextOnly,
        onPromptWithAgent: onPromptWithAgent,
        disabled: disabled,
        speechEnabled: speechEnabled,
        listening: listening,
        onToggleListening: onToggleListening,
        onStopTts: onStopTts,
      ),
    );
  }

  // ── Generating / speaking status bar ──────────────────────────────────────
  static Widget _buildStatusWidget({
    required bool isGenerating,
    required bool isSpeaking,
  }) {
    final label = isGenerating
        ? (isSpeaking ? 'Generating response and speaking' : 'Generating response')
        : 'Speaking response';
    final text = isGenerating
        ? (isSpeaking ? 'GENERATING + SPEAKING…' : 'GENERATING…')
        : 'SPEAKING…';

    return Container(
      height: 70,
      decoration: const BoxDecoration(
        color: _accent,
        border: Border(top: BorderSide(color: _ink, width: _borderW)),
      ),
      child: Semantics(
        label: label,
        hint: 'Please wait while the AI processes your request',
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              _ThinkingDots(),
              const SizedBox(width: 14),
              Text(
                text,
                style: const TextStyle(
                  color: _cream, fontWeight: FontWeight.w900,
                  fontSize: 13, letterSpacing: 1.5, fontFamily: 'monospace',
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
    return const Scaffold(
      backgroundColor: _cream,
      body: _LoadingBody(),
    );
  }
}

// ─── Internal widgets ─────────────────────────────────────────────────────────

class _LoadingBody extends StatefulWidget {
  const _LoadingBody();
  @override
  State<_LoadingBody> createState() => _LoadingBodyState();
}
class _LoadingBodyState extends State<_LoadingBody> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _blink;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(duration: const Duration(milliseconds: 800), vsync: this)..repeat(reverse: true);
    _blink = Tween<double>(begin: 0.2, end: 1.0).animate(_ctrl);
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Top bar
        Container(
          height: 56,
          decoration: const BoxDecoration(
            color: _cream,
            border: Border(bottom: BorderSide(color: _ink, width: 2)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: const Align(
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('BLIND VISION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: _ink, letterSpacing: 2)),
                Text('ASSISTANT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: _accent, letterSpacing: 2)),
              ],
            ),
          ),
        ),
        const Expanded(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'INITIALIZING —',
                    style: TextStyle(
                      fontFamily: 'monospace', fontSize: 11,
                      color: _accent, fontWeight: FontWeight.w700, letterSpacing: 1.0,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Loading\nGemma.',
                    style: TextStyle(
                      fontSize: 48, fontWeight: FontWeight.w900,
                      color: _ink, height: 0.95, letterSpacing: -2,
                    ),
                  ),
                  SizedBox(height: 16),
                  _LoadingBar(),
                  SizedBox(height: 16),
                  Text(
                    'Preparing your AI vision assistant.\nThis takes a moment.',
                    style: TextStyle(
                      fontSize: 13, fontFamily: 'monospace',
                      color: _inkSoft, height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LoadingBar extends StatefulWidget {
  const _LoadingBar();
  @override
  State<_LoadingBar> createState() => _LoadingBarState();
}
class _LoadingBarState extends State<_LoadingBar> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(duration: const Duration(seconds: 2), vsync: this)..repeat();
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 12,
      width: double.infinity,
      decoration: BoxDecoration(
        color: _paper,
        border: Border.all(color: _ink, width: 2),
      ),
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) {
          return FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: _ctrl.value,
            child: Container(color: _accent),
          );
        },
      ),
    );
  }
}

class _ThinkingDots extends StatefulWidget {
  @override
  State<_ThinkingDots> createState() => _ThinkingDotsState();
}
class _ThinkingDotsState extends State<_ThinkingDots> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(duration: const Duration(milliseconds: 900), vsync: this)..repeat();
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) {
            final t = ((_ctrl.value * 3) - i).clamp(0.0, 1.0);
            final lit = (1.0 - (t - 0.5).abs() * 2).clamp(0.0, 1.0) > 0.3;
            return Container(
              width: 8, height: 8,
              margin: const EdgeInsets.only(right: 4),
              color: lit ? _cream : _cream.withAlpha(80),
            );
          },
        );
      }),
    );
  }
}
