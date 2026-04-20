class ScheduleSummaryDto {
  final Map<DateTime, int> countsByDate;

  const ScheduleSummaryDto({required this.countsByDate});

  factory ScheduleSummaryDto.fromJson(Map<String, dynamic> json) {
    return ScheduleSummaryDto(
      countsByDate: json.map((date, count) {
        final parts = date.split('-').map(int.parse).toList();
        return MapEntry(
          DateTime(parts[0], parts[1], parts[2]),
          (count as num).toInt(),
        );
      }),
    );
  }
}
