class CalendarSchedule {
  final String id;
  String hospitalName;
  DateTime visitDateTime;
  bool isThreeDaysBefore;
  bool isOneDayBefore;
  bool isOneHourBefore;

  CalendarSchedule({
    required this.id,
    required this.hospitalName,
    required this.visitDateTime,
    this.isThreeDaysBefore = false,
    this.isOneDayBefore = false,
    this.isOneHourBefore = false,
  });

  CalendarSchedule copyWith({
    String? id,
    String? hospitalName,
    DateTime? visitDateTime,
    bool? isThreeDaysBefore,
    bool? isOneDayBefore,
    bool? isOneHourBefore,
  }) {
    return CalendarSchedule(
      id: id ?? this.id,
      hospitalName: hospitalName ?? this.hospitalName,
      visitDateTime: visitDateTime ?? this.visitDateTime,
      isThreeDaysBefore: isThreeDaysBefore ?? this.isThreeDaysBefore,
      isOneDayBefore: isOneDayBefore ?? this.isOneDayBefore,
      isOneHourBefore: isOneHourBefore ?? this.isOneHourBefore,
    );
  }
}
