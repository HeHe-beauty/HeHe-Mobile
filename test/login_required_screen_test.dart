import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hehe/screens/login_required_screen.dart';
import 'package:hehe/theme/app_theme.dart';

void main() {
  testWidgets('만 14세 이상 확인 전에는 소셜 로그인을 차단한다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const LoginRequiredScreen(),
      ),
    );

    expect(find.text('만 14세 이상입니다 (필수)'), findsOneWidget);

    final kakaoButton = find.byKey(const ValueKey('kakao-login-button'));
    final naverButton = find.byKey(const ValueKey('naver-login-button'));

    expect(
      tester
          .widget<InkWell>(
            find.descendant(of: kakaoButton, matching: find.byType(InkWell)),
          )
          .onTap,
      isNull,
    );
    expect(
      tester
          .widget<InkWell>(
            find.descendant(of: naverButton, matching: find.byType(InkWell)),
          )
          .onTap,
      isNull,
    );

    await tester.tap(find.text('만 14세 이상입니다 (필수)'));
    await tester.pump();

    expect(
      tester
          .widget<CheckboxListTile>(
            find.byKey(const ValueKey('age-confirmation-checkbox')),
          )
          .value,
      isTrue,
    );
    expect(
      tester
          .widget<InkWell>(
            find.descendant(of: kakaoButton, matching: find.byType(InkWell)),
          )
          .onTap,
      isNotNull,
    );
    expect(
      tester
          .widget<InkWell>(
            find.descendant(of: naverButton, matching: find.byType(InkWell)),
          )
          .onTap,
      isNotNull,
    );
  });
}
