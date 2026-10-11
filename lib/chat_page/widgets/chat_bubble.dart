// lib/chat_page/widgets/chat_bubble.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import '../models/message_models.dart';

// ─── Design tokens ────────────────────────────────────────────────────────────
class _C {
  static const bg        = Color(0xFF0A0A14);
  static const surface   = Color(0xFF12121E);
  static const surface2  = Color(0xFF1A1A2E);
  static const border    = Color(0xFF2D2D3F);
  static const violet    = Color(0xFF7C3AED);
  static const cyan      = Color(0xFF06B6D4);
  static const pink      = Color(0xFFEC4899);
  static const textHi    = Color(0xFFF1F5F9);
  static const textMid   = Color(0xFF94A3B8);
  static const textLo    = Color(0xFF475569);
}
// ─────────────────────────────────────────────────────────────────────────────

/// Chat message bubble — glassmorphism dark style with beautiful typography
class ChatBubble extends StatelessWidget {
  final ChatMessage msg;
  const ChatBubble({Key? key, required this.msg}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Combined image + text
    if (msg.imageFile != null && msg.text.isNotEmpty) {
      return Column(
        crossAxisAlignment:
            msg.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          _buildImageBubble(context),
          const SizedBox(height: 3),
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
        left:   msg.isUser ? 64.0 : 12.0,
        right:  msg.isUser ? 12.0 : 64.0,
        top:    3.0,
        bottom: 3.0,
      ),
      child: Align(
        alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
            maxWidth:  MediaQuery.of(context).size.width * 0.72,
            maxHeight: MediaQuery.of(context).size.height * 0.38,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _C.border),
            boxShadow: [
              BoxShadow(
                color: _C.violet.withOpacity(0.15),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: GestureDetector(
              onTap: () => _showFullScreenImage(context, msg.imageFile!),
              child: Hero(
                tag: 'image_${msg.text}_${msg.imageFile!.path}',
                child: Image.file(
                  msg.imageFile!,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      width: double.infinity,
                      color: _C.surface,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.broken_image_rounded, size: 44, color: _C.textLo),
                          SizedBox(height: 8),
                          Text(
                            'Could not load image',
                            style: TextStyle(color: _C.textMid, fontSize: 13),
                          ),
                        ],
                      ),
                    );
                  },
                ),
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

    // User bubbles: violet → pink gradient glow
    // AI bubbles:   dark glass surface with subtle cyan border
    return Padding(
      padding: EdgeInsets.only(
        left:   isUser ? 64.0 : 12.0,
        right:  isUser ? 12.0 : 64.0,
        top:    5.0,
        bottom: 5.0,
      ),
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.78,
          ),
          decoration: isUser ? _userDecoration() : _aiDecoration(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Sender label (AI only)
                if (!isUser) ...[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: _C.cyan,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Gemma',
                        style: TextStyle(
                          color: _C.cyan,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                ],

                // Message content
                if (msg.text.isNotEmpty) _buildMessageContent(context),

                // Performance stats
                if (msg.stats != null && !msg.isStreaming && msg.text.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: _buildStatsWidget(msg.stats!),
                  ),

                // Streaming indicator
                if (msg.isStreaming)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: _StreamingDots(isUser: isUser),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  BoxDecoration _userDecoration() {
    return BoxDecoration(
      gradient: const LinearGradient(
        colors: [_C.violet, Color(0xFF5B21B6)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: const BorderRadius.only(
        topLeft:     Radius.circular(20),
        topRight:    Radius.circular(4),
        bottomLeft:  Radius.circular(20),
        bottomRight: Radius.circular(20),
      ),
      boxShadow: [
        BoxShadow(
          color: _C.violet.withOpacity(0.35),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }

  BoxDecoration _aiDecoration() {
    return BoxDecoration(
      color: _C.surface,
      borderRadius: const BorderRadius.only(
        topLeft:     Radius.circular(4),
        topRight:    Radius.circular(20),
        bottomLeft:  Radius.circular(20),
        bottomRight: Radius.circular(20),
      ),
      border: Border.all(color: _C.border),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.25),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  // ── Message content (markdown) ───────────────────────────────────────────────
  Widget _buildMessageContent(BuildContext context) {
    final textColor = msg.isUser ? _C.textHi : _C.textHi;
    return GptMarkdown(
      msg.text,
      style: TextStyle(
        color: textColor,
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 1.45,
      ),
    );
  }

  // ── Full-screen image viewer ─────────────────────────────────────────────────
  void _showFullScreenImage(BuildContext context, File imageFile) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: _C.bg,
          appBar: AppBar(
            backgroundColor: _C.bg,
            iconTheme: const IconThemeData(color: _C.textMid),
            title: const Text('Photo', style: TextStyle(color: _C.textHi, fontSize: 16, fontWeight: FontWeight.w600)),
            elevation: 0,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(height: 1, color: _C.border),
            ),
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
                  errorBuilder: (context, error, stackTrace) {
                    return const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.broken_image_rounded, size: 64, color: _C.textLo),
                        SizedBox(height: 16),
                        Text('Could not load image', style: TextStyle(color: _C.textMid, fontSize: 16)),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Stats widget ─────────────────────────────────────────────────────────────
  Widget _buildStatsWidget(MessageStats stats) {
    final chipColor = msg.isUser
        ? Colors.white.withOpacity(0.12)
        : _C.surface2;
    final textColor = msg.isUser ? Colors.white70 : _C.textLo;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: msg.isUser ? Colors.white.withOpacity(0.1) : _C.border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bolt_rounded, size: 10, color: textColor),
          const SizedBox(width: 3),
          Text(
            '${stats.tokenCount} tok • ${stats.totalLatency!.toStringAsFixed(1)}s',
            style: TextStyle(color: textColor, fontSize: 10, fontWeight: FontWeight.w500),
          ),
          if (stats.timeToFirstToken != null)
            Text(
              ' • TTFT ${stats.timeToFirstToken!.toStringAsFixed(1)}s',
              style: TextStyle(color: textColor, fontSize: 10),
            ),
          if (stats.decodeSpeed != null)
            Text(
              ' • ${stats.decodeSpeed!.toStringAsFixed(1)} t/s',
              style: TextStyle(color: textColor, fontSize: 10),
            ),
        ],
      ),
    );
  }
}

// ─── Internal widget ──────────────────────────────────────────────────────────

class _StreamingDots extends StatefulWidget {
  final bool isUser;
  const _StreamingDots({required this.isUser});

  @override
  State<_StreamingDots> createState() => _StreamingDotsState();
}

class _StreamingDotsState extends State<_StreamingDots> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(duration: const Duration(milliseconds: 1000), vsync: this)..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isUser ? Colors.white70 : _C.cyan;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) {
            final t = ((_ctrl.value * 3) - i).clamp(0.0, 1.0);
            final y = -3.0 * (1 - (t - 0.5).abs() * 2).clamp(0.0, 1.0);
            return Transform.translate(
              offset: Offset(0, y),
              child: Container(
                width: 5,
                height: 5,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            );
          },
        );
      }),
    );
  }
}
