// lib/chat_page/services/remote_settings_manager.dart
//
// Persists remote model toggle + URL across app restarts.
// Used by main.dart to decide whether to skip the download page.

import 'package:shared_preferences/shared_preferences.dart';

const String _kUseRemoteKey = 'use_remote_model';
const String _kRemoteUrlKey = 'remote_model_url';

class RemoteSettingsManager {
  /// Save remote settings
  static Future<void> save({
    required bool useRemote,
    required String url,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kUseRemoteKey, useRemote);
    await prefs.setString(_kRemoteUrlKey, url);
  }

  /// Load remote settings — returns defaults if never saved
  static Future<({bool useRemote, String url})> load() async {
    final prefs = await SharedPreferences.getInstance();
    final useRemote = prefs.getBool(_kUseRemoteKey) ?? false;
    final url = prefs.getString(_kRemoteUrlKey) ?? '';
    return (useRemote: useRemote, url: url);
  }

  static Future<bool> isRemoteEnabled() async {
    final settings = await load();
    return settings.useRemote && settings.url.trim().isNotEmpty;
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kUseRemoteKey);
    await prefs.remove(_kRemoteUrlKey);
  }
}
