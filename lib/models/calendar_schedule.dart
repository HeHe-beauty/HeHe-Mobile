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
}
