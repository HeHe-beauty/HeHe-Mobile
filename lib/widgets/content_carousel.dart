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
  late final PageController _pageController;
  int _currentPage = 0;

  static const int _itemsPerPage = 2;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<List<ContentItem>> get _pages {
    final pages = <List<ContentItem>>[];
    for (int i = 0; i < widget.items.length; i += _itemsPerPage) {
      final end = (i + _itemsPerPage < widget.items.length)
          ? i + _itemsPerPage
          : widget.items.length;
      pages.add(widget.items.sublist(i, end));
    }
    return pages;
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final pages = _pages;

    return Column(
      children: [
        SizedBox(
          height: 152,
          child: PageView.builder(
            controller: _pageController,
            itemCount: pages.length,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, pageIndex) {
              final pageItems = pages[pageIndex];

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: ContentCard(
                        item: pageItems[0],
                        onTap: () => widget.onTapItem?.call(pageItems[0]),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: pageItems.length > 1
                          ? ContentCard(
                              item: pageItems[1],
                              onTap: () => widget.onTapItem?.call(pageItems[1]),
                            )
                          : const SizedBox(),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            pages.length,
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
