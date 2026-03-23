import 'package:flutter/material.dart';
import '../models/place_item.dart';
import '../theme/app_palette.dart';

const double _kPlaceCardRadius = 24;
const double _kPlaceCardInnerRadius = 16;

class PlaceCard extends StatefulWidget {
  final PlaceItem place;
  final String distanceLabel;
  final VoidCallback onTap;
  final VoidCallback onTapBookmark;

  const PlaceCard({
    super.key,
    required this.place,
    required this.distanceLabel,
    required this.onTap,
    required this.onTapBookmark,
  });

  @override
  State<PlaceCard> createState() => _PlaceCardState();
}

class _PlaceCardState extends State<PlaceCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bookmarkController;
  late final Animation<double> _bookmarkScale;

  bool _isPressed = false;

  @override
  void initState() {
    super.initState();

    _bookmarkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );

    _bookmarkScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 1.14,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 55,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.14,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 45,
      ),
    ]).animate(_bookmarkController);
  }

  @override
  void didUpdateWidget(covariant PlaceCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!oldWidget.place.isBookmarked && widget.place.isBookmarked) {
      _bookmarkController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _bookmarkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 160;
        final cardRadius = BorderRadius.circular(_kPlaceCardRadius);
        final horizontalPadding = isCompact ? 14.0 : 16.0;
        final visibleTags = widget.place.tags.take(isCompact ? 1 : 2).toList();

        return AnimatedScale(
          scale: _isPressed ? 0.988 : 1.0,
          duration: const Duration(milliseconds: 110),
          curve: Curves.easeOut,
          child: Material(
            color: palette.surface.withValues(alpha: 0),
            child: InkWell(
              borderRadius: cardRadius,
              onTap: widget.onTap,
              onHighlightChanged: (value) {
                if (_isPressed == value) return;
                setState(() {
                  _isPressed = value;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                curve: Curves.easeOut,
                decoration: BoxDecoration(
                  color: isDark
                      ? palette.bottomSheetInnerSurface
                      : palette.surface,
                  borderRadius: cardRadius,
                  border: Border.all(
                    color: _isPressed
                        ? palette.primary.withValues(
                      alpha: isDark ? 0.28 : 0.20,
                    )
                        : isDark
                        ? palette.bottomSheetBorder.withValues(alpha: 0.42)
                        : palette.border,
                  ),
                  boxShadow: [
                    if (!isDark)
                      BoxShadow(
                        color: palette.shadow,
                        blurRadius: _isPressed ? 8 : 12,
                        offset: const Offset(0, 4),
                      ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    isCompact ? 14 : 16,
                    horizontalPadding,
                    isCompact ? 12 : 14,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.distanceLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: isCompact ? 11 : 12,
                          fontWeight: FontWeight.w700,
                          color: palette.textSecondary,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        widget.place.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: isCompact ? 15 : 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.4,
                          color: palette.textPrimary,
                          height: 1.18,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (visibleTags.isNotEmpty)
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (int i = 0; i < visibleTags.length; i++)
                              _TagChip(
                                label: visibleTags[i],
                                compact: isCompact,
                                highlighted: i == 0,
                              ),
                          ],
                        ),
                      const Spacer(),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: AnimatedBuilder(
                          animation: _bookmarkScale,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _bookmarkScale.value,
                              child: child,
                            );
                          },
                          child: _BookmarkButton(
                            isActive: widget.place.isBookmarked,
                            compact: isCompact,
                            onTap: widget.onTapBookmark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  final bool compact;
  final bool highlighted;

  const _TagChip({
    required this.label,
    required this.compact,
    required this.highlighted,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      constraints: const BoxConstraints(minHeight: 26),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 9,
        vertical: compact ? 5 : 6,
      ),
      decoration: BoxDecoration(
        color: highlighted
            ? palette.primarySoft
            : isDark
            ? palette.bottomSheetSurface
            : palette.surfaceMuted,
        borderRadius: BorderRadius.circular(_kPlaceCardInnerRadius),
        border: Border.all(
          color: highlighted
              ? palette.primary.withValues(alpha: 0.22)
              : isDark
              ? palette.bottomSheetBorder.withValues(alpha: 0.34)
              : palette.border,
        ),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: compact ? 10 : 11,
          fontWeight: FontWeight.w800,
          color: highlighted ? palette.primary : palette.textSecondary,
          height: 1,
        ),
      ),
    );
  }
}

class _BookmarkButton extends StatelessWidget {
  final bool isActive;
  final bool compact;
  final VoidCallback onTap;

  const _BookmarkButton({
    required this.isActive,
    required this.compact,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: palette.surface.withValues(alpha: 0),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Ink(
          width: compact ? 38 : 40,
          height: compact ? 38 : 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive
                ? palette.primarySoft
                : isDark
                ? palette.bottomSheetInnerSurface
                : palette.surface,
            border: Border.all(
              color: isActive
                  ? palette.primary.withValues(alpha: 0.30)
                  : isDark
                  ? palette.bottomSheetBorder.withValues(alpha: 0.34)
                  : palette.border,
            ),
          ),
          child: Icon(
            isActive ? Icons.star_rounded : Icons.star_border_rounded,
            size: compact ? 18 : 20,
            color: isActive ? palette.primary : palette.textSecondary,
          ),
        ),
      ),
    );
  }
}