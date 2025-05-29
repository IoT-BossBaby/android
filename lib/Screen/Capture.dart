import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:async';
import 'dart:math';

class ShakeCaptureScreen extends StatefulWidget {
  const ShakeCaptureScreen({super.key});

  @override
  State<ShakeCaptureScreen> createState() => _ShakeCaptureScreenState();
}

class _ShakeCaptureScreenState extends State<ShakeCaptureScreen> {
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _hasCaptured = false;
  Timer? _windowTimer;
  bool _sawPos = false, _sawNeg = false;
  static final double _threshold = 20 * pi / 180;
  double _gz = 0.0;
  late StreamSubscription<GyroscopeEvent> _sub;

  @override
  void initState() {
    super.initState();
    _sub = gyroscopeEvents.listen(_onGyro);
  }

  void _onGyro(GyroscopeEvent e) {
    _gz = e.z;
    if (_windowTimer == null && _gz.abs() > _threshold) {
      _sawPos = _sawNeg = _hasCaptured = false;
      _windowTimer = Timer(const Duration(seconds: 1), _resetWindow);
    }

    if (_windowTimer != null) {
      if (_gz > _threshold) _sawPos = true;
      if (_gz < -_threshold) _sawNeg = true;
      if (_sawPos && _sawNeg && !_hasCaptured) {
        _hasCaptured = true;
        _captureScreen();
      }
    }
    setState(() {});
  }

  void _resetWindow() {
    _windowTimer?.cancel();
    _windowTimer = null;
  }

  Future<void> _captureScreen() async {
    try {
      // 한 번만 캡쳐
      final Uint8List? pngBytes = await _screenshotController.capture();
      if (pngBytes == null) {
        debugPrint('⚠️ 캡쳐된 데이터가 null 입니다.');
        return;
      }

      // 저장 디렉토리 가져오기
      final dir = await getApplicationDocumentsDirectory();
      final filePath =
          '${dir.path}/screenshot_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File(filePath);

      // 파일 쓰기
      await file.writeAsBytes(pngBytes);
      debugPrint('✅ 스크린샷 저장됨: $filePath');

    } catch (e, st) {
      debugPrint('❌ 스크린샷 저장 중 오류: $e\n$st');
    }
  }

  @override
  void dispose() {
    _sub.cancel();
    _windowTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final degZ = (_gz * 180 / pi).toStringAsFixed(1);
    return Screenshot(
      controller: _screenshotController,
      child: Scaffold(
        appBar: AppBar(title: const Text('흔들림으로 스크린샷')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Z축 속도: $degZ°/s', style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 16),
              Text(
                _windowTimer != null
                    ? '윈도우 중: 양($_sawPos) 음($_sawNeg), 캡쳐됨($_hasCaptured)'
                    : '흔들림 대기 중',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
