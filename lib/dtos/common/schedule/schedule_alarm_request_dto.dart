class ScheduleAlarmRequestDto {
  final String alarmType;

  const ScheduleAlarmRequestDto({required this.alarmType});

  Map<String, dynamic> toJson() {
    return {'alarmType': alarmType};
  }
}
