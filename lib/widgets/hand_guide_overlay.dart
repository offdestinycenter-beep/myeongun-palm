import 'package:flutter/material.dart';

/// 카메라 프리뷰 위에 손바닥 이미지 가이드를 투명하게 표시하는 오버레이
class HandGuideOverlay extends StatelessWidget {
  /// true = 왼손 (원본), false = 오른손 (좌우반전)
  final bool isLeftHand;

  const HandGuideOverlay({super.key, this.isLeftHand = true});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final guideWidth = size.width * 1.0;
    final guideHeight = guideWidth * 1.4;
    final centerY = size.height * 0.42;

    return IgnorePointer(
      child: Positioned.fill(
        child: Stack(
          children: [
            Positioned(
              left: (size.width - guideWidth) / 2,
              top: centerY - guideHeight / 2,
              child: Opacity(
                opacity: 0.25,
                child: Transform.flip(
                  flipX: isLeftHand,
                  child: SizedBox(
                    width: guideWidth,
                    height: guideHeight,
                    child: Image.asset(
                      'assets/images/palm_guide.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
