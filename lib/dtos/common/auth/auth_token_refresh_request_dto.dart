class AuthTokenRefreshRequestDto {
  final String refreshToken;

  AuthTokenRefreshRequestDto({required this.refreshToken});

  Map<String, dynamic> toJson() {
    return {'refreshToken': refreshToken};
  }
}
