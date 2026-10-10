import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import '../models/message_models.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return Padding(
      padding: EdgeInsets.only(
        left: isUser ? 48 : 8,
        right: isUser ? 8 : 48,
        top: 4, bottom: 4,
      ),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (message.imagePath != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(File(message.imagePath!), height: 120, fit: BoxFit.cover),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isUser ? const Color(0xFF4A90D9) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
            ),
            child: message.isStreaming && message.text.isEmpty
                ? _StreamingDots()
                : Semantics(
                    label: message.text,
                    child: GptMarkdown(message.text),
                  ),
          ),
          if (message.stats != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                '${message.stats!.tokenCount} tokens · ${message.stats!.totalLatency.toStringAsFixed(1)}s',
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ),
        ],
      ),
    );
  }
}

class _StreamingDots extends StatefulWidget {
  @override
  State<_StreamingDots> createState() => _StreamingDotsState();
}

class _StreamingDotsState extends State<_StreamingDots> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat();
    _anim = Tween(begin: 0.3, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: const Text('●●●', style: TextStyle(color: Colors.grey, fontSize: 16)),
    );
  }
}
