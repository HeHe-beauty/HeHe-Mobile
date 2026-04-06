import 'package:flutter/material.dart';
import '../core/auth/auth_gate.dart';
import '../core/auth/auth_state.dart';
import '../models/content_item.dart';
import '../models/device_item.dart';
import '../theme/app_palette.dart';
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

  List<DeviceItem> _devices() => const [
    DeviceItem(title: '젠틀맥스 프로', icon: Icons.auto_awesome_rounded),
    DeviceItem(title: '아포지', icon: Icons.bolt_rounded),
    DeviceItem(title: '클라리티', icon: Icons.blur_circular_rounded),
  ];

  List<ContentItem> _contents() => const [
    ContentItem(
      title: '생활 루틴 체크리스트',
      body:
          '시술이나 관리 전후에는 거창한 준비보다 기본 루틴을 점검하는 게 더 중요할 때가 많아요.\n\n수면, 수분, 염분, 면도 여부처럼 사소해 보이는 요소들이 실제 컨디션과 만족도에 영향을 줄 수 있어요.\n\n방문 전에는 내 상태를 짧게라도 체크해두면 훨씬 덜 흔들리고, 상담도 더 또렷하게 받을 수 있어요.',
      icon: Icons.checklist_rounded,
      author: '서비스명',
    ),
    ContentItem(
      title: '증상 기록으로 패턴 찾기',
      body:
          '한 번의 느낌만으로는 내 피부 반응이나 회복 패턴을 알기 어려워요.\n\n간단한 기록이라도 쌓이면 어떤 시점에 예민해지는지, 어떤 관리 후에 상태가 괜찮았는지를 보게 돼요.\n\n결국 기록은 정보를 모으는 게 아니라 다음 선택을 덜 불안하게 만드는 도구예요.',
      icon: Icons.insights_rounded,
      author: '서비스명',
    ),
    ContentItem(
      title: '병원 방문 전 준비',
      body:
          '병원을 방문할 때는 막연히 가기보다 내가 궁금한 점을 먼저 정리해두는 게 좋아요.\n\n가격, 주기, 통증, 사후관리처럼 꼭 확인해야 할 질문을 미리 적어두면 상담을 더 효율적으로 받을 수 있어요.\n\n짧게라도 기준을 정해두면 방문 이후 비교도 쉬워져요.',
      icon: Icons.local_hospital_rounded,
      author: '서비스명',
    ),
  ];

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
    final allowed = await AuthGate.ensureLoggedIn(
      context,
      title: '로그인이 필요해요',
      description: '내 캘린더는 로그인 후\n일정 저장과 관리를 할 수 있어요.',
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
    final allowed = await AuthGate.ensureLoggedIn(
      context,
      title: '로그인이 필요해요',
      description: '내 캘린더는 로그인 후\n일정 저장과 관리를 할 수 있어요.',
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
    return AuthGate.ensureLoggedIn(
      context,
      title: '로그인이 필요해요',
      description: '로그인 후 다가오는 예약 일정과 내 캘린더를 확인할 수 있어요.',
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
      final allowed = await AuthGate.ensureLoggedIn(
        context,
        title: '로그인이 필요해요',
        description: '내 정보와 개인화 메뉴는 로그인 후\n확인할 수 있어요.',
      );

      if (!allowed || !context.mounted) return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MyPageScreen()),
    );
  }

  List<CalendarSchedule> _upcomingSchedulesFromToday() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return CalendarScheduleStore.snapshot().values
        .expand((items) => items)
        .where((schedule) {
          final scheduleDate = DateTime(
            schedule.dateTime.year,
            schedule.dateTime.month,
            schedule.dateTime.day,
          );
          return !scheduleDate.isBefore(today);
        })
        .toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  String _nearestReservationTitle(CalendarSchedule schedule) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final scheduleDate = DateTime(
      schedule.dateTime.year,
      schedule.dateTime.month,
      schedule.dateTime.day,
    );
    final diff = scheduleDate.difference(today).inDays;

    if (diff <= 0) {
      return '${schedule.hospitalName} 예약 당일';
    }

    return '${schedule.hospitalName} 예약 $diff일 전';
  }

  String _scheduleDateLabel(DateTime dateTime) {
    const weekdayLabels = ['일', '월', '화', '수', '목', '금', '토'];
    final weekdayLabel = weekdayLabels[dateTime.weekday % 7];
    return '${dateTime.month}월 ${dateTime.day}일($weekdayLabel) ${_timeText(dateTime)}';
  }

  String _relativeLabel(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final scheduleDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    final diff = scheduleDate.difference(today).inDays;

    if (diff <= 0) {
      return '오늘';
    }

    return '$diff일 후';
  }

  String _timeText(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute;
    final period = hour < 12 ? '오전' : '오후';
    final displayHour = hour == 0
        ? 12
        : hour > 12
        ? hour - 12
        : hour;
    return '$period $displayHour:${minute.toString().padLeft(2, '0')}';
  }

  String _todayReferenceLabel() {
    final now = DateTime.now();
    const weekdayLabels = ['일', '월', '화', '수', '목', '금', '토'];
    final weekdayLabel = weekdayLabels[now.weekday % 7];
    return 'Today · ${now.month}월 ${now.day}일 ($weekdayLabel)';
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final devices = _devices();
    final contents = _contents();

    return ValueListenableBuilder<bool>(
      valueListenable: AuthState.isLoggedIn,
      builder: (context, isLoggedIn, _) {
        final upcomingSchedules = isLoggedIn
            ? _upcomingSchedulesFromToday()
            : const <CalendarSchedule>[];
        final nearestSchedule = upcomingSchedules.isNotEmpty
            ? upcomingSchedules.first
            : null;
        final reservationTitle = !isLoggedIn
            ? '로그인이 필요해요'
            : nearestSchedule != null
            ? _nearestReservationTitle(nearestSchedule)
            : '다가오는 예약이 없어요';
        final reservationSubtitle = !isLoggedIn
            ? '로그인 후 내 캘린더를 확인할 수 있어요'
            : nearestSchedule != null
            ? _scheduleDateLabel(nearestSchedule.dateTime)
            : '오늘 기준으로 예정된 예약이 없어요';
        final todayLabel = _todayReferenceLabel();
        final reservationItems = upcomingSchedules
            .skip(nearestSchedule != null ? 1 : 0)
            .map(
              (schedule) => CalendarCardReservationItem(
                title: schedule.hospitalName,
                dateLabel: _scheduleDateLabel(schedule.dateTime),
                relativeLabel: _relativeLabel(schedule.dateTime),
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
                        onTapRecord: () {},
                        onTapStart: () async {
                          final allowed = await AuthGate.ensureLoggedIn(
                            context,
                            title: '로그인이 필요해요',
                            description: '캘린더 일정 등록은 로그인 후\n이용할 수 있어요.',
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
