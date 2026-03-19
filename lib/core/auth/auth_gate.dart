import 'package:flutter/material.dart';
import '../../screens/login_required_screen.dart';
import 'auth_state.dart';

typedef AuthenticatedAction = Future<void> Function();

class AuthGate {
  const AuthGate._();

  static Future<void> run(
      BuildContext context, {
        required AuthenticatedAction onAuthenticated,
        String? title,
        String? description,
      }) async {
    if (AuthState.isLoggedIn.value) {
      await onAuthenticated();
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LoginRequiredScreen(
          title: title,
          description: description,
        ),
      ),
    );

    if (!AuthState.isLoggedIn.value) {
      return;
    }

    await onAuthenticated();
  }

  static Future<bool> ensureLoggedIn(
      BuildContext context, {
        String? title,
        String? description,
      }) async {
    if (AuthState.isLoggedIn.value) {
      return true;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LoginRequiredScreen(
          title: title,
          description: description,
        ),
      ),
    );

    return AuthState.isLoggedIn.value;
  }
}