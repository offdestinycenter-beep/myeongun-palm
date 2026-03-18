import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/constants.dart';
import '../models/palm_reading_result.dart';
import '../utils/image_utils.dart';

/// Firebase Functions API 호출 서비스
class ApiService {
  ApiService._();

  /// 손금 분석 API 호출
  static Future<PalmReadingResult> analyzePalm(
    String imagePath, {
    String handType = 'right',
  }) async {
    try {
      final base64Image = await ImageUtils.imageToBase64(imagePath);
      if (base64Image == null) {
        return PalmReadingResult(
          success: false,
          error: '이미지 처리에 실패했습니다. 다시 촬영해주세요.',
        );
      }

      final response = await http.post(
        Uri.parse(AppConstants.analyzePalmEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'image': base64Image,
          'handType': handType,
        }),
      ).timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          throw Exception('서버 응답 시간이 초과되었습니다.');
        },
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        jsonData['handType'] = handType;
        return PalmReadingResult.fromJson(jsonData);
      } else {
        try {
          final errorJson = jsonDecode(response.body) as Map<String, dynamic>;
          return PalmReadingResult(
            success: false,
            error: errorJson['error'] as String? ?? '서버 오류가 발생했습니다.',
          );
        } catch (_) {
          return PalmReadingResult(
            success: false,
            error: '서버 오류가 발생했습니다. (${response.statusCode})',
          );
        }
      }
    } catch (e) {
      debugPrint('API 호출 오류: $e');
      return PalmReadingResult(
        success: false,
        error: '네트워크 오류가 발생했습니다. 인터넷 연결을 확인해주세요.',
      );
    }
  }
}
