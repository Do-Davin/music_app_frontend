import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TokenStorageService {
  static const accessTokenKey = 'access_token';
  static const refreshTokenKey = 'refresh_token';

  const TokenStorageService({
    FlutterSecureStorage storage = const FlutterSecureStorage(),
  }) : _storage = storage;

  final FlutterSecureStorage _storage;

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    try {
      await _storage.write(key: accessTokenKey, value: accessToken);
      await _storage.write(key: refreshTokenKey, value: refreshToken);
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(accessTokenKey);
      await prefs.remove(refreshTokenKey);
    } on MissingPluginException {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(accessTokenKey, accessToken);
      await prefs.setString(refreshTokenKey, refreshToken);
    }
  }

  Future<String?> readAccessToken() async {
    try {
      return await _storage.read(key: accessTokenKey);
    } on MissingPluginException {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(accessTokenKey);
    }
  }

  Future<String?> readRefreshToken() async {
    try {
      return await _storage.read(key: refreshTokenKey);
    } on MissingPluginException {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(refreshTokenKey);
    }
  }

  Future<void> clearTokens() async {
    try {
      await _storage.delete(key: accessTokenKey);
      await _storage.delete(key: refreshTokenKey);
    } on MissingPluginException {
      // Fall through to shared preferences cleanup below.
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(accessTokenKey);
    await prefs.remove(refreshTokenKey);
  }
}
