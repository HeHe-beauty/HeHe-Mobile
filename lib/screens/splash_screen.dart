import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_palette.dart';
import 'home_screen.dart';

/// 둘 다 false  -> 실제 테마 따라감
/// dark true    -> 다크 스플래시 강제 표시
/// light true   -> 라이트 스플래시 강제 표시
///
const bool kForceDarkSplashPreview = false;
const bool kForceLightSplashPreview = false;

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  Timer? _navigationTimer;

  late final AnimationController _logoController;
  late final AnimationController _dotController;

  late final Animation<double> _logoOpacity;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoTranslateY;
  late final Animation<double> _textOpacity;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _dotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _logoOpacity = CurvedAnimation(
      parent: _logoController,
      curve: const Interval(0.0, 0.38, curve: Curves.easeOut),
    );

    _logoScale = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutBack),
    );

    _logoTranslateY = Tween<double>(begin: 18, end: 0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutCubic),
    );

    _textOpacity = CurvedAnimation(
      parent: _logoController,
      curve: const Interval(0.28, 0.75, curve: Curves.easeOut),
    );

    _logoController.forward();

    _navigationTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    });
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _logoController.dispose();
    _dotController.dispose();
    super.dispose();
  }

  bool _resolveSplashDarkMode(BuildContext context) {
    if (kForceDarkSplashPreview) return true;
    if (kForceLightSplashPreview) return false;
    return Theme.of(context).brightness == Brightness.dark;
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final isDark = _resolveSplashDarkMode(context);

    return Scaffold(
      backgroundColor: isDark ? palette.splashDarkBackground : palette.bg,
      body: Stack(
        children: [
          Positioned.fill(
            child: isDark
                ? const _DarkSplashBackground()
                : Container(color: palette.bg),
          ),
          SafeArea(
            child: AnimatedBuilder(
              animation: _logoController,
              builder: (context, child) {
                return Center(
                  child: Column(
                    children: [
                      const Spacer(flex: 12),
                      Opacity(
                        opacity: _logoOpacity.value.clamp(0.0, 1.0),
                        child: Transform.translate(
                          offset: Offset(0, _logoTranslateY.value),
                          child: Transform.scale(
                            scale: _logoScale.value,
                            child: _SplashLogo(isDark: isDark),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      Opacity(
                        opacity: _textOpacity.value.clamp(0.0, 1.0),
                        child: Column(
                          children: [
                            Text(
                              'HeHe',
                              style: TextStyle(
                                fontSize: isDark ? 32 : 34,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.8,
                                color: isDark
                                    ? palette.surface
                                    : palette.primary,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              '나에게 맞는 선택을 더 쉽게',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? palette.surface.withValues(alpha: 0.70)
                                    : palette.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(flex: 8),
                      FadeTransition(
                        opacity: _textOpacity,
                        child: _LoadingDots(
                          controller: _dotController,
                          color: isDark
                              ? palette.surface.withValues(alpha: 0.82)
                              : palette.primary.withValues(alpha: 0.80),
                        ),
                      ),
                      const SizedBox(height: 44),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SplashLogo extends StatelessWidget {
  final bool isDark;

  const _SplashLogo({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    if (isDark) {
      return Container(
        width: 170,
        height: 170,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              palette.primary.withValues(alpha: 0.18),
              palette.primary.withValues(alpha: 0.08),
              palette.surface.withValues(alpha: 0),
            ],
            stops: const [0.0, 0.42, 1.0],
          ),
        ),
        child: Center(
          child: Image.asset(
            'assets/images/logo.png',
            width: 86,
            height: 86,
            fit: BoxFit.contain,
          ),
        ),
      );
    }

    return Image.asset(
      'assets/images/logo.png',
      width: 88,
      height: 88,
      fit: BoxFit.contain,
    );
  }
}

class _LoadingDots extends StatelessWidget {
  final AnimationController controller;
  final Color color;

  const _LoadingDots({required this.controller, required this.color});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final t = controller.value;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final start = index * 0.18;
            final end = start + 0.42;
            final active = t >= start && t <= end;

            final scale = active
                ? 1.0 + ((t - start) / (end - start)) * 0.35
                : 1.0;
            final opacity = active ? 0.95 : 0.28;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Transform.scale(
                scale: scale.clamp(1.0, 1.35),
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: opacity.clamp(0.0, 1.0)),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

class _DarkSplashBackground extends StatelessWidget {
  const _DarkSplashBackground();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            /// 기존보다 살짝 밝고 덜 무겁게 보이도록 palette 값 사용
            palette.splashDarkGradientStart.withValues(alpha: 0.92),
            palette.splashDarkGradientMiddle.withValues(alpha: 0.90),
            palette.splashDarkGradientEnd.withValues(alpha: 0.94),
          ],
          stops: const [0.0, 0.45, 1.0],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -60,
            left: -40,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: palette.splashDarkOrbPrimary.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            top: 180,
            left: 40,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: palette.splashDarkOrbSecondary.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            right: -30,
            bottom: 120,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: palette.splashDarkOrbTertiary.withValues(alpha: 0.06),
              ),
            ),
          ),

          /// 하단 어둠 띠도 조금 덜 강하게
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 54,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    palette.surface.withValues(alpha: 0),
                    palette.textPrimary.withValues(alpha: 0.12),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}