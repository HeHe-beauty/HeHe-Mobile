import 'auth_user_dto.dart';

class AuthLoginResponseDto {
  final bool exists;
  final String? accessToken;
  final String? refreshToken;
  final AuthUserDto? user;

  AuthLoginResponseDto({
    required this.exists,
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  bool get hasSession {
    return accessToken != null && refreshToken != null && user != null;
  }

  factory AuthLoginResponseDto.fromJson(Map<String, dynamic> json) {
    final accessToken = json['accessToken'] as String?;
    final refreshToken = json['refreshToken'] as String?;
    final user = json['user'] is Map<String, dynamic>
        ? AuthUserDto.fromJson(json['user'] as Map<String, dynamic>)
        : null;

    return AuthLoginResponseDto(
      exists:
          json['exists'] as bool? ??
          (accessToken != null && refreshToken != null && user != null),
      accessToken: accessToken,
      refreshToken: refreshToken,
      user: user,
    );
  }
}
