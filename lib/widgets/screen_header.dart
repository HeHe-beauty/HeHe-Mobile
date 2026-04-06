import 'package:flutter/material.dart';

import '../theme/app_palette.dart';
import 'app_icon_circle_button.dart';

class ScreenHeader extends StatelessWidget {
  final String title;
  final VoidCallback onTapBack;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;
  final IconData leadingIcon;

  const ScreenHeader({
    super.key,
    required this.title,
    required this.onTapBack,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(20, 14, 20, 10),
    this.leadingIcon = Icons.arrow_back_ios_new_rounded,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Padding(
      padding: padding,
      child: Row(
        children: [
          AppIconCircleButton(
            icon: leadingIcon,
            iconSize: 22,
            onTap: onTapBack,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: palette.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 12), trailing!],
        ],
      ),
    );
  }
}
