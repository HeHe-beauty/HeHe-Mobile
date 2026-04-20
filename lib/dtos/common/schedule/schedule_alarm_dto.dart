class ScheduleAlarmDto {
  final String alarmType;
  final int alarmTime;
  final bool isSent;

  const ScheduleAlarmDto({
    required this.alarmType,
    required this.alarmTime,
    required this.isSent,
  });

  factory ScheduleAlarmDto.fromJson(Map<String, dynamic> json) {
    return ScheduleAlarmDto(
      alarmType: json['alarmType'] as String,
      alarmTime: (json['alarmTime'] as num).toInt(),
      isSent: json['isSent'] as bool,
    );
  }
}
