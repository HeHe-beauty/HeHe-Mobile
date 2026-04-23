import 'dart:convert';
import 'package:http/http.dart' as http;

import 'api_config.dart';

class ApiClient {
  final http.Client _client;

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

    final response = await _client.get(uri, headers: _jsonHeaders(headers));
    return _decodeJsonResponse(response, method: 'GET');
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    final uri = ApiConfig.uri(path);

    final response = await _client.post(
      uri,
      headers: _jsonHeaders(headers),
      body: _encodeJsonBody(body),
    );
    return _decodeJsonResponse(response, method: 'POST');
  }

  Future<Map<String, dynamic>> patch(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    final uri = ApiConfig.uri(path);

    final response = await _client.patch(
      uri,
      headers: _jsonHeaders(headers),
      body: _encodeJsonBody(body),
    );
    return _decodeJsonResponse(response, method: 'PATCH');
  }

  Future<Map<String, dynamic>> delete(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    final uri = ApiConfig.uri(path);

    final response = await _client.delete(
      uri,
      headers: _jsonHeaders(headers),
      body: _encodeJsonBody(body),
    );
    return _decodeJsonResponse(response, method: 'DELETE');
  }

  String? _encodeJsonBody(Map<String, dynamic>? body) {
    return body == null ? null : jsonEncode(body);
  }

  Map<String, dynamic> _decodeJsonResponse(
    http.Response response, {
    required String method,
  }) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('$method 요청 실패: ${response.statusCode}');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
