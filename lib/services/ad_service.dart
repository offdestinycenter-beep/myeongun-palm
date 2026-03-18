import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../config/constants.dart';

/// AdMob 광고 로드/표시 서비스
class AdService {
  RewardedInterstitialAd? _rewardedInterstitialAd;
  bool _isAdLoaded = false;
  bool _isLoading = false;
  final Completer<bool> _adLoadCompleter = Completer<bool>();

  bool get isAdLoaded => _isAdLoaded;

  /// 광고 로드 완료까지 대기하는 Future
  Future<bool> get adLoadFuture => _adLoadCompleter.future;

  /// AdMob 초기화 (앱 시작 시 1회 호출)
  static Future<void> initialize() async {
    await MobileAds.instance.initialize();
  }

  /// 보상형 전면광고 로드
  void loadRewardedInterstitialAd() {
    if (_isLoading || _isAdLoaded) return;
    _isLoading = true;

    RewardedInterstitialAd.load(
      adUnitId: AppConstants.rewardedInterstitialAdId,
      request: const AdRequest(),
      rewardedInterstitialAdLoadCallback: RewardedInterstitialAdLoadCallback(
        onAdLoaded: (RewardedInterstitialAd ad) {
          debugPrint('보상형 전면광고 로드 성공');
          _rewardedInterstitialAd = ad;
          _isAdLoaded = true;
          _isLoading = false;
          _setFullScreenContentCallback(ad);
          if (!_adLoadCompleter.isCompleted) {
            _adLoadCompleter.complete(true);
          }
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('보상형 전면광고 로드 실패: $error');
          _rewardedInterstitialAd = null;
          _isAdLoaded = false;
          _isLoading = false;
          if (!_adLoadCompleter.isCompleted) {
            _adLoadCompleter.complete(false);
          }
        },
      ),
    );
  }

  /// 광고 표시 (콜백으로 완료 알림)
  Future<void> showAd({required VoidCallback onAdDone}) async {
    if (_rewardedInterstitialAd == null || !_isAdLoaded) {
      // 광고 미준비 시 바로 완료 처리
      onAdDone();
      return;
    }

    _rewardedInterstitialAd!.fullScreenContentCallback =
        FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedInterstitialAd = null;
        _isAdLoaded = false;
        onAdDone();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('광고 표시 실패: $error');
        ad.dispose();
        _rewardedInterstitialAd = null;
        _isAdLoaded = false;
        onAdDone();
      },
    );

    await _rewardedInterstitialAd!.show(
      onUserEarnedReward: (ad, reward) {
        debugPrint('사용자 보상 획득: ${reward.amount} ${reward.type}');
      },
    );
  }

  void _setFullScreenContentCallback(RewardedInterstitialAd ad) {
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        debugPrint('광고 전체화면 표시');
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('광고 표시 실패: $error');
        ad.dispose();
      },
    );
  }

  /// 리소스 해제
  void dispose() {
    _rewardedInterstitialAd?.dispose();
    _rewardedInterstitialAd = null;
  }
}
