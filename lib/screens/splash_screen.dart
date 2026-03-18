import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';
import '../config/theme.dart';
import '../config/constants.dart';
import '../services/history_service.dart';
import 'package:provider/provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 2500));
    if (!mounted) return;

    final isOnboardingDone =
        await context.read<HistoryService>().isOnboardingComplete();

    if (mounted) {
      Navigator.of(context).pushReplacementNamed(
        isOnboardingDone ? '/home' : '/onboarding',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Lottie 애니메이션 + 손바닥 이미지 겹침
              SizedBox(
                width: 200,
                height: 200,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Lottie 글로우 배경
                    Lottie.asset(
                      'assets/animations/palm_glow.json',
                      width: 200,
                      height: 200,
                      fit: BoxFit.contain,
                      repeat: true,
                    ),
                    // 손바닥 이미지
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.gold.withValues(alpha: 0.15),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: ColorFiltered(
                          colorFilter: ColorFilter.mode(
                            AppTheme.gold.withValues(alpha: 0.15),
                            BlendMode.srcATop,
                          ),
                          child: Image.asset(
                            'assets/images/hand_guide.jpg',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 36),
              Text(
                AppConstants.appName,
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.gold,
                  letterSpacing: 6,
                  shadows: [
                    Shadow(
                      color: AppTheme.gold.withValues(alpha: 0.3),
                      blurRadius: 20,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(
                '당신의 손금이 말하는 운명',
                style: TextStyle(
                  fontSize: 15,
                  color: AppTheme.textSecondary.withValues(alpha: 0.8),
                  letterSpacing: 3,
                ),
              ),
            ],
          )
              .animate()
              .fadeIn(duration: 1000.ms, curve: Curves.easeOut)
              .scale(
                begin: const Offset(0.85, 0.85),
                end: const Offset(1.0, 1.0),
                duration: 1000.ms,
                curve: Curves.easeOut,
              ),
        ),
      ),
    );
  }
}
