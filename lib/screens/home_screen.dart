import 'package:flutter/material.dart';
import '../core/auth/auth_gate.dart';
import '../core/auth/auth_state.dart';
import '../models/content_item.dart';
import '../models/device_item.dart';
import '../theme/app_palette.dart';
import '../widgets/add_schedule_bottom_sheet.dart';
import '../widgets/calendar_card.dart';
import '../widgets/content_carousel.dart';
import '../widgets/device_tile.dart';
import '../widgets/header_bar.dart';
import '../widgets/section_card.dart';
import 'calendar_detail_screen.dart';
import 'content_detail_screen.dart';
import 'device_map_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  List<DeviceItem> _devices() => const [
    DeviceItem(title: '메인 기기 1', icon: Icons.devices_rounded),
    DeviceItem(title: '기기 2', icon: Icons.health_and_safety_rounded),
    DeviceItem(title: '기기 3', icon: Icons.spa_rounded),
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

  void _showAddScheduleSheet(BuildContext context) {
    final palette = context.palette;

    showModalBottomSheet(
      context: context,
      isDismissible: true,
      enableDrag: true,
      isScrollControlled: true,
      backgroundColor: palette.surface.withValues(alpha: 0),
      barrierColor: palette.modalBarrier,
      builder: (_) => const AddScheduleBottomSheet(),
    );
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

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final devices = _devices();
    final contents = _contents();

    return ValueListenableBuilder<bool>(
      valueListenable: AuthState.isLoggedIn,
      builder: (context, isLoggedIn, _) {
        return Scaffold(
          backgroundColor: palette.bg,
          body: Column(
            children: [
              HeaderBar(
                title: '슬로건',
                onTapSettings: () => _openSettings(context),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: DeviceTile(
                              title: devices[0].title,
                              icon: devices[0].icon,
                              height: 160,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => DeviceMapScreen(
                                      deviceName: devices[0].title,
                                    ),
                                  ),
                                );
                              },
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
                      const SizedBox(height: 18),
                      CalendarCard(
                        title: isLoggedIn ? '레이저제모 3일 전' : '로그인이 필요해요',
                        subtitle: isLoggedIn
                            ? '6월 14일(일)'
                            : '로그인 후 내 캘린더를 확인할 수 있어요',
                        selectedDay: 16,
                        days: const [14, 15, 16, 17, 18, 19, 20],
                        isLoginRequired: !isLoggedIn,
                        showAddButton: true,
                        onTapCalendar: () => _openCalendarIfLoggedIn(context),
                        onTapRecord: () {},
                        onTapStart: () async {
                          final allowed = await AuthGate.ensureLoggedIn(
                            context,
                            title: '로그인이 필요해요',
                            description: '캘린더 일정 등록은 로그인 후\n이용할 수 있어요.',
                          );

                          if (!allowed || !context.mounted) return;

                          _showAddScheduleSheet(context);
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
