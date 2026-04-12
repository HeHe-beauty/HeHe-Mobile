import 'package:flutter/material.dart';
import '../models/content_item.dart';
import '../theme/app_palette.dart';
import '../widgets/app_icon_circle_button.dart';

class ContentDetailScreen extends StatelessWidget {
  final ContentItem item;

  const ContentDetailScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Scaffold(
      backgroundColor: palette.bg,
      body: SafeArea(
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: palette.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: palette.surfaceMuted,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Icon(item.icon, size: 20, color: palette.primary),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item.author,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: palette.textPrimary,
                      ),
                    ),
                  ),
                  AppIconCircleButton(
                    icon: Icons.close_rounded,
                    size: 44,
                    iconSize: 22,
                    showBorder: false,
                    showShadow: false,
                    backgroundColor: palette.surfaceSoft,
                    onTap: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Text(
                item.title,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  height: 1.4,
                  color: palette.textPrimary,
                ),
              ),
              const SizedBox(height: 22),
              Container(
                width: 120,
                height: 3,
                decoration: BoxDecoration(
                  color: palette.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 22),
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    item.body,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.6,
                      fontWeight: FontWeight.w600,
                      color: palette.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
