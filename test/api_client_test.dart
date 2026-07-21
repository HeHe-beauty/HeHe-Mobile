import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hehe/core/network/api_client.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('ApiClient', () {
    test('accepts an empty successful response body', () async {
      final api = ApiClient(
        client: MockClient((_) async => http.Response('', 204)),
      );

      final response = await api.delete('/api/v1/test');

      expect(response, isEmpty);
    });

    test('preserves safe server error metadata', () async {
      final api = ApiClient(
        client: MockClient(
          (_) async => http.Response(
            jsonEncode({
              'error': {'code': 'USER_NOT_FOUND', 'message': 'user not found'},
            }),
            404,
          ),
        ),
      );

      await expectLater(
        api.post('/api/v1/auth/login'),
        throwsA(
          isA<ApiException>()
              .having((error) => error.statusCode, 'statusCode', 404)
              .having((error) => error.code, 'code', 'USER_NOT_FOUND')
              .having(
                (error) => error.indicatesMissingUser,
                'indicatesMissingUser',
                isTrue,
              ),
        ),
      );
    });

    test('requires a map-shaped data field', () {
      expect(
        () => ApiClient.requireDataMap({'data': <Object>[]}),
        throwsFormatException,
      );
    });

    test('requires a list-shaped data field', () {
      expect(
        () => ApiClient.requireDataList({'data': <String, Object>{}}),
        throwsFormatException,
      );
    });

    test('accepts an empty mutation envelope as success', () {
      expect(
        () => ApiClient.requireSuccess(const {}, failureMessage: 'failed'),
        returnsNormally,
      );
    });
  });
}
