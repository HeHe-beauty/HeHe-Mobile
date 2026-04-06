import 'package:flutter/material.dart';
import '../../screens/login_required_screen.dart';
import 'auth_prompt.dart';
import 'auth_state.dart';

typedef AuthenticatedAction = Future<void> Function();

class AuthGate {
  const AuthGate._();

  static Future<void> _openLoginRequiredScreen(
    BuildContext context, {
    String? title,
    String? description,
  }) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            LoginRequiredScreen(title: title, description: description),
      ),
    );
  }

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

    await _openLoginRequiredScreen(
      context,
      title: title,
      description: description,
    );

    if (!AuthState.isLoggedIn.value) {
      return;
    }

    await onAuthenticated();
  }

  static Future<void> runWithPrompt(
    BuildContext context, {
    required AuthPrompt prompt,
    required AuthenticatedAction onAuthenticated,
  }) {
    return run(
      context,
      title: prompt.title,
      description: prompt.description,
      onAuthenticated: onAuthenticated,
    );
  }

  static Future<bool> ensureLoggedIn(
    BuildContext context, {
    String? title,
    String? description,
  }) async {
    if (AuthState.isLoggedIn.value) {
      return true;
    }

    await _openLoginRequiredScreen(
      context,
      title: title,
      description: description,
    );

    return AuthState.isLoggedIn.value;
  }

  static Future<bool> ensureLoggedInWithPrompt(
    BuildContext context, {
    required AuthPrompt prompt,
  }) {
    return ensureLoggedIn(
      context,
      title: prompt.title,
      description: prompt.description,
    );
  }
}
