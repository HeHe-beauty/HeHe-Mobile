import 'package:flutter/services.dart';

class NaverAuthResult {
  final String? accessToken;
  final String? errorCode;
  final String? errorMessage;
  final bool cancelled;

  const NaverAuthResult({
    this.accessToken,
    this.errorCode,
    this.errorMessage,
    this.cancelled = false,
  });

  bool get isSuccess => accessToken != null && accessToken!.isNotEmpty;

  factory NaverAuthResult.fromMap(Map<Object?, Object?> map) {
    return NaverAuthResult(
      accessToken: map['accessToken'] as String?,
      errorCode: map['errorCode'] as String?,
      errorMessage: map['errorMessage'] as String?,
      cancelled: map['cancelled'] as bool? ?? false,
    );
  }
}

class NaverAuthChannel {
  const NaverAuthChannel._();

  static const MethodChannel _channel = MethodChannel(
    'kr.hehehe.hehe/naver_auth',
  );

  static Future<bool> initialize({
    required String clientId,
    required String clientSecret,
    required String clientName,
  }) async {
    final initialized = await _channel.invokeMethod<bool>('initialize', {
      'clientId': clientId,
      'clientSecret': clientSecret,
      'clientName': clientName,
    });
    return initialized ?? false;
  }

  static Future<NaverAuthResult> login() async {
    try {
      final response = await _channel.invokeMapMethod<Object?, Object?>(
        'login',
      );
      if (response == null) {
        return const NaverAuthResult(errorCode: 'empty_native_response');
      }
      return NaverAuthResult.fromMap(response);
    } on PlatformException catch (error) {
      return NaverAuthResult(
        errorCode: error.code,
        errorMessage: error.message,
      );
    }
  }
}
