import 'package:flutter/material.dart';
import '../core/auth/auth_session_store.dart';
import '../core/auth/auth_state.dart';
import '../core/auth/social_login_service.dart';
import '../core/common/app_settings_state.dart';
import '../core/logging/app_log.dart';
import '../core/network/api_client.dart';
import '../core/notification/notification_permission_service.dart';
import '../data/auth/auth_repository.dart';
import '../dtos/common/auth/auth_login_response_dto.dart';
import '../theme/app_palette.dart';
import '../theme/app_text_styles.dart';
import '../utils/app_snackbar.dart';
import '../utils/legal_document_links.dart';

class LoginRequiredScreen extends StatefulWidget {
  final String? title;
  final String? description;
  final bool showSignupConsentPreview;

  const LoginRequiredScreen({
    super.key,
    this.title,
    this.description,
    this.showSignupConsentPreview = false,
  });

  @override
  State<LoginRequiredScreen> createState() => _LoginRequiredScreenState();
}

class _LoginRequiredScreenState extends State<LoginRequiredScreen> {
  static const _termsVersion = 'v1.0.0';

  SocialLoginProvider? _loadingProvider;
  SocialLoginCredential? _pendingSignupCredential;
  late bool _isSignupConsentVisible;
  bool _isSubmittingSignup = false;
  bool _isNotificationAllowed = false;
  bool _isMarketingAllowed = false;
  bool _isNightPushAllowed = false;
  bool _isAgeConfirmed = false;

  @override
  void initState() {
    super.initState();
    _isSignupConsentVisible = widget.showSignupConsentPreview;
  }

  Future<void> _loginWithProvider(SocialLoginProvider provider) async {
    if (_loadingProvider != null) return;

    setState(() {
      _loadingProvider = provider;
    });

    SocialLoginCredential? credential;
    try {
      AppLog.debug(
        '[Auth][LoginScreen] login tapped provider=${provider.name}',
      );
      credential = switch (provider) {
        SocialLoginProvider.kakao => await SocialLoginService.loginWithKakao(),
        SocialLoginProvider.naver => await SocialLoginService.loginWithNaver(),
      };
      AppLog.debug(
        '[Auth][LoginScreen] social credential ready '
        'provider=${credential.provider.name} '
        'idTokenPresent=${credential.idToken != null}',
      );

      final auth = await AuthRepository.login(
        provider: credential.provider.name,
        accessToken: credential.accessToken,
      );

      if (!mounted) return;

      if (!auth.exists) {
        _showSignupConsentFlow(credential);
        return;
      }

      await _completeLoginWithAuthResponse(
        auth: auth,
        provider: credential.provider.name,
      );
    } on SocialLoginException catch (e) {
      AppLog.debug('[Auth][LoginScreen] social login exception', error: e);
      if (mounted) {
        showAppSnackBar(context, e.displayMessage);
      }
    } catch (e) {
      AppLog.debug('[Auth][LoginScreen] login error', error: e);
      if (mounted && credential != null && _isSignupRequiredError(e)) {
        _showSignupConsentFlow(credential);
        return;
      }
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

  bool _isSignupRequiredError(Object error) {
    return error is ApiException && error.indicatesMissingUser;
  }

  void _showSignupConsentFlow(SocialLoginCredential credential) {
    setState(() {
      _pendingSignupCredential = credential;
      _isSignupConsentVisible = true;
      _loadingProvider = null;
      _isNotificationAllowed = false;
      _isMarketingAllowed = false;
      _isNightPushAllowed = false;
      _isAgeConfirmed = false;
    });
  }

  void _setNotificationAllowed(bool value) {
    setState(() {
      _isNotificationAllowed = value;
      if (!value) {
        _isMarketingAllowed = false;
        _isNightPushAllowed = false;
      }
    });
  }

  Future<void> _submitSignupConsent() async {
    if (!_isAgeConfirmed) return;
    if (_isSubmittingSignup) return;

    final credential = _pendingSignupCredential;
    if (credential == null) {
      showAppSnackBar(context, '소셜 인증 정보가 만료되었어요. 다시 로그인해주세요.');
      setState(() {
        _isSignupConsentVisible = false;
      });
      return;
    }

    setState(() {
      _isSubmittingSignup = true;
    });

    try {
      var pushAgreed = _isNotificationAllowed;
      if (pushAgreed) {
        pushAgreed = await NotificationPermissionService.ensureGrantedForSignup(
          context,
        );
      }

      final auth = await AuthRepository.signup(
        provider: credential.provider.name,
        accessToken: credential.accessToken,
        pushAgreed: pushAgreed,
        nightAgreed: pushAgreed && _isNightPushAllowed,
        mktAgreed: pushAgreed && _isMarketingAllowed,
        isOverAge: _isAgeConfirmed,
        termsVersion: _termsVersion,
      );

      AppSettingsState.setPushEnabled(pushAgreed);
      AppSettingsState.setNightPushEnabled(pushAgreed && _isNightPushAllowed);
      AppSettingsState.setMarketingEnabled(pushAgreed && _isMarketingAllowed);

      if (!mounted) return;

      await _completeLoginWithAuthResponse(
        auth: auth,
        provider: credential.provider.name,
      );
    } catch (e) {
      AppLog.debug('[Auth][SignupConsent] signup error', error: e);
      if (mounted) {
        showAppSnackBar(context, '회원가입에 실패했어요. 잠시 후 다시 시도해주세요.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmittingSignup = false;
        });
      }
    }
  }

  Future<void> _completeLoginWithAuthResponse({
    required AuthLoginResponseDto auth,
    required String provider,
  }) async {
    if (!auth.hasSession) {
      throw StateError('Auth response does not include session data.');
    }

    final user = auth.user!;
    final session = AuthSession(
      accessToken: auth.accessToken!,
      refreshToken: auth.refreshToken!,
      userId: user.userId,
      nickname: user.nickname,
      provider: provider.toUpperCase(),
    );

    await AuthSessionStore.write(session);
    AppLog.debug('[Auth][LoginScreen] auth session saved');

    if (!mounted) return;

    _completeLogin(context, session);
    await NotificationPermissionService.syncCurrentDeviceTokenPreference();
  }

  void _completeLogin(BuildContext context, AuthSession session) {
    AuthState.logIn(authSession: session);
    AppLog.debug(
      '[Auth][LoginScreen] AuthState updated userId=${session.userId}',
    );
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
                    if (!_isSignupConsentVisible) ...[
                      const SizedBox(height: 16),
                      _HeroSection(
                        title: widget.title ?? '로그인이 필요해요',
                        description:
                            widget.description ??
                            '찜한 병원, 문의 내역, 내 캘린더 기능은\n로그인 후 이용할 수 있어요.',
                      ),
                    ] else
                      const SizedBox(height: 8),
                    const SizedBox(height: 28),
                    if (_isSignupConsentVisible)
                      _SignupConsentCard(
                        isNotificationAllowed: _isNotificationAllowed,
                        isMarketingAllowed: _isMarketingAllowed,
                        isNightPushAllowed: _isNightPushAllowed,
                        isAgeConfirmed: _isAgeConfirmed,
                        isSubmitting: _isSubmittingSignup,
                        onNotificationChanged: _setNotificationAllowed,
                        onMarketingChanged: (value) {
                          setState(() {
                            _isMarketingAllowed = value;
                          });
                        },
                        onNightPushChanged: (value) {
                          setState(() {
                            _isNightPushAllowed = value;
                          });
                        },
                        onAgeConfirmationChanged: (value) {
                          setState(() {
                            _isAgeConfirmed = value;
                          });
                        },
                        onSubmit: _submitSignupConsent,
                      )
                    else
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
                        LegalDocumentLinks.open(
                          context,
                          LegalDocumentLinks.privacy,
                        );
                      },
                      onTapTerms: () {
                        LegalDocumentLinks.open(
                          context,
                          LegalDocumentLinks.terms,
                        );
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
          const SizedBox(height: 20),
          _SocialLoginImageButton(
            key: const ValueKey('kakao-login-button'),
            assetPath: 'assets/images/kakao_login_medium_wide.png',
            progressColor: const Color(0xFF191919),
            onTap: loadingProvider == null ? onTapKakao : null,
            isLoading: loadingProvider == SocialLoginProvider.kakao,
          ),
          const SizedBox(height: 12),
          _SocialLoginImageButton(
            key: const ValueKey('naver-login-button'),
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
                    '로그인 전에 이용약관과 개인정보처리방침을 확인해주세요.',
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

class _SignupConsentCard extends StatelessWidget {
  final bool isNotificationAllowed;
  final bool isMarketingAllowed;
  final bool isNightPushAllowed;
  final bool isAgeConfirmed;
  final bool isSubmitting;
  final ValueChanged<bool> onNotificationChanged;
  final ValueChanged<bool> onMarketingChanged;
  final ValueChanged<bool> onNightPushChanged;
  final ValueChanged<bool> onAgeConfirmationChanged;
  final VoidCallback onSubmit;

  const _SignupConsentCard({
    required this.isNotificationAllowed,
    required this.isMarketingAllowed,
    required this.isNightPushAllowed,
    required this.isAgeConfirmed,
    required this.isSubmitting,
    required this.onNotificationChanged,
    required this.onMarketingChanged,
    required this.onNightPushChanged,
    required this.onAgeConfirmationChanged,
    required this.onSubmit,
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 54,
              height: 5,
              decoration: BoxDecoration(
                color: palette.border,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 22),
          Text(
            '회원가입 동의',
            textAlign: TextAlign.center,
            style: AppTextStyles.homeSectionTitle.copyWith(
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '알림 관련 동의는 선택사항이에요. 필수 확인을 완료하면 가입과 로그인이 이어져요.',
            textAlign: TextAlign.center,
            style: AppTextStyles.homeBody.copyWith(
              height: 1.5,
              color: palette.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          _AgeConfirmationTile(
            isAgeConfirmed: isAgeConfirmed,
            onChanged: onAgeConfirmationChanged,
          ),
          const SizedBox(height: 10),
          _ConsentSwitchTile(
            key: const ValueKey('notification-consent-switch'),
            icon: Icons.notifications_none_rounded,
            title: '알림 동의 (선택)',
            description: '예약 일정, 저장한 병원 소식 등 필요한 알림을 받을 수 있어요.',
            value: isNotificationAllowed,
            onChanged: onNotificationChanged,
          ),
          const SizedBox(height: 10),
          _ConsentSwitchTile(
            key: const ValueKey('marketing-consent-switch'),
            icon: Icons.campaign_outlined,
            title: '마케팅 수신 동의 (선택)',
            description: '이벤트와 혜택 안내를 받을 수 있어요.',
            value: isMarketingAllowed,
            onChanged: isNotificationAllowed ? onMarketingChanged : null,
          ),
          const SizedBox(height: 10),
          _ConsentSwitchTile(
            key: const ValueKey('night-push-consent-switch'),
            icon: Icons.nightlight_round,
            title: '야간 푸시 동의 (선택)',
            description: '밤 9시부터 다음 날 오전 8시 사이의 알림을 허용해요.',
            value: isNightPushAllowed,
            onChanged: isNotificationAllowed ? onNightPushChanged : null,
          ),
          const SizedBox(height: 18),
          _PrimaryActionButton(
            key: const ValueKey('signup-submit-button'),
            label: isSubmitting ? '가입 처리 중...' : '회원가입하고 로그인하기',
            onTap: isAgeConfirmed && !isSubmitting ? onSubmit : null,
          ),
        ],
      ),
    );
  }
}

class _ConsentSwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool value;
  final ValueChanged<bool>? onChanged;

  const _ConsentSwitchTile({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final isEnabled = onChanged != null;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 160),
      opacity: isEnabled ? 1 : 0.46,
      child: Container(
        decoration: BoxDecoration(
          color: palette.surfaceSoft,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: palette.border),
        ),
        child: SwitchListTile.adaptive(
          value: value,
          onChanged: onChanged,
          activeThumbColor: palette.primary,
          contentPadding: const EdgeInsets.fromLTRB(12, 4, 8, 4),
          secondary: Icon(icon, size: 21, color: palette.textSecondary),
          title: Text(
            title,
            style: AppTextStyles.homeBodyStrong.copyWith(
              color: palette.textPrimary,
            ),
          ),
          subtitle: Text(
            description,
            style: AppTextStyles.homeCaption.copyWith(
              color: palette.textSecondary,
              height: 1.35,
            ),
          ),
        ),
      ),
    );
  }
}

class _AgeConfirmationTile extends StatelessWidget {
  final bool isAgeConfirmed;
  final ValueChanged<bool> onChanged;

  const _AgeConfirmationTile({
    required this.isAgeConfirmed,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      decoration: BoxDecoration(
        color: palette.primarySoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.primary.withValues(alpha: 0.26)),
      ),
      child: CheckboxListTile(
        key: const ValueKey('age-confirmation-checkbox'),
        value: isAgeConfirmed,
        onChanged: (value) => onChanged(value ?? false),
        controlAffinity: ListTileControlAffinity.leading,
        activeColor: palette.primary,
        checkColor: palette.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10),
        visualDensity: VisualDensity.compact,
        title: Text(
          '만 14세 이상입니다 (필수)',
          style: AppTextStyles.homeBodyStrong.copyWith(
            color: palette.textPrimary,
          ),
        ),
        subtitle: Text(
          '만 14세 미만은 회원가입할 수 없어요.',
          style: AppTextStyles.homeCaption.copyWith(
            color: palette.textSecondary,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}

class _PrimaryActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _PrimaryActionButton({
    super.key,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final isEnabled = onTap != null;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 160),
      opacity: isEnabled ? 1 : 0.45,
      child: Material(
        color: isEnabled ? palette.primary : palette.surfaceMuted,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            height: 52,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.homeBodyStrong.copyWith(
                color: isEnabled ? palette.surface : palette.textSecondary,
              ),
            ),
          ),
        ),
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
    super.key,
    required this.assetPath,
    required this.progressColor,
    required this.onTap,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 160),
      opacity: onTap == null && !isLoading ? 0.45 : 1,
      child: Material(
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
                Positioned.fill(
                  child: Image.asset(assetPath, fit: BoxFit.fill),
                ),
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
      ),
    );
  }
}
