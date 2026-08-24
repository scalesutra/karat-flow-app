import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure token manager using FlutterSecureStorage for encrypted storage on device
class TokenStorageService {
  TokenStorageService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(
                encryptedSharedPreferences: true,
              ),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock,
              ),
            );

  final FlutterSecureStorage _storage;

  static const String _keyAccessToken = 'karatflow_access_token';
  static const String _keyRefreshToken = 'karatflow_refresh_token';
  static const String _keyUserRole = 'karatflow_user_role';

  // ── Access Token ──────────────────────────────────────────────────
  Future<void> saveAccessToken(String token) async {
    await _storage.write(key: _keyAccessToken, value: token);
  }

  Future<String?> getAccessToken() async {
    return _storage.read(key: _keyAccessToken);
  }

  Future<bool> hasAccessToken() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  // ── Refresh Token ─────────────────────────────────────────────────
  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: _keyRefreshToken, value: token);
  }

  Future<String?> getRefreshToken() async {
    return _storage.read(key: _keyRefreshToken);
  }

  // ── User Active Role ──────────────────────────────────────────────
  Future<void> saveUserRole(String role) async {
    await _storage.write(key: _keyUserRole, value: role);
  }

  Future<String?> getUserRole() async {
    return _storage.read(key: _keyUserRole);
  }

  // ── Clear Session (Logout) ────────────────────────────────────────
  Future<void> clearAll() async {
    await _storage.delete(key: _keyAccessToken);
    await _storage.delete(key: _keyRefreshToken);
    await _storage.delete(key: _keyUserRole);
  }
}
