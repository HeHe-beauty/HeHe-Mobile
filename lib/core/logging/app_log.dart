import 'package:flutter/foundation.dart';

class AppLog {
  const AppLog._();

  static void debug(String message, {Object? error, StackTrace? stackTrace}) {
    if (!kDebugMode) return;

    debugPrint(message);
    if (error != null) debugPrint('error: $error');
    if (stackTrace != null) debugPrintStack(stackTrace: stackTrace);
  }
}
