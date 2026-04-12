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
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: height,
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: palette.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 6, right: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.left,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              height: 1.15,
                              letterSpacing: -0.2,
                              color: palette.textPrimary,
                            ),
                          ),
                        ),
                        if (infoIcon != null) ...[
                          const SizedBox(width: 2),
                          infoIcon!,
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              if (imageAsset != null) ...[
                const SizedBox(width: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 50,
                    height: double.infinity,
                    child: Image.asset(
                      imageAsset!,
                      fit: BoxFit.contain,
                      alignment: Alignment.center,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
