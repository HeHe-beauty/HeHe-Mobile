import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../auth/auth_session_store.dart';
import '../auth/auth_state.dart';
import '../logging/app_log.dart';
import 'api_config.dart';
import 'api_endpoints.dart';

class ApiException implements Exception {
  final int statusCode;
  final String method;
  final String? code;
  final String? serverMessage;

  const ApiException({
    required this.statusCode,
    required this.method,
    this.code,
    this.serverMessage,
  });

  bool get indicatesMissingUser {
    if (statusCode == 404) return true;
    final normalized = '${code ?? ''} ${serverMessage ?? ''}'.toLowerCase();
    return normalized.contains('user_not_found') ||
        normalized.contains('user not found') ||
        normalized.contains('가입된') ||
        normalized.contains('찾을 수 없');
  }

  @override
  String toString() {
    final detail = code == null ? '' : ' ($code)';
    return '$method 요청 실패: $statusCode$detail';
  }
}

class ApiConnectionException implements Exception {
  final String method;

  const ApiConnectionException(this.method);

  @override
  String toString() => '$method 요청 중 네트워크 연결 시간이 초과되었습니다.';
}

class ApiClient {
  static const Duration _requestTimeout = Duration(seconds: 20);
  final http.Client _client;
  static Future<String>? _refreshInFlight;

  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  static Map<String, String> bearerHeaders(String accessToken) {
    return {'Authorization': 'Bearer $accessToken'};
  }

  static Map<String, String> _jsonHeaders(Map<String, String>? headers) {
    return {'Content-Type': 'application/json', ...?headers};
  }

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    final uri = ApiConfig.uri(path, queryParameters);

    return _sendWithAuthRetry(
      path: path,
      method: 'GET',
      uri: uri,
      headers: headers,
      send: (requestHeaders) =>
          _client.get(uri, headers: _jsonHeaders(requestHeaders)),
    );
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    final uri = ApiConfig.uri(path);

    return _sendWithAuthRetry(
      path: path,
      method: 'POST',
      uri: uri,
      headers: headers,
      send: (requestHeaders) => _client.post(
        uri,
        headers: _jsonHeaders(requestHeaders),
        body: _encodeJsonBody(body),
      ),
    );
  }

  Future<Map<String, dynamic>> patch(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    final uri = ApiConfig.uri(path);

    return _sendWithAuthRetry(
      path: path,
      method: 'PATCH',
      uri: uri,
      headers: headers,
      send: (requestHeaders) => _client.patch(
        uri,
        headers: _jsonHeaders(requestHeaders),
        body: _encodeJsonBody(body),
      ),
    );
  }

  Future<Map<String, dynamic>> delete(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    final uri = ApiConfig.uri(path);

    return _sendWithAuthRetry(
      path: path,
      method: 'DELETE',
      uri: uri,
      headers: headers,
      send: (requestHeaders) => _client.delete(
        uri,
        headers: _jsonHeaders(requestHeaders),
        body: _encodeJsonBody(body),
      ),
    );
  }

  String? _encodeJsonBody(Map<String, dynamic>? body) {
    return body == null ? null : jsonEncode(body);
  }

  Future<Map<String, dynamic>> _sendWithAuthRetry({
    required String path,
    required String method,
    required Uri uri,
    required Map<String, String>? headers,
    required Future<http.Response> Function(Map<String, String>? headers) send,
  }) async {
    final response = await _sendWithTimeout(method, () => send(headers));
    if (!_shouldRetryWithRefresh(
      path: path,
      response: response,
      headers: headers,
    )) {
      return _decodeJsonResponse(response, method: method);
    }

    final refreshedAccessToken = await _refreshAccessToken();
    final retriedHeaders = {
      ...?headers,
      'Authorization': 'Bearer $refreshedAccessToken',
    };
    AppLog.debug(
      '[ApiClient] retrying $method ${uri.path} after token refresh',
    );
    final retriedResponse = await _sendWithTimeout(
      method,
      () => send(retriedHeaders),
    );
    return _decodeJsonResponse(retriedResponse, method: method);
  }

  Future<http.Response> _sendWithTimeout(
    String method,
    Future<http.Response> Function() send,
  ) async {
    try {
      return await send().timeout(_requestTimeout);
    } on TimeoutException {
      throw ApiConnectionException(method);
    }
  }

  bool _shouldRetryWithRefresh({
    required String path,
    required http.Response response,
    required Map<String, String>? headers,
  }) {
    if (response.statusCode != 401) return false;
    if (path == ApiEndpoints.authTokenRefresh) return false;

    final authorization = headers?['Authorization'];
    if (authorization == null || authorization.isEmpty) return false;

    return true;
  }

  Future<String> _refreshAccessToken() {
    final inFlight = _refreshInFlight;
    if (inFlight != null) return inFlight;

    final future = _performRefreshAccessToken();
    _refreshInFlight = future;

    return future.whenComplete(() {
      if (identical(_refreshInFlight, future)) {
        _refreshInFlight = null;
      }
    });
  }

  Future<String> _performRefreshAccessToken() async {
    final savedSession = await AuthSessionStore.read();
    if (savedSession == null) {
      AppLog.debug('[ApiClient][Auth] refresh skipped: no saved session');
      AuthState.logOut();
      throw const ApiException(statusCode: 401, method: 'POST');
    }

    final uri = ApiConfig.uri(ApiEndpoints.authTokenRefresh);
    AppLog.debug('[ApiClient][Auth] refresh request');
    final response = await _sendWithTimeout(
      'POST',
      () => _client.post(
        uri,
        headers: _jsonHeaders(null),
        body: _encodeJsonBody({'refreshToken': savedSession.refreshToken}),
      ),
    );

    if (response.statusCode == 401 || response.statusCode == 403) {
      await AuthSessionStore.clear();
      AuthState.logOut();
      AppLog.debug('[ApiClient][Auth] refresh failed and session cleared');
      throw _apiExceptionFromResponse(response, method: 'POST');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _apiExceptionFromResponse(response, method: 'POST');
    }

    final body = _decodeJsonObject(response.body);
    final data = requireDataMap(body);
    final nextAccessToken = data['accessToken'] as String?;
    if (nextAccessToken == null || nextAccessToken.isEmpty) {
      throw const FormatException('토큰 갱신 응답에 accessToken이 없습니다.');
    }
    final nextRefreshToken =
        data['refreshToken'] as String? ?? savedSession.refreshToken;

    final refreshedSession = savedSession.copyWith(
      accessToken: nextAccessToken,
      refreshToken: nextRefreshToken,
    );

    await AuthSessionStore.write(refreshedSession);
    AuthState.restore(refreshedSession);
    AppLog.debug('[ApiClient][Auth] access token refreshed');

    return nextAccessToken;
  }

  Map<String, dynamic> _decodeJsonResponse(
    http.Response response, {
    required String method,
  }) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _apiExceptionFromResponse(response, method: method);
    }

    if (response.body.trim().isEmpty) return <String, dynamic>{};
    return _decodeJsonObject(response.body);
  }

  static Map<String, dynamic> requireDataMap(Map<String, dynamic> body) {
    return requireJsonMap(body['data'], fieldName: 'data');
  }

  static List<dynamic> requireDataList(Map<String, dynamic> body) {
    final data = body['data'];
    if (data is List<dynamic>) return data;
    throw const FormatException('API 응답의 data 형식이 올바르지 않습니다.');
  }

  static Map<String, dynamic> requireJsonMap(
    Object? value, {
    String fieldName = '항목',
  }) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    throw FormatException('API 응답의 $fieldName 형식이 올바르지 않습니다.');
  }

  static void requireSuccess(
    Map<String, dynamic> body, {
    required String failureMessage,
  }) {
    // 204 No Content is also a successful mutation response.
    if (body.isEmpty || body['success'] == true) return;
    throw FormatException(failureMessage);
  }

  static Map<String, dynamic> _decodeJsonObject(String source) {
    final decoded = jsonDecode(source);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
    throw const FormatException('API 응답이 JSON 객체가 아닙니다.');
  }

  static ApiException _apiExceptionFromResponse(
    http.Response response, {
    required String method,
  }) {
    String? code;
    String? message;

    try {
      final body = _decodeJsonObject(response.body);
      final nestedError = body['error'];
      final error = nestedError is Map
          ? Map<String, dynamic>.from(nestedError)
          : body;
      code = _stringValue(error['code']) ?? _stringValue(body['code']);
      message =
          _stringValue(error['message']) ??
          _stringValue(error['description']) ??
          _stringValue(body['message']);
    } on FormatException {
      // HTML 오류 페이지나 빈 응답 본문은 상태 코드만 보존한다.
    }

    return ApiException(
      statusCode: response.statusCode,
      method: method,
      code: code,
      serverMessage: message,
    );
  }

  static String? _stringValue(Object? value) {
    if (value is! String || value.trim().isEmpty) return null;
    return value.trim();
  }
}
