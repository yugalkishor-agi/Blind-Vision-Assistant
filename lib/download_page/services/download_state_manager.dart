// download_page/services/download_state_manager.dart

import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart';
import 'logger.dart';

/// Persists download state for crash recovery (survives app restarts/kills)
class DownloadStateManager {
  /// Save download as in-progress with task ID for recovery
  static Future<void> saveDownloadInProgress(String taskId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(downloadStateKey, 'in_progress');
    await prefs.setString(downloadTaskIdKey, taskId);
    Logger.info('Saved download state: in_progress with task ID: $taskId');
  }

  /// Mark download as completed and clean up task ID
  static Future<void> saveDownloadCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(downloadStateKey, 'completed');
    await prefs.remove(downloadTaskIdKey); // Don't need task ID anymore
    Logger.info('Saved download state: completed');
  }

  /// Reset download state (fresh start or after cancellation)
  static Future<void> clearDownloadState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(downloadStateKey);
    await prefs.remove(downloadTaskIdKey);
    Logger.info('Cleared download state');
  }

  static Future<String?> getDownloadState() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(downloadStateKey);
  }

  static Future<String?> getDownloadTaskId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(downloadTaskIdKey);
  }
}
