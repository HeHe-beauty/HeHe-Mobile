import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:geolocator/geolocator.dart';

import '../core/auth/auth_gate.dart';
import '../core/auth/auth_prompt.dart';
import '../core/auth/auth_state.dart';
import '../core/common/favorite_store.dart';
import '../data/hospital/hospital_repository.dart';
import '../dtos/common/hospital/hospital_detail_dto.dart';
import '../dtos/common/hospital/hospital_dto.dart';
import '../dtos/common/hospital/hospital_map_cluster_dto.dart';
import '../models/place_item.dart';
import '../models/subway_station.dart';
import '../repositories/subway_station_repository.dart';
import '../theme/app_palette.dart';
import '../utils/app_snackbar.dart';
import '../utils/naver_reverse_geocode.dart';
import '../widgets/cluster_count_marker.dart';
import '../widgets/map_bottom_sheet.dart';
import '../widgets/device_map_controls.dart';
import '../widgets/map_side_panel.dart';
import 'calendar_detail_screen.dart';
import 'hospital_history_screen.dart';
import 'login_required_screen.dart';
import 'my_page_screen.dart';

class DeviceMapScreen extends StatefulWidget {
  final String deviceName;
  final int? equipId;

  const DeviceMapScreen({super.key, required this.deviceName, this.equipId});

  @override
  State<DeviceMapScreen> createState() => _DeviceMapScreenState();
}

class _DeviceMapScreenState extends State<DeviceMapScreen> {
  static const double _individualMarkerZoom = 16.0;

  final DraggableScrollableController _sheetController =
      DraggableScrollableController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final SubwayStationRepository _subwayStationRepository =
      SubwayStationRepository();
  final FavoriteStore _favoriteStore = FavoriteStore.instance;

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
  bool _hasShownHospitalMapError = false;
  double _currentZoom = 13.2;
  String _currentRegionLabel = '역삼동';

  List<PlaceItem> _sheetPlaces = [];
  List<SubwayStation> _stationSuggestions = [];

  String? _selectedClusterId;
  Timer? _regionLabelDebounce;
  String? _lastRegionRequestKey;
  String? _lastResolvedRegionKey;
  int _regionRequestToken = 0;
  int _hospitalListRequestToken = 0;

  final Map<String, Future<NOverlayImage>> _iconCache = {};

  PlaceItem _visiblePlaceForAuth(PlaceItem place, bool isLoggedIn) {
    if (isLoggedIn) return place;
    return place.copyWith(isBookmarked: false);
  }

  List<PlaceItem> _visiblePlacesForAuth(
    Iterable<PlaceItem> places,
    bool isLoggedIn,
  ) {
    if (isLoggedIn) return List<PlaceItem>.from(places);
    return places
        .map((place) => place.copyWith(isBookmarked: false))
        .toList(growable: false);
  }

  @override
  void initState() {
    super.initState();
    _favoriteStore.addListener(_handleFavoriteStoreChanged);
    _searchFocusNode.addListener(_handleSearchFocusChanged);
    _loadSubwayStations();
  }

  @override
  void dispose() {
    _regionLabelDebounce?.cancel();
    _favoriteStore.removeListener(_handleFavoriteStoreChanged);
    _searchFocusNode.removeListener(_handleSearchFocusChanged);
    _searchFocusNode.dispose();
    _searchController.dispose();
    _sheetController.dispose();
    super.dispose();
  }

  void _handleFavoriteStoreChanged() {
    if (!mounted) return;

    setState(() {
      _sheetPlaces = _favoriteStore.applyFavoriteStateToAll(_sheetPlaces);
      if (_selectedPlace != null) {
        _selectedPlace = _favoriteStore.findById(_selectedPlace!.id);
      }
    });

    unawaited(_refreshMarkers());
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

    final allowed = await AuthGate.ensureLoggedInWithPrompt(
      context,
      prompt: AuthPrompts.mapMyPage,
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

    final selectedPlaceId = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => HospitalHistoryScreen(initialTabIndex: initialTabIndex),
      ),
    );

    if (selectedPlaceId == null || !mounted) return;

    await _focusOnPlaceById(selectedPlaceId);
  }

  Future<void> _openProtectedCalendarPage() async {
    _closeSidePanel();

    final allowed = await AuthGate.ensureLoggedInWithPrompt(
      context,
      prompt: AuthPrompts.calendar,
    );

    if (!allowed || !mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CalendarDetailScreen()),
    );
  }

  Future<void> _handleProtectedInquiry() async {
    await AuthGate.runWithPrompt(
      context,
      prompt: AuthPrompts.contact,
      onAuthenticated: () async {
        if (!mounted) return;

        showAppSnackBar(context, '문의하기 기능은 추후 연결 예정입니다.');
      },
    );
  }

  Future<void> _showFavoriteLoginPromptSheet() async {
    final palette = context.palette;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: palette.bottomSheetSurface,
      barrierColor: palette.modalBarrier,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              14,
              20,
              bottomPadding > 0 ? bottomPadding + 8 : 12,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 52,
                    height: 6,
                    decoration: BoxDecoration(
                      color: palette.bottomSheetBorder,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  '로그인하면 찜한 병원을 모아볼 수 있어요',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: palette.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '찜한 병원은 로그인 후 저장하고 언제든 다시 확인할 수 있어요.',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    fontWeight: FontWeight.w700,
                    color: palette.textSecondary,
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: _FavoritePromptButton(
                        label: '나중에',
                        isPrimary: false,
                        onTap: () => Navigator.pop(sheetContext),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _FavoritePromptButton(
                        label: '로그인하기',
                        isPrimary: true,
                        onTap: () async {
                          Navigator.pop(sheetContext);
                          if (!mounted) return;
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => LoginRequiredScreen(
                                title: AuthPrompts.favorites.title,
                                description: AuthPrompts.favorites.description,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
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

    final nodes = await _loadHospitalClusterNodes(controller);

    await controller.clearOverlays();

    final overlays = <NAddableOverlay<NOverlay<void>>>{};
    final selectedPlace = _selectedPlace;

    for (final node in nodes) {
      if (selectedPlace != null &&
          _shouldHideNodeBehindSelectedPlace(node, selectedPlace)) {
        continue;
      }

      final place = node.place;

      if (place != null) {
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
        continue;
      }

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
        _onTapHospitalCluster(node);
      });

      overlays.add(marker);
    }

    if (selectedPlace != null) {
      final marker = NMarker(
        id: selectedPlace.id,
        position: NLatLng(selectedPlace.latitude, selectedPlace.longitude),
        icon: await _getSingleIcon(isSelected: true),
        anchor: const NPoint(0.5, 0.5),
        isFlat: true,
      );

      marker.setOnTapListener((overlay) {
        _onTapHospitalMarker(selectedPlace);
      });

      overlays.add(marker);
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

  bool _shouldHideNodeBehindSelectedPlace(
    _HospitalMarkerNode node,
    PlaceItem selectedPlace,
  ) {
    final nodePlace = node.place;
    if (nodePlace != null) {
      return _isSamePlace(nodePlace, selectedPlace);
    }

    final nodePoint = _worldPixelFor(
      latitude: node.latitude,
      longitude: node.longitude,
      zoom: _currentZoom,
    );
    final selectedPoint = _worldPixelFor(
      latitude: selectedPlace.latitude,
      longitude: selectedPlace.longitude,
      zoom: _currentZoom,
    );

    final hideRadius = math.max(_clusterMarkerIconSize(node.count), 92.0);
    return (nodePoint - selectedPoint).distance <= hideRadius;
  }

  bool _isSamePlace(PlaceItem a, PlaceItem b) {
    final aHospitalId = a.hospitalId;
    final bHospitalId = b.hospitalId;

    if (aHospitalId != null && bHospitalId != null) {
      return aHospitalId == bHospitalId;
    }

    return a.id == b.id;
  }

  Future<List<_HospitalMarkerNode>> _loadHospitalClusterNodes(
    NaverMapController controller,
  ) async {
    try {
      final bounds = await controller.getContentBounds();
      final position = await controller.getCameraPosition();
      final mapData = await HospitalRepository.getHospitalMap(
        swLat: bounds.southWest.latitude,
        swLng: bounds.southWest.longitude,
        neLat: bounds.northEast.latitude,
        neLng: bounds.northEast.longitude,
        zoomLevel: position.zoom.round().clamp(1, 21),
        equipId: widget.equipId,
      );

      _currentZoom = position.zoom;
      _hasShownHospitalMapError = false;

      final nodes = _mergeHospitalMapItems(
        mapData.items,
        precision: mapData.precision,
        zoom: position.zoom,
      );

      final hasSingleHospitalNode = nodes.any(
        (node) => node.count == 1 && node.sources.length == 1,
      );

      if (position.zoom < _individualMarkerZoom && !hasSingleHospitalNode) {
        return nodes;
      }

      final resolvedNodes = await Future.wait(
        nodes.map(_resolveSingleHospitalMarkerNode),
      );

      return resolvedNodes;
    } catch (e) {
      if (mounted && !_hasShownHospitalMapError) {
        _hasShownHospitalMapError = true;
        showTopAppSnackBar(context, '병원 정보를 불러오지 못했어요');
      }

      return const [];
    }
  }

  Future<_HospitalMarkerNode> _resolveSingleHospitalMarkerNode(
    _HospitalMarkerNode node,
  ) async {
    if (node.count != 1 || node.sources.length != 1) {
      return node;
    }

    try {
      final hospitals = await _loadHospitalsForClusterNode(node);
      if (hospitals.length != 1) {
        return node.copyWith(place: _placeItemFromClusterNode(node));
      }

      final summaryPlace = _placeItemFromHospital(
        hospitals.first,
        latitude: node.latitude,
        longitude: node.longitude,
      );

      try {
        final detail = await HospitalRepository.getHospitalDetail(
          hospitals.first.hospitalId,
        );

        return node.copyWith(
          place: _placeItemFromHospitalDetail(
            detail,
            fallbackPlace: summaryPlace,
          ),
        );
      } catch (e) {
        return node.copyWith(place: summaryPlace);
      }
    } catch (e) {
      return node.copyWith(place: _placeItemFromClusterNode(node));
    }
  }

  Future<List<HospitalDto>> _loadHospitalsForClusterNode(
    _HospitalMarkerNode node,
  ) async {
    final byId = <int, HospitalDto>{};

    for (final source in node.sources) {
      final hospitals = await HospitalRepository.getHospitals(
        lat: source.latitude,
        lng: source.longitude,
        precision: source.precision,
        equipId: widget.equipId,
      );

      for (final hospital in hospitals) {
        byId[hospital.hospitalId] = hospital;
      }
    }

    return byId.values.toList();
  }

  Future<void> _onTapHospitalCluster(_HospitalMarkerNode node) async {
    final place = node.place;
    if (place != null) {
      await _onTapHospitalMarker(place);
      return;
    }

    _closeSidePanel();
    final requestToken = ++_hospitalListRequestToken;

    setState(() {
      _isSheetHidden = false;
      _selectedPlace = null;
      _selectedClusterId = node.id;
      _sheetPlaces = [];
    });

    if (_sheetController.isAttached) {
      await _sheetController.animateTo(
        0.18,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    }

    await _refreshMarkers();
    await _moveCameraToHospitalCluster(node, zoomOffset: 0.8, maxZoom: 15.2);

    try {
      final hospitals = await _loadHospitalsForClusterNode(node);

      if (!mounted || requestToken != _hospitalListRequestToken) return;

      setState(() {
        _sheetPlaces = hospitals
            .map(
              (hospital) => _placeItemFromHospital(
                hospital,
                latitude: node.latitude,
                longitude: node.longitude,
              ),
            )
            .toList();
      });
    } catch (e) {
      if (!mounted || requestToken != _hospitalListRequestToken) return;

      showTopAppSnackBar(context, '병원 정보를 불러오지 못했어요');
    }
  }

  Future<void> _onTapHospitalMarker(PlaceItem place) async {
    _closeSidePanel();
    final resolvedPlace = await _resolvePlaceDetail(
      place,
      showFallbackError: false,
    );

    if (!mounted) return;

    setState(() {
      _isSheetHidden = false;
      _selectedPlace = resolvedPlace;
      _selectedClusterId = null;
      _sheetPlaces = [resolvedPlace];
    });

    _expandSinglePlaceSheet();

    await _refreshMarkers();
    await _moveCameraToPlace(resolvedPlace, zoom: 16.2);
    _expandSinglePlaceSheet();
  }

  Future<void> _onTapPlaceCard(PlaceItem place) async {
    _closeSidePanel();
    final resolvedPlace = await _resolvePlaceDetail(
      place,
      showFallbackError: false,
    );

    if (!mounted) return;

    setState(() {
      _isSheetHidden = false;
      _selectedPlace = resolvedPlace;
      _selectedClusterId = null;
      _sheetPlaces = [resolvedPlace];
    });

    _expandSinglePlaceSheet();

    await _refreshMarkers();
    await _moveCameraToPlace(resolvedPlace, zoom: 16.2);
    _expandSinglePlaceSheet();
  }

  void _expandSinglePlaceSheet() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || !_sheetController.isAttached) return;

      await _sheetController.animateTo(
        0.36,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    });
  }

  Future<void> _focusOnPlaceById(String placeId) async {
    final place = _favoriteStore.findById(placeId);
    if (place == null) return;

    await _onTapPlaceCard(place);
  }

  Future<PlaceItem> _resolvePlaceDetail(
    PlaceItem place, {
    bool showFallbackError = true,
  }) async {
    final hospitalId = place.hospitalId;
    if (hospitalId == null) {
      return place;
    }

    try {
      final detail = await HospitalRepository.getHospitalDetail(hospitalId);
      return _placeItemFromHospitalDetail(detail, fallbackPlace: place);
    } catch (e) {
      if (mounted && showFallbackError) {
        showTopAppSnackBar(context, '병원 정보를 불러오지 못했어요');
      }
      return place;
    }
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
    final markerSize = isSelected
        ? ClusterCountMarker.singleSelectedSize
        : ClusterCountMarker.singleDefaultSize;

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
    final size = _clusterMarkerIconSize(count);

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

  Future<void> _moveCameraToHospitalCluster(
    _HospitalMarkerNode node, {
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
    if (!AuthState.isLoggedIn.value) {
      _showFavoriteLoginPromptSheet();
      return;
    }

    _favoriteStore.toggleFavorite(place.id);
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
            final visibleSheetPlaces = _visiblePlacesForAuth(
              _sheetPlaces,
              isLoggedIn,
            );
            final visibleSelectedPlace = _selectedPlace == null
                ? null
                : _visiblePlaceForAuth(_selectedPlace!, isLoggedIn);

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
                  places: visibleSheetPlaces,
                  selectedPlace: visibleSelectedPlace,
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
                    title: AuthPrompts.recentPlaces.title,
                    description: AuthPrompts.recentPlaces.description,
                  ),
                  onTapFavorite: () => _openProtectedHistoryPage(
                    1,
                    title: AuthPrompts.favorites.title,
                    description: AuthPrompts.favorites.description,
                  ),
                  onTapInquiry: () => _openProtectedHistoryPage(
                    2,
                    title: AuthPrompts.inquiries.title,
                    description: AuthPrompts.inquiries.description,
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

double _clusterMarkerIconSize(int count) {
  final scaledSize = 68 + (((count - 2).clamp(0, 48) / 3) * 5.0);
  return scaledSize.clamp(68.0, 128.0);
}

class _HospitalMarkerNode {
  final String id;
  final double latitude;
  final double longitude;
  final int count;
  final List<_HospitalClusterSource> sources;
  final PlaceItem? place;

  const _HospitalMarkerNode({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.count,
    required this.sources,
    this.place,
  });

  factory _HospitalMarkerNode.fromSources(
    List<_HospitalClusterSource> sources,
  ) {
    final count = sources.fold<int>(0, (sum, source) => sum + source.count);
    final weightedLat =
        sources.fold<double>(
          0,
          (sum, source) => sum + (source.latitude * source.count),
        ) /
        count;
    final weightedLng =
        sources.fold<double>(
          0,
          (sum, source) => sum + (source.longitude * source.count),
        ) /
        count;
    final id = sources.map((source) => source.id).join('|');

    return _HospitalMarkerNode(
      id: 'hospital_cluster_$id',
      latitude: weightedLat,
      longitude: weightedLng,
      count: count,
      sources: sources,
    );
  }

  _HospitalMarkerNode copyWith({PlaceItem? place}) {
    return _HospitalMarkerNode(
      id: id,
      latitude: place?.latitude ?? latitude,
      longitude: place?.longitude ?? longitude,
      count: count,
      sources: sources,
      place: place ?? this.place,
    );
  }
}

class _HospitalClusterSource {
  final String id;
  final int count;
  final double latitude;
  final double longitude;
  final int precision;

  const _HospitalClusterSource({
    required this.id,
    required this.count,
    required this.latitude,
    required this.longitude,
    required this.precision,
  });

  factory _HospitalClusterSource.fromMap(
    HospitalMapClusterDto item,
    int precision,
  ) {
    return _HospitalClusterSource(
      id: '${precision}_${item.lat}_${item.lng}_${item.count}',
      count: item.count,
      latitude: item.lat,
      longitude: item.lng,
      precision: precision,
    );
  }
}

List<_HospitalMarkerNode> _mergeHospitalMapItems(
  List<HospitalMapClusterDto> items, {
  required int precision,
  required double zoom,
}) {
  final sources = items
      .map((item) => _HospitalClusterSource.fromMap(item, precision))
      .toList();
  final groups = <List<_HospitalClusterSource>>[];

  for (final source in sources) {
    final sourcePoint = _worldPixelFor(
      latitude: source.latitude,
      longitude: source.longitude,
      zoom: zoom,
    );
    var merged = false;

    for (final group in groups) {
      final groupPoint = _weightedWorldPixelFor(group, zoom);
      final distance = (sourcePoint - groupPoint).distance;

      if (distance <= _clusterMergePixelRadiusFor(group, source)) {
        group.add(source);
        merged = true;
        break;
      }
    }

    if (!merged) {
      groups.add([source]);
    }
  }

  return groups.map(_HospitalMarkerNode.fromSources).toList();
}

Offset _weightedWorldPixelFor(
  List<_HospitalClusterSource> sources,
  double zoom,
) {
  final count = sources.fold<int>(0, (sum, source) => sum + source.count);
  final weighted = sources.fold<Offset>(Offset.zero, (sum, source) {
    return sum +
        (_worldPixelFor(
              latitude: source.latitude,
              longitude: source.longitude,
              zoom: zoom,
            ) *
            source.count.toDouble());
  });

  return weighted / count.toDouble();
}

Offset _worldPixelFor({
  required double latitude,
  required double longitude,
  required double zoom,
}) {
  final sinLatitude = math.sin(latitude * math.pi / 180).clamp(-0.9999, 0.9999);
  final scale = 256 * math.pow(2, zoom).toDouble();
  final x = ((longitude + 180) / 360) * scale;
  final y =
      (0.5 - math.log((1 + sinLatitude) / (1 - sinLatitude)) / (4 * math.pi)) *
      scale;

  return Offset(x, y);
}

double _clusterMergePixelRadiusFor(
  List<_HospitalClusterSource> group,
  _HospitalClusterSource source,
) {
  final groupCount = group.fold<int>(0, (sum, item) => sum + item.count);
  final largestCount = math.max(groupCount, source.count);

  if (largestCount >= 100) return 70;
  if (largestCount >= 10) return 62;
  return 54;
}

PlaceItem _placeItemFromHospital(
  HospitalDto hospital, {
  required double latitude,
  required double longitude,
}) {
  return PlaceItem(
    hospitalId: hospital.hospitalId,
    id: 'hospital_${hospital.hospitalId}',
    name: hospital.name,
    tags: hospital.tags,
    description: '',
    address: hospital.address,
    isBookmarked: false,
    latitude: latitude,
    longitude: longitude,
  );
}

PlaceItem _placeItemFromClusterNode(_HospitalMarkerNode node) {
  return PlaceItem(
    id: 'hospital_marker_${node.id}',
    name: '병원',
    tags: const [],
    description: '',
    address: '',
    isBookmarked: false,
    latitude: node.latitude,
    longitude: node.longitude,
  );
}

PlaceItem _placeItemFromHospitalDetail(
  HospitalDetailDto hospital, {
  required PlaceItem fallbackPlace,
}) {
  return PlaceItem(
    hospitalId: hospital.hospitalId,
    id: fallbackPlace.id,
    name: hospital.name,
    tags: hospital.tags,
    description: fallbackPlace.description,
    address: hospital.address,
    isBookmarked: fallbackPlace.isBookmarked,
    latitude: hospital.lat,
    longitude: hospital.lng,
  );
}

class _FavoritePromptButton extends StatelessWidget {
  final String label;
  final bool isPrimary;
  final VoidCallback onTap;

  const _FavoritePromptButton({
    required this.label,
    required this.isPrimary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Material(
      color: isPrimary ? palette.primarySoft : palette.bottomSheetInnerSurface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isPrimary
                  ? palette.primarySoft
                  : palette.bottomSheetBorder,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: isPrimary ? palette.primaryStrong : palette.textSecondary,
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
