import 'package:flutter_test/flutter_test.dart';
import 'package:hehe/core/auth/naver_auth_channel.dart';

void main() {
  test('NaverAuthResult parses native login failures without raw tokens', () {
    final result = NaverAuthResult.fromMap(const {
      'errorCode': 'invalid_request',
      'errorMessage': 'No categorized error',
      'cancelled': false,
    });

    expect(result.isSuccess, isFalse);
    expect(result.errorCode, 'invalid_request');
    expect(result.cancelled, isFalse);
  });
}
