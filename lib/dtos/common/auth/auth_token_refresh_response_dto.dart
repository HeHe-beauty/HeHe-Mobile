class AuthTokenRefreshResponseDto {
  final String accessToken;

  AuthTokenRefreshResponseDto({required this.accessToken});

  factory AuthTokenRefreshResponseDto.fromJson(Map<String, dynamic> json) {
    return AuthTokenRefreshResponseDto(
      accessToken: json['accessToken'] as String,
    );
  }
}
