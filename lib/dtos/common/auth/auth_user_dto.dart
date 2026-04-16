class AuthUserDto {
  final int userId;
  final String nickname;

  AuthUserDto({required this.userId, required this.nickname});

  factory AuthUserDto.fromJson(Map<String, dynamic> json) {
    return AuthUserDto(
      userId: json['userId'] as int,
      nickname: json['nickname'] as String,
    );
  }
}
