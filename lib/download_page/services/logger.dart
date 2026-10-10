// download_page/services/logger.dart

import 'dart:async';
import '../models/models.dart';

class Logger {
  static final List<LogEntry> _logs = [];

  /// Broadcast stream for real-time log updates across the app
  static final StreamController<LogEntry> _logController =
      StreamController<LogEntry>.broadcast();

  static Stream<LogEntry> get logStream => _logController.stream;
  static List<LogEntry> get logs => List.unmodifiable(_logs);

  static void info(String message) => _log('INFO', message);
  static void error(String message) => _log('ERROR', message);
  static void debug(String message) => _log('DEBUG', message);
  static void warning(String message) => _log('WARN', message);

  /// Core logging function that handles storage and streaming
  static void _log(String level, String message) {
    final entry = LogEntry(
      timestamp: DateTime.now(),
      level: level,
      message: message,
    );
    _logs.add(entry);
    _logController.add(entry); // Notify UI listeners
    print('[$level] $message'); // Also print to console
  }

  /// Formats all logs as a single string for copying/sharing
  static String getAllLogsAsString() {
    return _logs.map((log) => log.toString()).join('\n');
  }

  static void clear() {
    _logs.clear();
  }
}
