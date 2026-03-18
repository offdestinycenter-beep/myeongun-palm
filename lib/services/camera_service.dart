import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:hand_landmarker/hand_landmarker.dart';
import 'package:permission_handler/permission_handler.dart';

/// 카메라 초기화, 권한 요청, 촬영 + MediaPipe 손 랜드마크 감지
class CameraService {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isInitialized = false;
  HandLandmarkerPlugin? _handPlugin;
  bool _isDetecting = false;

  /// 마지막으로 감지된 손 랜드마크
  List<Hand> lastDetectedHands = [];

  /// 촬영 시점의 랜드마크 (결과 화면에서 시각화용)
  List<Hand>? capturedLandmarks;

  /// 손 감지 상태 콜백
  ValueChanged<List<Hand>>? onHandsDetected;

  CameraController? get controller => _controller;
  bool get isInitialized => _isInitialized;
  bool get hasHandDetected => lastDetectedHands.isNotEmpty;

  /// 카메라 권한 요청
  Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  /// 카메라 초기화 (후면 카메라, 고해상도) + MediaPipe 초기화
  Future<void> initializeCamera() async {
    _cameras = await availableCameras();
    if (_cameras.isEmpty) {
      throw Exception('사용 가능한 카메라가 없습니다.');
    }

    final backCamera = _cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.back,
      orElse: () => _cameras.first,
    );

    _controller = CameraController(
      backCamera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    await _controller!.initialize();
    _isInitialized = true;

    // MediaPipe HandLandmarker 초기화
    try {
      _handPlugin = HandLandmarkerPlugin.create(
        numHands: 1,
        minHandDetectionConfidence: 0.6,
        delegate: HandLandmarkerDelegate.GPU,
      );
    } catch (e) {
      debugPrint('HandLandmarker 초기화 실패 (GPU), CPU로 재시도: $e');
      try {
        _handPlugin = HandLandmarkerPlugin.create(
          numHands: 1,
          minHandDetectionConfidence: 0.6,
          delegate: HandLandmarkerDelegate.CPU,
        );
      } catch (e2) {
        debugPrint('HandLandmarker CPU 초기화도 실패: $e2');
        _handPlugin = null;
      }
    }

    if (_handPlugin != null) {
      _startImageStream();
    }
  }

  void _startImageStream() {
    _controller?.startImageStream((CameraImage image) {
      _processCameraImage(image);
    });
  }

  void _processCameraImage(CameraImage image) {
    if (_isDetecting || _handPlugin == null || _controller == null) return;
    _isDetecting = true;

    try {
      final hands = _handPlugin!.detect(
        image,
        _controller!.description.sensorOrientation,
      );
      lastDetectedHands = hands;
      onHandsDetected?.call(hands);
    } catch (e) {
      // 감지 실패는 무시 (프레임 드롭)
    } finally {
      _isDetecting = false;
    }
  }

  /// 이미지 스트림 중지
  Future<void> stopImageStream() async {
    try {
      await _controller?.stopImageStream();
    } catch (_) {}
  }

  /// 사진 촬영 — 스트림 중지 → 랜드마크 저장 → 촬영 → 스트림 재시작
  Future<XFile?> takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return null;
    }
    if (_controller!.value.isTakingPicture) {
      return null;
    }

    try {
      // 촬영 시점의 랜드마크 저장
      capturedLandmarks = List.from(lastDetectedHands);

      await stopImageStream();
      final XFile file = await _controller!.takePicture();
      return file;
    } catch (e) {
      debugPrint('촬영 오류: $e');
      return null;
    }
  }

  /// 이미지 스트림 재시작
  void restartImageStream() {
    capturedLandmarks = null;
    if (_handPlugin != null && _controller != null && _isInitialized) {
      _startImageStream();
    }
  }

  /// 카메라 리소스 해제
  Future<void> dispose() async {
    try {
      await _controller?.stopImageStream();
    } catch (_) {}
    await _controller?.dispose();
    _controller = null;
    _isInitialized = false;
    _handPlugin?.dispose();
    _handPlugin = null;
  }
}
