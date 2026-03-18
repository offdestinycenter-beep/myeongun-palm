import 'dart:io';
import 'package:flutter/material.dart';
import '../config/theme.dart';

/// 촬영된 손바닥 이미지 표시
class PalmOverlay extends StatelessWidget {
  final String imagePath;

  const PalmOverlay({
    super.key,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.purple.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: AspectRatio(
          aspectRatio: 3 / 4,
          child: Image.file(File(imagePath), fit: BoxFit.cover),
        ),
      ),
    );
  }
}
