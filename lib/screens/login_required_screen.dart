import 'package:flutter/material.dart';
import '../core/auth/auth_state.dart';
import '../theme/app_palette.dart';

class LoginRequiredScreen extends StatelessWidget {
  final String? title;
  final String? description;

  const LoginRequiredScreen({super.key, this.title, this.description});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;

    return Scaffold(
      backgroundColor: palette.bg,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(
              onTapBack: () {
                Navigator.pop(context);
              },
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height - 120,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        const SizedBox(height: 28),
                        _HeroSection(
                          theme: theme,
                          title: title ?? '로그인이 필요해요',
                          description:
                              description ??
                              '찜한 병원, 문의 내역, 내 캘린더 기능은\n로그인 후 이용할 수 있어요.',
                        ),
                        const SizedBox(height: 36),
                        _LoginCard(
                          onTapKakao: () {
                            AuthState.logIn();

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('테스트 로그인 완료')),
                            );

                            Future.delayed(
                              const Duration(milliseconds: 200),
                              () {
                                if (context.mounted) {
                                  Navigator.pop(context);
                                }
                              },
                            );
                          },
                          onTapNaver: () {
                            AuthState.logIn();

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('테스트 로그인 완료')),
                            );

                            Future.delayed(
                              const Duration(milliseconds: 200),
                              () {
                                if (context.mounted) {
                                  Navigator.pop(context);
                                }
                              },
                            );
                          },
                        ),
                        const Spacer(),
                        const SizedBox(height: 28),
                        _BottomAgreementSection(
                          onTapPrivacy: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('개인정보처리방침 페이지 연결 예정'),
                              ),
                            );
                          },
                          onTapTerms: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('이용약관 페이지 연결 예정')),
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final VoidCallback onTapBack;

  const _TopBar({required this.onTapBack});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 20, 8),
      child: Row(
        children: [
          Material(
            color: palette.surface,
            borderRadius: BorderRadius.circular(14),
            elevation: 0.5,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: onTapBack,
              child: Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 18,
                  color: palette.icon,
                ),
              ),
            ),
          ),
          const Spacer(),
          Text(
            '로그인',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: palette.textPrimary,
              letterSpacing: -0.2,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 44),
        ],
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  final ThemeData theme;
  final String title;
  final String description;

  const _HeroSection({
    required this.theme,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Column(
      children: [
        Container(
          width: 92,
          height: 92,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              colors: [palette.primaryStrong, palette.primary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: palette.shadow,
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Icon(
            Icons.lock_outline_rounded,
            color: palette.surface,
            size: 38,
          ),
        ),
        const SizedBox(height: 22),
        Text(
          title,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: palette.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          description,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            height: 1.55,
            color: palette.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _LoginCard extends StatelessWidget {
  final VoidCallback onTapKakao;
  final VoidCallback onTapNaver;

  const _LoginCard({required this.onTapKakao, required this.onTapNaver});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: palette.shadow,
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 54,
            height: 5,
            decoration: BoxDecoration(
              color: palette.border,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 22),
          Text(
            '소셜 계정으로 계속하기',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '처음 로그인하는 경우 자동으로 가입이 진행돼요.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              height: 1.5,
              color: palette.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          _SocialLoginButton.kakao(onTap: onTapKakao),
          const SizedBox(height: 12),
          _SocialLoginButton.naver(onTap: onTapNaver),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: palette.surfaceSoft,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: palette.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: Icon(
                    Icons.info_outline_rounded,
                    size: 18,
                    color: palette.textSecondary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '로그인 시 서비스 이용약관 및 개인정보처리방침에 동의한 것으로 간주됩니다.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: palette.textSecondary,
                      height: 1.45,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomAgreementSection extends StatelessWidget {
  final VoidCallback onTapPrivacy;
  final VoidCallback onTapTerms;

  const _BottomAgreementSection({
    required this.onTapPrivacy,
    required this.onTapTerms,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: palette.textSecondary,
      fontWeight: FontWeight.w600,
    );

    return Column(
      children: [
        Text(
          '안전한 사용을 위해 꼭 확인해주세요',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: palette.textTertiary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          children: [
            GestureDetector(
              onTap: onTapPrivacy,
              child: Text('개인정보처리방침', style: style),
            ),
            Text(
              '·',
              style: TextStyle(
                color: palette.textTertiary,
                fontWeight: FontWeight.w700,
              ),
            ),
            GestureDetector(
              onTap: onTapTerms,
              child: Text('이용약관', style: style),
            ),
          ],
        ),
      ],
    );
  }
}

class _SocialLoginButton extends StatelessWidget {
  final VoidCallback onTap;
  final Color backgroundColor;
  final Color foregroundColor;
  final Widget leading;
  final String text;
  final Border? border;

  const _SocialLoginButton({
    required this.onTap,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.leading,
    required this.text,
    this.border,
  });

  factory _SocialLoginButton.kakao({required VoidCallback onTap}) {
    return _SocialLoginButton(
      onTap: onTap,
      backgroundColor: AppPalette.light.kakaoBackground,
      foregroundColor: AppPalette.light.kakaoForeground,
      text: '카카오로 계속하기',
      border: null,
      leading: const _KakaoMark(),
    );
  }

  factory _SocialLoginButton.naver({required VoidCallback onTap}) {
    return _SocialLoginButton(
      onTap: onTap,
      backgroundColor: AppPalette.light.naverBackground,
      foregroundColor: AppPalette.light.surface,
      text: '네이버로 계속하기',
      border: null,
      leading: const _NaverMark(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: border,
          ),
          child: Row(
            children: [
              leading,
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  text,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: foregroundColor,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              const SizedBox(width: 26),
            ],
          ),
        ),
      ),
    );
  }
}

class _KakaoMark extends StatelessWidget {
  const _KakaoMark();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: palette.kakaoForeground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.chat_bubble_rounded,
        size: 15,
        color: palette.kakaoBackground,
      ),
    );
  }
}

class _NaverMark extends StatelessWidget {
  const _NaverMark();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: palette.naverOverlay,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'N',
        style: TextStyle(
          color: palette.surface,
          fontSize: 15,
          fontWeight: FontWeight.w900,
          height: 1.0,
        ),
      ),
    );
  }
}
