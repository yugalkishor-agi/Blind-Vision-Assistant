// models/message_models.dart
import 'dart:io';
import 'dart:typed_data';

/// Chat message with image support for vision AI
class ChatMessage {
  String text;
  final bool isUser;
  bool isStreaming;
  MessageStats? stats;
  File? imageFile; // Camera captured images
  Uint8List? imageBytes; // In-memory images

  ChatMessage(
    this.text, {
    required this.isUser,
    this.isStreaming = false,
    this.stats,
    this.imageFile,
    this.imageBytes,
  });

  /// Text-only message constructor
  ChatMessage.text(
    this.text, {
    required this.isUser,
    this.isStreaming = false,
    this.stats,
  }) : imageFile = null,
       imageBytes = null;

  /// Message with camera image file
  ChatMessage.withImageFile(
    this.text, {
    required this.isUser,
    required this.imageFile,
    this.isStreaming = false,
    this.stats,
  }) : imageBytes = null;

  /// Message with image data in memory
  ChatMessage.withImageBytes(
    this.text, {
    required this.isUser,
    required this.imageBytes,
    this.isStreaming = false,
    this.stats,
  }) : imageFile = null;

  bool get hasImage => imageFile != null || imageBytes != null;

  /// Convert image to bytes for API calls (handles both file and memory images)
  Future<Uint8List?> getImageBytes() async {
    if (imageBytes != null) return imageBytes;
    if (imageFile != null) return await imageFile!.readAsBytes();
    return null;
  }
}

/// AI response performance metrics
class MessageStats {
  final double? timeToFirstToken;
  final double? totalLatency;
  final double? prefillSpeed;
  final double? decodeSpeed;
  final int? tokenCount;

  const MessageStats({
    this.timeToFirstToken,
    this.totalLatency,
    this.prefillSpeed,
    this.decodeSpeed,
    this.tokenCount,
  });
}
