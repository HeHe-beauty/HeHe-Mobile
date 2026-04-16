import 'package:flutter/material.dart';
import '../theme/app_palette.dart';
import '../theme/app_text_styles.dart';

class HeaderBar extends StatelessWidget {
  final String title;
  final VoidCallback? onTapProfile;
  final VoidCallback? onTapSettings;
  final bool isLoggedIn;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? utilityIconColor;

  const HeaderBar({
    super.key,
    required this.title,
    required this.isLoggedIn,
    this.onTapProfile,
    this.onTapSettings,
    this.backgroundColor,
    this.foregroundColor,
    this.utilityIconColor,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final safeTop = MediaQuery.of(context).padding.top;

    return Container(
      padding: EdgeInsets.fromLTRB(20, safeTop + 18, 20, 14),
      color: backgroundColor ?? palette.bg,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: RichText(
                text: TextSpan(
                  style: AppTextStyles.homeHeadline.copyWith(
                    color: foregroundColor ?? palette.textPrimary,
                  ),
                  children: [
                    const TextSpan(text: '시술 꿀팁부터\n기기 찾기까지\n'),
                    TextSpan(
                      text: '관리는 HeHe에서',
                      style: AppTextStyles.homeHeadlineStrong.copyWith(
                        color: foregroundColor ?? palette.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.topRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _UtilityIconButton(
                  icon: Icons.person_outline_rounded,
                  onTap: onTapProfile,
                  color: utilityIconColor,
                ),
                _UtilityIconButton(
                  icon: Icons.settings_outlined,
                  onTap: onTapSettings,
                  color: utilityIconColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UtilityIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color? color;

  const _UtilityIconButton({required this.icon, this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return SizedBox(
      width: 38,
      height: 44,
      child: Material(
        color: Colors.transparent,
        child: InkResponse(
          onTap: onTap,
          radius: 22,
          child: Icon(icon, size: 22, color: color ?? palette.textSecondary),
        ),
      ),
    );
  }
}
