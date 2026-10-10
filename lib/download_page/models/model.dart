// download_page/models/models.dart
import 'package:flutter_downloader/flutter_downloader.dart';


class AuthTokenData {
  final String accessToken;
  final String? refreshToken;
  final DateTime expiryTime;

  AuthTokenData({
    required this.accessToken,
    this.refreshToken,
    required this.expiryTime,
  });

  // Check if token has expired (compares with current time)
  bool get isExpired => DateTime.now().isAfter(expiryTime);

  Map<String, dynamic> toJson() => {
    'accessToken': accessToken,
    'refreshToken': refreshToken,
    'expiryTime': expiryTime.toIso8601String(),
  };

  factory AuthTokenData.fromJson(Map<String, dynamic> json) => AuthTokenData(
    accessToken: json['accessToken'],
    refreshToken: json['refreshToken'],
    expiryTime: DateTime.parse(json['expiryTime']),
  );
}

// Download progress data with percentage calculation
class DownloadProgress {
  final int totalBytes;
  final int downloadedBytes;
  final double downloadRate;
  final Duration remainingTime;
  final DownloadTaskStatus status;

  DownloadProgress({
    required this.totalBytes,
    required this.downloadedBytes,
    required this.downloadRate,
    required this.remainingTime,
    required this.status,
  });

 
  double get progress => totalBytes > 0 ? downloadedBytes / totalBytes : 0.0;


  int get progressPercent => (progress * 100).round();
}


class LogEntry {
  final DateTime timestamp;
  final String level;
  final String message;

  LogEntry({
    required this.timestamp,
    required this.level,
    required this.message,
  });


  String get formattedTime =>
      '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}';

  @override
  String toString() => '[$formattedTime] [$level] $message';
}
