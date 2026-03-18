import 'dart:convert';

/// 히스토리 항목 데이터 모델
class PalmHistory {
  final String id;
  final DateTime analyzedAt;
  final String summary;
  final String resultJson;
  final String? handType;

  PalmHistory({
    required this.id,
    required this.analyzedAt,
    required this.summary,
    required this.resultJson,
    this.handType,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'analyzedAt': analyzedAt.toIso8601String(),
        'summary': summary,
        'resultJson': resultJson,
        if (handType != null) 'handType': handType,
      };

  factory PalmHistory.fromJson(Map<String, dynamic> json) {
    return PalmHistory(
      id: json['id'] as String,
      analyzedAt: DateTime.parse(json['analyzedAt'] as String),
      summary: json['summary'] as String,
      resultJson: json['resultJson'] as String,
      handType: json['handType'] as String?,
    );
  }

  /// resultJson을 Map으로 파싱
  Map<String, dynamic> get resultMap =>
      jsonDecode(resultJson) as Map<String, dynamic>;
}
