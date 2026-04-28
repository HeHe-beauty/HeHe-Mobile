class AuthTokenRefreshResponseDto {
  final String accessToken;
  final String? refreshToken;

  AuthTokenRefreshResponseDto({required this.accessToken, this.refreshToken});

  factory AuthTokenRefreshResponseDto.fromJson(Map<String, dynamic> json) {
    return AuthTokenRefreshResponseDto(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String?,
    );
  }
}
