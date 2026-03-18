/// 손금 분석 결과 데이터 모델
class PalmReadingResult {
  final bool success;
  final String? error;
  final Map<String, PalmLine>? lines;
  final Map<String, Fortune>? fortune;
  final String? summary;
  final String? handType; // 'left' or 'right'

  PalmReadingResult({
    required this.success,
    this.error,
    this.lines,
    this.fortune,
    this.summary,
    this.handType,
  });

  factory PalmReadingResult.fromJson(Map<String, dynamic> json) {
    if (json['success'] != true) {
      return PalmReadingResult(
        success: false,
        error: json['error'] as String? ?? '알 수 없는 오류가 발생했습니다.',
      );
    }

    // 손금 선 파싱
    final linesJson = json['lines'] as Map<String, dynamic>?;
    final lines = <String, PalmLine>{};
    if (linesJson != null) {
      linesJson.forEach((key, value) {
        lines[key] = PalmLine.fromJson(value as Map<String, dynamic>);
      });
    }

    // 운세 파싱
    final fortuneJson = json['fortune'] as Map<String, dynamic>?;
    final fortune = <String, Fortune>{};
    if (fortuneJson != null) {
      fortuneJson.forEach((key, value) {
        fortune[key] = Fortune.fromJson(value as Map<String, dynamic>);
      });
    }

    return PalmReadingResult(
      success: true,
      lines: lines,
      fortune: fortune,
      summary: json['summary'] as String?,
      handType: json['handType'] as String?,
    );
  }
}

/// 개별 손금 선 데이터
class PalmLine {
  final String name;
  final String description;

  PalmLine({
    required this.name,
    required this.description,
  });

  factory PalmLine.fromJson(Map<String, dynamic> json) {
    return PalmLine(
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
    );
  }
}

/// 운세 데이터
class Fortune {
  final String name;
  final String description;
  final int score;

  Fortune({
    required this.name,
    required this.description,
    required this.score,
  });

  factory Fortune.fromJson(Map<String, dynamic> json) {
    return Fortune(
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      score: (json['score'] as num?)?.toInt() ?? 50,
    );
  }
}
