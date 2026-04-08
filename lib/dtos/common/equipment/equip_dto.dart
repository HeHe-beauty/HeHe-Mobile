import 'package:flutter/material.dart';

class EquipDto {
  final int equipId;
  final String modelName;
  final int displayOrder;

  EquipDto({
    required this.equipId,
    required this.modelName,
    required this.displayOrder,
  });

  factory EquipDto.fromJson(Map<String, dynamic> json) {
    return EquipDto(
      equipId: json['equipId'] as int,
      modelName: json['modelName'] as String,
      displayOrder: json['displayOrder'] as int,
    );
  }

  // 플러스 텍스트 치환
  String get displayName {
    return modelName.replaceAll('플러스', '');
  }

  IconData get icon {
    if (displayName.contains('젠틀맥스')) {
      return Icons.auto_awesome_rounded;
    }
    if (displayName.contains('아포지')) {
      return Icons.bolt_rounded;
    }
    if (displayName.contains('클라리티')) {
      return Icons.blur_circular_rounded;
    }
    return Icons.device_unknown;
  }
}