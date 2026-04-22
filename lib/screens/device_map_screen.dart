import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:geolocator/geolocator.dart';

import '../core/auth/auth_gate.dart';
import '../core/auth/auth_prompt.dart';
import '../core/auth/auth_state.dart';
import '../core/common/favorite_store.dart';
import '../core/map/naver_map_styles.dart';
import '../data/contact/contact_repository.dart';
import '../data/hospital/hospital_repository.dart';
import '../data/recent_view/recent_view_repository.dart';
import '../dtos/common/hospital/hospital_dto.dart';
import '../dtos/common/hospital/hospital_map_cluster_dto.dart';
import '../models/place_item.dart';
import '../models/subway_station.dart';
import '../repositories/subway_station_repository.dart';
import '../theme/app_palette.dart';
import '../utils/app_snackbar.dart';
import '../utils/naver_reverse_geocode.dart';
import '../utils/place_distance_utils.dart';
import '../utils/place_item_mappers.dart';
import '../widgets/cluster_count_marker.dart';
import '../widgets/current_location_marker.dart';
import '../widgets/device_map_controls.dart';
import '../widgets/map_bottom_sheet.dart';
import '../widgets/map_side_panel.dart';
import '../widgets/selected_hospital_marker.dart';
import '../widgets/station_line_badge.dart';
import 'calendar_detail_screen.dart';
import 'hospital_history_screen.dart';
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
    unawaited(_loadCurrentLocationIfGranted());
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

    final schedulerPhase = WidgetsBinding.instance.schedulerPhase;
    if (schedulerPhase != SchedulerPhase.idle) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _applyFavoriteStoreChange();
      });
      return;
    }

    _applyFavoriteStoreChange();
  }

  void _applyFavoriteStoreChange() {
    if (!mounted) return;

    setState(() {
      _sheetPlaces = _favoriteStore.applyFavoriteStateToAll(_sheetPlaces);
      if (_selectedPlace != null) {
        _selectedPlace = _favoriteStore.applyFavoriteState(_selectedPlace!);
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

  Future<void> _handleProtectedInquiry(PlaceItem place) async {
    await AuthGate.runWithPrompt(
      context,
      prompt: AuthPrompts.contact,
      onAuthenticated: () async {
        if (!mounted) return;

        final accessToken = AuthState.session?.accessToken;
        if (accessToken == null || accessToken.isEmpty) {
          showAppSnackBar(context, '로그인이 필요해요');
          return;
        }

        final hospitalId = place.hospitalId;
        if (hospitalId == null) {
          showAppSnackBar(context, '병원 정보를 확인하지 못했어요. 잠시 후 다시 시도해주세요.');
          return;
        }

        try {
          await ContactRepository.addCallContact(
            accessToken: accessToken,
            hospitalId: hospitalId,
          );

          if (!mounted) return;
          showAppSnackBar(context, '문의 내역에 저장했어요.');
        } catch (e) {
          if (!mounted) return;
          showAppSnackBar(context, '문의 내역을 저장하지 못했어요. 잠시 후 다시 시도해주세요.');
        }
      },
    );
  }

  Future<void> _onMapReady(NaverMapController controller) async {
    _mapController = controller;
    _isMapReady = true;
    _selectedClusterId = null;

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

    await controller.clearOverlays();

    final nodes = await _loadHospitalClusterNodes(controller);

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
            label: place.name,
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
        icon: await _getSingleIcon(isSelected: true, label: selectedPlace.name),
        anchor: const NPoint(0.5, 1),
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

      final summaryPlace = placeItemFromHospital(
        hospitals.first,
        latitude: node.latitude,
        longitude: node.longitude,
      );

      try {
        final detail = await HospitalRepository.getHospitalDetail(
          hospitals.first.hospitalId,
        );

        return node.copyWith(
          place: placeItemFromHospitalDetail(
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
              (hospital) => placeItemFromHospital(
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
    unawaited(_recordRecentView(resolvedPlace));

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
    unawaited(_recordRecentView(resolvedPlace));

    _expandSinglePlaceSheet();

    await _refreshMarkers();
    await _moveCameraToPlace(resolvedPlace, zoom: 16.2);
    _expandSinglePlaceSheet();
  }

  Future<void> _recordRecentView(PlaceItem place) async {
    final accessToken = AuthState.session?.accessToken;
    final hospitalId = place.hospitalId;
    if (accessToken == null || accessToken.isEmpty || hospitalId == null) {
      return;
    }

    try {
      await RecentViewRepository.addRecentView(
        accessToken: accessToken,
        hospitalId: hospitalId,
      );
    } catch (e) {
      debugPrint('recent view register error: $e');
    }
  }

  String _distanceLabelForPlace(PlaceItem place) {
    return formatPlaceDistanceLabel(
      place: place,
      currentLatitude: _currentLocation?.latitude,
      currentLongitude: _currentLocation?.longitude,
    );
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
      _currentLocation = NLatLng(position.latitude, position.longitude);
    });
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
      return placeItemFromHospitalDetail(detail, fallbackPlace: place);
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

  Future<NOverlayImage> _getSingleIcon({
    required bool isSelected,
    String? label,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeKey = isDark ? 'dark' : 'light';
    final resolvedLabel = (label == null || label.trim().isEmpty)
        ? '병원'
        : label.trim();
    final key = isSelected
        ? 'single_${themeKey}_selected_$resolvedLabel'
        : 'single_${themeKey}_default';

    if (isSelected) {
      return _iconCache.putIfAbsent(
        key,
        () => NOverlayImage.fromWidget(
          context: context,
          size: const Size(
            SelectedHospitalMarker.width,
            SelectedHospitalMarker.height,
          ),
          widget: SelectedHospitalMarker(name: resolvedLabel),
        ),
      );
    }

    const markerSize = ClusterCountMarker.singleDefaultSize;

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
        widget: const CurrentLocationMarker(),
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
    unawaited(_toggleBookmarkAfterLogin(place));
  }

  Future<void> _toggleBookmarkAfterLogin(PlaceItem place) async {
    final allowed = await AuthGate.ensureLoggedInWithPrompt(
      context,
      prompt: AuthPrompts.favorites,
    );

    if (!allowed || !mounted) return;

    final accessToken = AuthState.session?.accessToken;
    if (accessToken == null || accessToken.isEmpty) {
      showTopAppSnackBar(context, '로그인이 필요해요');
      return;
    }

    if (place.hospitalId == null) {
      showTopAppSnackBar(context, '병원 정보를 확인하지 못했어요. 잠시 후 다시 시도해주세요.');
      return;
    }

    try {
      await _favoriteStore.setBookmark(
        accessToken: accessToken,
        place: place,
        enabled: !_favoriteStore.isFavorite(place.id),
      );
    } catch (e) {
      if (!mounted) return;
      showTopAppSnackBar(context, '찜하기를 변경하지 못했어요. 잠시 후 다시 시도해주세요.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mapStyleId = isDark
        ? NaverMapStyles.darkDynamicStyleId
        : NaverMapStyles.lightDynamicStyleId;

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
                    options: NaverMapViewOptions(
                      initialCameraPosition: const NCameraPosition(
                        target: NLatLng(37.4979, 127.0276),
                        zoom: 13.2,
                      ),
                      scaleBarEnable: false,
                      indoorEnable: true,
                      locationButtonEnable: false,
                      customStyleId: mapStyleId,
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
                  distanceLabelForPlace: _distanceLabelForPlace,
                  onDismissSingle: _clearSelection,
                ),
                if (_isSidePanelOpen)
                  DeviceMapSidePanelScrim(onTap: _closeSidePanel),
                MapSidePanel(
                  isOpen: _isSidePanelOpen,
                  topInset: 76,
                  userName: isLoggedIn ? '노명욱님' : '로그인 / 회원가입',
                  isLoggedIn: isLoggedIn,
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
                            color: palette.primaryStrong,
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
                                    .map((line) => StationLineBadge(line: line))
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

  final nodes = groups.map(_HospitalMarkerNode.fromSources).toList();
  return _mergeOverlappingHospitalMarkerNodes(nodes, zoom: zoom);
}

List<_HospitalMarkerNode> _mergeOverlappingHospitalMarkerNodes(
  List<_HospitalMarkerNode> nodes, {
  required double zoom,
}) {
  if (nodes.length <= 1) return nodes;

  var mergedNodes = nodes;
  var didMerge = true;

  while (didMerge) {
    didMerge = false;
    final nextNodes = <_HospitalMarkerNode>[];
    final usedIndexes = <int>{};

    for (var i = 0; i < mergedNodes.length; i++) {
      if (usedIndexes.contains(i)) continue;

      var mergedSources = <_HospitalClusterSource>[...mergedNodes[i].sources];
      usedIndexes.add(i);

      var keepSearching = true;
      while (keepSearching) {
        keepSearching = false;
        final currentNode = _HospitalMarkerNode.fromSources(mergedSources);

        for (var j = 0; j < mergedNodes.length; j++) {
          if (usedIndexes.contains(j)) continue;

          if (_shouldMergeVisualClusterNodes(
            currentNode,
            mergedNodes[j],
            zoom: zoom,
          )) {
            mergedSources = [...mergedSources, ...mergedNodes[j].sources];
            usedIndexes.add(j);
            didMerge = true;
            keepSearching = true;
          }
        }
      }

      nextNodes.add(_HospitalMarkerNode.fromSources(mergedSources));
    }

    mergedNodes = nextNodes;
  }

  return mergedNodes;
}

bool _shouldMergeVisualClusterNodes(
  _HospitalMarkerNode a,
  _HospitalMarkerNode b, {
  required double zoom,
}) {
  final aPoint = _worldPixelFor(
    latitude: a.latitude,
    longitude: a.longitude,
    zoom: zoom,
  );
  final bPoint = _worldPixelFor(
    latitude: b.latitude,
    longitude: b.longitude,
    zoom: zoom,
  );
  final distance = (aPoint - bPoint).distance;

  return distance <= _clusterVisualMergeDistance(a, b);
}

double _clusterVisualMergeDistance(
  _HospitalMarkerNode a,
  _HospitalMarkerNode b,
) {
  final aSize = a.count <= 1
      ? ClusterCountMarker.singleDefaultSize
      : _clusterMarkerIconSize(a.count);
  final bSize = b.count <= 1
      ? ClusterCountMarker.singleDefaultSize
      : _clusterMarkerIconSize(b.count);

  return ((aSize + bSize) / 2) + 12;
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
