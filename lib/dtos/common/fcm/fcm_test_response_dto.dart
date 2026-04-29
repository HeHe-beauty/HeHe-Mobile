class FcmTestResultDto {
  final int successCount;
  final int failCount;

  const FcmTestResultDto({required this.successCount, required this.failCount});

  factory FcmTestResultDto.fromJson(Map<String, dynamic> json) {
    return FcmTestResultDto(
      successCount: (json['successCount'] as num?)?.toInt() ?? 0,
      failCount: (json['failCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class FcmTestResponseDto {
  final bool success;
  final FcmTestResultDto data;
  final String? errorCode;
  final String? message;

  const FcmTestResponseDto({
    required this.success,
    required this.data,
    this.errorCode,
    this.message,
  });

  factory FcmTestResponseDto.fromJson(Map<String, dynamic> json) {
    return FcmTestResponseDto(
      success: json['success'] as bool? ?? false,
      data: FcmTestResultDto.fromJson(
        (json['data'] as Map<String, dynamic>?) ?? const {},
      ),
      errorCode: json['errorCode'] as String?,
      message: json['message'] as String?,
    );
  }
}
