class ScheduleCreateResponseDto {
  final String scheduleId;

  const ScheduleCreateResponseDto({required this.scheduleId});

  factory ScheduleCreateResponseDto.fromJson(Map<String, dynamic> json) {
    return ScheduleCreateResponseDto(scheduleId: json['scheduleId'].toString());
  }
}
