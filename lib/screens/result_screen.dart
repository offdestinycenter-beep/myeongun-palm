import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/theme.dart';
import '../models/palm_reading_result.dart';
import '../services/share_service.dart';
import '../widgets/score_gauge.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const Map<String, IconData> lineIcons = {
    'life_line': Icons.favorite,
    'heart_line': Icons.favorite_border,
    'fate_line': Icons.star,
    'head_line': Icons.psychology,
  };

  static const Map<String, Color> lineColors = {
    'life_line': AppTheme.lifeLine,
    'heart_line': AppTheme.heartLine,
    'fate_line': AppTheme.fateLine,
    'head_line': AppTheme.headLine,
  };

  static const Map<String, IconData> fortuneIcons = {
    'love': Icons.favorite_rounded,
    'wealth': Icons.monetization_on,
    'health': Icons.health_and_safety,
    'career': Icons.work_rounded,
    'academic': Icons.school_rounded,
  };

  static const Map<String, Color> fortuneColors = {
    'love': AppTheme.loveFortune,
    'wealth': AppTheme.wealthFortune,
    'health': AppTheme.healthFortune,
    'career': AppTheme.careerFortune,
    'academic': AppTheme.academicFortune,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args == null) return _buildError(context, '결과 데이터를 불러올 수 없습니다.');

    final imagePath = args['imagePath'] as String?;
    final result = args['result'] as PalmReadingResult?;
    final handType = args['handType'] as String? ?? 'right';

    if (result == null || !result.success) {
      return _buildError(context, result?.error ?? '손금 분석에 실패했습니다.');
    }

    return _buildResult(context, imagePath, result, handType);
  }

  Widget _buildResult(
    BuildContext context,
    String? imagePath,
    PalmReadingResult result,
    String handType,
  ) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              // 상단 바
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Text(
                      '분석 결과',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.gold,
                        shadows: [Shadow(color: AppTheme.gold.withValues(alpha: 0.2), blurRadius: 10)],
                      ),
                    ),
                    const SizedBox(width: 10),
                    // 손 타입 뱃지
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.purple.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.purple.withValues(alpha: 0.25)),
                      ),
                      child: Text(
                        handType == 'left' ? '왼손' : '오른손',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.purple.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => ShareService.shareResult(result),
                      icon: Icon(Icons.share_outlined, color: AppTheme.textSecondary.withValues(alpha: 0.7), size: 22),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil('/home', (r) => false),
                      icon: Icon(Icons.close, color: AppTheme.textSecondary.withValues(alpha: 0.7), size: 22),
                    ),
                  ],
                ),
              ),

              // 탭 바 (버튼 스타일)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _buildTabButton('손금 해석', 0),
                    const SizedBox(width: 10),
                    _buildTabButton('운세', 1),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // 탭 뷰
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // 탭 1: 손금 해석
                    _buildPalmTab(imagePath, result),
                    // 탭 2: 운세
                    _buildFortuneTab(result),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 탭 1: 손금 해석 (이미지 + 카드)
  Widget _buildPalmTab(String? imagePath, PalmReadingResult result) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          // 촬영 사진
          if (imagePath != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildPalmImage(imagePath),
            ),

          const SizedBox(height: 16),

          // 종합 해석
          if (result.summary != null)
            _buildSummaryCard(result.summary!),
          const SizedBox(height: 12),

          // 손금 해석 카드들
          if (result.lines != null)
            ...result.lines!.entries.toList().asMap().entries.map((entry) {
              final i = entry.key;
              final e = entry.value;
              return _buildLineCard(
                icon: lineIcons[e.key] ?? Icons.remove_red_eye,
                iconColor: lineColors[e.key] ?? AppTheme.gold,
                title: e.value.name,
                description: e.value.description,
              ).animate()
                  .fadeIn(delay: Duration(milliseconds: 120 * i + 200), duration: 400.ms)
                  .slideX(begin: 0.05, end: 0, delay: Duration(milliseconds: 120 * i + 200), duration: 400.ms);
            }),
          const SizedBox(height: 28),
          _buildRetryButton(context),
          const SizedBox(height: 36),
        ],
      ),
    );
  }

  /// 탭 2: 운세 (점수 게이지 + 카드)
  Widget _buildFortuneTab(PalmReadingResult result) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          const SizedBox(height: 8),

          // 종합 해석
          if (result.summary != null)
            _buildSummaryCard(result.summary!),
          const SizedBox(height: 16),

          // 점수 요약 그리드
          if (result.fortune != null)
            _buildScoreSummary(result.fortune!),
          const SizedBox(height: 16),

          // 운세 상세 카드들
          if (result.fortune != null)
            ...result.fortune!.entries.toList().asMap().entries.map((entry) {
              final i = entry.key;
              final e = entry.value;
              return _buildFortuneCard(
                icon: fortuneIcons[e.key] ?? Icons.auto_awesome,
                iconColor: fortuneColors[e.key] ?? AppTheme.gold,
                title: e.value.name,
                description: e.value.description,
                score: e.value.score,
              ).animate()
                  .fadeIn(delay: Duration(milliseconds: 120 * i + 200), duration: 400.ms)
                  .slideX(begin: 0.05, end: 0, delay: Duration(milliseconds: 120 * i + 200), duration: 400.ms);
            }),
          const SizedBox(height: 28),
          _buildRetryButton(context),
          const SizedBox(height: 36),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, int index) {
    final selected = _tabController.index == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => _tabController.animateTo(index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppTheme.gold.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppTheme.gold.withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                color: selected ? AppTheme.gold : AppTheme.textMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 촬영 사진
  Widget _buildPalmImage(String imagePath) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.purple.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: AspectRatio(
          aspectRatio: 3 / 4,
          child: Image.file(File(imagePath), fit: BoxFit.cover),
        ),
      ),
    ).animate().fadeIn(duration: 500.ms);
  }

  /// 점수 요약 그리드 (원형 게이지 5개)
  Widget _buildScoreSummary(Map<String, Fortune> fortune) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      decoration: AppTheme.glassCardGold,
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 16,
        children: fortune.entries.map((e) {
          final color = fortuneColors[e.key] ?? AppTheme.gold;
          return SizedBox(
            width: 80,
            child: Column(
              children: [
                ScoreGauge(
                  score: e.value.score,
                  color: color,
                  size: 52,
                ),
                const SizedBox(height: 6),
                Text(
                  e.value.name,
                  style: TextStyle(
                    fontSize: 11,
                    color: color.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    ).animate().fadeIn(duration: 500.ms);
  }

  Widget _buildSummaryCard(String summary) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.gold.withValues(alpha: 0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 3,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppTheme.gold, AppTheme.gold.withValues(alpha: 0.3)],
              ),
              borderRadius: BorderRadius.circular(2),
              boxShadow: [BoxShadow(color: AppTheme.gold.withValues(alpha: 0.3), blurRadius: 6)],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_awesome, color: AppTheme.gold.withValues(alpha: 0.8), size: 18),
                    const SizedBox(width: 8),
                    const Text('종합 해석', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.gold)),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  summary,
                  style: TextStyle(fontSize: 14, color: AppTheme.textSecondary.withValues(alpha: 0.85), height: 1.65),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms);
  }

  Widget _buildLineCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(18),
      decoration: AppTheme.glassCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: iconColor.withValues(alpha: 0.08), blurRadius: 8)],
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            description,
            style: TextStyle(fontSize: 14, color: AppTheme.textSecondary.withValues(alpha: 0.85), height: 1.65),
          ),
        ],
      ),
    );
  }

  Widget _buildFortuneCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required int score,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(18),
      decoration: AppTheme.glassCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: iconColor.withValues(alpha: 0.08), blurRadius: 8)],
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              ),
              ScoreGauge(score: score, color: iconColor, size: 48),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            description,
            style: TextStyle(fontSize: 14, color: AppTheme.textSecondary.withValues(alpha: 0.85), height: 1.65),
          ),
        ],
      ),
    );
  }

  Widget _buildRetryButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: AppTheme.goldGradient,
        boxShadow: [
          BoxShadow(color: AppTheme.gold.withValues(alpha: 0.2), blurRadius: 16, offset: const Offset(0, 4)),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil('/home', (r) => false),
        icon: const Icon(Icons.refresh, size: 18),
        label: const Text('다시 분석하기'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, String msg) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 72, color: AppTheme.textMuted.withValues(alpha: 0.4)),
                  const SizedBox(height: 24),
                  const Text('분석 실패', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                  const SizedBox(height: 12),
                  Text(msg, style: const TextStyle(fontSize: 15, color: AppTheme.textSecondary, height: 1.5), textAlign: TextAlign.center),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil('/home', (r) => false),
                    icon: const Icon(Icons.home),
                    label: const Text('홈으로 돌아가기'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
