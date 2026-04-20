import 'schedule_alarm_dto.dart';

class ScheduleDetailDto {
  final String scheduleId;
  final String hospitalName;
  final String procedureName;
  final int visitTime;
  final bool alarmEnabled;
  final List<ScheduleAlarmDto> alarms;

  const ScheduleDetailDto({
    required this.scheduleId,
    required this.hospitalName,
    required this.procedureName,
    required this.visitTime,
    required this.alarmEnabled,
    required this.alarms,
  });

  factory ScheduleDetailDto.fromJson(Map<String, dynamic> json) {
    final alarms = json['alarms'] as List<dynamic>? ?? const <dynamic>[];

    return ScheduleDetailDto(
      scheduleId: json['scheduleId'].toString(),
      hospitalName: json['hospitalName'] as String,
      procedureName: json['procedureName'] as String? ?? '',
      visitTime: (json['visitTime'] as num).toInt(),
      alarmEnabled: json['alarmEnabled'] as bool? ?? false,
      alarms: alarms
          .map(
            (alarm) => ScheduleAlarmDto.fromJson(alarm as Map<String, dynamic>),
          )
          .toList(),
    );
  }
}
