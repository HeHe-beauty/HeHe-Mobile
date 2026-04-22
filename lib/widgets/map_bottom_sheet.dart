import 'package:flutter/material.dart';
import '../models/place_item.dart';
import '../theme/app_palette.dart';
import '../theme/app_text_styles.dart';
import 'map_control_surface.dart';
import 'place_card.dart';

const double _kMapSheetRadius = 28;
const double _kMapSheetInnerRadius = 22;

class MapBottomSheet extends StatefulWidget {
  final DraggableScrollableController controller;
  final String regionLabel;
  final List<PlaceItem> places;
  final PlaceItem? selectedPlace;
  final bool isHidden;
  final ValueChanged<PlaceItem> onTapPlaceCard;
  final ValueChanged<PlaceItem> onTapInquiry;
  final ValueChanged<PlaceItem> onTapBookmark;
  final String Function(PlaceItem place) distanceLabelForPlace;
  final VoidCallback onDismissSingle;

  const MapBottomSheet({
    super.key,
    required this.controller,
    required this.regionLabel,
    required this.places,
    required this.selectedPlace,
    required this.isHidden,
    required this.onTapPlaceCard,
    required this.onTapInquiry,
    required this.onTapBookmark,
    required this.distanceLabelForPlace,
    required this.onDismissSingle,
  });

  @override
  State<MapBottomSheet> createState() => _MapBottomSheetState();
}

class _MapBottomSheetState extends State<MapBottomSheet> {
  static const double _hiddenSize = 0.015;
  static const double _defaultSize = 0.125;

  static const double _clusterInitialSize = 0.22;
  static const double _clusterMinSize = 0.22;
  static const double _clusterMidSize = 0.42;
  static const double _clusterMaxSize = 0.99;

  static const double _singleInitialSize = 0.3;
  static const double _singleMinSize = 0.01;
  static const double _singleMaxSize = 0.3;

  bool get _isHiddenMode => widget.isHidden;

  bool get _isSingleMode {
    return widget.selectedPlace != null &&
        widget.places.length == 1 &&
        widget.places.first.id == widget.selectedPlace!.id;
  }

  bool get _isDefaultMode {
    return widget.selectedPlace == null && widget.places.isEmpty;
  }

  bool get _isClusterMode {
    return widget.selectedPlace == null && widget.places.isNotEmpty;
  }

  @override
  void didUpdateWidget(covariant MapBottomSheet oldWidget) {
    super.didUpdateWidget(oldWidget);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !widget.controller.isAttached) return;

      final oldWasSingle =
          oldWidget.selectedPlace != null &&
          oldWidget.places.length == 1 &&
          oldWidget.places.first.id == oldWidget.selectedPlace!.id;

      final newIsSingle = _isSingleMode;
      final newIsDefault = _isDefaultMode;
      final newIsCluster = _isClusterMode;

      final oldSelectedId = oldWidget.selectedPlace?.id;
      final newSelectedId = widget.selectedPlace?.id;

      final selectedPlaceChanged = oldSelectedId != newSelectedId;
      final modeChanged =
          oldWasSingle != newIsSingle ||
          (oldWidget.places.isEmpty != widget.places.isEmpty);

      if (_isHiddenMode) {
        final currentSize = widget.controller.size;
        if ((currentSize - _hiddenSize).abs() > 0.01) {
          widget.controller.jumpTo(_hiddenSize);
        }
        return;
      }

      if (oldWidget.isHidden && newIsDefault) {
        return;
      }

      if (newIsSingle && (modeChanged || selectedPlaceChanged)) {
        final currentSize = widget.controller.size;
        if ((currentSize - _singleInitialSize).abs() > 0.01) {
          widget.controller.animateTo(
            _singleInitialSize,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
          );
        }
        return;
      }

      if (newIsDefault) {
        final currentSize = widget.controller.size;
        if ((currentSize - _defaultSize).abs() > 0.01) {
          widget.controller.jumpTo(_defaultSize);
        }
        return;
      }

      if (newIsCluster) {
        final currentSize = widget.controller.size;
        if (currentSize < _clusterMinSize || currentSize > _clusterMaxSize) {
          widget.controller.jumpTo(_clusterInitialSize);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isDefaultMode) {
      return _FixedLocationPanel(
        isHidden: _isHiddenMode,
        child: _WideRegionChip(label: widget.regionLabel),
      );
    }

    if (_isSingleMode) {
      if (_isHiddenMode) return const SizedBox.shrink();

      return Positioned(
        left: 18,
        right: 18,
        bottom: 0,
        child: SafeArea(
          top: false,
          minimum: const EdgeInsets.only(bottom: 14),
          child: _SinglePlaceGestureBlocker(
            child: _SinglePlaceSection(
              place: widget.places.first,
              distanceLabel: widget.distanceLabelForPlace(widget.places.first),
              onTapInquiry: widget.onTapInquiry,
              onTapBookmark: widget.onTapBookmark,
            ),
          ),
        ),
      );
    }

    final enableSnap = _isClusterMode;

    final double initialSize = _isHiddenMode
        ? _hiddenSize
        : _isDefaultMode
        ? _defaultSize
        : _isSingleMode
        ? _singleInitialSize
        : _clusterInitialSize;

    final double minSize = _isHiddenMode
        ? _hiddenSize
        : _isDefaultMode
        ? _defaultSize
        : _isSingleMode
        ? _singleMinSize
        : _clusterMinSize;

    final double maxSize = _isHiddenMode
        ? _hiddenSize
        : _isDefaultMode
        ? _defaultSize
        : _isSingleMode
        ? _singleMaxSize
        : _clusterMaxSize;

    final List<double> snapSizes = _isHiddenMode
        ? const [_hiddenSize]
        : _isDefaultMode
        ? const [_defaultSize]
        : _isSingleMode
        ? const [_singleMinSize, _singleInitialSize]
        : const [_clusterMinSize, _clusterMidSize, _clusterMaxSize];

    return DraggableScrollableSheet(
      controller: widget.controller,
      initialChildSize: initialSize,
      minChildSize: minSize,
      maxChildSize: maxSize,
      snap: enableSnap,
      snapSizes: enableSnap ? snapSizes : null,
      builder: (context, scrollController) {
        return AnimatedBuilder(
          animation: widget.controller,
          builder: (context, child) {
            final isTinySheet = _isHiddenMode;

            if (isTinySheet) {
              return SizedBox.expand(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: palette.bottomSheetSurface,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(_kMapSheetRadius),
                    ),
                  ),
                ),
              );
            }

            return Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: palette.bottomSheetSurface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(_kMapSheetRadius),
                ),
                border: Border(
                  top: BorderSide(
                    color: palette.bottomSheetBorder.withValues(
                      alpha: isDark ? 0.42 : 1,
                    ),
                  ),
                ),
              ),
              child: ClipRect(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isShortHeight = constraints.maxHeight < 520;
                    final allowSingleScroll = _isSingleMode && isShortHeight;
                    final bottomInset = MediaQuery.of(
                      context,
                    ).viewPadding.bottom;
                    const horizontalPadding = 18.0;
                    final defaultTopSpacer = isShortHeight ? 18.0 : 22.0;
                    final defaultChipBottomSpacer = isShortHeight ? 10.0 : 12.0;
                    final bottomPadding =
                        (_isSingleMode
                            ? (isShortHeight ? 28.0 : 30.0)
                            : _isDefaultMode
                            ? (isShortHeight ? 12.0 : 14.0)
                            : (isShortHeight ? 20.0 : 24.0)) +
                        bottomInset;
                    const gridSpacing = 18.0;
                    final crossAxisCount = constraints.maxWidth < 360 ? 1 : 2;
                    final childAspectRatio = crossAxisCount == 1 ? 1.68 : 0.64;

                    return SingleChildScrollView(
                      controller: scrollController,
                      physics: allowSingleScroll
                          ? const ClampingScrollPhysics()
                          : _isSingleMode
                          ? const NeverScrollableScrollPhysics()
                          : const ClampingScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_isClusterMode) ...[
                              SizedBox(height: isShortHeight ? 12 : 14),
                              const _MapSheetDragHandle(),
                              SizedBox(height: isShortHeight ? 12 : 14),
                            ],
                            Padding(
                              padding: EdgeInsets.fromLTRB(
                                horizontalPadding,
                                2,
                                horizontalPadding,
                                bottomPadding,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_isHiddenMode) const SizedBox.shrink(),

                                  if (!_isHiddenMode && _isDefaultMode) ...[
                                    SizedBox(height: defaultTopSpacer),
                                    _WideRegionChip(label: widget.regionLabel),
                                    SizedBox(height: defaultChipBottomSpacer),
                                  ],

                                  if (!_isHiddenMode && _isClusterMode) ...[
                                    _WideRegionChip(label: widget.regionLabel),
                                    SizedBox(height: isShortHeight ? 10 : 12),
                                    GridView.builder(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemCount: widget.places.length,
                                      gridDelegate:
                                          SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: crossAxisCount,
                                            crossAxisSpacing: gridSpacing,
                                            mainAxisSpacing: gridSpacing,
                                            childAspectRatio: childAspectRatio,
                                          ),
                                      itemBuilder: (context, index) {
                                        final place = widget.places[index];

                                        return PlaceCard(
                                          place: place,
                                          distanceLabel: widget
                                              .distanceLabelForPlace(place),
                                          onTap: () =>
                                              widget.onTapPlaceCard(place),
                                          onTapBookmark: () =>
                                              widget.onTapBookmark(place),
                                        );
                                      },
                                    ),
                                    SizedBox(height: isShortHeight ? 6 : 8),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _MapSheetDragHandle extends StatelessWidget {
  const _MapSheetDragHandle();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Center(
      child: Container(
        width: 38,
        height: 5,
        decoration: BoxDecoration(
          color: palette.bottomSheetBorder,
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

class _FixedLocationPanel extends StatelessWidget {
  final bool isHidden;
  final Widget child;

  const _FixedLocationPanel({required this.isHidden, required this.child});

  @override
  Widget build(BuildContext context) {
    if (isHidden) {
      return const SizedBox.shrink();
    }

    return Positioned(
      left: 18,
      right: 18,
      bottom: 0,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragStart: (_) {},
        onVerticalDragUpdate: (_) {},
        onVerticalDragEnd: (_) {},
        child: SafeArea(
          top: false,
          minimum: const EdgeInsets.only(bottom: 14),
          child: child,
        ),
      ),
    );
  }
}

class _WideRegionChip extends StatelessWidget {
  final String label;

  const _WideRegionChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 48),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? palette.bottomSheetChipSurface : palette.surface,
        borderRadius: BorderRadius.circular(kMapControlRadius),
        border: Border.all(
          color: isDark
              ? palette.bottomSheetChipBorder
              : palette.bottomSheetBorder,
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: palette.shadow,
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          if (isDark)
            BoxShadow(
              color: palette.shadow.withValues(alpha: 0.18),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.location_on_rounded,
            size: 20,
            color: palette.primaryStrong,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: palette.textPrimary,
                height: 1.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SinglePlaceSection extends StatelessWidget {
  final PlaceItem place;
  final String distanceLabel;
  final ValueChanged<PlaceItem> onTapInquiry;
  final ValueChanged<PlaceItem> onTapBookmark;

  const _SinglePlaceSection({
    required this.place,
    required this.distanceLabel,
    required this.onTapInquiry,
    required this.onTapBookmark,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 2, 2, 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stackActions = constraints.maxWidth < 340;
          final visibleTags = place.tags.take(4).toList();

          return Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(15, 14, 15, 15),
            decoration: BoxDecoration(
              color: palette.bottomSheetInnerSurface,
              borderRadius: BorderRadius.circular(_kMapSheetInnerRadius),
              border: Border.all(
                color: palette.bottomSheetBorder.withValues(
                  alpha: isDark ? 0.42 : 1,
                ),
              ),
              boxShadow: [
                if (!isDark)
                  BoxShadow(
                    color: palette.shadow,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  distanceLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.homeCaption.copyWith(
                    color: palette.textTertiary,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  place.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.homeSectionTitle.copyWith(
                    color: palette.textPrimary,
                    height: 1.18,
                  ),
                ),
                if (visibleTags.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 5,
                    runSpacing: 5,
                    children: visibleTags
                        .map((tag) => _HospitalTagChip(label: tag))
                        .toList(),
                  ),
                ],
                if (place.address.isNotEmpty) ...[
                  const SizedBox(height: 9),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 1),
                        child: Icon(
                          Icons.location_on_rounded,
                          size: 15,
                          color: palette.primaryStrong,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          place.address,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.homeCaption.copyWith(
                            color: palette.textSecondary,
                            fontWeight: FontWeight.w600,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                if (stackActions) ...[
                  _PrimaryActionButton(
                    icon: Icons.call_rounded,
                    label: '문의하기',
                    onTap: () => onTapInquiry(place),
                  ),
                  const SizedBox(height: 8),
                  _SecondaryActionButton(
                    icon: place.isBookmarked
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    label: '찜하기',
                    isActive: place.isBookmarked,
                    onTap: () => onTapBookmark(place),
                  ),
                ] else
                  Row(
                    children: [
                      Expanded(
                        child: _PrimaryActionButton(
                          icon: Icons.call_rounded,
                          label: '문의하기',
                          onTap: () => onTapInquiry(place),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _SecondaryActionButton(
                          icon: place.isBookmarked
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          label: '찜하기',
                          isActive: place.isBookmarked,
                          onTap: () => onTapBookmark(place),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PrimaryActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PrimaryActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final buttonTextStyle = AppTextStyles.homeBodyStrong.copyWith(
      color: Colors.white,
      height: 1,
    );

    return Material(
      color: palette.surface.withValues(alpha: 0),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Ink(
          height: 42,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: palette.primary,
            boxShadow: [
              if (!isDark)
                BoxShadow(
                  color: palette.shadow,
                  blurRadius: 7,
                  offset: const Offset(0, 3),
                ),
            ],
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: Colors.white),
                const SizedBox(width: 6),
                Text(label, style: buttonTextStyle),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SinglePlaceGestureBlocker extends StatelessWidget {
  final Widget child;

  const _SinglePlaceGestureBlocker({required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onVerticalDragStart: (_) {},
      onVerticalDragUpdate: (_) {},
      onVerticalDragEnd: (_) {},
      child: child,
    );
  }
}

class _SecondaryActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _SecondaryActionButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor = isActive ? palette.primaryStrong : palette.textSecondary;

    return Material(
      color: palette.surface.withValues(alpha: 0),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Ink(
          height: 42,
          decoration: BoxDecoration(
            color: isActive
                ? palette.primarySoft
                : palette.bottomSheetSurface.withValues(
                    alpha: isDark ? 0.7 : 1,
                  ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isActive
                  ? palette.primary.withValues(alpha: 0.35)
                  : palette.bottomSheetBorder.withValues(
                      alpha: isDark ? 0.4 : 1,
                    ),
            ),
            boxShadow: [
              if (!isDark)
                BoxShadow(
                  color: palette.shadow,
                  blurRadius: 7,
                  offset: const Offset(0, 3),
                ),
            ],
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: isActive ? palette.primary : palette.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: AppTextStyles.homeBodyStrong.copyWith(
                    color: labelColor,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HospitalTagChip extends StatelessWidget {
  final String label;

  const _HospitalTagChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: palette.primarySoft.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: palette.primary.withValues(alpha: 0.12)),
      ),
      child: Text(
        '#$label',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.homeCaption.copyWith(
          color: palette.primaryStrong,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
    );
  }
}
