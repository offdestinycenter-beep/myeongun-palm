import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import '../config/constants.dart';

/// 이미지 변환 유틸리티
class ImageUtils {
  ImageUtils._();

  /// 이미지 파일을 리사이즈 후 Base64로 변환 (Isolate에서 실행)
  static Future<String?> imageToBase64(String imagePath) async {
    try {
      final bytes = await File(imagePath).readAsBytes();
      return compute(_processImageToBase64, _ImageProcessParams(bytes, AppConstants.maxImageSize));
    } catch (e) {
      debugPrint('이미지 변환 오류: $e');
      return null;
    }
  }
}

class _ImageProcessParams {
  final Uint8List bytes;
  final int maxSize;
  const _ImageProcessParams(this.bytes, this.maxSize);
}

/// Isolate에서 실행되는 이미지 처리 함수 (top-level)
String? _processImageToBase64(_ImageProcessParams params) {
  try {
    img.Image? image = img.decodeImage(params.bytes);
    if (image == null) return null;

    if (image.width > params.maxSize || image.height > params.maxSize) {
      image = img.copyResize(
        image,
        width: image.width > image.height ? params.maxSize : null,
        height: image.height >= image.width ? params.maxSize : null,
        interpolation: img.Interpolation.linear,
      );
    }

    final jpegBytes = img.encodeJpg(image, quality: 85);
    return base64Encode(jpegBytes);
  } catch (e) {
    return null;
  }
}
