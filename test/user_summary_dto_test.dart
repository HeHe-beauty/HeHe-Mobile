import 'package:flutter_test/flutter_test.dart';
import 'package:hehe/dtos/common/user/user_summary_dto.dart';

void main() {
  group('UserSummaryDto.fromJson', () {
    test('parses a provided email', () {
      final summary = UserSummaryDto.fromJson({
        'email': 'tester@example.com',
        'bookmarkCount': 1,
        'contactCount': 2,
        'scheduleCount': 3,
      });

      expect(summary.email, 'tester@example.com');
    });

    test('keeps email null when it is unavailable', () {
      final summary = UserSummaryDto.fromJson({
        'email': null,
        'bookmarkCount': 1,
        'contactCount': 2,
        'scheduleCount': 3,
      });

      expect(summary.email, isNull);
    });
  });
}
