import 'package:flutter/material.dart';

class AppTextStyles {
  const AppTextStyles._();

  static const homeHeadline = TextStyle(
    fontSize: 21,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.2,
    height: 1.32,
  );

  static const homeHeadlineStrong = TextStyle(
    fontSize: 21,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
    height: 1.32,
  );

  static const homeSectionTitle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w900,
    letterSpacing: -0.2,
  );

  static const homeBody = TextStyle(fontSize: 13, fontWeight: FontWeight.w600);

  static const homeBodyStrong = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w900,
  );

  static const homeCaption = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
  );
}
