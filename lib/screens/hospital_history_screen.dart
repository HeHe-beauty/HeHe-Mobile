import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../core/auth/auth_state.dart';
import '../core/common/favorite_store.dart';
import '../data/contact/contact_repository.dart';
import '../data/hospital/hospital_repository.dart';
import '../data/recent_view/recent_view_repository.dart';
import '../models/place_item.dart';
import '../theme/app_palette.dart';
import '../theme/app_text_styles.dart';
import '../utils/app_snackbar.dart';
import '../utils/place_distance_utils.dart';
import '../utils/place_item_mappers.dart';
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

  List<PlaceItem> recentPlaces = const [];
  List<PlaceItem> inquiryPlaces = const [];
  double? _currentLatitude;
  double? _currentLongitude;
  bool _isLoadingRecentViews = false;
  bool _isLoadingContacts = false;

  @override
  void initState() {
    super.initState();
    selectedTabIndex = widget.initialTabIndex;
    _loadCurrentLocationIfGranted();
    if (selectedTabIndex == 0) {
      _loadRecentPlaces();
    } else if (selectedTabIndex == 1) {
      _loadFavoritePlaces();
    } else if (selectedTabIndex == 2) {
      _loadInquiryPlaces();
    }
  }

  Future<void> _loadRecentPlaces() async {
    final accessToken = AuthState.session?.accessToken;
    if (accessToken == null || accessToken.isEmpty) {
      setState(() {
        recentPlaces = const [];
      });
      return;
    }

    setState(() {
      _isLoadingRecentViews = true;
    });

    try {
      final recentViews = await RecentViewRepository.getRecentViews(
        accessToken: accessToken,
      );

      if (!mounted) return;

      final places = await Future.wait(
        recentViews.map((recentView) async {
          final fallbackPlace = placeItemFromRecentView(recentView);

          try {
            final detail = await HospitalRepository.getHospitalDetail(
              recentView.hospitalId,
            );
            return placeItemFromHospitalDetail(
              detail,
              fallbackPlace: fallbackPlace,
            );
          } catch (_) {
            return fallbackPlace;
          }
        }),
      );

      if (!mounted) return;

      setState(() {
        recentPlaces = places;
      });
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(context, '최근 본 병원 목록을 불러오지 못했어요. 잠시 후 다시 시도해주세요.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingRecentViews = false;
        });
      }
    }
  }

  Future<void> _loadFavoritePlaces() async {
    final accessToken = AuthState.session?.accessToken;
    if (accessToken == null || accessToken.isEmpty) {
      _favoriteStore.clear();
      return;
    }

    try {
      await _favoriteStore.loadBookmarks(accessToken: accessToken);
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(context, '찜한 병원 목록을 불러오지 못했어요. 잠시 후 다시 시도해주세요.');
    }
  }

  Future<void> _loadInquiryPlaces() async {
    final accessToken = AuthState.session?.accessToken;
    if (accessToken == null || accessToken.isEmpty) {
      setState(() {
        inquiryPlaces = const [];
      });
      return;
    }

    setState(() {
      _isLoadingContacts = true;
    });

    try {
      final contacts = await ContactRepository.getContacts(
        accessToken: accessToken,
      );

      if (!mounted) return;

      final places = await Future.wait(
        contacts.map((contact) async {
          final fallbackPlace = placeItemFromContact(contact);

          try {
            final detail = await HospitalRepository.getHospitalDetail(
              contact.hospitalId,
            );
            return placeItemFromHospitalDetail(
              detail,
              fallbackPlace: fallbackPlace,
            );
          } catch (_) {
            return fallbackPlace;
          }
        }),
      );

      if (!mounted) return;

      setState(() {
        inquiryPlaces = places;
      });
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(context, '문의 내역을 불러오지 못했어요. 잠시 후 다시 시도해주세요.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingContacts = false;
        });
      }
    }
  }

  Future<void> _loadCurrentLocationIfGranted() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }

    final position =
        await Geolocator.getLastKnownPosition() ??
        await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        );

    if (!mounted) return;

    setState(() {
      _currentLatitude = position.latitude;
      _currentLongitude = position.longitude;
    });
  }

  String _distanceLabelForPlace(PlaceItem place) {
    return formatPlaceDistanceLabel(
      place: place,
      currentLatitude: _currentLatitude,
      currentLongitude: _currentLongitude,
    );
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

  Future<void> _toggleBookmark(PlaceItem place) async {
    final accessToken = AuthState.session?.accessToken;
    if (accessToken == null || accessToken.isEmpty) {
      showAppSnackBar(context, '로그인이 필요해요');
      return;
    }

    if (place.hospitalId == null) {
      showAppSnackBar(context, '병원 정보를 확인하지 못했어요. 잠시 후 다시 시도해주세요.');
      return;
    }

    final nextValue = !_favoriteStore.isFavorite(place.id);

    try {
      await _favoriteStore.setBookmark(
        accessToken: accessToken,
        place: place,
        enabled: nextValue,
      );

      if (!mounted) return;

      setState(() {
        recentPlaces = recentPlaces.map((item) {
          if (item.id != place.id) return item;
          return item.copyWith(isBookmarked: nextValue);
        }).toList();

        inquiryPlaces = inquiryPlaces.map((item) {
          if (item.id != place.id) return item;
          return item.copyWith(isBookmarked: nextValue);
        }).toList();
      });
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(context, '찜하기를 변경하지 못했어요. 잠시 후 다시 시도해주세요.');
    }
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
                            if (i == 0) {
                              _loadRecentPlaces();
                            } else if (i == 1) {
                              _loadFavoritePlaces();
                            } else if (i == 2) {
                              _loadInquiryPlaces();
                            }
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
                      style: AppTextStyles.homeSectionTitle.copyWith(
                        fontSize: 18,
                        color: palette.textPrimary,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: _favoriteStore.isLoading && selectedTabIndex == 1
                      ? const Center(child: CircularProgressIndicator())
                      : _isLoadingRecentViews && selectedTabIndex == 0
                      ? const Center(child: CircularProgressIndicator())
                      : _isLoadingContacts && selectedTabIndex == 2
                      ? const Center(child: CircularProgressIndicator())
                      : places.isEmpty
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
                              distanceLabel: _distanceLabelForPlace(place),
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
            style: AppTextStyles.homeBodyStrong.copyWith(
              fontWeight: FontWeight.w600,
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
        style: AppTextStyles.homeBody.copyWith(
          fontSize: 13,
          color: palette.textSecondary,
        ),
      ),
    );
  }
}
