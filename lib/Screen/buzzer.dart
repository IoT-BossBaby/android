import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class BuzzerControlScreen extends StatefulWidget {
  const BuzzerControlScreen({super.key});

  @override
  State<BuzzerControlScreen> createState() => _BuzzerControlScreenState();
}

class _BuzzerControlScreenState extends State<BuzzerControlScreen> {
  // 실시간 자이로스코프 값
  double _gx = 0, _gy = 0, _gz = 0;

  // 15도/s = 15 * π/180 rad/s
  static final double _shakeThresholdRad = 15 * pi / 180;

  // 흔들림 지속 기준
  static const Duration _shakeDuration = Duration(seconds: 3);
  // 가만히 있을 때 false 메시지 지연
  static const Duration _idleDuration = Duration(seconds: 10);

  bool _buzzerOn = false;
  final Stopwatch _shakeStopwatch = Stopwatch();
  Timer? _idleTimer;
  late StreamSubscription<GyroscopeEvent> _sub;

  @override
  void initState() {
    super.initState();
    _sub = gyroscopeEvents.listen(_onGyroEvent);
  }

  void _onGyroEvent(GyroscopeEvent event) {
    setState(() {
      _gx = event.x;
      _gy = event.y;
      _gz = event.z;
    });

    // 축별로 절대값이 임계치 넘는지 확인
    final bool isShaking =
        _gx.abs() > _shakeThresholdRad ||
            _gy.abs() > _shakeThresholdRad ||
            _gz.abs() > _shakeThresholdRad;

    if (isShaking) {
      // 흔들림 감지 → idle 타이머 취소
      _idleTimer?.cancel();
      _idleTimer = null;

      if (!_shakeStopwatch.isRunning) {
        _shakeStopwatch
          ..reset()
          ..start();
      } else if (_shakeStopwatch.elapsed >= _shakeDuration && !_buzzerOn) {
        _shakeStopwatch.stop();
        _sendBuzzer(true);
      }
    } else {
      // 흔들림 멈춤
      if (_shakeStopwatch.isRunning) {
        _shakeStopwatch
          ..stop()
          ..reset();
      }
      // 이미 ON 상태였다면, 10초 대기 후 OFF
      if (_buzzerOn && _idleTimer == null) {
        _idleTimer = Timer(_idleDuration, () {
          _sendBuzzer(false);
        });
      }
    }
  }

  Future<void> _sendBuzzer(bool on) async {
    _buzzerOn = on;
    debugPrint('🔔 Buzzer 메시지: ${on ? 'ON' : 'OFF'}');

    final uri = Uri.parse('https://your.server.com/buzzer');
    try {
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'on': on}),
      );
      final msg = on ? '버저 ON' : '버저 OFF';
      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
        debugPrint('✅ 서버 응답 200: $msg');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('서버 오류: ${res.statusCode}')),
        );
        debugPrint('❌ 서버 오류 코드: ${res.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('네트워크 오류')),
      );
      debugPrint('⚠️ 네트워크 오류: $e');
    }
  }

  @override
  void dispose() {
    _sub.cancel();
    _idleTimer?.cancel();
    _shakeStopwatch.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 시각화를 위해 현재 각 축의 속도를 deg/s 단위로 보여줍니다.
    final degX = (_gx * 180 / pi).toStringAsFixed(1);
    final degY = (_gy * 180 / pi).toStringAsFixed(1);
    final degZ = (_gz * 180 / pi).toStringAsFixed(1);

    return Scaffold(
      appBar: AppBar(title: const Text('자이로 흔들림 제어')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('X: $degX°/s   Y: $degY°/s   Z: $degZ°/s',
                style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 24),
            LinearProgressIndicator(
              value: min(
                  _shakeStopwatch.elapsed.inMilliseconds /
                      _shakeDuration.inMilliseconds,
                  1.0),
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation(
                  _buzzerOn ? Colors.green : Colors.red),
            ),
            const SizedBox(height: 8),
            Text(
              _buzzerOn
                  ? '버저 ON (가만히 10초 후 OFF)'
                  : '흔들림 감지 대기 (15°/s 이상 → 3초 후 ON)',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}