import 'package:flutter/foundation.dart';

class AuthSession {
  final String accessToken;
  final String refreshToken;
  final int userId;
  final String nickname;

  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.userId,
    required this.nickname,
  });

  AuthSession copyWith({
    String? accessToken,
    String? refreshToken,
    int? userId,
    String? nickname,
  }) {
    return AuthSession(
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      userId: userId ?? this.userId,
      nickname: nickname ?? this.nickname,
    );
  }
}

class AuthState {
  static final ValueNotifier<bool> isLoggedIn = ValueNotifier(false);
  static AuthSession? session;

  static void restore(AuthSession authSession) {
    session = authSession;
    isLoggedIn.value = true;
  }

  static void logIn({AuthSession? authSession}) {
    session = authSession;
    isLoggedIn.value = true;
  }

  static void logOut() {
    session = null;
    isLoggedIn.value = false;
  }
}
