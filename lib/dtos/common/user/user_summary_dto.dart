class UserSummaryDto {
  final String? email;
  final int bookmarkCount;
  final int contactCount;
  final int scheduleCount;

  const UserSummaryDto({
    this.email,
    required this.bookmarkCount,
    required this.contactCount,
    required this.scheduleCount,
  });

  factory UserSummaryDto.empty() {
    return const UserSummaryDto(
      email: null,
      bookmarkCount: 0,
      contactCount: 0,
      scheduleCount: 0,
    );
  }

  factory UserSummaryDto.fromJson(Map<String, dynamic> json) {
    return UserSummaryDto(
      email: json['email'] as String?,
      bookmarkCount: json['bookmarkCount'] as int? ?? 0,
      contactCount: json['contactCount'] as int? ?? 0,
      scheduleCount: json['scheduleCount'] as int? ?? 0,
    );
  }
}
