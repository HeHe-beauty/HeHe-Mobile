class AuthPrompt {
  final String title;
  final String description;

  const AuthPrompt({required this.title, required this.description});
}

class AuthPrompts {
  const AuthPrompts._();

  static const calendar = AuthPrompt(
    title: '로그인이 필요해요',
    description: '내 캘린더는 로그인 후\n일정 저장과 관리를 할 수 있어요.',
  );

  static const reservationOverview = AuthPrompt(
    title: '로그인이 필요해요',
    description: '로그인 후 다가오는 예약 일정과 내 캘린더를 확인할 수 있어요.',
  );

  static const calendarAdd = AuthPrompt(
    title: '로그인이 필요해요',
    description: '캘린더 일정 등록은 로그인 후\n이용할 수 있어요.',
  );

  static const myPage = AuthPrompt(
    title: '로그인이 필요해요',
    description: '내 정보와 개인화 메뉴는 로그인 후\n확인할 수 있어요.',
  );

  static const mapMyPage = AuthPrompt(
    title: '로그인이 필요해요',
    description: '마이페이지는 로그인 후\n내 정보와 활동을 확인할 수 있어요.',
  );

  static const recentPlaces = AuthPrompt(
    title: '로그인이 필요해요',
    description: '최근 본 병원은 로그인 후\n기록과 관리를 할 수 있어요.',
  );

  static const favorites = AuthPrompt(
    title: '로그인이 필요해요',
    description: '찜한 병원은 로그인 후 저장하고\n언제든 다시 확인할 수 있어요.',
  );

  static const inquiries = AuthPrompt(
    title: '로그인이 필요해요',
    description: '문의한 병원 내역은 로그인 후\n확인할 수 있어요.',
  );

  static const contact = AuthPrompt(
    title: '문의하려면 로그인이 필요해요',
    description: '문의 내역 확인과 상담 연결은\n로그인 후 이용할 수 있어요.',
  );
}
