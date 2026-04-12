import 'package:flutter/material.dart';
import 'package:hehe/common/helper/date_refresh_mixin.dart';
import 'package:hehe/common/utils/app_time.dart';
import '../core/auth/auth_prompt.dart';
import '../core/auth/auth_gate.dart';
import '../core/auth/auth_state.dart';
import '../models/calendar_schedule.dart';
import '../models/content_item.dart';
import '../theme/app_palette.dart';
import '../data/calendar_schedule_store.dart';
import '../data/home_catalog.dart';
import '../data/equipment/equip_repository.dart';
import '../dtos/common/equipment/equip_dto.dart';
import '../utils/calendar_schedule_utils.dart';
import '../widgets/calendar_card.dart';
import '../widgets/content_carousel.dart';
import '../widgets/device_tile.dart';
import '../widgets/header_bar.dart';
import '../widgets/visit_schedule_bottom_sheet.dart';
import 'calendar_detail_screen.dart';
import 'content_detail_screen.dart';
import 'device_map_screen.dart';
import 'settings_screen.dart';
import 'my_page_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver, DateRefreshMixin {
  static const int _maxVisibleReservations = 2;
  static const double _deviceTooltipWidth = 244;
  List<EquipDto> _devices = [];
  final GlobalKey _homeStackKey = GlobalKey();
  final GlobalKey _gentleInfoKey = GlobalKey();
  final GlobalKey _apogeeInfoKey = GlobalKey();
  final GlobalKey _clarityInfoKey = GlobalKey();
  String? _activeDeviceInfoId;
  _DeviceInfo? _activeDeviceInfo;
  Offset? _deviceTooltipOffset;

  EquipDto? _device(int index) {
    if (index >= _devices.length) return null;
    return _devices[index];
  }

  Future<void> _showAddScheduleSheet(BuildContext context) async {
    final result = await showVisitScheduleBottomSheet(
      context,
      initialDateTime: AppTime.now(),
      title: '병원 방문 일정을 등록할까요?',
    );

    if (result == null) return;

    CalendarScheduleStore.upsertFromResult(result);
    setState(() {});
  }

  Future<void> _openCalendarIfLoggedIn(BuildContext context) async {
    final allowed = await AuthGate.ensureLoggedInWithPrompt(
      context,
      prompt: AuthPrompts.calendar,
    );

    if (!allowed || !context.mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CalendarDetailScreen()),
    );
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _openReservationDetail(
    BuildContext context,
    CalendarSchedule schedule,
  ) async {
    final allowed = await AuthGate.ensureLoggedInWithPrompt(
      context,
      prompt: AuthPrompts.calendar,
    );

    if (!allowed || !context.mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CalendarDetailScreen(initialScheduleId: schedule.id),
      ),
    );
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _openReservationLoginRequired(BuildContext context) {
    return AuthGate.ensureLoggedInWithPrompt(
      context,
      prompt: AuthPrompts.reservationOverview,
    );
  }

  void _openContentDetail(BuildContext context, ContentItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ContentDetailScreen(item: item)),
    );
  }

  void _openSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
  }

  void _openDeviceMap(BuildContext context, String deviceName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DeviceMapScreen(deviceName: deviceName),
      ),
    );
  }

  Future<void> _openMyPage(BuildContext context) async {
    final isLoggedIn = AuthState.isLoggedIn.value;

    if (!isLoggedIn) {
      final allowed = await AuthGate.ensureLoggedInWithPrompt(
        context,
        prompt: AuthPrompts.myPage,
      );

      if (!allowed || !context.mounted) return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MyPageScreen()),
    );
  }

  @override
  void onDateChanged() {
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  Future<void> _loadDevices() async {
    try {
      final devices = await EquipRepository.getEquips();

      if (!mounted) return;

      setState(() {
        _devices = devices;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _devices = [];
      });
    }
  }

  void _hideDeviceTooltip() {
    if (_activeDeviceInfoId == null) return;

    setState(() {
      _activeDeviceInfoId = null;
      _activeDeviceInfo = null;
      _deviceTooltipOffset = null;
    });
  }

  void _toggleDeviceTooltip(String id, GlobalKey iconKey, _DeviceInfo info) {
    if (_activeDeviceInfoId == id) {
      _hideDeviceTooltip();
      return;
    }

    final stackContext = _homeStackKey.currentContext;
    final iconContext = iconKey.currentContext;
    if (stackContext == null || iconContext == null) return;

    final stackBox = stackContext.findRenderObject() as RenderBox?;
    final iconBox = iconContext.findRenderObject() as RenderBox?;
    if (stackBox == null || iconBox == null) return;

    final iconOffset = stackBox.globalToLocal(
      iconBox.localToGlobal(Offset.zero),
    );
    final centeredLeft =
        iconOffset.dx + (iconBox.size.width / 2) - (_deviceTooltipWidth / 2);
    final left = centeredLeft.clamp(
      12.0,
      stackBox.size.width - _deviceTooltipWidth - 12,
    );

    setState(() {
      _activeDeviceInfoId = id;
      _activeDeviceInfo = info;
      _deviceTooltipOffset = Offset(
        left,
        iconOffset.dy + iconBox.size.height + 8,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final contents = HomeCatalog.contents;
    final d0 = _device(0);
    final d1 = _device(1);
    final d2 = _device(2);
    final d0Name = _deviceName(d0, '젠틀맥스 프로');
    final d0Label = _gentleMaxLabel(d0Name);
    final d1Name = _deviceName(d1, '아포지');
    final d2Name = _deviceName(d2, '클라리티2');
    final d0Asset = _deviceImageAsset(d0Name);

    return ValueListenableBuilder<bool>(
      valueListenable: AuthState.isLoggedIn,
      builder: (context, isLoggedIn, _) {
        final upcomingSchedules = isLoggedIn
            ? upcomingSchedulesFromToday(
                CalendarScheduleStore.snapshot().values.expand(
                  (items) => items,
                ),
              )
            : const <CalendarSchedule>[];
        final nearestSchedule = upcomingSchedules.isNotEmpty
            ? upcomingSchedules.first
            : null;
        final reservationTitle = !isLoggedIn
            ? '로그인이 필요해요'
            : nearestSchedule != null
            ? '${nearestSchedule.hospitalName} 방문'
            : '다가오는 예약이 없어요';
        final reservationDday = !isLoggedIn
            ? null
            : nearestSchedule != null
            ? formatDDay(nearestSchedule.dateTime)
            : null;
        final reservationSubtitle = !isLoggedIn
            ? null
            : nearestSchedule != null
            ? formatCompactScheduleDate(nearestSchedule.dateTime)
            : '오늘 기준으로 예정된 예약이 없어요';
        final reservationItems = upcomingSchedules
            .skip(nearestSchedule != null ? 1 : 0)
            .map(
              (schedule) => CalendarCardReservationItem(
                title: schedule.hospitalName,
                dateLabel: formatCompactScheduleDate(schedule.dateTime),
                dDayLabel: formatDDay(schedule.dateTime),
                onTap: () => _openReservationDetail(context, schedule),
              ),
            )
            .toList();
        final reservationSectionLabel =
            isLoggedIn && reservationItems.isNotEmpty ? '이후 예약 일정' : null;

        return Scaffold(
          backgroundColor: palette.bg,
          body: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _hideDeviceTooltip,
            child: Stack(
              key: _homeStackKey,
              children: [
                NotificationListener<ScrollStartNotification>(
                  onNotification: (_) {
                    _hideDeviceTooltip();
                    return false;
                  },
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        HeaderBar(
                          title: '시술 꿀팁부터 병원 찾기까지 관리는 HeHe에서',
                          isLoggedIn: isLoggedIn,
                          onTapProfile: () => _openMyPage(context),
                          onTapSettings: () => _openSettings(context),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: _PrimaryDeviceCard(
                                      title: d0Label,
                                      imageAsset: d0Asset,
                                      infoIcon: _DeviceInfoButton(
                                        key: _gentleInfoKey,
                                        onTap: () => _toggleDeviceTooltip(
                                          'gentle',
                                          _gentleInfoKey,
                                          const _DeviceInfo(
                                            title: '젠틀맥스 프로플러스',
                                            body:
                                                '뿌리 깊은 털이 고민인 분, 돈은 들어도 확실하고 안 아픈 게 최고라면?',
                                          ),
                                        ),
                                      ),
                                      onTap: () =>
                                          _openDeviceMap(context, d0Name),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      children: [
                                        DeviceTile(
                                          title: d1Name,
                                          height: 73,
                                          infoIcon: _DeviceInfoButton(
                                            key: _apogeeInfoKey,
                                            onTap: () => _toggleDeviceTooltip(
                                              'apogee',
                                              _apogeeInfoKey,
                                              const _DeviceInfo(
                                                title: '아포지 (엘리트 플러스)',
                                                body:
                                                    '얇은 털까지 깔끔하게! 효과적이면서도 가성비 좋은 선택을 원하는 분',
                                              ),
                                            ),
                                          ),
                                          onTap: () =>
                                              _openDeviceMap(context, d1Name),
                                        ),
                                        const SizedBox(height: 14),
                                        DeviceTile(
                                          title: d2Name,
                                          height: 73,
                                          infoIcon: _DeviceInfoButton(
                                            key: _clarityInfoKey,
                                            onTap: () => _toggleDeviceTooltip(
                                              'clarity',
                                              _clarityInfoKey,
                                              const _DeviceInfo(
                                                title: '클라리티 2',
                                                body:
                                                    '피부가 예민해 걱정인 분, 바쁜 일상 속 빠른 제모로 시간을 아끼고 싶다면',
                                              ),
                                            ),
                                          ),
                                          onTap: () =>
                                              _openDeviceMap(context, d2Name),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                '💡 기기를 선택하면 주변 병원 위치를 확인할 수 있어요',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: palette.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 18),
                              CalendarCard(
                                title: reservationTitle,
                                dDayLabel: reservationDday,
                                subtitle: reservationSubtitle,
                                reservationSectionLabel:
                                    reservationSectionLabel,
                                reservations: reservationItems,
                                isLoginRequired: !isLoggedIn,
                                showAddButton: isLoggedIn,
                                maxVisibleItems: _maxVisibleReservations,
                                onTapCalendar: () =>
                                    _openCalendarIfLoggedIn(context),
                                onTapCard: !isLoggedIn
                                    ? () =>
                                          _openReservationLoginRequired(context)
                                    : null,
                                onTapSummary:
                                    nearestSchedule != null && isLoggedIn
                                    ? () => _openReservationDetail(
                                        context,
                                        nearestSchedule,
                                      )
                                    : null,
                                onTapStart: () async {
                                  final allowed =
                                      await AuthGate.ensureLoggedInWithPrompt(
                                        context,
                                        prompt: AuthPrompts.calendarAdd,
                                      );

                                  if (!allowed || !context.mounted) return;

                                  await _showAddScheduleSheet(context);
                                },
                              ),
                              const SizedBox(height: 24),
                              Text(
                                '추천 콘텐츠',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.2,
                                  color: palette.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 14),
                              ContentCarousel(
                                items: contents,
                                onTapItem: (item) =>
                                    _openContentDetail(context, item),
                              ),
                              const SizedBox(height: 14),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_activeDeviceInfo != null && _deviceTooltipOffset != null)
                  Positioned(
                    left: _deviceTooltipOffset!.dx,
                    top: _deviceTooltipOffset!.dy,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {},
                      child: _DeviceInfoBubble(
                        width: _deviceTooltipWidth,
                        info: _activeDeviceInfo!,
                      ),
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

class _PrimaryDeviceCard extends StatelessWidget {
  final String title;
  final String imageAsset;
  final Widget? infoIcon;
  final VoidCallback onTap;

  const _PrimaryDeviceCard({
    required this.title,
    required this.imageAsset,
    this.infoIcon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Ink(
          height: 160,
          decoration: BoxDecoration(
            color: palette.primary,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: palette.primary.withValues(alpha: 0.14),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Stack(
              children: [
                Positioned(
                  right: -14,
                  bottom: -24,
                  child: IgnorePointer(
                    child: SizedBox(
                      width: 214,
                      height: 160,
                      child: Image.asset(
                        imageAsset,
                        fit: BoxFit.contain,
                        alignment: Alignment.bottomRight,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 18,
                  top: 22,
                  right: 12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _primaryDeviceTitleFirstLine(title),
                        maxLines: 1,
                        textAlign: TextAlign.left,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          height: 1.1,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _primaryDeviceTitleSecondLine(title),
                            maxLines: 1,
                            textAlign: TextAlign.left,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              height: 1.1,
                            ),
                          ),
                          if (infoIcon != null) ...[
                            const SizedBox(width: 5),
                            infoIcon!,
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DeviceInfo {
  final String title;
  final String body;

  const _DeviceInfo({required this.title, required this.body});
}

class _DeviceInfoButton extends StatelessWidget {
  final VoidCallback onTap;

  const _DeviceInfoButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 22,
        height: 22,
        alignment: Alignment.center,
        child: Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: palette.surface.withValues(alpha: 0.74),
            border: Border.all(color: palette.border),
          ),
          child: Center(
            child: Text(
              'i',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                height: 1,
                color: palette.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DeviceInfoBubble extends StatelessWidget {
  final double width;
  final _DeviceInfo info;

  const _DeviceInfoBubble({required this.width, required this.info});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Material(
      color: Colors.transparent,
      child: Container(
        width: width,
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: palette.border),
          boxShadow: [
            BoxShadow(
              color: palette.shadow,
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              info.title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: palette.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              info.body,
              style: TextStyle(
                fontSize: 11,
                height: 1.45,
                fontWeight: FontWeight.w600,
                color: palette.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _primaryDeviceTitleFirstLine(String title) {
  final lines = title.split('\n');
  return lines.first;
}

String _primaryDeviceTitleSecondLine(String title) {
  final lines = title.split('\n');
  if (lines.length < 2) return '';
  return lines.sublist(1).join(' ');
}

String _deviceName(EquipDto? device, String fallback) {
  return (device?.displayName ?? fallback).trim();
}

String _gentleMaxLabel(String deviceName) {
  if (deviceName.contains('젠틀맥스')) {
    return '젠틀맥스\n프로';
  }
  return deviceName;
}

String _deviceImageAsset(String deviceName) {
  if (deviceName.contains('젠틀맥스')) {
    return 'assets/images/gentlemax_pro_plus.png';
  }
  if (deviceName.contains('아포지')) {
    return 'assets/images/apogee_plus.png';
  }
  if (deviceName.contains('클라리티')) {
    return 'assets/images/clarity2.png';
  }
  return 'assets/images/logo.png';
}
