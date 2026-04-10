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
          height: 152,
          child: LayoutBuilder(
            builder: (context, constraints) {
              const gap = 14.0;
              final cardWidth = (constraints.maxWidth - (gap * 2)) / 2.5;
              final itemExtent = cardWidth + gap;

              return NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  if (items.isEmpty) return false;
                  final maxScrollExtent = notification.metrics.maxScrollExtent;
                  final progress = maxScrollExtent <= 0
                      ? 0.0
                      : (notification.metrics.pixels / maxScrollExtent).clamp(
                          0.0,
                          1.0,
                        );
                  final nextPage = (progress * (items.length - 1))
                      .round()
                      .clamp(0, items.length - 1);
                  if (nextPage != _currentPage) {
                    setState(() {
                      _currentPage = nextPage;
                    });
                  }
                  return false;
                },
                child: ListView.separated(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.zero,
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(width: gap),
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
