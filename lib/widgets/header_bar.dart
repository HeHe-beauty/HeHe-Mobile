import 'package:flutter/material.dart';
import '../theme/app_palette.dart';

class HeaderBar extends StatelessWidget {
  final String title;
  final VoidCallback? onTapSettings;

  const HeaderBar({
    super.key,
    required this.title,
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
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.2,
                color: palette.textPrimary,
              ),
            ),
          ),
          _RoundIconButton(
            icon: Icons.settings_outlined,
            onTap: onTapSettings,
          ),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _RoundIconButton({
    required this.icon,
    this.onTap,
  });

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
        child: Icon(
          icon,
          size: 22,
          color: palette.icon,
        ),
      ),
    );
  }
}