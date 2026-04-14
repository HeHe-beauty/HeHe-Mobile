import 'package:flutter/material.dart';
import '../core/auth/auth_state.dart';
import '../theme/app_palette.dart';
import '../utils/app_snackbar.dart';
import '../widgets/screen_header.dart';

class MyPageScreen extends StatelessWidget {
  const MyPageScreen({super.key});

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
                            const _SummarySection(),
                            const SizedBox(height: 16),
                            _MenuSection(
                              onTapCalendar: () {
                                showAppSnackBar(context, '내 캘린더 연결 예정');
                              },
                              onTapFavorites: () {
                                showAppSnackBar(context, '찜한 병원 연결 예정');
                              },
                              onTapInquiries: () {
                                showAppSnackBar(context, '문의 내역 연결 예정');
                              },
                              onTapRecent: () {
                                showAppSnackBar(context, '최근 본 병원 연결 예정');
                              },
                            ),
                            const SizedBox(height: 16),
                            _AccountSection(
                              isLoggedIn: isLoggedIn,
                              onTapLogout: () {
                                AuthState.logOut();

                                showAppSnackBar(context, '로그아웃 되었어요');

                                Navigator.pop(context);
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
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: palette.textPrimary,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '내 활동과 저장한 정보를 한 번에 볼 수 있어요.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              height: 1.45,
              fontWeight: FontWeight.w600,
              color: palette.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummarySection extends StatelessWidget {
  const _SummarySection();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(
          child: _SummaryCard(
            label: '찜한 병원',
            value: '12',
            icon: Icons.star_rounded,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            label: '문의 내역',
            value: '4',
            icon: Icons.call_rounded,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            label: '캘린더',
            value: '3',
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
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              height: 1.3,
              fontWeight: FontWeight.w700,
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
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
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
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: palette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
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
            child: const Text(
              '로그아웃',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
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
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: palette.danger,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
