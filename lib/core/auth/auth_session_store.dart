import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'auth_state.dart';

class AuthSessionStore {
  static const _storage = FlutterSecureStorage();

  static const _accessTokenKey = 'auth.accessToken';
  static const _refreshTokenKey = 'auth.refreshToken';
  static const _userIdKey = 'auth.userId';
  static const _nicknameKey = 'auth.nickname';

  static Future<AuthSession?> read() async {
    final accessToken = await _storage.read(key: _accessTokenKey);
    final refreshToken = await _storage.read(key: _refreshTokenKey);
    final userIdValue = await _storage.read(key: _userIdKey);
    final nickname = await _storage.read(key: _nicknameKey);

    if (accessToken == null ||
        refreshToken == null ||
        userIdValue == null ||
        nickname == null) {
      return null;
    }

    final userId = int.tryParse(userIdValue);
    if (userId == null) {
      await clear();
      return null;
    }

    return AuthSession(
      accessToken: accessToken,
      refreshToken: refreshToken,
      userId: userId,
      nickname: nickname,
    );
  }

  static Future<void> write(AuthSession session) async {
    await _storage.write(key: _accessTokenKey, value: session.accessToken);
    await _storage.write(key: _refreshTokenKey, value: session.refreshToken);
    await _storage.write(key: _userIdKey, value: session.userId.toString());
    await _storage.write(key: _nicknameKey, value: session.nickname);
  }

  static Future<void> clear() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _userIdKey);
    await _storage.delete(key: _nicknameKey);
  }
}
