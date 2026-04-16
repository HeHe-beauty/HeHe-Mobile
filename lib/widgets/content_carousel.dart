import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import '../models/content_item.dart';
import '../theme/app_palette.dart';
import 'content_card.dart';

class ContentCarousel extends StatefulWidget {
  final List<ContentItem> items;
  final ValueChanged<ContentItem>? onTapItem;

  const ContentCarousel({super.key, required this.items, this.onTapItem});

  @override
  State<ContentCarousel> createState() => _ContentCarouselState();
}

class _ContentCarouselState extends State<ContentCarousel> {
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 0;

  @override
  void didUpdateWidget(covariant ContentCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.items.isEmpty) {
      if (_currentPage != 0) {
        setState(() {
          _currentPage = 0;
        });
      }
      return;
    }

    if (_currentPage >= widget.items.length) {
      final nextPage = widget.items.length - 1;
      setState(() {
        _currentPage = nextPage;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final items = widget.items;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 102,
          child: LayoutBuilder(
            builder: (context, constraints) {
              const gap = 14.0;
              final cardWidth = constraints.maxWidth * 0.86;

              int nearestPageByCenter(ScrollMetrics metrics) {
                var nearestIndex = 0;
                var nearestDistance = double.infinity;
                final viewportCenter =
                    metrics.pixels + (metrics.viewportDimension / 2);

                for (var index = 0; index < items.length; index++) {
                  final itemCenter =
                      (index * (cardWidth + gap)) + (cardWidth / 2);
                  final distance = (viewportCenter - itemCenter).abs();

                  if (distance < nearestDistance) {
                    nearestDistance = distance;
                    nearestIndex = index;
                  }
                }

                return nearestIndex;
              }

              return NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  if (items.isEmpty) return false;

                  final visiblePage = nearestPageByCenter(notification.metrics);
                  if (visiblePage != _currentPage) {
                    setState(() {
                      _currentPage = visiblePage;
                    });
                  }

                  return false;
                },
                child: ListView.separated(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  physics: _RecommendationCarouselScrollPhysics(
                    itemCount: items.length,
                    cardWidth: cardWidth,
                    gap: gap,
                  ),
                  padding: EdgeInsets.zero,
                  itemCount: items.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: gap),
                  itemBuilder: (context, index) {
                    final item = items[index];

                    return SizedBox(
                      width: cardWidth,
                      child: ContentCard(
                        item: item,
                        onTap: () => widget.onTapItem?.call(item),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            items.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: index == _currentPage ? 28 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: index == _currentPage ? palette.primary : palette.border,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RecommendationCarouselScrollPhysics extends ScrollPhysics {
  final int itemCount;
  final double cardWidth;
  final double gap;

  const _RecommendationCarouselScrollPhysics({
    required this.itemCount,
    required this.cardWidth,
    required this.gap,
    super.parent,
  });

  @override
  _RecommendationCarouselScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return _RecommendationCarouselScrollPhysics(
      itemCount: itemCount,
      cardWidth: cardWidth,
      gap: gap,
      parent: buildParent(ancestor),
    );
  }

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    if ((velocity <= 0.0 && position.pixels <= position.minScrollExtent) ||
        (velocity >= 0.0 && position.pixels >= position.maxScrollExtent)) {
      return super.createBallisticSimulation(position, velocity);
    }

    final target = _targetPixels(position);

    if ((target - position.pixels).abs() < toleranceFor(position).distance) {
      return null;
    }

    return ScrollSpringSimulation(
      spring,
      position.pixels,
      target,
      velocity,
      tolerance: toleranceFor(position),
    );
  }

  double _targetPixels(ScrollMetrics position) {
    if (itemCount <= 1) return position.minScrollExtent;

    final itemExtent = cardWidth + gap;
    final centerInset = (position.viewportDimension - cardWidth) / 2;
    final rawIndex = (position.pixels + centerInset) / itemExtent;
    final index = rawIndex.round().clamp(0, itemCount - 1).toInt();

    if (index <= 0) return position.minScrollExtent;
    if (index >= itemCount - 1) return position.maxScrollExtent;

    final itemLeading = index * itemExtent;
    final centeredOffset = itemLeading - centerInset;

    return centeredOffset.clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
  }
}
