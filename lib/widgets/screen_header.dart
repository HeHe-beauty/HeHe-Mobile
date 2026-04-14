import 'package:flutter/material.dart';

import '../theme/app_palette.dart';
import '../theme/app_text_styles.dart';

class ScreenHeader extends StatelessWidget {
  final String title;
  final VoidCallback onTapBack;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;
  final IconData leadingIcon;
  final double? titleFontSize;

  const ScreenHeader({
    super.key,
    required this.title,
    required this.onTapBack,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(20, 14, 20, 10),
    this.leadingIcon = Icons.arrow_back_ios_new_rounded,
    this.titleFontSize,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final trailingWidget = SizedBox(width: 44, child: trailing);

    return Padding(
      padding: padding,
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
                child: Icon(leadingIcon, size: 18, color: palette.icon),
              ),
            ),
          ),
          const Spacer(),
          Expanded(
            child: SizedBox(
              height: 44,
              child: Center(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.homeSectionTitle.copyWith(
                    fontSize: titleFontSize,
                    height: 1,
                    color: palette.textPrimary,
                  ),
                ),
              ),
            ),
          ),
          const Spacer(),
          trailingWidget,
        ],
      ),
    );
  }
}
