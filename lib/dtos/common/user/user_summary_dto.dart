class UserSummaryDto {
  final int bookmarkCount;
  final int contactCount;
  final int scheduleCount;

  const UserSummaryDto({
    required this.bookmarkCount,
    required this.contactCount,
    required this.scheduleCount,
  });

  factory UserSummaryDto.empty() {
    return const UserSummaryDto(
      bookmarkCount: 0,
      contactCount: 0,
      scheduleCount: 0,
    );
  }

  factory UserSummaryDto.fromJson(Map<String, dynamic> json) {
    return UserSummaryDto(
      bookmarkCount: json['bookmarkCount'] as int? ?? 0,
      contactCount: json['contactCount'] as int? ?? 0,
      scheduleCount: json['scheduleCount'] as int? ?? 0,
    );
  }
}
