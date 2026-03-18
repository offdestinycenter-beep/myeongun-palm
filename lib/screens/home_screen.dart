import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../config/constants.dart';
import '../services/history_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 2),
              // Lottie 오브 + 타이틀
              SizedBox(
                width: 160,
                height: 160,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Lottie.asset(
                      'assets/animations/palm_glow.json',
                      width: 160,
                      height: 160,
                    ),
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.gold.withValues(alpha: 0.08),
                        border: Border.all(
                          color: AppTheme.gold.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Icon(
                        Icons.back_hand_rounded,
                        size: 36,
                        color: AppTheme.gold.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 600.ms),
              const SizedBox(height: 20),
              Text(
                AppConstants.appName,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.gold,
                  letterSpacing: 6,
                  shadows: [
                    Shadow(
                      color: AppTheme.gold.withValues(alpha: 0.2),
                      blurRadius: 12,
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 200.ms, duration: 500.ms),
              const SizedBox(height: 8),
              Text(
                '손금으로 읽는 당신의 운명',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary.withValues(alpha: 0.7),
                  letterSpacing: 2,
                ),
              ).animate().fadeIn(delay: 400.ms, duration: 500.ms),
              const Spacer(flex: 1),
              // 최근 분석 미니 카드
              _buildRecentAnalysis(context),
              const Spacer(flex: 1),
              // 기능 아이콘 행
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildFeatureIcon(Icons.front_hand, '왼손', AppTheme.purple),
                    _buildFeatureIcon(Icons.back_hand, '오른손', AppTheme.gold),
                    _buildFeatureIcon(Icons.auto_awesome, '5대 운세', AppTheme.heartLine),
                    _buildFeatureIcon(Icons.psychology, '상세 해석', AppTheme.headLine),
                  ],
                ),
              ).animate().fadeIn(delay: 600.ms, duration: 500.ms),
              const Spacer(flex: 1),
              // 분석 시작 버튼
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48),
                child: SizedBox(
                  width: double.infinity,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      gradient: AppTheme.goldGradient,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.gold.withValues(alpha: 0.25),
                          blurRadius: 24,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () =>
                          Navigator.of(context).pushNamed('/camera'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt, size: 20),
                          SizedBox(width: 10),
                          Text(
                            '손금 분석 시작',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 300.ms, duration: 600.ms),
              const SizedBox(height: 24),
              // 지난 분석 기록
              GestureDetector(
                onTap: () => Navigator.of(context).pushNamed('/history'),
                child: Text(
                  '지난 분석 기록',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textMuted.withValues(alpha: 0.6),
                    decoration: TextDecoration.underline,
                    decorationColor: AppTheme.textMuted.withValues(alpha: 0.3),
                  ),
                ),
              ).animate().fadeIn(delay: 500.ms, duration: 600.ms),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureIcon(IconData icon, String label, Color color) {
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.1),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Icon(icon, size: 20, color: color.withValues(alpha: 0.8)),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: AppTheme.textMuted.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentAnalysis(BuildContext context) {
    return Consumer<HistoryService>(
      builder: (context, svc, _) {
        if (svc.histories.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: AppTheme.glassCard,
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.purple.withValues(alpha: 0.1),
                    ),
                    child: Icon(
                      Icons.history,
                      color: AppTheme.purple.withValues(alpha: 0.5),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      '아직 분석 기록이 없습니다\n첫 번째 손금을 분석해보세요!',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textMuted.withValues(alpha: 0.6),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(delay: 500.ms, duration: 500.ms);
        }

        final latest = svc.histories.first;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: GestureDetector(
            onTap: () => Navigator.of(context).pushNamed('/history'),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.glassCardGold,
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.gold.withValues(alpha: 0.1),
                    ),
                    child: Icon(
                      Icons.auto_awesome,
                      color: AppTheme.gold.withValues(alpha: 0.7),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              '최근 분석',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.gold.withValues(alpha: 0.8),
                              ),
                            ),
                            const Spacer(),
                            if (latest.handType != null)
                              Text(
                                latest.handType == 'left' ? '왼손' : '오른손',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppTheme.textMuted.withValues(alpha: 0.6),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          latest.summary,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary.withValues(alpha: 0.7),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: AppTheme.textMuted.withValues(alpha: 0.3),
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ).animate().fadeIn(delay: 500.ms, duration: 500.ms);
      },
    );
  }
}
