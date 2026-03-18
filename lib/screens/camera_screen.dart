import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/theme.dart';
import '../config/constants.dart';
import '../services/camera_service.dart';
import '../widgets/hand_guide_overlay.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> with WidgetsBindingObserver {
  final CameraService _cameraService = CameraService();
  bool _isLoading = true;
  bool _hasPermission = false;
  String? _capturedImagePath;
  bool _handDetected = false;
  String _selectedHand = AppConstants.leftHand; // 기본: 왼손

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _initCamera();
    } else if (state == AppLifecycleState.inactive) {
      _cameraService.dispose();
    }
  }

  Future<void> _initCamera() async {
    setState(() => _isLoading = true);
    _hasPermission = await _cameraService.requestCameraPermission();
    if (!_hasPermission) {
      setState(() => _isLoading = false);
      return;
    }
    try {
      await _cameraService.initializeCamera();
      _cameraService.onHandsDetected = (hands) {
        if (mounted) {
          final detected = hands.isNotEmpty;
          if (detected != _handDetected) {
            setState(() => _handDetected = detected);
          }
        }
      };
    } catch (e) {
      debugPrint('카메라 초기화 실패: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _takePicture() async {
    final file = await _cameraService.takePicture();
    if (file != null && mounted) {
      setState(() => _capturedImagePath = file.path);
    }
  }

  void _retakePicture() {
    setState(() => _capturedImagePath = null);
    _cameraService.restartImageStream();
  }

  void _analyzeImage() {
    if (_capturedImagePath != null) {
      Navigator.of(context).pushReplacementNamed(
        '/analyzing',
        arguments: {
          'imagePath': _capturedImagePath,
          'handType': _selectedHand,
          'landmarks': _cameraService.capturedLandmarks
              ?.map((h) => h.landmarks.map((l) => {'x': l.x, 'y': l.y}).toList())
              .toList(),
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return _buildLoading();
    if (!_hasPermission) return _buildPermissionDenied();
    if (_capturedImagePath != null) return _buildPreview();
    return _buildCamera();
  }

  Widget _buildLoading() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: CircularProgressIndicator(
          color: AppTheme.gold.withValues(alpha: 0.7),
          strokeWidth: 2,
        ),
      ),
    );
  }

  Widget _buildPermissionDenied() {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.camera_alt_outlined, size: 72, color: AppTheme.textMuted.withValues(alpha: 0.4)),
                  const SizedBox(height: 24),
                  const Text('카메라 권한이 필요합니다',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                  const SizedBox(height: 12),
                  const Text('손금을 분석하려면 카메라 접근 권한이 필요합니다.\n설정에서 카메라 권한을 허용해주세요.',
                      style: TextStyle(fontSize: 14, color: AppTheme.textSecondary), textAlign: TextAlign.center),
                  const SizedBox(height: 32),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppTheme.textMuted.withValues(alpha: 0.3)),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: const Text('돌아가기', style: TextStyle(color: AppTheme.textSecondary)),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(onPressed: _initCamera, child: const Text('다시 시도')),
                  ]),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCamera() {
    if (!_cameraService.isInitialized || _cameraService.controller == null) return _buildLoading();

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Center(child: CameraPreview(_cameraService.controller!)),
          HandGuideOverlay(isLeftHand: _selectedHand == AppConstants.leftHand),
          // 상단 바
          Positioned(
            top: 0, left: 0, right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    _buildCircleButton(Icons.arrow_back, () => Navigator.of(context).pop()),
                    const Spacer(),
                    // 손 감지 상태
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: _handDetected
                            ? const Color(0xFF2E7D32).withValues(alpha: 0.8)
                            : Colors.black.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _handDetected
                              ? const Color(0xFF4CAF50).withValues(alpha: 0.5)
                              : Colors.white.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _handDetected ? Icons.check_circle_outline : Icons.pan_tool_outlined,
                            color: _handDetected ? const Color(0xFF81C784) : Colors.white.withValues(alpha: 0.7),
                            size: 15,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _handDetected ? '손 인식됨' : '손을 보여주세요',
                            style: TextStyle(
                              color: _handDetected ? const Color(0xFFA5D6A7) : Colors.white.withValues(alpha: 0.7),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 40),
                  ],
                ),
              ),
            ),
          ),
          // 하단: 왼손/오른손 선택 + 촬영 버튼
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
                ),
              ),
              child: Column(
                children: [
                  Text(
                    '가이드에 맞춰 손바닥을 펴주세요',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  // 왼손/오른손 선택
                  _buildHandSelector(),
                  const SizedBox(height: 20),
                  // 촬영 버튼
                  GestureDetector(
                    onTap: _takePicture,
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.gold.withValues(alpha: 0.8), width: 3),
                      ),
                      child: Center(
                        child: Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppTheme.goldGradient,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.gold.withValues(alpha: 0.3),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.camera_alt, color: AppTheme.bgDark, size: 26),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 왼손/오른손 선택 위젯
  Widget _buildHandSelector() {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _handOption(
            label: '왼손',
            icon: Icons.front_hand,
            value: AppConstants.leftHand,
            subtitle: '선천운',
          ),
          const SizedBox(width: 4),
          _handOption(
            label: '오른손',
            icon: Icons.back_hand,
            value: AppConstants.rightHand,
            subtitle: '후천운',
          ),
        ],
      ),
    );
  }

  Widget _handOption({
    required String label,
    required IconData icon,
    required String value,
    required String subtitle,
  }) {
    final selected = _selectedHand == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedHand = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppTheme.gold.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected ? AppTheme.gold.withValues(alpha: 0.5) : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: selected ? AppTheme.gold : Colors.white.withValues(alpha: 0.5)),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                    color: selected ? AppTheme.gold : Colors.white.withValues(alpha: 0.6),
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 9,
                    color: selected
                        ? AppTheme.gold.withValues(alpha: 0.6)
                        : Colors.white.withValues(alpha: 0.3),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircleButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withValues(alpha: 0.35),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildPreview() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.file(File(_capturedImagePath!), fit: BoxFit.contain),
          // 선택된 손 표시
          Positioned(
            top: 0, left: 0, right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    _buildCircleButton(Icons.arrow_back, () => Navigator.of(context).pop()),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: AppTheme.gold.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.gold.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        _selectedHand == AppConstants.leftHand ? '왼손 (선천운)' : '오른손 (후천운)',
                        style: TextStyle(
                          color: AppTheme.gold.withValues(alpha: 0.9),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 40),
                  ],
                ),
              ),
            ),
          ),
          // 하단 버튼
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 44),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withValues(alpha: 0.85)],
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _retakePicture,
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('다시 촬영'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(color: Colors.white.withValues(alpha: 0.4)),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        gradient: AppTheme.goldGradient,
                        boxShadow: [
                          BoxShadow(color: AppTheme.gold.withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: _analyzeImage,
                        icon: const Icon(Icons.auto_awesome, size: 18),
                        label: const Text('분석하기'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                        ),
                      ),
                    ),
                  ),
                ],
              ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.2, end: 0, duration: 300.ms),
            ),
          ),
        ],
      ),
    );
  }
}
