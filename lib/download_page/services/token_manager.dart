// download_page/services/token_manager.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart';
import '../models/models.dart';
import '../models/enums.dart';
import 'logger.dart';

/// OAuth token persistence and validation for HuggingFace auth (like Google API tokens)
class TokenManager {
  /// Check token state: notStored/expired/valid - decides if we need to re-auth
  static Future<TokenStatus> getTokenStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final tokenString = prefs.getString(authTokenKey);

    if (tokenString == null) {
      Logger.debug('No stored token found');
      return TokenStatus.notStored;
    }

    try {
      // Deserialize stored JSON token and check expiry against current time
      final tokenData = AuthTokenData.fromJson(json.decode(tokenString));
      final status = tokenData.isExpired
          ? TokenStatus.expired
          : TokenStatus.valid;
      Logger.debug('Token status: $status');
      return status;
    } catch (e) {
      // Corrupted token data - treat as missing to trigger fresh auth
      Logger.error('Error reading stored token: $e');
      return TokenStatus.notStored;
    }
  }

  /// Get actual token object for API calls (contains accessToken, refreshToken, expiry)
  static Future<AuthTokenData?> getStoredToken() async {
    final prefs = await SharedPreferences.getInstance();
    final tokenString = prefs.getString(authTokenKey);

    if (tokenString == null) return null;

    try {
      return AuthTokenData.fromJson(json.decode(tokenString));
    } catch (e) {
      // Return null on parse error - triggers re-auth flow
      Logger.error('Error parsing stored token: $e');
      return null;
    }
  }

  /// Remove token from storage (logout/reset auth state)
  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(authTokenKey);
    Logger.info('Cleared stored token');
  }
}
