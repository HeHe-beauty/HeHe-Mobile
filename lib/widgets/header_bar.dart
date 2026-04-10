import 'package:flutter/material.dart';
import '../theme/app_palette.dart';

class HeaderBar extends StatelessWidget {
  final String title;
  final VoidCallback? onTapProfile;
  final VoidCallback? onTapSettings;
  final bool isLoggedIn;

  const HeaderBar({
    super.key,
    required this.title,
    required this.isLoggedIn,
    this.onTapProfile,
    this.onTapSettings,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final safeTop = MediaQuery.of(context).padding.top;

    return Container(
      padding: EdgeInsets.fromLTRB(20, safeTop + 18, 20, 14),
      color: palette.bg,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.2,
                    height: 1.32,
                    color: palette.textPrimary,
                  ),
                  children: const [
                    TextSpan(text: '시술 꿀팁부터\n병원 찾기까지\n'),
                    TextSpan(
                      text: '관리는 HeHe에서',
                      style: TextStyle(fontWeight: FontWeight.w700),
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
                _RoundIconButton(
                  icon: Icons.person_outline_rounded,
                  onTap: onTapProfile,
                ),
                const SizedBox(width: 8),
                _RoundIconButton(
                  icon: Icons.settings_outlined,
                  onTap: onTapSettings,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _RoundIconButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return InkResponse(
      onTap: onTap,
      radius: 22,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: palette.border),
        ),
        child: Icon(icon, size: 22, color: palette.icon),
      ),
    );
  }
}
