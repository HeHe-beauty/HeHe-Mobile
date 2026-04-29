import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class LocationPermissionService {
  const LocationPermissionService._();

  static Future<bool> ensureGrantedForCurrentLocation(
    BuildContext context,
  ) async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!context.mounted) return false;
      await _showAlert(
        context: context,
        title: '위치 서비스가 꺼져 있어요',
        content: '내 위치를 사용하려면 기기의 위치 서비스를 켜주세요.',
        confirmLabel: '확인',
      );
      return false;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse) {
      return true;
    }

    if (!context.mounted) return false;

    final shouldRequest = await _showConfirm(
      context: context,
      title: '위치 권한이 필요해요',
      content: '내 위치를 확인하려면 위치 정보 사용을 허용해주세요.',
      confirmLabel: '허용하기',
    );

    if (shouldRequest != true) {
      return false;
    }

    permission = await Geolocator.requestPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  static Future<bool?> _showConfirm({
    required BuildContext context,
    required String title,
    required String content,
    required String confirmLabel,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(confirmLabel),
            ),
          ],
        );
      },
    );
  }

  static Future<void> _showAlert({
    required BuildContext context,
    required String title,
    required String content,
    required String confirmLabel,
  }) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(confirmLabel),
            ),
          ],
        );
      },
    );
  }
}
