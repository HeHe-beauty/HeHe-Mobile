import 'package:flutter/material.dart';
import 'package:hehe/common/helper/date_refresh_mixin.dart';
import 'package:hehe/common/utils/app_time.dart';
import '../core/auth/auth_prompt.dart';
import '../core/auth/auth_gate.dart';
import '../core/auth/auth_state.dart';
import '../models/calendar_schedule.dart';
import '../models/content_item.dart';
import '../theme/app_palette.dart';
import '../theme/app_text_styles.dart';
import '../data/article/article_repository.dart';
import '../data/calendar_schedule_store.dart';
import '../data/home_catalog.dart';
import '../data/equipment/equip_repository.dart';
import '../dtos/common/article/article_dto.dart';
import '../dtos/common/equipment/equip_dto.dart';
import '../utils/calendar_schedule_utils.dart';
import '../utils/app_snackbar.dart';
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

const _homeBackgroundColor = Color(0xFFF0F1F4);
const _homeSecondaryTextColor = Color(0xFF4B5563);
const _homeSoftCardColor = Color(0xFFF6F7F9);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver, DateRefreshMixin {
  static const int _maxVisibleReservations = 2;
  List<EquipDto> _devices = [];
  List<ContentItem> _contents = HomeCatalog.contents;

  EquipDto? _device(int index) {
    if (index >= _devices.length) return null;
    return _devices[index];
  }

  Future<void> _showAddScheduleSheet(BuildContext context) async {
    _hideDeviceTooltip();

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
    _hideDeviceTooltip();

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
    _hideDeviceTooltip();

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
    _hideDeviceTooltip();

    return AuthGate.ensureLoggedInWithPrompt(
      context,
      prompt: AuthPrompts.reservationOverview,
    );
  }

  Future<void> _openContentDetail(
    BuildContext context,
    ContentItem item,
  ) async {
    _hideDeviceTooltip();

    final articleId = item.articleId;

    if (articleId == null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ContentDetailScreen(item: item)),
      );
      return;
    }

    try {
      final detail = await ArticleRepository.getArticleDetail(articleId);

      if (!context.mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ContentDetailScreen.content(
            title: detail.title,
            htmlContent: detail.content,
            icon: item.icon,
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      showAppSnackBar(context, '콘텐츠를 불러오지 못했어요');
    }
  }

  void _openSettings(BuildContext context) {
    _hideDeviceTooltip();

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
  }

  void _openDeviceMap(BuildContext context, String deviceName, {int? equipId}) {
    _hideDeviceTooltip();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            DeviceMapScreen(deviceName: deviceName, equipId: equipId),
      ),
    );
  }

  Future<void> _openMyPage(BuildContext context) async {
    _hideDeviceTooltip();

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
    _loadArticles();
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

  Future<void> _loadArticles() async {
    try {
      final articles = await ArticleRepository.getArticles();

      if (!mounted) return;

      setState(() {
        _contents = articles.map(_contentItemFromArticle).toList();
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _contents = HomeCatalog.contents;
      });
    }
  }

  void _hideDeviceTooltip() {
    return;
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final contents = _contents;
    final d0 = _device(0);
    final d1 = _device(1);
    final d2 = _device(2);
    final d0Name = _deviceName(d0, '젠틀맥스 프로');
    final d0Label = d0Name;
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
          backgroundColor: palette.surface,
          body: GestureDetector(
            behavior: HitTestBehavior.deferToChild,
            child: Stack(
              children: [
                NotificationListener<ScrollStartNotification>(
                  onNotification: (_) {
                    _hideDeviceTooltip();
                    return false;
                  },
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            HeaderBar(
                              title: '시술 꿀팁부터 병원 찾기까지 관리는 HeHe에서',
                              isLoggedIn: isLoggedIn,
                              backgroundColor: Colors.transparent,
                              foregroundColor: palette.textPrimary,
                              utilityIconColor: palette.textPrimary,
                              onTapProfile: () => _openMyPage(context),
                              onTapSettings: () => _openSettings(context),
                            ),
                            Container(
                              width: double.infinity,
                              color: _homeBackgroundColor,
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  42,
                                  20,
                                  22,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Stack(
                                            clipBehavior: Clip.none,
                                            children: [
                                              _PrimaryDeviceCard(
                                                title: d0Label,
                                                description:
                                                    '돈은 들어도 확실하고 안 아픈 게 최고라면?',
                                                imageAsset: d0Asset,
                                                onTap: () => _openDeviceMap(
                                                  context,
                                                  d0Name,
                                                  equipId: d0?.equipId,
                                                ),
                                              ),
                                              const Positioned(
                                                left: 12,
                                                top: -20,
                                                child: _DeviceCategoryBubble(),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            children: [
                                              DeviceTile(
                                                title: d1Name,
                                                description: '가성비 좋은 선택을 원하는 분',
                                                imageAsset: d1Asset,
                                                height: 90,
                                                onTap: () => _openDeviceMap(
                                                  context,
                                                  d1Name,
                                                  equipId: d1?.equipId,
                                                ),
                                              ),
                                              const SizedBox(height: 14),
                                              DeviceTile(
                                                title: d2Name,
                                                description:
                                                    '빠른 제모로 시간을 아끼고 싶다면?',
                                                imageAsset: d2Asset,
                                                height: 90,
                                                onTap: () => _openDeviceMap(
                                                  context,
                                                  d2Name,
                                                  equipId: d2?.equipId,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 20),
                                    Text.rich(
                                      const TextSpan(
                                        children: [
                                          TextSpan(
                                            text: '💡 ',
                                            style: TextStyle(
                                              fontFamily: 'Tossface',
                                              fontSize: 12,
                                            ),
                                          ),
                                          TextSpan(
                                            text:
                                                '기기를 선택하면 주변 병원 위치를 확인할 수 있어요',
                                            style: TextStyle(fontSize: 13),
                                          ),
                                        ],
                                      ),
                                      style: AppTextStyles.homeCaption.copyWith(
                                        color: palette.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          width: double.infinity,
                          color: palette.surface,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 24, 20, 18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '내 일정',
                                  style: AppTextStyles.homeSectionTitle
                                      .copyWith(
                                        color: palette.textPrimary,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                                const SizedBox(height: 14),
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
                                      ? () => _openReservationLoginRequired(
                                          context,
                                        )
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
                                  style: AppTextStyles.homeSectionTitle
                                      .copyWith(
                                        color: palette.textPrimary,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                                const SizedBox(height: 14),
                                ContentCarousel(
                                  items: contents,
                                  cardBackgroundColor: palette.primarySoft
                                      .withValues(alpha: 0.45),
                                  thumbnailBackgroundColor: palette.surface,
                                  onTapItem: (item) {
                                    _openContentDetail(context, item);
                                  },
                                ),
                                const SizedBox(height: 14),
                              ],
                            ),
                          ),
                        ),
                      ],
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
  final String description;
  final String imageAsset;
  final VoidCallback onTap;

  const _PrimaryDeviceCard({
    required this.title,
    required this.description,
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
          height: 194,
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(28),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Stack(
              children: [
                Positioned(
                  right: 14,
                  bottom: 14,
                  child: IgnorePointer(
                    child: SizedBox(
                      width: 78,
                      height: 66,
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
                  right: 54,
                  top: 24,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          title.replaceAll(RegExp(r'\s+'), ' '),
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.visible,
                          textAlign: TextAlign.left,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: palette.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            height: 1.1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _DeviceDescriptionText(
                        description,
                        style: TextStyle(
                          color: _homeSecondaryTextColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          height: 1.25,
                        ),
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

class _DeviceDescriptionText extends StatelessWidget {
  final String text;
  final TextStyle style;

  const _DeviceDescriptionText(this.text, {required this.style});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final lines = _wordWrapLines(
          text.trim().replaceAll(RegExp(r'\s+'), ' '),
          style,
          constraints.maxWidth,
          context,
        );

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final line in lines)
              Text(
                line,
                softWrap: false,
                maxLines: 1,
                overflow: TextOverflow.visible,
                style: style,
              ),
          ],
        );
      },
    );
  }
}

class _DeviceCategoryBubble extends StatelessWidget {
  const _DeviceCategoryBubble();

  @override
  Widget build(BuildContext context) {
    const bubbleColor = Color(0xFFFF8A3D);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.circular(999),
          ),
          child: const Text(
            '가장 많이 찾는 기기',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 18),
          child: CustomPaint(
            size: const Size(14, 10),
            painter: _BubbleTailPainter(color: bubbleColor),
          ),
        ),
      ],
    );
  }
}

class _BubbleTailPainter extends CustomPainter {
  final Color color;

  const _BubbleTailPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _BubbleTailPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

List<String> _wordWrapLines(
  String text,
  TextStyle style,
  double maxWidth,
  BuildContext context,
) {
  final words = text.split(RegExp(r'\s+')).where((word) => word.isNotEmpty);
  final lines = <String>[];
  var currentLine = '';

  for (final word in words) {
    final candidate = currentLine.isEmpty ? word : '$currentLine $word';
    if (currentLine.isEmpty || _textFits(candidate, style, maxWidth, context)) {
      currentLine = candidate;
      continue;
    }

    lines.add(currentLine);
    currentLine = word;
  }

  if (currentLine.isNotEmpty) {
    lines.add(currentLine);
  }

  return lines.isEmpty ? const [''] : lines;
}

bool _textFits(
  String text,
  TextStyle style,
  double maxWidth,
  BuildContext context,
) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: Directionality.of(context),
    maxLines: 1,
  )..layout(maxWidth: maxWidth);

  return !painter.didExceedMaxLines;
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

ContentItem _contentItemFromArticle(ArticleDto article) {
  return ContentItem(
    articleId: article.articleId,
    title: article.title,
    subTitle: article.subTitle,
    thumbnailUrl: article.thumbnailUrl,
    htmlContent: null,
    icon: Icons.article_rounded,
    author: 'HeHe',
  );
}
