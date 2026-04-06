class CalendarSchedule {
  final String id;
  String hospitalName;
  DateTime dateTime;
  bool isThreeDaysBefore;
  bool isOneDayBefore;
  bool isOneHourBefore;

  CalendarSchedule({
    required this.id,
    required this.hospitalName,
    required this.dateTime,
    this.isThreeDaysBefore = false,
    this.isOneDayBefore = false,
    this.isOneHourBefore = false,
  });

  CalendarSchedule copyWith({
    String? id,
    String? hospitalName,
    DateTime? dateTime,
    bool? isThreeDaysBefore,
    bool? isOneDayBefore,
    bool? isOneHourBefore,
  }) {
    return CalendarSchedule(
      id: id ?? this.id,
      hospitalName: hospitalName ?? this.hospitalName,
      dateTime: dateTime ?? this.dateTime,
      isThreeDaysBefore: isThreeDaysBefore ?? this.isThreeDaysBefore,
      isOneDayBefore: isOneDayBefore ?? this.isOneDayBefore,
      isOneHourBefore: isOneHourBefore ?? this.isOneHourBefore,
    );
  }

  String get timeText {
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

  String get dateText {
    const labels = ['일', '월', '화', '수', '목', '금', '토'];
    final weekdayLabel = labels[dateTime.weekday % 7];
    return '${dateTime.month}월 ${dateTime.day}일 $weekdayLabel요일';
  }

  String get reminderSummary {
    final items = <String>[];
    if (isThreeDaysBefore) items.add('방문 3일 전에 알림');
    if (isOneDayBefore) items.add('방문 1일 전에 알림');
    if (isOneHourBefore) items.add('방문 1시간 전에 알림');

    if (items.isEmpty) {
      return '알림 없음';
    }

    return items.join(' · ');
  }
}
