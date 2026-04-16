import 'package:flutter/material.dart';
import '../theme/app_palette.dart';

class DeviceTile extends StatelessWidget {
  final String title;
  final String? imageAsset;
  final double height;
  final Widget? infoIcon;
  final VoidCallback? onTap;

  const DeviceTile({
    super.key,
    required this.title,
    this.imageAsset,
    required this.height,
    this.infoIcon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Material(
      color: palette.surface,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: height,
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: palette.border),
            boxShadow: [
              BoxShadow(
                color: palette.shadow,
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                top: 0,
                child: SizedBox(
                  width: 76,
                  height: height - 30,
                  child: Image.asset(
                    imageAsset!,
                    fit: BoxFit.contain,
                    alignment: Alignment.topLeft,
                  ),
                ),
              ),
              Positioned(
                left: 20,
                right: 0,
                bottom: 0,
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    height: 1.15,
                    letterSpacing: -0.2,
                    color: palette.textPrimary,
                  ),
                ),
              ),
              if (infoIcon != null)
                Positioned(top: -6, right: -2, child: infoIcon!),
            ],
          ),
        ),
      ),
    );
  }
}
