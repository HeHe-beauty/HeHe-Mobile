class PushTokenDeleteRequestDto {
  final String token;

  const PushTokenDeleteRequestDto({required this.token});

  Map<String, dynamic> toJson() {
    return {'token': token};
  }
}
