import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:geolocator/geolocator.dart';

import '../core/auth/auth_gate.dart';
import '../core/auth/auth_state.dart';
import '../models/place_cluster_node.dart';
import '../models/place_item.dart';
import '../models/subway_station.dart';
import '../repositories/subway_station_repository.dart';
import '../theme/app_palette.dart';
import '../utils/naver_reverse_geocode.dart';
import '../utils/place_cluster_builder.dart';
import '../widgets/cluster_count_marker.dart';
import '../widgets/map_bottom_sheet.dart';
import '../widgets/device_map_controls.dart';
import '../widgets/map_side_panel.dart';
import 'calendar_detail_screen.dart';
import 'hospital_history_screen.dart';
import 'my_page_screen.dart';

class DeviceMapScreen extends StatefulWidget {
  final String deviceName;

  const DeviceMapScreen({super.key, required this.deviceName});

  @override
  State<DeviceMapScreen> createState() => _DeviceMapScreenState();
}

class _DeviceMapScreenState extends State<DeviceMapScreen> {
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final SubwayStationRepository _subwayStationRepository =
      SubwayStationRepository();

  NaverMapController? _mapController;
  NLatLng? _currentLocation;
  PlaceItem? _selectedPlace;
  SubwayStation? _selectedStation;
  bool _isSidePanelOpen = false;
  bool _isMapReady = false;
  bool _isMovingToMyLocation = false;
  bool _isSheetHidden = false;
  bool _isSuggestionVisible = false;
  bool _isStationDataReady = false;
  double _currentZoom = 13.2;
  String _currentRegionLabel = '역삼동';

  late List<PlaceItem> _places = _buildMockHospitals();
  List<PlaceItem> _sheetPlaces = [];
  List<SubwayStation> _stationSuggestions = [];

  String? _selectedClusterId;
  Timer? _regionLabelDebounce;
  String? _lastRegionRequestKey;
  String? _lastResolvedRegionKey;
  int _regionRequestToken = 0;

  final Map<String, Future<NOverlayImage>> _iconCache = {};

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(_handleSearchFocusChanged);
    _loadSubwayStations();
  }

  @override
  void dispose() {
    _regionLabelDebounce?.cancel();
    _searchFocusNode.removeListener(_handleSearchFocusChanged);
    _searchFocusNode.dispose();
    _searchController.dispose();
    _sheetController.dispose();
    super.dispose();
  }

  List<PlaceItem> _buildMockHospitals() {
    const baseLat = 37.4979;
    const baseLng = 127.0276;
    final random = Random(7);

    return List.generate(48, (index) {
      final latOffset = (random.nextDouble() - 0.5) * 0.014;
      final lngOffset = (random.nextDouble() - 0.5) * 0.016;

      return PlaceItem(
        id: 'hospital_$index',
        name: '테스트 병원 ${index + 1}',
        tags: index.isEven ? ['#피부', '#토닝'] : ['#레이저', '#남성시술'],
        description: '임시 데이터로 넣은 병원입니다.',
        address: '서울 강남구 테헤란로 ${101 + index}',
        isBookmarked: index % 3 == 0,
        latitude: baseLat + latOffset,
        longitude: baseLng + lngOffset,
      );
    });
  }

  void _toggleSidePanel() {
    _hideStationSuggestions();
    setState(() {
      _isSidePanelOpen = !_isSidePanelOpen;
    });
  }

  Future<void> _loadSubwayStations() async {
    await _subwayStationRepository.loadStations();
    if (!mounted) return;
    setState(() {
      _isStationDataReady = true;
    });
  }

  void _closeSidePanel() {
    if (!_isSidePanelOpen) return;
    _hideStationSuggestions(unfocus: false);
    setState(() {
      _isSidePanelOpen = false;
    });
  }

  void _handleSearchFocusChanged() {
    if (!_searchFocusNode.hasFocus) {
      if (!_isSuggestionVisible) return;
      setState(() {
        _isSuggestionVisible = false;
      });
      return;
    }

    if (_stationSuggestions.isEmpty) return;

    setState(() {
      _isSuggestionVisible = true;
    });
  }

  void _hideStationSuggestions({bool unfocus = true}) {
    if (unfocus) {
      _searchFocusNode.unfocus();
    }

    if (!_isSuggestionVisible && _stationSuggestions.isEmpty) {
      return;
    }

    setState(() {
      _isSuggestionVisible = false;
      _stationSuggestions = [];
    });
  }

  Future<void> _onSearchChanged(String value) async {
    final query = value.trim();
    if (!_isStationDataReady) {
      return;
    }

    if (query.isEmpty) {
      setState(() {
        _selectedStation = null;
        _stationSuggestions = [];
        _isSuggestionVisible = false;
      });
      return;
    }

    final suggestions = await _subwayStationRepository.searchStations(query);
    if (!mounted || _searchController.text.trim() != query) {
      return;
    }

    final selectedStation = _selectedStation;
    final isKeepingSelection =
        selectedStation != null && selectedStation.name == query;

    setState(() {
      _selectedStation = isKeepingSelection ? selectedStation : null;
      _stationSuggestions = suggestions;
      _isSuggestionVisible =
          suggestions.isNotEmpty && _searchFocusNode.hasFocus;
    });
  }

  Future<void> _onSubmitStationSearch([String? rawQuery]) async {
    final query = (rawQuery ?? _searchController.text).trim();
    if (query.isEmpty) {
      _hideStationSuggestions();
      return;
    }

    if (!_isStationDataReady) {
      await _loadSubwayStations();
      if (!_isStationDataReady) {
        return;
      }
    }

    final station =
        _selectedStation ?? await _subwayStationRepository.findBestMatch(query);
    if (station == null) {
      _hideStationSuggestions();
      return;
    }

    _searchController.value = TextEditingValue(
      text: station.name,
      selection: TextSelection.collapsed(offset: station.name.length),
    );

    setState(() {
      _selectedStation = station;
      _isSuggestionVisible = false;
      _stationSuggestions = [];
    });

    _searchFocusNode.unfocus();
    await _moveCameraToStation(station);
  }

  Future<void> _onTapStationSuggestion(SubwayStation station) async {
    _searchController.value = TextEditingValue(
      text: station.name,
      selection: TextSelection.collapsed(offset: station.name.length),
    );

    setState(() {
      _selectedStation = station;
      _isSuggestionVisible = false;
      _stationSuggestions = [];
    });

    await _moveCameraToStation(station);
  }

  Future<void> _openProtectedMyPage() async {
    _closeSidePanel();

    final allowed = await AuthGate.ensureLoggedIn(
      context,
      title: '로그인이 필요해요',
      description: '마이페이지는 로그인 후\n내 정보와 활동을 확인할 수 있어요.',
    );

    if (!allowed || !mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MyPageScreen()),
    );
  }

  Future<void> _openProtectedHistoryPage(
    int initialTabIndex, {
    required String title,
    required String description,
  }) async {
    _closeSidePanel();

    final allowed = await AuthGate.ensureLoggedIn(
      context,
      title: title,
      description: description,
    );

    if (!allowed || !mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HospitalHistoryScreen(initialTabIndex: initialTabIndex),
      ),
    );
  }

  Future<void> _openProtectedCalendarPage() async {
    _closeSidePanel();

    final allowed = await AuthGate.ensureLoggedIn(
      context,
      title: '로그인이 필요해요',
      description: '내 캘린더는 로그인 후\n일정 저장과 관리를 할 수 있어요.',
    );

    if (!allowed || !mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CalendarDetailScreen()),
    );
  }

  Future<void> _handleProtectedInquiry() async {
    await AuthGate.run(
      context,
      title: '문의하려면 로그인이 필요해요',
      description: '문의 내역 확인과 상담 연결은\n로그인 후 이용할 수 있어요.',
      onAuthenticated: () async {
        if (!mounted) return;

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('문의하기 기능은 추후 연결 예정입니다.')));
      },
    );
  }

  Future<void> _onMapReady(NaverMapController controller) async {
    _mapController = controller;
    _isMapReady = true;

    final position = await controller.getCameraPosition();
    _currentZoom = position.zoom;

    await _refreshMarkers();
    _scheduleRegionLabelUpdate(position.target, force: true);
  }

  Future<void> _onCameraIdle() async {
    final controller = _mapController;
    if (controller == null) return;

    final position = await controller.getCameraPosition();
    _currentZoom = position.zoom;

    await _refreshMarkers();
    _scheduleRegionLabelUpdate(position.target);
  }

  Future<void> _refreshMarkers() async {
    final controller = _mapController;
    if (!_isMapReady || controller == null) return;

    final nodes = buildPlaceClusterNodes(_places, _currentZoom);

    await controller.clearOverlays();

    final overlays = <NAddableOverlay<NOverlay<void>>>{};

    for (final node in nodes) {
      if (node.isCluster) {
        final marker = NMarker(
          id: node.id,
          position: NLatLng(node.latitude, node.longitude),
          icon: await _getClusterIcon(
            node.count,
            isSelected: _selectedClusterId == node.id,
          ),
          anchor: const NPoint(0.5, 0.5),
          isFlat: true,
        );

        marker.setOnTapListener((overlay) {
          _onTapCluster(node);
        });

        overlays.add(marker);
      } else {
        final place = node.places.first;

        final marker = NMarker(
          id: place.id,
          position: NLatLng(place.latitude, place.longitude),
          icon: await _getSingleIcon(
            isSelected: _selectedPlace?.id == place.id,
          ),
          anchor: const NPoint(0.5, 0.5),
          isFlat: true,
        );

        marker.setOnTapListener((overlay) {
          _onTapHospitalMarker(place);
        });

        overlays.add(marker);
      }
    }

    final currentLocation = _currentLocation;
    if (currentLocation != null) {
      overlays.add(
        NMarker(
          id: 'current_location_marker',
          position: currentLocation,
          icon: await _getCurrentLocationIcon(),
          anchor: const NPoint(0.5, 0.5),
          isFlat: true,
        ),
      );
    }

    await controller.addOverlayAll(overlays);
  }

  Future<void> _onTapCluster(PlaceClusterNode node) async {
    _closeSidePanel();

    setState(() {
      _isSheetHidden = false;
      _selectedPlace = null;
      _selectedClusterId = node.id;
      _sheetPlaces = List.of(node.places);
    });

    if (_sheetController.isAttached) {
      await _sheetController.animateTo(
        0.18,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    }

    await _refreshMarkers();
    await _moveCameraToCluster(node, zoomOffset: 0.8, maxZoom: 15.2);
  }

  Future<void> _onTapHospitalMarker(PlaceItem place) async {
    _closeSidePanel();

    setState(() {
      _isSheetHidden = false;
      _selectedPlace = place;
      _selectedClusterId = null;
      _sheetPlaces = [place];
    });

    await _refreshMarkers();
    await _moveCameraToPlace(place, zoom: 16.2);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || !_sheetController.isAttached) return;

      await _sheetController.animateTo(
        0.36,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    });
  }

  Future<void> _onTapPlaceCard(PlaceItem place) async {
    _closeSidePanel();

    setState(() {
      _isSheetHidden = false;
      _selectedPlace = place;
      _selectedClusterId = null;
      _sheetPlaces = [place];
    });

    await _refreshMarkers();
    await _moveCameraToPlace(place, zoom: 16.2);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || !_sheetController.isAttached) return;

      await _sheetController.animateTo(
        0.36,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    });
  }

  Future<void> _clearSelection() async {
    FocusScope.of(context).unfocus();
    _hideStationSuggestions(unfocus: false);

    if (mounted) {
      setState(() {
        _isSheetHidden = true;
      });
    }

    await WidgetsBinding.instance.endOfFrame;

    if (mounted && _sheetController.isAttached) {
      await _sheetController.animateTo(
        0.01,
        duration: const Duration(milliseconds: 170),
        curve: Curves.easeOutCubic,
      );
    }

    if (!mounted) return;

    setState(() {
      _selectedPlace = null;
      _selectedClusterId = null;
      _isSidePanelOpen = false;
      _sheetPlaces = [];
      _isSheetHidden = false;
    });

    await _refreshMarkers();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || !_sheetController.isAttached) return;

      await _sheetController.animateTo(
        0.14,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
      );
    });

    final controller = _mapController;
    if (controller != null) {
      final update = NCameraUpdate.withParams(
        zoom: _currentZoom > 15.5 ? 15.5 : _currentZoom,
      );

      update.setAnimation(
        animation: NCameraAnimation.easing,
        duration: const Duration(milliseconds: 260),
      );

      await controller.updateCamera(update);
    }
  }

  Future<void> _moveToMyLocation() async {
    if (_isMovingToMyLocation) return;

    setState(() {
      _isMovingToMyLocation = true;
    });

    try {
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final target = NLatLng(position.latitude, position.longitude);

      if (mounted) {
        setState(() {
          _currentLocation = target;
        });
      } else {
        _currentLocation = target;
      }

      await _refreshMarkers();

      await _mapController?.updateCamera(
        NCameraUpdate.withParams(target: target, zoom: 15.5),
      );

      _scheduleRegionLabelUpdate(target, force: true);
    } finally {
      if (mounted) {
        setState(() {
          _isMovingToMyLocation = false;
        });
      }
    }
  }

  Future<void> _moveCameraToStation(SubwayStation station) async {
    final controller = _mapController;
    if (controller == null) return;

    final targetZoom = _currentZoom < 15.2 ? 15.2 : _currentZoom;
    final target = NLatLng(station.latitude, station.longitude);
    final update = NCameraUpdate.withParams(target: target, zoom: targetZoom);

    update.setAnimation(
      animation: NCameraAnimation.easing,
      duration: const Duration(milliseconds: 420),
    );

    await controller.updateCamera(update);
    _scheduleRegionLabelUpdate(target, force: true);
  }

  Future<NOverlayImage> _getSingleIcon({required bool isSelected}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeKey = isDark ? 'dark' : 'light';
    final key = 'single_${themeKey}_${isSelected ? 'selected' : 'default'}';
    final markerSize = isSelected ? 30.0 : 24.0;

    return _iconCache.putIfAbsent(
      key,
      () => NOverlayImage.fromWidget(
        context: context,
        size: Size(markerSize, markerSize),
        widget: ClusterCountMarker(
          count: 1,
          isSelected: isSelected,
          isSingle: true,
        ),
      ),
    );
  }

  Future<NOverlayImage> _getCurrentLocationIcon() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeKey = isDark ? 'dark' : 'light';
    const key = 'current_location_marker';

    return _iconCache.putIfAbsent(
      '${key}_$themeKey',
      () => NOverlayImage.fromWidget(
        context: context,
        size: const Size(34, 34),
        widget: const _CurrentLocationMarker(),
      ),
    );
  }

  void _scheduleRegionLabelUpdate(NLatLng target, {bool force = false}) {
    final requestKey = _regionRequestKeyFor(target);
    if (!force &&
        (requestKey == _lastRegionRequestKey ||
            requestKey == _lastResolvedRegionKey)) {
      return;
    }

    _lastRegionRequestKey = requestKey;
    _regionLabelDebounce?.cancel();
    _regionLabelDebounce = Timer(
      Duration(milliseconds: force ? 80 : 320),
      () => _resolveRegionLabel(target, requestKey),
    );
  }

  Future<void> _resolveRegionLabel(NLatLng target, String requestKey) async {
    final requestToken = ++_regionRequestToken;

    final label = await NaverReverseGeocode.resolveRegionLabel(
      latitude: target.latitude,
      longitude: target.longitude,
    );

    if (!mounted || requestToken != _regionRequestToken || label == null) {
      return;
    }

    _lastResolvedRegionKey = requestKey;
    if (_currentRegionLabel == label) return;

    setState(() {
      _currentRegionLabel = label;
    });
  }

  String _regionRequestKeyFor(NLatLng target) {
    final lat = target.latitude.toStringAsFixed(4);
    final lng = target.longitude.toStringAsFixed(4);
    return '$lat:$lng';
  }

  Future<NOverlayImage> _getClusterIcon(int count, {required bool isSelected}) {
    final size = count >= 100 ? 78.0 : (count >= 10 ? 68.0 : 60.0);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeKey = isDark ? 'dark' : 'light';
    final key =
        'cluster_${themeKey}_${count}_${isSelected ? 'selected' : 'default'}';

    return _iconCache.putIfAbsent(
      key,
      () => NOverlayImage.fromWidget(
        context: context,
        size: Size(size, size),
        widget: ClusterCountMarker(
          count: count,
          isSelected: isSelected,
          isSingle: false,
        ),
      ),
    );
  }

  Future<void> _moveCameraToPlace(PlaceItem place, {double zoom = 16.2}) async {
    final controller = _mapController;
    if (controller == null) return;

    final targetZoom = _currentZoom < zoom ? zoom : _currentZoom;

    final update = NCameraUpdate.withParams(
      target: NLatLng(place.latitude, place.longitude),
      zoom: targetZoom,
    );

    update.setAnimation(
      animation: NCameraAnimation.easing,
      duration: const Duration(milliseconds: 450),
    );

    update.setPivot(const NPoint(0.5, 0.34));

    await controller.updateCamera(update);
  }

  Future<void> _moveCameraToCluster(
    PlaceClusterNode node, {
    double zoomOffset = 0.8,
    double maxZoom = 15.2,
  }) async {
    final controller = _mapController;
    if (controller == null) return;

    final candidateZoom = _currentZoom + zoomOffset;
    final upperBound = _currentZoom > maxZoom ? _currentZoom : maxZoom;
    final nextZoom = candidateZoom.clamp(_currentZoom, upperBound);

    final update = NCameraUpdate.withParams(
      target: NLatLng(node.latitude, node.longitude),
      zoom: nextZoom,
    );

    update.setAnimation(
      animation: NCameraAnimation.easing,
      duration: const Duration(milliseconds: 350),
    );

    update.setPivot(const NPoint(0.5, 0.38));

    await controller.updateCamera(update);
  }

  void _toggleBookmark(PlaceItem place) {
    setState(() {
      _places = _places.map((item) {
        if (item.id != place.id) return item;
        return item.copyWith(isBookmarked: !item.isBookmarked);
      }).toList();

      _sheetPlaces = _sheetPlaces.map((item) {
        if (item.id != place.id) return item;
        return item.copyWith(isBookmarked: !item.isBookmarked);
      }).toList();

      if (_selectedPlace?.id == place.id) {
        _selectedPlace = _selectedPlace!.copyWith(
          isBookmarked: !_selectedPlace!.isBookmarked,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Scaffold(
      backgroundColor: palette.bg,
      body: SafeArea(
        bottom: false,
        child: ValueListenableBuilder<bool>(
          valueListenable: AuthState.isLoggedIn,
          builder: (context, isLoggedIn, _) {
            return Stack(
              children: [
                Positioned.fill(
                  child: NaverMap(
                    options: const NaverMapViewOptions(
                      initialCameraPosition: NCameraPosition(
                        target: NLatLng(37.4979, 127.0276),
                        zoom: 13.2,
                      ),
                      scaleBarEnable: false,
                      indoorEnable: true,
                      locationButtonEnable: false,
                    ),
                    onMapReady: _onMapReady,
                    onMapTapped: (mapPoint, latLng) {
                      _hideStationSuggestions();
                      _clearSelection();
                    },
                    onCameraIdle: _onCameraIdle,
                  ),
                ),
                _buildTopBar(),
                if (_isSuggestionVisible && _stationSuggestions.isNotEmpty)
                  _buildStationSuggestions(),
                Positioned(
                  right: 18,
                  bottom: 118,
                  child: DeviceMapMyLocationButton(
                    isLoading: _isMovingToMyLocation,
                    onTap: _moveToMyLocation,
                  ),
                ),
                MapBottomSheet(
                  controller: _sheetController,
                  regionLabel: _currentRegionLabel,
                  places: _sheetPlaces,
                  selectedPlace: _selectedPlace,
                  isHidden: _isSheetHidden,
                  onTapPlaceCard: _onTapPlaceCard,
                  onTapInquiry: _handleProtectedInquiry,
                  onTapBookmark: _toggleBookmark,
                  onDismissSingle: _clearSelection,
                ),
                if (_isSidePanelOpen)
                  DeviceMapSidePanelScrim(onTap: _closeSidePanel),
                MapSidePanel(
                  isOpen: _isSidePanelOpen,
                  topInset: 76,
                  userName: isLoggedIn ? '노명욱님' : '로그인 / 회원가입',
                  isLoggedIn: isLoggedIn,
                  onClose: _closeSidePanel,
                  onTapMyPage: _openProtectedMyPage,
                  onTapRecent: () => _openProtectedHistoryPage(
                    0,
                    title: '로그인이 필요해요',
                    description: '최근 본 병원은 로그인 후\n기록과 관리를 할 수 있어요.',
                  ),
                  onTapFavorite: () => _openProtectedHistoryPage(
                    1,
                    title: '로그인이 필요해요',
                    description: '찜한 병원은 로그인 후 저장하고\n언제든 다시 확인할 수 있어요.',
                  ),
                  onTapInquiry: () => _openProtectedHistoryPage(
                    2,
                    title: '로그인이 필요해요',
                    description: '문의한 병원 내역은 로그인 후\n확인할 수 있어요.',
                  ),
                  onTapCalendar: _openProtectedCalendarPage,
                  onTapNotice: () {},
                  onTapContact: () {},
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return DeviceMapTopBar(
      searchController: _searchController,
      searchFocusNode: _searchFocusNode,
      onSearchChanged: _onSearchChanged,
      onSearchSubmitted: _onSubmitStationSearch,
      onTapBack: () => Navigator.pop(context),
      onTapMenu: _toggleSidePanel,
    );
  }

  Widget _buildStationSuggestions() {
    final palette = context.palette;

    return Positioned(
      top: 82,
      left: 84,
      right: 84,
      child: Material(
        color: palette.surface.withValues(alpha: 0),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: palette.border),
            boxShadow: [
              BoxShadow(
                color: palette.shadow,
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 296),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              shrinkWrap: true,
              itemCount: _stationSuggestions.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                indent: 16,
                endIndent: 16,
                color: palette.border.withValues(alpha: 0.7),
              ),
              itemBuilder: (context, index) {
                final station = _stationSuggestions[index];
                return InkWell(
                  onTap: () => _onTapStationSuggestion(station),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: palette.primarySoft,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.subway_rounded,
                            size: 20,
                            color: palette.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                station.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: palette.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: station.lines
                                    .map(
                                      (line) => _StationLineBadge(line: line),
                                    )
                                    .toList(),
                              ),
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
        ),
      ),
    );
  }
}

class _CurrentLocationMarker extends StatelessWidget {
  const _CurrentLocationMarker();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return SizedBox(
      width: 34,
      height: 34,
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: palette.primary.withValues(alpha: 0.14),
                border: Border.all(
                  color: palette.primary.withValues(alpha: 0.26),
                  width: 1.25,
                ),
              ),
            ),
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: palette.primary,
                boxShadow: [
                  BoxShadow(
                    color: palette.shadow.withValues(alpha: 0.18),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: palette.surface,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StationLineBadge extends StatelessWidget {
  final String line;

  const _StationLineBadge({required this.line});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.primarySoft,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: palette.border.withValues(alpha: 0.85)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Text(
          line,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: palette.primaryStrong,
            height: 1.1,
          ),
        ),
      ),
    );
  }
}
