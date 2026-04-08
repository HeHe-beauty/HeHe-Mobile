import 'dart:convert';
import 'package:http/http.dart' as http;

class ServerTimeApi {
  static Future<Map<String, dynamic>> fetchServerTime() async {
    final uri = Uri.parse('https://example.com/api/time');

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('서버 시간 조회 실패: ${response.statusCode}');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}