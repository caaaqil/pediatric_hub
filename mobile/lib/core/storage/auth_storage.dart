import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Token vault + cached user record.
///
/// Tokens live in `flutter_secure_storage` (Keystore / Keychain); the non-secret
/// user payload lives in `shared_preferences` so the splash screen can restore a
/// session without a round-trip.
class AuthStorage {
  AuthStorage({FlutterSecureStorage? secureStorage})
    : _secure = secureStorage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _secure;

  static const String _kAccessToken = 'phh_access_token';
  static const String _kRefreshToken = 'phh_refresh_token';
  static const String _kUserJson = 'phh_user_json';

  Future<String?> readAccessToken() => _secure.read(key: _kAccessToken);

  Future<String?> readRefreshToken() => _secure.read(key: _kRefreshToken);

  Future<void> writeAccessToken(String token) =>
      _secure.write(key: _kAccessToken, value: token);

  Future<void> writeRefreshToken(String? token) async {
    if (token == null || token.isEmpty) {
      await _secure.delete(key: _kRefreshToken);
      return;
    }
    await _secure.write(key: _kRefreshToken, value: token);
  }

  Future<void> writeUser(Map<String, dynamic> user) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kUserJson, jsonEncode(user));
  }

  Future<Map<String, dynamic>?> readUser() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_kUserJson);
    if (raw == null || raw.isEmpty) return null;
    try {
      final dynamic decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } on FormatException {
      // Corrupted cache — treat as "no session".
    }
    return null;
  }

  Future<void> clear() async {
    await _secure.delete(key: _kAccessToken);
    await _secure.delete(key: _kRefreshToken);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kUserJson);
  }
}
