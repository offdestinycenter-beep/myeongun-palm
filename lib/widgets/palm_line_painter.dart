import 'package:flutter/material.dart';
import '../config/theme.dart';

/// 손금 선 시각화 페인터
/// MediaPipe 손 랜드마크를 기반으로 손금 선을 추정하여 그림
class PalmLinePainter extends CustomPainter {
  /// 랜드마크 좌표 (0~1 정규화, 21개 포인트)
  /// MediaPipe 순서: 0=wrist, 1-4=thumb, 5-8=index, 9-12=middle, 13-16=ring, 17-20=pinky
  final List<Offset> landmarks;
  final bool showLifeLine;
  final bool showHeartLine;
  final bool showFateLine;
  final bool showHeadLine;

  PalmLinePainter({
    required this.landmarks,
    this.showLifeLine = true,
    this.showHeartLine = true,
    this.showFateLine = true,
    this.showHeadLine = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (landmarks.length < 21) return;

    // 랜드마크를 화면 좌표로 변환
    List<Offset> pts = landmarks.map((l) => Offset(l.dx * size.width, l.dy * size.height)).toList();

    if (showLifeLine) _drawLifeLine(canvas, size, pts);
    if (showHeartLine) _drawHeartLine(canvas, size, pts);
    if (showHeadLine) _drawHeadLine(canvas, size, pts);
    if (showFateLine) _drawFateLine(canvas, size, pts);
  }

  /// 생명선: 엄지와 검지 사이에서 손목 방향으로 곡선
  void _drawLifeLine(Canvas canvas, Size size, List<Offset> pts) {
    final paint = _linePaint(AppTheme.lifeLine);

    // 시작: 엄지 CMC(1)와 검지 MCP(5) 사이
    final start = Offset(
      (pts[1].dx + pts[5].dx) / 2 + (pts[5].dx - pts[1].dx) * 0.1,
      (pts[1].dy + pts[5].dy) / 2,
    );

    // 끝: 손목(0) 근처, 약간 엄지 쪽
    final end = Offset(
      pts[0].dx + (pts[1].dx - pts[0].dx) * 0.3,
      pts[0].dy - (pts[0].dy - pts[5].dy) * 0.15,
    );

    // 제어점: 손바닥 중앙 쪽으로 곡선
    final ctrl = Offset(
      pts[9].dx - (pts[9].dx - pts[1].dx) * 0.2,
      (start.dy + end.dy) / 2 + (end.dy - start.dy) * 0.1,
    );

    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..quadraticBezierTo(ctrl.dx, ctrl.dy, end.dx, end.dy);

    canvas.drawPath(path, paint);
    canvas.drawPath(path, _glowPaint(AppTheme.lifeLine));
  }

  /// 감정선: 검지 MCP(5) 아래에서 새끼손가락 MCP(17) 방향으로
  void _drawHeartLine(Canvas canvas, Size size, List<Offset> pts) {
    final paint = _linePaint(AppTheme.heartLine);

    final start = Offset(
      pts[5].dx + (pts[9].dx - pts[5].dx) * 0.1,
      pts[5].dy + (pts[0].dy - pts[5].dy) * 0.12,
    );

    final end = Offset(
      pts[17].dx + (pts[17].dx - pts[13].dx) * 0.3,
      pts[17].dy + (pts[0].dy - pts[17].dy) * 0.08,
    );

    final ctrl1 = Offset(
      (start.dx + end.dx) * 0.4,
      start.dy + (end.dy - start.dy) * 0.15,
    );
    final ctrl2 = Offset(
      (start.dx + end.dx) * 0.65,
      end.dy - (end.dy - start.dy) * 0.1,
    );

    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..cubicTo(ctrl1.dx, ctrl1.dy, ctrl2.dx, ctrl2.dy, end.dx, end.dy);

    canvas.drawPath(path, paint);
    canvas.drawPath(path, _glowPaint(AppTheme.heartLine));
  }

  /// 두뇌선: 생명선 시작점 근처에서 손바닥 중앙을 가로지름
  void _drawHeadLine(Canvas canvas, Size size, List<Offset> pts) {
    final paint = _linePaint(AppTheme.headLine);

    final start = Offset(
      (pts[1].dx + pts[5].dx) / 2 + (pts[5].dx - pts[1].dx) * 0.05,
      (pts[1].dy + pts[5].dy) / 2 + (pts[0].dy - pts[5].dy) * 0.05,
    );

    final end = Offset(
      pts[17].dx + (pts[17].dx - pts[13].dx) * 0.1,
      pts[17].dy + (pts[0].dy - pts[17].dy) * 0.25,
    );

    final ctrl = Offset(
      (start.dx + end.dx) / 2,
      (start.dy + end.dy) / 2 + (end.dy - start.dy) * 0.15,
    );

    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..quadraticBezierTo(ctrl.dx, ctrl.dy, end.dx, end.dy);

    canvas.drawPath(path, paint);
    canvas.drawPath(path, _glowPaint(AppTheme.headLine));
  }

  /// 운명선: 손목(0)에서 중지 MCP(9) 방향으로 세로선
  void _drawFateLine(Canvas canvas, Size size, List<Offset> pts) {
    final paint = _linePaint(AppTheme.fateLine);

    final start = Offset(
      (pts[0].dx + pts[9].dx) / 2,
      pts[0].dy - (pts[0].dy - pts[9].dy) * 0.1,
    );

    final end = Offset(
      pts[9].dx,
      pts[9].dy + (pts[0].dy - pts[9].dy) * 0.15,
    );

    final ctrl = Offset(
      (start.dx + end.dx) / 2 + (end.dx - start.dx) * 0.15,
      (start.dy + end.dy) / 2,
    );

    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..quadraticBezierTo(ctrl.dx, ctrl.dy, end.dx, end.dy);

    canvas.drawPath(path, paint);
    canvas.drawPath(path, _glowPaint(AppTheme.fateLine));
  }

  Paint _linePaint(Color color) => Paint()
    ..color = color.withValues(alpha: 0.85)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.5
    ..strokeCap = StrokeCap.round;

  Paint _glowPaint(Color color) => Paint()
    ..color = color.withValues(alpha: 0.25)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 8
    ..strokeCap = StrokeCap.round
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

  @override
  bool shouldRepaint(covariant PalmLinePainter oldDelegate) => true;
}
