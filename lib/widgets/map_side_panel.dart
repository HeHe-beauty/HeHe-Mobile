import 'package:flutter/material.dart';
import '../theme/app_palette.dart';
import '../theme/app_text_styles.dart';

class MapSidePanel extends StatelessWidget {
  final bool isOpen;
  final double topInset;
  final String userName;
  final bool isLoggedIn;
  final VoidCallback onTapMyPage;
  final VoidCallback onTapRecent;
  final VoidCallback onTapFavorite;
  final VoidCallback onTapInquiry;
  final VoidCallback onTapCalendar;
  final VoidCallback onTapNotice;
  final VoidCallback onTapContact;

  const MapSidePanel({
    super.key,
    required this.isOpen,
    required this.topInset,
    required this.userName,
    required this.isLoggedIn,
    required this.onTapMyPage,
    required this.onTapRecent,
    required this.onTapFavorite,
    required this.onTapInquiry,
    required this.onTapCalendar,
    required this.onTapNotice,
    required this.onTapContact,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeInOut,
      top: topInset,
      bottom: 0,
      right: isOpen ? 0 : -238,
      width: 238,
      child: Material(
        color: palette.surface.withValues(alpha: 0),
        child: Container(
          decoration: BoxDecoration(
            color: palette.surface.withValues(alpha: 0.98),
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(24)),
            border: Border.all(color: palette.border),
            boxShadow: [
              BoxShadow(
                blurRadius: 18,
                offset: const Offset(-4, 0),
                color: palette.shadow,
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 16, 14, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Material(
                    color: palette.surface.withValues(alpha: 0),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: onTapMyPage,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: palette.surfaceMuted,
                              child: Icon(
                                Icons.person_outline_rounded,
                                size: 20,
                                color: palette.primary,
                              ),
                            ),
                            const SizedBox(width: 9),
                            Expanded(
                              child: Text(
                                userName,
                                style: AppTextStyles.homeSectionTitle.copyWith(
                                  color: palette.textPrimary,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 22,
                              color: palette.textTertiary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '내 병원 활동',
                    style: AppTextStyles.homeCaption.copyWith(
                      fontWeight: FontWeight.w700,
                      color: palette.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _MenuCard(
                    title: '최근 본 병원',
                    subtitle: '최근 확인했던 병원 목록을 볼 수 있어요.',
                    onTap: onTapRecent,
                  ),
                  const SizedBox(height: 9),
                  _MenuCard(
                    title: '찜한 병원',
                    subtitle: '저장해둔 병원 목록을 모아볼 수 있어요.',
                    onTap: onTapFavorite,
                  ),
                  const SizedBox(height: 9),
                  _MenuCard(
                    title: '문의한 병원',
                    subtitle: '문의했던 병원 내역을 확인할 수 있어요.',
                    onTap: onTapInquiry,
                  ),
                  if (isLoggedIn) ...[
                    const SizedBox(height: 9),
                    _MenuCard(
                      title: '내 캘린더',
                      subtitle: '등록한 병원 일정과 체크리스트를 볼 수 있어요.',
                      onTap: onTapCalendar,
                    ),
                  ],
                  const Spacer(),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      children: [
                        _BottomTextButton(
                          icon: Icons.campaign_outlined,
                          label: '공지사항',
                          onTap: onTapNotice,
                        ),
                        Text(
                          '·',
                          style: AppTextStyles.homeCaption.copyWith(
                            fontWeight: FontWeight.w700,
                            color: palette.textTertiary,
                          ),
                        ),
                        _BottomTextButton(
                          icon: Icons.mail_outline_rounded,
                          label: '문의하기',
                          onTap: onTapContact,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuCard({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Material(
      color: palette.surfaceSoft,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: palette.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.homeBodyStrong.copyWith(
                  color: palette.textPrimary,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                subtitle,
                style: AppTextStyles.homeCaption.copyWith(
                  color: palette.textSecondary,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomTextButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _BottomTextButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Material(
      color: palette.surface.withValues(alpha: 0),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: palette.textSecondary),
              const SizedBox(width: 4),
              Text(
                label,
                style: AppTextStyles.homeCaption.copyWith(
                  fontWeight: FontWeight.w700,
                  color: palette.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
