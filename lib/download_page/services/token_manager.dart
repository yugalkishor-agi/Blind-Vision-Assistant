import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart';
import '../models/models.dart';
import 'logger.dart';

class TokenManager {
  static Future<void> saveToken(HuggingFaceToken token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(authTokenKey, token.accessToken);
      AppLogger.log('Token saved successfully');
    } catch (e) {
      AppLogger.error('Failed to save token', e);
    }
  }

  static Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(authTokenKey);
    } catch (e) {
      AppLogger.error('Failed to get token', e);
      return null;
    }
  }

  static Future<void> clearToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(authTokenKey);
      AppLogger.log('Token cleared');
    } catch (e) {
      AppLogger.error('Failed to clear token', e);
    }
  }

  static Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
