import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hehe/screens/login_required_screen.dart';
import 'package:hehe/theme/app_theme.dart';

void main() {
  testWidgets('로그인 단계에서는 소셜 로그인을 바로 시작할 수 있다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const LoginRequiredScreen(),
      ),
    );

    expect(find.text('만 14세 이상입니다 (필수)'), findsNothing);

    final kakaoButton = find.byKey(const ValueKey('kakao-login-button'));
    final naverButton = find.byKey(const ValueKey('naver-login-button'));

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

  testWidgets('가입 동의 단계에서는 알림과 14세 확인 상태에 따라 선택지를 제어한다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const LoginRequiredScreen(showSignupConsentPreview: true),
      ),
    );

    expect(find.text('회원가입 동의'), findsOneWidget);
    expect(find.text('알림 동의 (선택)'), findsOneWidget);
    expect(find.text('마케팅 수신 동의 (선택)'), findsOneWidget);
    expect(find.text('야간 푸시 동의 (선택)'), findsOneWidget);
    expect(find.text('만 14세 이상입니다 (필수)'), findsOneWidget);

    final submitButton = find.byKey(const ValueKey('signup-submit-button'));
    final marketingSwitch = find.byKey(
      const ValueKey('marketing-consent-switch'),
    );
    final nightPushSwitch = find.byKey(
      const ValueKey('night-push-consent-switch'),
    );

    expect(
      tester
          .widget<SwitchListTile>(
            find.descendant(
              of: marketingSwitch,
              matching: find.byType(SwitchListTile),
            ),
          )
          .onChanged,
      isNull,
    );
    expect(
      tester
          .widget<SwitchListTile>(
            find.descendant(
              of: nightPushSwitch,
              matching: find.byType(SwitchListTile),
            ),
          )
          .onChanged,
      isNull,
    );
    expect(
      tester
          .widget<InkWell>(
            find.descendant(of: submitButton, matching: find.byType(InkWell)),
          )
          .onTap,
      isNull,
    );

    await tester.tap(find.text('알림 동의 (선택)'));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<SwitchListTile>(
            find.descendant(
              of: marketingSwitch,
              matching: find.byType(SwitchListTile),
            ),
          )
          .onChanged,
      isNotNull,
    );
    expect(
      tester
          .widget<SwitchListTile>(
            find.descendant(
              of: nightPushSwitch,
              matching: find.byType(SwitchListTile),
            ),
          )
          .onChanged,
      isNotNull,
    );

    await tester.ensureVisible(find.text('만 14세 이상입니다 (필수)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('만 14세 이상입니다 (필수)'));
    await tester.pumpAndSettle();

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
            find.descendant(of: submitButton, matching: find.byType(InkWell)),
          )
          .onTap,
      isNotNull,
    );
  });
}
