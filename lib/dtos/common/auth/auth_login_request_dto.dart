class AuthLoginRequestDto {
  final String provider;
  final String accessToken;

  AuthLoginRequestDto({required this.provider, required this.accessToken});

  Map<String, dynamic> toJson() {
    return {'provider': provider, 'accessToken': accessToken};
  }
}
