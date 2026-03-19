import 'package:flutter/foundation.dart';

class AuthState {
  static final ValueNotifier<bool> isLoggedIn = ValueNotifier(false);

  static void logIn() {
    isLoggedIn.value = true;
  }

  static void logOut() {
    isLoggedIn.value = false;
  }
}