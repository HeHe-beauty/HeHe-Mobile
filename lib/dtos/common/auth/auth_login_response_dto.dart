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
    return AuthLoginResponseDto(
      exists: json['exists'] as bool? ?? true,
      accessToken: json['accessToken'] as String?,
      refreshToken: json['refreshToken'] as String?,
      user: json['user'] is Map<String, dynamic>
          ? AuthUserDto.fromJson(json['user'] as Map<String, dynamic>)
          : null,
    );
  }
}
