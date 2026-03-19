import 'package:flutter/material.dart';

import '../theme/app_palette.dart';
import 'map_circle_button.dart';

const double _kMapControlRadius = 22;

class DeviceMapTopBar extends StatelessWidget {
  final TextEditingController searchController;
  final FocusNode? searchFocusNode;
  final ValueChanged<String>? onSearchChanged;
  final ValueChanged<String>? onSearchSubmitted;
  final VoidCallback onTapBack;
  final VoidCallback onTapMenu;

  const DeviceMapTopBar({
    super.key,
    required this.searchController,
    this.searchFocusNode,
    this.onSearchChanged,
    this.onSearchSubmitted,
    required this.onTapBack,
    required this.onTapMenu,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Positioned(
      top: 12,
      left: 16,
      right: 16,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          MapCircleButton(
            onTap: onTapBack,
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 28,
              color: palette.icon,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: BorderRadius.circular(_kMapControlRadius),
                border: Border.all(color: palette.border),
                boxShadow: [
                  BoxShadow(
                    color: palette.shadow,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 56),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 22,
                        height: 22,
                        child: Center(
                          child: Icon(
                            Icons.search_rounded,
                            size: 20,
                            color: palette.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: searchController,
                          focusNode: searchFocusNode,
                          textAlignVertical: TextAlignVertical.center,
                          textInputAction: TextInputAction.search,
                          maxLines: 1,
                          onChanged: onSearchChanged,
                          onSubmitted: onSearchSubmitted,
                          decoration: InputDecoration(
                            hintText: '지하철역 검색',
                            hintStyle: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: palette.textSecondary,
                              height: 1.2,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: palette.textPrimary,
                            height: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          MapCircleButton(
            onTap: onTapMenu,
            child: Icon(Icons.menu_rounded, size: 28, color: palette.icon),
          ),
        ],
      ),
    );
  }
}

class DeviceMapMyLocationButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onTap;

  const DeviceMapMyLocationButton({
    super.key,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return MapCircleButton(
      size: 54,
      onTap: onTap,
      child: isLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                valueColor: AlwaysStoppedAnimation<Color>(palette.primary),
              ),
            )
          : SizedBox(
              width: 24,
              height: 24,
              child: Center(
                child: Icon(
                  Icons.my_location_rounded,
                  size: 22,
                  color: palette.primary,
                ),
              ),
            ),
    );
  }
}

class DeviceMapSidePanelScrim extends StatelessWidget {
  final VoidCallback onTap;

  const DeviceMapSidePanelScrim({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: onTap,
        child: ColoredBox(color: palette.scrim),
      ),
    );
  }
}
