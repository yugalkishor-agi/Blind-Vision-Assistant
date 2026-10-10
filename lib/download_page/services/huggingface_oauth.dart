// download_page/services/huggingface_oauth.dart

import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart';
import '../models/models.dart';
import 'logger.dart';

/// OAuth 2.0 + PKCE for HuggingFace (PKCE = security for mobile apps without client secrets)
class HuggingFaceOAuth {
  /// Generate random 32-byte string for PKCE code_verifier (like a temporary password)
  static String _generateCodeVerifier() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64Url.encode(bytes).replaceAll('=', ''); // URL-safe base64
  }

  /// Hash the code_verifier with SHA256 for code_challenge (public version)
  static String _generateCodeChallenge(String verifier) {
    final bytes = utf8.encode(verifier);
    final digest = sha256.convert(bytes);
    return base64Url.encode(digest.bytes).replaceAll('=', '');
  }

  /// Build OAuth URL with PKCE params - user visits this to authorize our app
  static Future<String> generateAuthUrl() async {
    final codeVerifier = _generateCodeVerifier();
    final codeChallenge = _generateCodeChallenge(codeVerifier);

    Logger.debug('Generated OAuth code verifier and challenge');

    // Store verifier locally - need it later to prove we started this OAuth flow
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(codeVerifierKey, codeVerifier);

    // Standard OAuth params + PKCE challenge
    final params = {
      'client_id': hfClientId,
      'redirect_uri': hfRedirectUri,
      'response_type': 'code', // Want auth code, not direct tokens
      'scope': scope,
      'code_challenge': codeChallenge, // Hash of our secret verifier
      'code_challenge_method': 'S256', // SHA256 hashing method
    };

    // URL-encode params safely (handles spaces, special chars)
    final query = params.entries
        .map(
          (e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}',
        )
        .join('&');

    final authUrl = '$authEndpoint?$query';
    Logger.info('Generated OAuth URL');
    return authUrl;
  }

  /// Exchange auth code from redirect for actual access tokens
  static Future<AuthTokenData?> exchangeCodeForToken(String code) async {
    final prefs = await SharedPreferences.getInstance();
    // Get the verifier we stored earlier - proves we started this flow
    final codeVerifier = prefs.getString(codeVerifierKey);

    if (codeVerifier == null) {
      Logger.error('Code verifier not found');
      return null;
    }

    try {
      Logger.info('Exchanging authorization code for access token');

      // POST to token endpoint with auth code + PKCE verifier
      final response = await http.post(
        Uri.parse(tokenEndpoint),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'client_id': hfClientId,
          'code': code, // Auth code from HuggingFace redirect
          'redirect_uri': hfRedirectUri,
          'grant_type': 'authorization_code',
          'code_verifier':
              codeVerifier, // Original secret - proves our identity
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Calculate token expiry time (default 1hr if not specified)
        final expiryTime = DateTime.now().add(
          Duration(seconds: data['expires_in'] ?? 3600),
        );

        final tokenData = AuthTokenData(
          accessToken: data['access_token'], // Bearer token for API calls
          refreshToken: data['refresh_token'], // For getting new access tokens
          expiryTime: expiryTime,
        );

        // Store tokens persistently, cleanup temp verifier
        await prefs.setString(authTokenKey, json.encode(tokenData.toJson()));
        await prefs.remove(codeVerifierKey);

        Logger.info('Successfully obtained access token');
        return tokenData;
      } else {
        Logger.error(
          'Token exchange failed with status ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      Logger.error('Token exchange error: $e');
    }
    return null;
  }
}
