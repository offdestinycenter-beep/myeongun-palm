import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';
import '../config/theme.dart';
import '../config/constants.dart';
import '../models/palm_reading_result.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/ad_service.dart';
import '../services/history_service.dart';

class AnalyzingScreen extends StatefulWidget {
  const AnalyzingScreen({super.key});

  @override
  State<AnalyzingScreen> createState() => _AnalyzingScreenState();
}

class _AnalyzingScreenState extends State<AnalyzingScreen> {
  String _currentText = AppConstants.analyzingTexts[0];
  Timer? _textTimer;
  String? _imagePath;
  String _handType = AppConstants.rightHand;
  List<dynamic>? _landmarks;
  final AdService _adService = AdService();
  bool _argsLoaded = false;

  @override
  void initState() {
    super.initState();
    _textTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted) {
        setState(() {
          _currentText = AppConstants.analyzingTexts[
              Random().nextInt(AppConstants.analyzingTexts.length)];
        });
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_argsLoaded) {
      _argsLoaded = true;
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, dynamic>) {
        _imagePath = args['imagePath'] as String?;
        _handType = args['handType'] as String? ?? AppConstants.rightHand;
        _landmarks = args['landmarks'] as List<dynamic>?;
      } else if (args is String) {
        _imagePath = args;
      }
      if (_imagePath != null) _startAnalysis();
    }
  }

  @override
  void dispose() {
    _textTimer?.cancel();
    _adService.dispose();
    super.dispose();
  }

  Future<void> _startAnalysis() async {
    _adService.loadRewardedInterstitialAd();
    final results = await Future.wait([
      ApiService.analyzePalm(_imagePath!, handType: _handType),
      _adService.adLoadFuture,
    ]);
    if (!mounted) return;
    final analysisResult = results[0] as PalmReadingResult;
    if (_adService.isAdLoaded) {
      await _adService.showAd(onAdDone: () {
        if (mounted) _navigateToResult(analysisResult);
      });
    } else {
      _navigateToResult(analysisResult);
    }
  }

  void _navigateToResult(PalmReadingResult result) {
    if (result.success && result.summary != null) {
      context.read<HistoryService>().addHistory(
        summary: result.summary!,
        resultJson: _resultToJson(result),
        handType: _handType,
      );
    }
    Navigator.of(context).pushReplacementNamed('/result', arguments: {
      'imagePath': _imagePath,
      'result': result,
      'handType': _handType,
      'landmarks': _landmarks,
    });
  }

  Map<String, dynamic> _resultToJson(PalmReadingResult result) {
    final map = <String, dynamic>{
      'success': result.success,
      'summary': result.summary,
      'handType': _handType,
    };
    if (result.lines != null) {
      map['lines'] = result.lines!.map((k, l) => MapEntry(k, {
        'name': l.name, 'description': l.description,
      }));
    }
    if (result.fortune != null) {
      map['fortune'] = result.fortune!.map((k, f) => MapEntry(k, {
        'name': f.name, 'description': f.description, 'score': f.score,
      }));
    }
    return map;
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
              // Lottie 분석 애니메이션
              SizedBox(
                width: 160,
                height: 160,
                child: Lottie.asset(
                  'assets/animations/analyzing.json',
                  width: 160,
                  height: 160,
                  repeat: true,
                ),
              ),
              const SizedBox(height: 10),
              // 손 타입 표시
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.gold.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.gold.withValues(alpha: 0.15)),
                ),
                child: Text(
                  _handType == AppConstants.leftHand ? '왼손 (선천운) 분석 중' : '오른손 (후천운) 분석 중',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.gold.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                child: Text(
                  _currentText,
                  key: ValueKey(_currentText),
                  style: const TextStyle(fontSize: 16, color: AppTheme.textPrimary, letterSpacing: 1),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: 180,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    minHeight: 3,
                    backgroundColor: AppTheme.textMuted.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.gold.withValues(alpha: 0.7)),
                  ),
                ),
              ),
            ],
          ).animate().fadeIn(duration: 600.ms),
        ),
      ),
    );
  }
}
