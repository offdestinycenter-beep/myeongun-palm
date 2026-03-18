import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app.dart';
import 'services/ad_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  // Firebase 초기화 (Crashlytics 포함)
  // firebase_options.dart가 생성된 후 아래 주석 해제:
  // try {
  //   await Firebase.initializeApp(
  //     options: DefaultFirebaseOptions.currentPlatform,
  //   );
  //   FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  //   PlatformDispatcher.instance.onError = (error, stack) {
  //     FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
  //     return true;
  //   };
  // } catch (e) {
  //   debugPrint('Firebase 초기화 실패 (Crashlytics 비활성): $e');
  // }

  await AdService.initialize();

  runApp(const MyeongunPalmApp());
}
