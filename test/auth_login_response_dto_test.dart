import 'package:flutter_test/flutter_test.dart';
import 'package:hehe/dtos/common/auth/auth_login_response_dto.dart';

void main() {
  group('AuthLoginResponseDto', () {
    test(
      'does not assume an incomplete response belongs to an existing user',
      () {
        final response = AuthLoginResponseDto.fromJson(const {});

        expect(response.exists, isFalse);
        expect(response.hasSession, isFalse);
      },
    );

    test('infers an existing user when a complete session is returned', () {
      final response = AuthLoginResponseDto.fromJson({
        'accessToken': 'access',
        'refreshToken': 'refresh',
        'user': {'userId': 1, 'nickname': 'tester'},
      });

      expect(response.exists, isTrue);
      expect(response.hasSession, isTrue);
    });

    test('honors an explicit exists value', () {
      final response = AuthLoginResponseDto.fromJson(const {'exists': false});

      expect(response.exists, isFalse);
    });
  });
}
