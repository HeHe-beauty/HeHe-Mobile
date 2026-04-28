import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

import '../auth/auth_session_store.dart';
import '../auth/auth_state.dart';
import 'api_config.dart';
import 'api_endpoints.dart';

class ApiException implements Exception {
  final int statusCode;
  final String method;

  const ApiException({required this.statusCode, required this.method});

  @override
  String toString() => '$method 요청 실패: $statusCode';
}

class ApiClient {
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
    required Map<String, String>? headers,
    required Future<http.Response> Function(Map<String, String>? headers) send,
  }) async {
    final response = await send(headers);
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
    final retriedResponse = await send(retriedHeaders);
    return _decodeJsonResponse(retriedResponse, method: method);
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
      AuthState.logOut();
      throw const ApiException(statusCode: 401, method: 'POST');
    }

    final response = await _client.post(
      ApiConfig.uri(ApiEndpoints.authTokenRefresh),
      headers: _jsonHeaders(null),
      body: _encodeJsonBody({'refreshToken': savedSession.refreshToken}),
    );

    if (response.statusCode == 401 || response.statusCode == 403) {
      await AuthSessionStore.clear();
      AuthState.logOut();
      throw ApiException(statusCode: response.statusCode, method: 'POST');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(statusCode: response.statusCode, method: 'POST');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final data = body['data'] as Map<String, dynamic>;
    final nextAccessToken = data['accessToken'] as String;
    final nextRefreshToken =
        data['refreshToken'] as String? ?? savedSession.refreshToken;

    final refreshedSession = savedSession.copyWith(
      accessToken: nextAccessToken,
      refreshToken: nextRefreshToken,
    );

    await AuthSessionStore.write(refreshedSession);
    AuthState.restore(refreshedSession);
    debugPrint('🔥 access token refreshed and request will retry');

    return nextAccessToken;
  }

  Map<String, dynamic> _decodeJsonResponse(
    http.Response response, {
    required String method,
  }) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(statusCode: response.statusCode, method: method);
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
