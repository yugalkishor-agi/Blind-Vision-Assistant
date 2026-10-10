class ChatMessage {
  String text;
  final bool isUser;
  bool isStreaming;
  MessageStats? stats;
  final String? imagePath;

  ChatMessage._({
    required this.text,
    required this.isUser,
    this.isStreaming = false,
    this.stats,
    this.imagePath,
  });

  factory ChatMessage.text(String text, {required bool isUser, bool isStreaming = false}) {
    return ChatMessage._(text: text, isUser: isUser, isStreaming: isStreaming);
  }

  factory ChatMessage.withImageFile(String text, {required bool isUser, dynamic imageFile}) {
    return ChatMessage._(
      text: text,
      isUser: isUser,
      imagePath: imageFile?.path,
    );
  }
}

class MessageStats {
  final double? timeToFirstToken;
  final double totalLatency;
  final int tokenCount;
  final double? prefillSpeed;
  final double? decodeSpeed;

  MessageStats({
    this.timeToFirstToken,
    required this.totalLatency,
    required this.tokenCount,
    this.prefillSpeed,
    this.decodeSpeed,
  });
}
