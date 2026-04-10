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
  List<EquipDto> _devices = [];

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

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final contents = HomeCatalog.contents;
    final d0 = _device(0);
    final d1 = _device(1);
    final d2 = _device(2);
    final d0Name = _deviceName(d0, '젠틀맥스 프로');
    final d1Name = _deviceName(d1, '아포지');
    final d2Name = _deviceName(d2, '클라리티2');
    final d0Asset = _deviceImageAsset(d0Name);
    final d1Asset = _deviceImageAsset(d1Name);
    final d2Asset = _deviceImageAsset(d2Name);

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
          body: SingleChildScrollView(
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
                              title: d0Name,
                              imageAsset: d0Asset,
                              onTap: () => _openDeviceMap(context, d0Name),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              children: [
                                DeviceTile(
                                  title: d1Name,
                                  imageAsset: d1Asset,
                                  height: 73,
                                  onTap: () => _openDeviceMap(context, d1Name),
                                ),
                                const SizedBox(height: 14),
                                DeviceTile(
                                  title: d2Name,
                                  imageAsset: d2Asset,
                                  height: 73,
                                  onTap: () => _openDeviceMap(context, d2Name),
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
                        reservationSectionLabel: reservationSectionLabel,
                        reservations: reservationItems,
                        isLoginRequired: !isLoggedIn,
                        showAddButton: isLoggedIn,
                        maxVisibleItems: _maxVisibleReservations,
                        onTapCalendar: () => _openCalendarIfLoggedIn(context),
                        onTapCard: !isLoggedIn
                            ? () => _openReservationLoginRequired(context)
                            : null,
                        onTapSummary: nearestSchedule != null && isLoggedIn
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
                        onTapItem: (item) => _openContentDetail(context, item),
                      ),
                      const SizedBox(height: 14),
                    ],
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
  final VoidCallback onTap;

  const _PrimaryDeviceCard({
    required this.title,
    required this.imageAsset,
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
                  left: 18,
                  top: 22,
                  right: 92,
                  child: Text(
                    title,
                    maxLines: 2,
                    textAlign: TextAlign.left,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                    ),
                  ),
                ),
                Positioned(
                  right: -14,
                  bottom: -24,
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _deviceName(EquipDto? device, String fallback) {
  return (device?.displayName ?? fallback).trim();
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
