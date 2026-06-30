import 'package:flutter/material.dart';

import '../../theme/app_palette.dart';

class ArticleIcon extends StatelessWidget {
  final String name;
  final double size;

  const ArticleIcon({super.key, required this.name, this.size = 22});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    switch (name) {
      case 'note':
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: palette.primary,
            borderRadius: BorderRadius.circular(size * 0.22),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: size * 0.23,
            vertical: size * 0.27,
          ),
          child: CustomPaint(painter: _NoteLinesPainter()),
        );
      case 'bulb':
        return SizedBox(
          width: size,
          height: size,
          child: Icon(
            Icons.lightbulb_rounded,
            size: size,
            color: const Color(0xFFF6B93B),
          ),
        );
      case 'sparkle':
        return SizedBox(
          width: size,
          height: size,
          child: Icon(
            Icons.auto_awesome_rounded,
            size: size,
            color: palette.primary,
          ),
        );
      default:
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: palette.primarySoft,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.info_outline_rounded,
            size: size * 0.62,
            color: palette.primary,
          ),
        );
    }
  }
}

class ArticleCheckCircleIcon extends StatelessWidget {
  final double size;

  const ArticleCheckCircleIcon({super.key, this.size = 18});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: palette.primary, shape: BoxShape.circle),
      child: Icon(
        Icons.check_rounded,
        size: size * 0.68,
        color: Colors.white,
        weight: 800,
      ),
    );
  }
}

class ArticleNumberIcon extends StatelessWidget {
  final String number;

  const ArticleNumberIcon({super.key, required this.number});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      width: 19,
      height: 19,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: palette.surfaceSoft,
        shape: BoxShape.circle,
      ),
      child: Text(
        number,
        style: TextStyle(
          color: palette.textSecondary,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
    );
  }
}

class _NoteLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 3; i++) {
      final y = size.height * (0.18 + i * 0.32);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
