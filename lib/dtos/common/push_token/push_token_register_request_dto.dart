class PushTokenRegisterRequestDto {
  final String token;
  final String platform;
  final bool notificationPermissionGranted;

  const PushTokenRegisterRequestDto({
    required this.token,
    required this.platform,
    required this.notificationPermissionGranted,
  });

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'platform': platform,
      'notificationPermissionGranted': notificationPermissionGranted,
    };
  }
}
