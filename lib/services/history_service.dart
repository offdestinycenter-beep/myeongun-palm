import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/palm_history.dart';
import '../config/constants.dart';

/// 분석 히스토리 로컬 저장 서비스
class HistoryService extends ChangeNotifier {
  static const String _storageKey = 'palm_history';
  static const int maxHistoryCount = 20;

  List<PalmHistory> _histories = [];
  bool _isLoaded = false;

  List<PalmHistory> get histories => List.unmodifiable(_histories);

  /// 온보딩 완료 여부
  Future<bool> isOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(AppConstants.onboardingCompleteKey) ?? false;
  }

  /// 온보딩 완료 처리
  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.onboardingCompleteKey, true);
  }

  /// 히스토리 로드
  Future<void> loadHistories() async {
    if (_isLoaded) return;
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_storageKey);
    if (jsonStr != null) {
      final list = jsonDecode(jsonStr) as List<dynamic>;
      _histories = list
          .map((e) => PalmHistory.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    _isLoaded = true;
    notifyListeners();
  }

  /// 히스토리 저장
  Future<void> addHistory({
    required String summary,
    required Map<String, dynamic> resultJson,
    String? handType,
  }) async {
    final history = PalmHistory(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      analyzedAt: DateTime.now(),
      summary: summary,
      resultJson: jsonEncode(resultJson),
      handType: handType,
    );

    _histories.insert(0, history);

    if (_histories.length > maxHistoryCount) {
      _histories = _histories.sublist(0, maxHistoryCount);
    }

    await _save();
    notifyListeners();
  }

  /// 특정 히스토리 삭제
  Future<void> deleteHistory(String id) async {
    _histories.removeWhere((h) => h.id == id);
    await _save();
    notifyListeners();
  }

  /// 전체 히스토리 삭제
  Future<void> clearAll() async {
    _histories.clear();
    await _save();
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(_histories.map((h) => h.toJson()).toList());
    await prefs.setString(_storageKey, jsonStr);
  }
}
