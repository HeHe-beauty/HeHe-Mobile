import 'package:flutter/material.dart';
import '../models/place_item.dart';
import '../theme/app_palette.dart';
import '../widgets/place_card.dart';

class HospitalHistoryScreen extends StatefulWidget {
  final int initialTabIndex;

  const HospitalHistoryScreen({
    super.key,
    this.initialTabIndex = 0,
  });

  @override
  State<HospitalHistoryScreen> createState() => _HospitalHistoryScreenState();
}

class _HospitalHistoryScreenState extends State<HospitalHistoryScreen> {
  late int selectedTabIndex;

  final List<String> tabs = const ['최근 본', '찜한', '문의한'];

  late List<PlaceItem> recentPlaces = [
    const PlaceItem(
      id: 'recent_xx',
      name: 'XX 의원',
      tags: ['#피부', '#레이저'],
      description: '후기 많고 접근성 좋은 곳',
      address: '임시 주소 1',
      isBookmarked: true,
      latitude: 37.4979,
      longitude: 127.0276,
    ),
    const PlaceItem(
      id: 'recent_yy',
      name: 'YY 클리닉',
      tags: ['#피부', '#토닝'],
      description: '상담 만족도가 높은 편',
      address: '임시 주소 2',
      isBookmarked: true,
      latitude: 37.4993,
      longitude: 127.0310,
    ),
    const PlaceItem(
      id: 'recent_ab',
      name: 'AB 피부과',
      tags: ['#여드름', '#모공'],
      description: '기기 다양, 예약 편리',
      address: '임시 주소 3',
      isBookmarked: false,
      latitude: 37.4958,
      longitude: 127.0305,
    ),
  ];

  late List<PlaceItem> favoritePlaces = [
    const PlaceItem(
      id: 'favorite_xx',
      name: 'XX 의원',
      tags: ['#피부', '#레이저'],
      description: '후기 많고 접근성 좋은 곳',
      address: '임시 주소 4',
      isBookmarked: true,
      latitude: 37.4979,
      longitude: 127.0276,
    ),
    const PlaceItem(
      id: 'favorite_ef',
      name: 'EF 클리닉',
      tags: ['#리프팅', '#탄력'],
      description: '후기 반응 좋고 위치 편리',
      address: '임시 주소 5',
      isBookmarked: true,
      latitude: 37.4948,
      longitude: 127.0288,
    ),
  ];

  late List<PlaceItem> inquiryPlaces = [
    const PlaceItem(
      id: 'inquiry_gh',
      name: 'GH 피부과',
      tags: ['#색소', '#토닝'],
      description: '설명 자세하고 빠른 예약 가능',
      address: '임시 주소 6',
      isBookmarked: false,
      latitude: 37.4966,
      longitude: 127.0249,
    ),
    const PlaceItem(
      id: 'inquiry_cd',
      name: 'CD 의원',
      tags: ['#제모', '#남성시술'],
      description: '가성비 괜찮고 재방문율 높음',
      address: '임시 주소 7',
      isBookmarked: false,
      latitude: 37.5002,
      longitude: 127.0257,
    ),
  ];

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
        return favoritePlaces;
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
    setState(() {
      recentPlaces = recentPlaces.map((item) {
        if (item.id != place.id) return item;
        return item.copyWith(isBookmarked: !item.isBookmarked);
      }).toList();

      favoritePlaces = favoritePlaces.map((item) {
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${place.name} 상세보기는 추후 연결 예정입니다.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final places = currentPlaces;

    return Scaffold(
      backgroundColor: palette.bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
              child: Row(
                children: [
                  _CircleButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                ],
              ),
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
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Material(
      color: palette.surface,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: palette.border),
            boxShadow: [
              BoxShadow(
                color: palette.shadow,
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Icon(
            icon,
            size: 24,
            color: palette.icon,
          ),
        ),
      ),
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