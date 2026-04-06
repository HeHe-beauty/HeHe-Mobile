import 'package:flutter/material.dart';
import '../core/auth/auth_prompt.dart';
import '../core/auth/auth_gate.dart';
import '../core/auth/auth_state.dart';
import '../models/calendar_schedule.dart';
import '../models/content_item.dart';
import '../theme/app_palette.dart';
import '../data/calendar_schedule_store.dart';
import '../data/home_catalog.dart';
import '../utils/calendar_schedule_utils.dart';
import '../widgets/calendar_card.dart';
import '../widgets/content_carousel.dart';
import '../widgets/device_tile.dart';
import '../widgets/header_bar.dart';
import '../widgets/section_card.dart';
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

class _HomeScreenState extends State<HomeScreen> {
  static const int _maxVisibleReservations = 3;

  Future<void> _showAddScheduleSheet(BuildContext context) async {
    final result = await showVisitScheduleBottomSheet(
      context,
      initialDateTime: DateTime.now(),
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
  Widget build(BuildContext context) {
    final palette = context.palette;
    final devices = HomeCatalog.devices;
    final contents = HomeCatalog.contents;

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
            ? buildNearestReservationTitle(nearestSchedule)
            : '다가오는 예약이 없어요';
        final reservationSubtitle = !isLoggedIn
            ? '로그인 후 내 캘린더를 확인할 수 있어요'
            : nearestSchedule != null
            ? formatCompactScheduleDate(nearestSchedule.dateTime)
            : '오늘 기준으로 예정된 예약이 없어요';
        final todayLabel = formatTodayReferenceLabel();
        final reservationItems = upcomingSchedules
            .skip(nearestSchedule != null ? 1 : 0)
            .map(
              (schedule) => CalendarCardReservationItem(
                title: schedule.hospitalName,
                dateLabel: formatCompactScheduleDate(schedule.dateTime),
                relativeLabel: formatRelativeFromToday(schedule.dateTime),
                onTap: () => _openReservationDetail(context, schedule),
              ),
            )
            .toList();
        final reservationSectionLabel =
            isLoggedIn && reservationItems.isNotEmpty ? '이후 예약 일정' : null;

        return Scaffold(
          backgroundColor: palette.bg,
          body: Column(
            children: [
              HeaderBar(
                title: '슬로건',
                isLoggedIn: isLoggedIn,
                onTapProfile: () => _openMyPage(context),
                onTapSettings: () => _openSettings(context),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _PrimaryDeviceCard(
                              title: devices[0].title,
                              icon: devices[0].icon,
                              onTap: () =>
                                  _openDeviceMap(context, devices[0].title),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              children: [
                                DeviceTile(
                                  title: devices[1].title,
                                  icon: devices[1].icon,
                                  height: 73,
                                  onTap: () {},
                                ),
                                const SizedBox(height: 14),
                                DeviceTile(
                                  title: devices[2].title,
                                  icon: devices[2].icon,
                                  height: 73,
                                  onTap: () {},
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
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: palette.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 18),
                      CalendarCard(
                        title: reservationTitle,
                        subtitle: reservationSubtitle,
                        todayLabel: todayLabel,
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
                      const SizedBox(height: 18),
                      SectionCard(
                        title: '추천 콘텐츠',
                        child: ContentCarousel(
                          items: contents,
                          onTapItem: (item) =>
                              _openContentDetail(context, item),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PrimaryDeviceCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _PrimaryDeviceCard({
    required this.title,
    required this.icon,
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
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Align(
              alignment: const Alignment(0, -0.10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(icon, color: Colors.white, size: 15),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    title,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
