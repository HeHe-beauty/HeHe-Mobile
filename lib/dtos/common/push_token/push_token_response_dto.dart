class PushTokenResponseDto {
  final bool success;

  const PushTokenResponseDto({required this.success});

  factory PushTokenResponseDto.fromJson(Map<String, dynamic> json) {
    return PushTokenResponseDto(success: json['success'] as bool? ?? false);
  }
}
