// lib/chat_page/widgets/chat_bubble.dart
// ── BRUTALIST EDITORIAL DESIGN ──────────────────────────────────────────────

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import '../models/message_models.dart';

const _cream   = Color(0xFFF5F0E8);
const _ink     = Color(0xFF1A1A1A);
const _inkSoft = Color(0xFF3A3530);
const _inkMute = Color(0xFF888070);
const _accent  = Color(0xFFE8441A);
const _paper   = Color(0xFFEDE8DF);
const _borderW = 2.0;

/// Brutalist editorial chat bubble — thick borders, offset shadows, bold type
class ChatBubble extends StatelessWidget {
  final ChatMessage msg;
  const ChatBubble({Key? key, required this.msg}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (msg.imageFile != null && msg.text.isNotEmpty) {
      return Column(
        crossAxisAlignment: msg.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          _buildImageBubble(context),
          const SizedBox(height: 4),
          _buildTextBubble(context),
        ],
      );
    }
    if (msg.imageFile != null) return _buildImageBubble(context);
    return _buildTextBubble(context);
  }

  // ── Image bubble ────────────────────────────────────────────────────────────
  Widget _buildImageBubble(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: msg.isUser ? 60.0 : 0,
        right: msg.isUser ? 0 : 60.0,
        top: 4, bottom: 4,
      ),
      child: Align(
        alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.72,
            maxHeight: MediaQuery.of(context).size.height * 0.38,
          ),
          decoration: BoxDecoration(
            border: Border.all(color: _ink, width: _borderW),
            boxShadow: const [BoxShadow(color: _ink, offset: Offset(4, 4), blurRadius: 0)],
          ),
          child: GestureDetector(
            onTap: () => _showFullScreenImage(context, msg.imageFile!),
            child: Hero(
              tag: 'image_${msg.text}_${msg.imageFile!.path}',
              child: Image.file(
                msg.imageFile!,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 160, width: double.infinity,
                    color: _paper,
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.broken_image_rounded, size: 36, color: _inkMute),
                        SizedBox(height: 8),
                        Text('Could not load image', style: TextStyle(color: _inkMute, fontSize: 12, fontFamily: 'monospace')),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Text bubble ─────────────────────────────────────────────────────────────
  Widget _buildTextBubble(BuildContext context) {
    final isUser = msg.isUser;

    // User: accent-filled  |  AI: cream with thick border
    final bg     = isUser ? _accent : _cream;
    final fg     = isUser ? _cream  : _ink;
    final border = isUser
        ? Border.all(color: _ink, width: _borderW)
        : Border.all(color: _ink, width: _borderW);
    final shadow = const [BoxShadow(color: _ink, offset: Offset(3, 3), blurRadius: 0)];

    return Padding(
      padding: EdgeInsets.only(
        left:   isUser ? 56.0 : 0,
        right:  isUser ? 0 : 56.0,
        top:    5, bottom: 5,
      ),
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.82,
          ),
          decoration: BoxDecoration(
            color: bg,
            border: border,
            boxShadow: shadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Sender label strip
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: isUser ? _ink : _paper,
                  border: Border(bottom: BorderSide(color: _ink, width: 1.5)),
                ),
                child: Text(
                  isUser ? 'YOU' : 'GEMMA',
                  style: TextStyle(
                    fontSize: 9, fontWeight: FontWeight.w900,
                    color: isUser ? _accent : _inkMute,
                    letterSpacing: 1.8, fontFamily: 'monospace',
                  ),
                ),
              ),

              // Message content
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (msg.text.isNotEmpty) _buildContent(context, fg),

                    // Stats
                    if (msg.stats != null && !msg.isStreaming && msg.text.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: _buildStats(msg.stats!, isUser),
                      ),

                    // Streaming dots
                    if (msg.isStreaming)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: _TypingIndicator(fg: fg),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, Color fg) {
    return GptMarkdown(
      msg.text,
      style: TextStyle(
        color: fg, fontSize: 15,
        fontWeight: FontWeight.w500, height: 1.5,
      ),
    );
  }

  Widget _buildStats(MessageStats stats, bool isUser) {
    final fg = isUser ? _cream.withAlpha(180) : _inkMute;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isUser ? Colors.black.withAlpha(40) : _paper,
        border: Border.all(color: isUser ? _cream.withAlpha(60) : _ink, width: 1),
      ),
      child: Text(
        '${stats.tokenCount} tok  •  ${stats.totalLatency!.toStringAsFixed(1)}s'
        '${stats.timeToFirstToken != null ? '  •  TTFT ${stats.timeToFirstToken!.toStringAsFixed(1)}s' : ''}'
        '${stats.decodeSpeed != null ? '  •  ${stats.decodeSpeed!.toStringAsFixed(1)} t/s' : ''}',
        style: TextStyle(
          color: fg, fontSize: 10,
          fontFamily: 'monospace', fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _showFullScreenImage(BuildContext context, File imageFile) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: _cream,
          appBar: AppBar(
            backgroundColor: _cream,
            elevation: 0,
            iconTheme: const IconThemeData(color: _ink),
            title: const Text('PHOTO', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: _ink, letterSpacing: 2, fontFamily: 'monospace')),
            bottom: PreferredSize(preferredSize: const Size.fromHeight(2), child: Container(height: 2, color: _ink)),
          ),
          body: Center(
            child: Hero(
              tag: 'image_${msg.text}_${imageFile.path}',
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.file(
                  imageFile,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.broken_image_rounded, size: 56, color: _inkMute),
                      SizedBox(height: 12),
                      Text('Could not load image', style: TextStyle(color: _inkMute, fontFamily: 'monospace')),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Three square blinking dots for streaming indicator
class _TypingIndicator extends StatefulWidget {
  final Color fg;
  const _TypingIndicator({required this.fg});
  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}
class _TypingIndicatorState extends State<_TypingIndicator> with SingleTickerProviderStateMixin {
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
              width: 7, height: 7,
              margin: const EdgeInsets.only(right: 4),
              color: lit ? widget.fg : widget.fg.withAlpha(60),
            );
          },
        );
      }),
    );
  }
}
