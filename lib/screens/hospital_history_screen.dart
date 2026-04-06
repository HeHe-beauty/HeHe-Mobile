import 'package:flutter/material.dart';
import '../core/common/favorite_store.dart';
import '../data/mock_place_data.dart';
import '../models/place_item.dart';
import '../theme/app_palette.dart';
import '../widgets/place_card.dart';
import '../widgets/screen_header.dart';

class HospitalHistoryScreen extends StatefulWidget {
  final int initialTabIndex;

  const HospitalHistoryScreen({super.key, this.initialTabIndex = 0});

  @override
  State<HospitalHistoryScreen> createState() => _HospitalHistoryScreenState();
}

class _HospitalHistoryScreenState extends State<HospitalHistoryScreen> {
  final FavoriteStore _favoriteStore = FavoriteStore.instance;
  late int selectedTabIndex;

  final List<String> tabs = const ['최근 본', '찜한', '문의한'];

  late List<PlaceItem> recentPlaces = MockPlaceData.recentPlaces();

  late List<PlaceItem> inquiryPlaces = MockPlaceData.inquiryPlaces();

  @override
  void initState() {
    super.initState();
    selectedTabIndex = widget.initialTabIndex;
  }

  List<PlaceItem> get currentPlaces {
    switch (selectedTabIndex) {
      case 0:
        return recentPlaces;
      case 1:
        return _favoriteStore.favoritePlaces;
      case 2:
        return inquiryPlaces;
      default:
        return recentPlaces;
    }
  }

  String get currentTitle {
    switch (selectedTabIndex) {
      case 0:
        return '최근 본 병원';
      case 1:
        return '찜한 병원';
      case 2:
        return '문의한 병원';
      default:
        return '병원 리스트';
    }
  }

  void _toggleBookmark(PlaceItem place) {
    if (_favoriteStore.containsPlace(place.id)) {
      _favoriteStore.toggleFavorite(place.id);
      return;
    }

    setState(() {
      recentPlaces = recentPlaces.map((item) {
        if (item.id != place.id) return item;
        return item.copyWith(isBookmarked: !item.isBookmarked);
      }).toList();

      inquiryPlaces = inquiryPlaces.map((item) {
        if (item.id != place.id) return item;
        return item.copyWith(isBookmarked: !item.isBookmarked);
      }).toList();
    });
  }

  void _openPlaceDetail(PlaceItem place) {
    Navigator.pop(context, place.id);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return AnimatedBuilder(
      animation: _favoriteStore,
      builder: (context, _) {
        final places = currentPlaces;

        return Scaffold(
          backgroundColor: palette.bg,
          body: SafeArea(
            child: Column(
              children: [
                ScreenHeader(
                  title: '',
                  onTapBack: () => Navigator.pop(context),
                  trailing: const SizedBox.shrink(),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
                  child: Row(
                    children: [
                      for (int i = 0; i < tabs.length; i++) ...[
                        _TabChip(
                          label: tabs[i],
                          isSelected: selectedTabIndex == i,
                          onTap: () {
                            setState(() {
                              selectedTabIndex = i;
                            });
                          },
                        ),
                        if (i != tabs.length - 1) const SizedBox(width: 10),
                      ],
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      currentTitle,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: palette.textPrimary,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: places.isEmpty
                      ? const _EmptyState()
                      : GridView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                          itemCount: places.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: 0.72,
                              ),
                          itemBuilder: (context, index) {
                            final place = places[index];

                            return PlaceCard(
                              place: place,
                              distanceLabel: '여기서 1.2km',
                              onTap: () => _openPlaceDetail(place),
                              onTapBookmark: () => _toggleBookmark(place),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TabChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Material(
      color: isSelected ? palette.primarySoft : palette.surface,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: isSelected ? palette.primaryStrong : palette.border,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: isSelected ? palette.primary : palette.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Center(
      child: Text(
        '아직 내역이 없어요',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: palette.textSecondary,
        ),
      ),
    );
  }
}
