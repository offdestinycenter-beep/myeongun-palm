/// 앱 상수값
class AppConstants {
  AppConstants._();

  // 앱 정보
  static const String appName = '명운관 손금';
  static const String appVersion = '2.0.0';

  // Firebase Functions API URL
  static const String apiBaseUrl = 'https://us-central1-myeongun-palm-app.cloudfunctions.net';
  static const String analyzePalmEndpoint = '$apiBaseUrl/analyzePalm';

  // AdMob 광고 ID (테스트)
  static const String rewardedInterstitialAdId = 'ca-app-pub-3940256099942544/5354046379';

  // 이미지 설정
  static const int maxImageSize = 1024;

  // 온보딩 SharedPreferences 키
  static const String onboardingCompleteKey = 'onboarding_complete';

  // 분석 중 표시 텍스트
  static const List<String> analyzingTexts = [
    '손금의 비밀을 해독하는 중...',
    '생명선과 감정선을 읽고 있습니다',
    '당신의 운명을 분석하는 중...',
    '손금 속 숨겨진 이야기를 찾는 중',
    '운세의 흐름을 읽고 있습니다',
    '거의 완료되었습니다...',
  ];

  // 손 타입
  static const String leftHand = 'left';
  static const String rightHand = 'right';
}
