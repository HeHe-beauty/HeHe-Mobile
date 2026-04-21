import 'package:flutter/material.dart';
import '../core/common/app_settings_state.dart';
import '../theme/app_palette.dart';
import '../theme/app_text_styles.dart';
import '../utils/app_snackbar.dart';
import '../widgets/screen_header.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Scaffold(
      backgroundColor: palette.bg,
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(title: '설정', onTapBack: () => Navigator.pop(context)),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
                child: Column(
                  children: [
                    ValueListenableBuilder<bool>(
                      valueListenable: AppSettingsState.pushEnabled,
                      builder: (context, pushEnabled, _) {
                        return ValueListenableBuilder<bool>(
                          valueListenable: AppSettingsState.nightPushEnabled,
                          builder: (context, nightPushEnabled, _) {
                            return ValueListenableBuilder<bool>(
                              valueListenable:
                                  AppSettingsState.marketingEnabled,
                              builder: (context, marketingEnabled, _) {
                                return _SectionCard(
                                  title: '알림 설정',
                                  child: Column(
                                    children: [
                                      _SettingToggleTile(
                                        title: '푸시 알림 동의',
                                        subtitle:
                                            '방문 일정, 문의 상태, 주요 알림을 받아볼 수 있어요.',
                                        value: pushEnabled,
                                        onChanged:
                                            AppSettingsState.setPushEnabled,
                                      ),
                                      const SizedBox(height: 10),
                                      _SettingToggleTile(
                                        title: '야간 알림 허용',
                                        subtitle: '늦은 시간에도 필요한 알림을 받을 수 있어요.',
                                        value: nightPushEnabled,
                                        onChanged: pushEnabled
                                            ? AppSettingsState
                                                  .setNightPushEnabled
                                            : null,
                                      ),
                                      const SizedBox(height: 10),
                                      _SettingToggleTile(
                                        title: '마케팅 수신 동의',
                                        subtitle: '이벤트, 혜택, 추천 소식을 받아볼 수 있어요.',
                                        value: marketingEnabled,
                                        onChanged: AppSettingsState
                                            .setMarketingEnabled,
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                    ValueListenableBuilder<ThemeMode>(
                      valueListenable: AppSettingsState.themeMode,
                      builder: (context, themeMode, _) {
                        final isDarkMode = themeMode == ThemeMode.dark;

                        return _SectionCard(
                          title: '화면 설정',
                          child: Column(
                            children: [
                              _ThemeModeTile(
                                isDarkMode: isDarkMode,
                                onChanged: AppSettingsState.setDarkMode,
                              ),
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.fromLTRB(
                                  14,
                                  12,
                                  14,
                                  12,
                                ),
                                decoration: BoxDecoration(
                                  color: palette.surfaceSoft,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(color: palette.border),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.info_outline_rounded,
                                      size: 18,
                                      color: palette.textSecondary,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        '설정에서 선택한 테마가 앱 전체에 바로 반영돼요.',
                                        style: AppTextStyles.homeBody.copyWith(
                                          height: 1.45,
                                          color: palette.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                    _SectionCard(
                      title: '기타',
                      child: Column(
                        children: [
                          _SimpleMenuTile(
                            icon: Icons.description_outlined,
                            title: '이용약관',
                            subtitle: '서비스 이용 관련 내용을 확인할 수 있어요.',
                            onTap: () {
                              showAppSnackBar(context, '이용약관 연결 예정');
                            },
                          ),
                          const SizedBox(height: 10),
                          _SimpleMenuTile(
                            icon: Icons.privacy_tip_outlined,
                            title: '개인정보처리방침',
                            subtitle: '개인정보 수집 및 이용 정책을 확인할 수 있어요.',
                            onTap: () {
                              showAppSnackBar(context, '개인정보처리방침 연결 예정');
                            },
                          ),
                        ],
                      ),
                    ),
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

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
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
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              title,
              style: AppTextStyles.homeSectionTitle.copyWith(
                color: palette.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _SettingToggleTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  const _SettingToggleTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final enabled = onChanged != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: enabled ? palette.surfaceSoft : palette.surfaceMuted,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.homeBodyStrong.copyWith(
                    color: enabled ? palette.textPrimary : palette.textTertiary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTextStyles.homeCaption.copyWith(
                    height: 1.4,
                    color: enabled
                        ? palette.textSecondary
                        : palette.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Transform.scale(
            scale: 0.95,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: palette.primaryStrong,
              activeTrackColor: palette.primary.withValues(alpha: 0.58),
              inactiveThumbColor: palette.textTertiary,
              inactiveTrackColor: palette.surfaceMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeModeTile extends StatelessWidget {
  final bool isDarkMode;
  final ValueChanged<bool> onChanged;

  const _ThemeModeTile({required this.isDarkMode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: palette.surfaceSoft,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: palette.surfaceMuted,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
              size: 22,
              color: palette.primaryStrong,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isDarkMode ? '다크모드' : '라이트모드',
                  style: AppTextStyles.homeBodyStrong.copyWith(
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '앱 화면 테마를 변경할 수 있어요.',
                  style: AppTextStyles.homeCaption.copyWith(
                    height: 1.4,
                    color: palette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch(
            value: isDarkMode,
            onChanged: onChanged,
            activeThumbColor: palette.primaryStrong,
            activeTrackColor: palette.primary.withValues(alpha: 0.58),
            inactiveThumbColor: palette.textTertiary,
            inactiveTrackColor: palette.surfaceMuted,
          ),
        ],
      ),
    );
  }
}

class _SimpleMenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SimpleMenuTile({
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
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: palette.border),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: palette.surfaceMuted,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 22, color: palette.primaryStrong),
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
                        height: 1.4,
                        color: palette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                size: 24,
                color: palette.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
