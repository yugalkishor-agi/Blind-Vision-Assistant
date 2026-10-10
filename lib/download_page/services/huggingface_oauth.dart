import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:http/http.dart' as http;
import '../config/constants.dart';
import '../models/models.dart';
import 'logger.dart';

class HuggingFaceOAuth {
  static String _generateCodeVerifier() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64UrlEncode(bytes).replaceAll('=', '');
  }

  static String _generateCodeChallenge(String verifier) {
    final bytes = utf8.encode(verifier);
    final digest = sha256.convert(bytes);
    return base64UrlEncode(digest.bytes).replaceAll('=', '');
  }

  static Future<HuggingFaceToken?> authenticate() async {
    try {
      final verifier = _generateCodeVerifier();
      final challenge = _generateCodeChallenge(verifier);
      final state = base64UrlEncode(List<int>.generate(16, (_) => Random.secure().nextInt(256)));

      final authUri = Uri.parse(authEndpoint).replace(queryParameters: {
        'client_id': hfClientId,
        'redirect_uri': hfRedirectUri,
        'scope': scope,
        'response_type': 'code',
        'code_challenge': challenge,
        'code_challenge_method': 'S256',
        'state': state,
      });

      final result = await FlutterWebAuth2.authenticate(
        url: authUri.toString(),
        callbackUrlScheme: 'com.hackathon.blind_vision_assistant',
      );

      final code = Uri.parse(result).queryParameters['code'];
      if (code == null) return null;

      final response = await http.post(Uri.parse(tokenEndpoint), body: {
        'client_id': hfClientId,
        'code': code,
        'code_verifier': verifier,
        'grant_type': 'authorization_code',
        'redirect_uri': hfRedirectUri,
      });

      if (response.statusCode == 200) {
        return HuggingFaceToken.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      AppLogger.error('OAuth failed', e);
      return null;
    }
  }
}
