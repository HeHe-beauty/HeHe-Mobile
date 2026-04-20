class ScheduleCreateRequestDto {
  final String hospitalName;
  final String procedureName;
  final String visitTime;

  const ScheduleCreateRequestDto({
    required this.hospitalName,
    required this.procedureName,
    required this.visitTime,
  });

  Map<String, dynamic> toJson() {
    return {
      'hospitalName': hospitalName,
      'procedureName': procedureName,
      'visitTime': visitTime,
    };
  }
}
