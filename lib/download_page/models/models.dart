import 'enums.dart';

class DownloadState {
  final DownloadStatus status;
  final int progress;
  final String? taskId;
  final String? errorMessage;

  const DownloadState({
    this.status = DownloadStatus.notStarted,
    this.progress = 0,
    this.taskId,
    this.errorMessage,
  });

  DownloadState copyWith({
    DownloadStatus? status,
    int? progress,
    String? taskId,
    String? errorMessage,
  }) {
    return DownloadState(
      status: status ?? this.status,
      progress: progress ?? this.progress,
      taskId: taskId ?? this.taskId,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class HuggingFaceToken {
  final String accessToken;
  final String tokenType;

  const HuggingFaceToken({required this.accessToken, required this.tokenType});

  factory HuggingFaceToken.fromJson(Map<String, dynamic> json) {
    return HuggingFaceToken(
      accessToken: json['access_token'] as String,
      tokenType: json['token_type'] as String? ?? 'Bearer',
    );
  }
}
