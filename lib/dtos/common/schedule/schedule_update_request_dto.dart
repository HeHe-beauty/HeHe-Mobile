class ScheduleUpdateRequestDto {
  final String? hospitalName;
  final String? procedureName;
  final int? visitTime;

  const ScheduleUpdateRequestDto({
    this.hospitalName,
    this.procedureName,
    this.visitTime,
  });

  Map<String, dynamic> toJson() {
    final body = <String, dynamic>{};

    if (hospitalName != null) body['hospitalName'] = hospitalName;
    if (procedureName != null) body['procedureName'] = procedureName;
    if (visitTime != null) body['visitTime'] = visitTime;

    return body;
  }
}
