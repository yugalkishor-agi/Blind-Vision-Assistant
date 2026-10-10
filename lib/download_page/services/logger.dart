import 'package:flutter/foundation.dart';

class AppLogger {
  static void log(String message) {
    if (kDebugMode) debugPrint('[BlindVision] $message');
  }

  static void error(String message, [Object? error]) {
    if (kDebugMode) debugPrint('[BlindVision ERROR] $message${error != null ? ': $error' : ''}');
  }
}
