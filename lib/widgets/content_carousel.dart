import 'package:flutter/material.dart';
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
          height: 174,
          child: LayoutBuilder(
            builder: (context, constraints) {
              const gap = 14.0;
              final cardWidth = constraints.maxWidth * 0.86;

              int nearestPage(ScrollMetrics metrics) {
                var nearestIndex = 0;
                var nearestDistance = double.infinity;

                for (var index = 0; index < items.length; index++) {
                  final targetOffset = _targetOffsetFor(
                    index: index,
                    itemCount: items.length,
                    cardWidth: cardWidth,
                    gap: gap,
                    viewportWidth: constraints.maxWidth,
                    maxScrollExtent: metrics.maxScrollExtent,
                  );
                  final distance = (metrics.pixels - targetOffset).abs();

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

                  final nextPage = nearestPage(notification.metrics);
                  if (nextPage != _currentPage) {
                    setState(() {
                      _currentPage = nextPage;
                    });
                  }

                  if (notification is ScrollEndNotification) {
                    final targetOffset = _targetOffsetFor(
                      index: nextPage,
                      itemCount: items.length,
                      cardWidth: cardWidth,
                      gap: gap,
                      viewportWidth: constraints.maxWidth,
                      maxScrollExtent: notification.metrics.maxScrollExtent,
                    );

                    if ((notification.metrics.pixels - targetOffset).abs() >
                            0.5 &&
                        _scrollController.hasClients) {
                      _scrollController.animateTo(
                        targetOffset,
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                      );
                    }
                  }

                  return false;
                },
                child: ListView.separated(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
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

  double _targetOffsetFor({
    required int index,
    required int itemCount,
    required double cardWidth,
    required double gap,
    required double viewportWidth,
    required double maxScrollExtent,
  }) {
    if (index <= 0 || itemCount <= 1) return 0;
    if (index >= itemCount - 1) return maxScrollExtent;

    final itemLeading = index * (cardWidth + gap);
    final centeredOffset = itemLeading - ((viewportWidth - cardWidth) / 2);

    return centeredOffset.clamp(0.0, maxScrollExtent);
  }
}
