class AuthSignupRequestDto {
  final String provider;
  final String accessToken;
  final bool pushAgreed;
  final bool nightAgreed;
  final bool mktAgreed;
  final bool isOverAge;
  final String termsVersion;

  const AuthSignupRequestDto({
    required this.provider,
    required this.accessToken,
    required this.pushAgreed,
    required this.nightAgreed,
    required this.mktAgreed,
    required this.isOverAge,
    required this.termsVersion,
  });

  Map<String, dynamic> toJson() {
    return {
      'provider': provider,
      'accessToken': accessToken,
      'pushAgreed': pushAgreed,
      'nightAgreed': nightAgreed,
      'mktAgreed': mktAgreed,
      'isOverAge': isOverAge,
      'termsVersion': termsVersion,
    };
  }
}
