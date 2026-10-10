// lib/chat_page/widgets/chat_bubble.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import '../models/message_models.dart';

/// Chat message bubble with support for text, images, markdown rendering, and performance stats
/// Handles different message types: text-only, image-only, or combined image+text messages
class ChatBubble extends StatelessWidget {
  final ChatMessage msg;

  const ChatBubble({Key? key, required this.msg}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Combined image+text messages: show as connected bubbles
    if (msg.imageFile != null && msg.text.isNotEmpty) {
      return Column(
        crossAxisAlignment: msg.isUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          _buildImageBubble(context),
          const SizedBox(height: 2), // Tight spacing to feel connected
          _buildTextBubble(context),
        ],
      );
    }

    // Image-only message
    if (msg.imageFile != null) {
      return _buildImageBubble(context);
    }

    // Text-only message (most common case)
    return _buildTextBubble(context);
  }

  /// Image bubble with tap-to-expand and error handling
  Widget _buildImageBubble(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: msg.isUser ? 60.0 : 8.0,
        right: msg.isUser ? 8.0 : 60.0,
        top: 2.0,
        bottom: 2.0,
      ),
      child: Align(
        alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.7,
            maxHeight: MediaQuery.of(context).size.height * 0.4,
          ),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(18)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: GestureDetector(
              onTap: () => _showFullScreenImage(context, msg.imageFile!),
              child: Hero(
                tag: 'image_${msg.text}_${msg.imageFile!.path}',
                child: Image.file(
                  msg.imageFile!,
                  fit: BoxFit.contain,
                  // Graceful error handling for corrupted/missing images
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      width: double.infinity,
                      color: Colors.grey.shade200,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Could not load image',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
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

  /// Text bubble with markdown support, streaming indicator, and performance stats
  Widget _buildTextBubble(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: msg.isUser ? 60.0 : 8.0,
        right: msg.isUser ? 8.0 : 60.0,
        top: 4.0,
        bottom: 4.0,
      ),
      child: Align(
        alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.7,
          ),
          decoration: BoxDecoration(
            // User messages: blue, AI messages: light gray
            color: msg.isUser ? Colors.blueAccent : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 14.0,
              vertical: 10.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (msg.text.isNotEmpty) _buildMessageContent(context),

                // Performance stats for completed AI responses
                if (msg.stats != null &&
                    !msg.isStreaming &&
                    msg.text.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6.0),
                    child: _buildStatsWidget(msg.stats!),
                  ),

                // Streaming indicator for messages being generated
                if (msg.isStreaming)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          msg.isUser ? Colors.white : Colors.blueAccent,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Render message content with markdown support for AI responses
  Widget _buildMessageContent(BuildContext context) {
    // GptMarkdown handles AI responses with markdown formatting, LaTeX, code blocks
    // User messages use simple text since they typically don't contain markdown
    return GptMarkdown(
      msg.text,
      style: TextStyle(
        color: msg.isUser ? Colors.white : Colors.black87,
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 1.3, // Line height for readability
      ),
    );
  }

  /// Full-screen image viewer with pinch-to-zoom
  void _showFullScreenImage(BuildContext context, File imageFile) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
            title: const Text('Image', style: TextStyle(color: Colors.white)),
          ),
          body: Center(
            child: Hero(
              tag: 'image_${msg.text}_${imageFile.path}',
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 3.0, // Allow 3x zoom
                child: Image.file(
                  imageFile,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Could not load image',
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
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

  /// Performance statistics widget showing AI response metrics
  Widget _buildStatsWidget(MessageStats stats) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 10,
            color: msg.isUser ? Colors.white70 : Colors.black54,
          ),
          const SizedBox(width: 3),
          // Core metrics: token count and total time
          Text(
            '${stats.tokenCount} tokens • ${stats.totalLatency!.toStringAsFixed(1)}s',
            style: TextStyle(
              color: msg.isUser ? Colors.white70 : Colors.black54,
              fontSize: 10,
              fontWeight: FontWeight.w400,
            ),
          ),
          // Time to first token (latency metric)
          if (stats.timeToFirstToken != null) ...[
            Text(
              ' • TTFT ${stats.timeToFirstToken!.toStringAsFixed(1)}s',
              style: TextStyle(
                color: msg.isUser ? Colors.white70 : Colors.black54,
                fontSize: 10,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
          // Generation speed (tokens per second)
          if (stats.decodeSpeed != null) ...[
            Text(
              ' • ${stats.decodeSpeed!.toStringAsFixed(1)} tok/s',
              style: TextStyle(
                color: msg.isUser ? Colors.white70 : Colors.black54,
                fontSize: 10,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
