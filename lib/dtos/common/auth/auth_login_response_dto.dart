import 'auth_user_dto.dart';

class AuthLoginResponseDto {
  final String accessToken;
  final String refreshToken;
  final AuthUserDto user;

  AuthLoginResponseDto({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  factory AuthLoginResponseDto.fromJson(Map<String, dynamic> json) {
    return AuthLoginResponseDto(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      user: AuthUserDto.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}
