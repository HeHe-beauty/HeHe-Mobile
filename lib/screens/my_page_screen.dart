import 'package:flutter/material.dart';
import '../core/auth/auth_gate.dart';
import '../core/auth/auth_prompt.dart';
import '../core/auth/auth_session_store.dart';
import '../core/auth/auth_state.dart';
import '../data/auth/auth_repository.dart';
import '../data/user/user_repository.dart';
import '../dtos/common/user/user_summary_dto.dart';
import '../theme/app_palette.dart';
import '../theme/app_text_styles.dart';
import '../utils/app_snackbar.dart';
import '../widgets/screen_header.dart';
import 'hospital_history_screen.dart';

class MyPageScreen extends StatefulWidget {
  const MyPageScreen({super.key});

  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  UserSummaryDto _summary = UserSummaryDto.empty();

  @override
  void initState() {
    super.initState();
    _loadUserSummary();
  }

  Future<void> _loadUserSummary() async {
    final accessToken = AuthState.session?.accessToken;
    if (accessToken == null || accessToken.isEmpty) {
      setState(() {
        _summary = UserSummaryDto.empty();
      });
      return;
    }

    try {
      final summary = await UserRepository.getUserSummary(
        accessToken: accessToken,
      );

      if (!mounted) return;

      setState(() {
        _summary = summary;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _summary = UserSummaryDto.empty();
      });
      showAppSnackBar(context, '마이페이지 정보를 불러오지 못했어요. 잠시 후 다시 시도해주세요.');
    }
  }

  Future<void> _openFavoriteHospitals() async {
    final allowed = await AuthGate.ensureLoggedInWithPrompt(
      context,
      prompt: AuthPrompts.favorites,
    );

    if (!allowed || !mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const HospitalHistoryScreen(initialTabIndex: 1),
      ),
    );
  }

  Future<void> _openInquiryHospitals() async {
    final allowed = await AuthGate.ensureLoggedInWithPrompt(
      context,
      prompt: AuthPrompts.inquiries,
    );

    if (!allowed || !mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const HospitalHistoryScreen(initialTabIndex: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return ValueListenableBuilder<bool>(
      valueListenable: AuthState.isLoggedIn,
      builder: (context, isLoggedIn, _) {
        final userName = isLoggedIn ? '노명욱' : '게스트';

        return Scaffold(
          backgroundColor: palette.bg,
          body: SafeArea(
            child: Stack(
              children: [
                Positioned(
                  top: -72,
                  right: -52,
                  child: _BackgroundCircle(size: 180, opacity: 0.18),
                ),
                Positioned(
                  top: 42,
                  left: -34,
                  child: _BackgroundCircle(size: 96, opacity: 0.14),
                ),
                Positioned(
                  top: 112,
                  right: 42,
                  child: _BackgroundCircle(size: 54, opacity: 0.12),
                ),
                SingleChildScrollView(
                  child: Column(
                    children: [
                      ScreenHeader(
                        title: '마이페이지',
                        onTapBack: () => Navigator.pop(context),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                        child: Column(
                          children: [
                            _ProfileCard(userName: userName),
                            const SizedBox(height: 16),
                            _SummarySection(summary: _summary),
                            const SizedBox(height: 16),
                            _MenuSection(
                              onTapCalendar: () {
                                showAppSnackBar(context, '내 캘린더 연결 예정');
                              },
                              onTapFavorites: () {
                                _openFavoriteHospitals();
                              },
                              onTapInquiries: () {
                                _openInquiryHospitals();
                              },
                              onTapRecent: () {
                                showAppSnackBar(context, '최근 본 병원 연결 예정');
                              },
                            ),
                            const SizedBox(height: 16),
                            _AccountSection(
                              isLoggedIn: isLoggedIn,
                              onTapLogout: () async {
                                final accessToken =
                                    AuthState.session?.accessToken;

                                if (accessToken == null ||
                                    accessToken.isEmpty) {
                                  await AuthSessionStore.clear();
                                  AuthState.logOut();
                                  if (!context.mounted) return;

                                  showAppSnackBar(context, '로그아웃 되었습니다');
                                  Navigator.pop(context);
                                  return;
                                }

                                try {
                                  await AuthRepository.logout(accessToken);

                                  if (!context.mounted) return;

                                  await AuthSessionStore.clear();
                                  AuthState.logOut();
                                  if (!context.mounted) return;

                                  showAppSnackBar(context, '로그아웃 되었습니다');
                                  Navigator.pop(context);
                                } catch (e) {
                                  if (context.mounted) {
                                    showAppSnackBar(
                                      context,
                                      '로그아웃에 실패했어요. 잠시 후 다시 시도해주세요.',
                                    );
                                  }
                                }
                              },
                              onTapWithdraw: () {
                                showAppSnackBar(
                                  context,
                                  '회원탈퇴 기능은 추후 연결 예정입니다.',
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BackgroundCircle extends StatelessWidget {
  final double size;
  final double opacity;

  const _BackgroundCircle({required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: palette.primary.withValues(alpha: opacity),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final String userName;

  const _ProfileCard({required this.userName});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: palette.border),
        boxShadow: [
          BoxShadow(
            blurRadius: 14,
            offset: const Offset(0, 8),
            color: palette.shadow,
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: palette.surfaceMuted,
              border: Border.all(color: palette.border),
            ),
            child: Icon(
              Icons.person_outline_rounded,
              size: 38,
              color: palette.primary,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            userName,
            style: AppTextStyles.homeBodyStrong.copyWith(
              fontSize: 16,
              color: palette.textPrimary,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '내 활동과 저장한 정보를 한 번에 볼 수 있어요.',
            textAlign: TextAlign.center,
            style: AppTextStyles.homeCaption.copyWith(
              height: 1.45,
              color: palette.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummarySection extends StatelessWidget {
  final UserSummaryDto summary;

  const _SummarySection({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            label: '찜한 병원',
            value: summary.bookmarkCount.toString(),
            icon: Icons.star_rounded,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            label: '문의 내역',
            value: summary.contactCount.toString(),
            icon: Icons.call_rounded,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            label: '캘린더',
            value: summary.scheduleCount.toString(),
            icon: Icons.calendar_month_rounded,
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: palette.surfaceMuted,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, size: 18, color: palette.primary),
          ),
          const SizedBox(height: 9),
          Text(
            value,
            style: AppTextStyles.homeBodyStrong.copyWith(
              fontSize: 17,
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyles.homeCaption.copyWith(
              height: 1.3,
              color: palette.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuSection extends StatelessWidget {
  final VoidCallback onTapCalendar;
  final VoidCallback onTapFavorites;
  final VoidCallback onTapInquiries;
  final VoidCallback onTapRecent;

  const _MenuSection({
    required this.onTapCalendar,
    required this.onTapFavorites,
    required this.onTapInquiries,
    required this.onTapRecent,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '내 활동',
              style: AppTextStyles.homeSectionTitle.copyWith(
                fontSize: 18,
                color: palette.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _MenuTile(
            icon: Icons.calendar_month_rounded,
            title: '내 캘린더',
            subtitle: '등록한 일정과 체크리스트를 확인해요.',
            onTap: onTapCalendar,
          ),
          const SizedBox(height: 10),
          _MenuTile(
            icon: Icons.star_rounded,
            title: '찜한 병원',
            subtitle: '저장한 병원들을 모아볼 수 있어요.',
            onTap: onTapFavorites,
          ),
          const SizedBox(height: 10),
          _MenuTile(
            icon: Icons.call_rounded,
            title: '문의 내역',
            subtitle: '상담이나 문의한 병원을 다시 확인해요.',
            onTap: onTapInquiries,
          ),
          const SizedBox(height: 10),
          _MenuTile(
            icon: Icons.history_rounded,
            title: '최근 본 병원',
            subtitle: '최근 확인한 병원 목록을 볼 수 있어요.',
            onTap: onTapRecent,
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Material(
      color: palette.surfaceSoft,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 13, 16, 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: palette.border),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: palette.surfaceMuted,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 19, color: palette.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.homeBodyStrong.copyWith(
                        color: palette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: AppTextStyles.homeCaption.copyWith(
                        height: 1.35,
                        color: palette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                size: 22,
                color: palette.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountSection extends StatelessWidget {
  final bool isLoggedIn;
  final VoidCallback onTapLogout;
  final VoidCallback onTapWithdraw;

  const _AccountSection({
    required this.isLoggedIn,
    required this.onTapLogout,
    required this.onTapWithdraw,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: isLoggedIn ? onTapLogout : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: palette.primarySoft,
              foregroundColor: palette.primary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Text(
              '로그아웃',
              style: AppTextStyles.homeBodyStrong.copyWith(
                color: palette.primary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: onTapWithdraw,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(
              '회원탈퇴',
              style: AppTextStyles.homeCaption.copyWith(color: palette.danger),
            ),
          ),
        ),
      ],
    );
  }
}
