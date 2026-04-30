import 'package:flutter/material.dart';
import '../core/auth/auth_session_store.dart';
import '../core/auth/auth_state.dart';
import '../core/auth/social_login_service.dart';
import '../core/notification/notification_permission_service.dart';
import '../data/auth/auth_repository.dart';
import '../theme/app_palette.dart';
import '../theme/app_text_styles.dart';
import '../utils/app_snackbar.dart';

class LoginRequiredScreen extends StatefulWidget {
  final String? title;
  final String? description;

  const LoginRequiredScreen({super.key, this.title, this.description});

  @override
  State<LoginRequiredScreen> createState() => _LoginRequiredScreenState();
}

class _LoginRequiredScreenState extends State<LoginRequiredScreen> {
  SocialLoginProvider? _loadingProvider;

  Future<void> _loginWithProvider(SocialLoginProvider provider) async {
    if (_loadingProvider != null) return;

    setState(() {
      _loadingProvider = provider;
    });

    try {
      final credential = switch (provider) {
        SocialLoginProvider.kakao => await SocialLoginService.loginWithKakao(),
        SocialLoginProvider.naver => await SocialLoginService.loginWithNaver(),
      };

      final auth = await AuthRepository.login(
        provider: credential.provider.name,
        accessToken: credential.accessToken,
      );

      if (!mounted) return;

      final session = AuthSession(
        accessToken: auth.accessToken,
        refreshToken: auth.refreshToken,
        userId: auth.user.userId,
        nickname: auth.user.nickname,
      );

      await AuthSessionStore.write(session);

      if (!mounted) return;

      _completeLogin(context, session);
      await NotificationPermissionService.syncCurrentDeviceTokenPreference();
    } on SocialLoginException catch (e) {
      if (mounted) {
        showAppSnackBar(context, e.message);
      }
    } catch (e) {
      if (mounted) {
        showAppSnackBar(context, '로그인에 실패했어요. 잠시 후 다시 시도해주세요.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _loadingProvider = null;
        });
      }
    }
  }

  void _completeLogin(BuildContext context, AuthSession session) {
    AuthState.logIn(authSession: session);
    showAppSnackBar(context, '로그인 완료');

    Future.delayed(const Duration(milliseconds: 200), () {
      if (context.mounted) {
        Navigator.pop(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    _HeroSection(
                      title: widget.title ?? '로그인이 필요해요',
                      description:
                          widget.description ??
                          '찜한 병원, 문의 내역, 내 캘린더 기능은\n로그인 후 이용할 수 있어요.',
                    ),
                    const SizedBox(height: 28),
                    _LoginCard(
                      loadingProvider: _loadingProvider,
                      onTapKakao: () =>
                          _loginWithProvider(SocialLoginProvider.kakao),
                      onTapNaver: () =>
                          _loginWithProvider(SocialLoginProvider.naver),
                    ),
                    const SizedBox(height: 18),
                    _BottomAgreementSection(
                      onTapPrivacy: () {
                        showAppSnackBar(context, '개인정보처리방침 페이지 연결 예정');
                      },
                      onTapTerms: () {
                        showAppSnackBar(context, '이용약관 페이지 연결 예정');
                      },
                    ),
                    const SizedBox(height: 14),
                  ],
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
          SizedBox(
            height: 44,
            child: Center(
              child: Text(
                '로그인',
                style: AppTextStyles.homeSectionTitle.copyWith(
                  height: 1,
                  color: palette.textPrimary,
                ),
              ),
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
  final String title;
  final String description;

  const _HeroSection({required this.title, required this.description});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              colors: [palette.primaryStrong, palette.primary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: palette.shadow,
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(
            Icons.lock_outline_rounded,
            color: palette.surface,
            size: 30,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          title,
          textAlign: TextAlign.center,
          style: AppTextStyles.homeHeadline.copyWith(
            color: palette.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          description,
          textAlign: TextAlign.center,
          style: AppTextStyles.homeBody.copyWith(
            height: 1.55,
            color: palette.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _LoginCard extends StatelessWidget {
  final VoidCallback onTapKakao;
  final VoidCallback onTapNaver;
  final SocialLoginProvider? loadingProvider;

  const _LoginCard({
    required this.onTapKakao,
    required this.onTapNaver,
    required this.loadingProvider,
  });

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
            style: AppTextStyles.homeSectionTitle.copyWith(
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '처음 로그인하는 경우 자동으로 가입이 진행돼요.',
            textAlign: TextAlign.center,
            style: AppTextStyles.homeBody.copyWith(
              height: 1.5,
              color: palette.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          _SocialLoginImageButton(
            assetPath: 'assets/images/kakao_login_medium_wide.png',
            progressColor: const Color(0xFF191919),
            onTap: loadingProvider == null ? onTapKakao : null,
            isLoading: loadingProvider == SocialLoginProvider.kakao,
          ),
          const SizedBox(height: 12),
          _SocialLoginImageButton(
            assetPath: 'assets/images/naver_login_medium_wide.png',
            progressColor: Colors.white,
            onTap: loadingProvider == null ? onTapNaver : null,
            isLoading: loadingProvider == SocialLoginProvider.naver,
          ),
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
                    style: AppTextStyles.homeCaption.copyWith(
                      color: palette.textSecondary,
                      height: 1.45,
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
    final style = AppTextStyles.homeCaption.copyWith(
      color: palette.textSecondary,
    );

    return Column(
      children: [
        Text(
          '안전한 사용을 위해 꼭 확인해주세요',
          style: AppTextStyles.homeCaption.copyWith(
            color: palette.textTertiary,
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
              style: AppTextStyles.homeCaption.copyWith(
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

class _SocialLoginImageButton extends StatelessWidget {
  static const double _kakaoWideAspectRatio = 300 / 45;

  final String assetPath;
  final Color progressColor;
  final VoidCallback? onTap;
  final bool isLoading;

  const _SocialLoginImageButton({
    required this.assetPath,
    required this.progressColor,
    required this.onTap,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(6),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: AspectRatio(
          aspectRatio: _kakaoWideAspectRatio,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(child: Image.asset(assetPath, fit: BoxFit.fill)),
              if (isLoading)
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.08),
                    ),
                    child: Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: progressColor,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
