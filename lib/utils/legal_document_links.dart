import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'app_snackbar.dart';

class LegalDocumentLinks {
  LegalDocumentLinks._();

  static final Uri terms = Uri.https('www.hehehe.kr', '/terms');
  static final Uri privacy = Uri.https('www.hehehe.kr', '/privacy');
  static final Uri accountDeletion = Uri.https(
    'www.hehehe.kr',
    '/account-deletion',
  );

  static Future<void> open(BuildContext context, Uri uri) async {
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      showAppSnackBar(context, '페이지를 열 수 없어요. 잠시 후 다시 시도해주세요.');
    }
  }
}
