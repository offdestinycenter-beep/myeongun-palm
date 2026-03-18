import 'package:share_plus/share_plus.dart';
import '../models/palm_reading_result.dart';
import '../config/constants.dart';

/// 결과 공유 서비스
class ShareService {
  ShareService._();

  static Future<void> shareResult(PalmReadingResult result) async {
    final buffer = StringBuffer();
    buffer.writeln('${AppConstants.appName} 분석 결과');
    buffer.writeln();

    if (result.handType != null) {
      buffer.writeln(result.handType == 'left' ? '[ 왼손 - 선천적 운명 ]' : '[ 오른손 - 후천적 운세 ]');
      buffer.writeln();
    }

    if (result.summary != null) {
      buffer.writeln('종합 해석');
      buffer.writeln(result.summary);
      buffer.writeln();
    }

    if (result.lines != null) {
      for (final entry in result.lines!.entries) {
        buffer.writeln(entry.value.name);
        buffer.writeln(entry.value.description);
        buffer.writeln();
      }
    }

    if (result.fortune != null) {
      for (final entry in result.fortune!.entries) {
        final starCount = (entry.value.score / 20).ceil().clamp(1, 5);
        final stars = List.filled(starCount, '*').join();
        buffer.writeln('${entry.value.name} $stars (${entry.value.score}점)');
        buffer.writeln(entry.value.description);
        buffer.writeln();
      }
    }

    buffer.writeln('- ${AppConstants.appName}에서 분석했습니다');

    await Share.share(buffer.toString());
  }
}
