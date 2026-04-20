import 'dart:convert';
import 'package:http/http.dart' as http;

import 'api_config.dart';

class ApiClient {
  final http.Client _client;

  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    final uri = ApiConfig.uri(path, queryParameters);

    final response = await _client.get(
      uri,
      headers: {'Content-Type': 'application/json', ...?headers},
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('GET 요청 실패: ${response.statusCode}');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    final uri = ApiConfig.uri(path);

    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json', ...?headers},
      body: body == null ? null : jsonEncode(body),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('POST 요청 실패: ${response.statusCode}');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> patch(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    final uri = ApiConfig.uri(path);

    final response = await _client.patch(
      uri,
      headers: {'Content-Type': 'application/json', ...?headers},
      body: body == null ? null : jsonEncode(body),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('PATCH 요청 실패: ${response.statusCode}');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> delete(
    String path, {
    Map<String, String>? headers,
  }) async {
    final uri = ApiConfig.uri(path);

    final response = await _client.delete(
      uri,
      headers: {'Content-Type': 'application/json', ...?headers},
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('DELETE 요청 실패: ${response.statusCode}');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
