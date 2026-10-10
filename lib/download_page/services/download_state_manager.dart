import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart';
import '../models/enums.dart';
import '../models/models.dart';
import 'logger.dart';

class DownloadStateManager {
  static Future<void> saveState(DownloadState state) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(downloadStateKey, state.status.name);
      if (state.taskId != null) await prefs.setString(downloadTaskIdKey, state.taskId!);
      AppLogger.log('Download state saved: ${state.status.name}');
    } catch (e) {
      AppLogger.error('Failed to save download state', e);
    }
  }

  static Future<DownloadState> loadState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final statusName = prefs.getString(downloadStateKey);
      final taskId = prefs.getString(downloadTaskIdKey);
      final status = DownloadStatus.values.firstWhere(
        (s) => s.name == statusName,
        orElse: () => DownloadStatus.notStarted,
      );
      return DownloadState(status: status, taskId: taskId);
    } catch (e) {
      AppLogger.error('Failed to load download state', e);
      return const DownloadState();
    }
  }

  static Future<void> clearState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(downloadStateKey);
      await prefs.remove(downloadTaskIdKey);
    } catch (e) {
      AppLogger.error('Failed to clear download state', e);
    }
  }
}
