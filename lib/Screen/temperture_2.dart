import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../config.dart' as cfg;

class HumidityBuzzerScreen extends StatefulWidget {
  const HumidityBuzzerScreen({Key? key}) : super(key: key);

  @override
  State<HumidityBuzzerScreen> createState() => _HumidityBuzzerScreenState();
}

class _HumidityBuzzerScreenState extends State<HumidityBuzzerScreen> {
  double _temperature = -1.0;
  double _humidity = -1.0;
  bool _babyDetected = false;
  double _confidence = -1.0;
  bool _isBuzzerOn = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchSensorData();
  }

  Future<void> _fetchSensorData() async {
    final base = cfg.serverUrl.trim();
    print('📡 서버 주소: $base');
    if (base.isEmpty) {
      _showSnackBar('서버 주소가 비어 있습니다');
      return;
    }

    final uri = Uri.parse('$base/app/data/latest');
    setState(() => _isLoading = true);

    try {
      final res = await http.get(uri);

      if (res.statusCode == 200) {
        final jsonData = json.decode(res.body);
        print('📦 Response body: ${res.body}');
        final data = jsonData['data'];
        if (data != null) {
          setState(() {
            _temperature = (data['temperature'] as num?)?.toDouble() ?? 0.0;
            _humidity    = (data['humidity'] as num?)?.toDouble() ?? 0.0;
            _babyDetected = data['baby_detected'] ?? false;
            _confidence  = (data['confidence'] as num?)?.toDouble() ?? 0.0;
          });
        } else {
          _showSnackBar('센서 데이터가 없습니다');
        }
      } else {
        _showSnackBar('서버 오류: ${res.statusCode}');
      }
    } catch (e) {
      _showSnackBar('데이터 불러오기 실패: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _setBuzzer(bool on) async {
    final base = cfg.serverUrl.trim();
    if (base.isEmpty) {
      _showSnackBar('서버 주소가 비어 있습니다');
      return;
    }

    final uri = Uri.parse('$base/app/command');
    try {
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'on': on}),
      );

      if (res.statusCode == 200) {
        setState(() => _isBuzzerOn = on);
        _showSnackBar(on ? '버저를 켰습니다' : '버저를 껐습니다');
      } else {
        _showSnackBar('버저 제어 실패: ${res.statusCode}');
      }
    } catch (e) {
      _showSnackBar('버저 제어 중 오류 발생: $e');
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEFCEE),
      appBar: AppBar(
        title: const Text('온습도 & 버저 제어'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Icon(Icons.thermostat, size: 40, color: Colors.black87),
                      const SizedBox(height: 12),
                      Text(
                        '현재 온도: ${_temperature.toStringAsFixed(1)}°C',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '현재 습도: ${_humidity.toStringAsFixed(1)}%',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '아기 감지 여부: ${_babyDetected ? '감지됨 👶' : '없음'}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: _babyDetected ? Colors.redAccent : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '신뢰도: ${(_confidence * 100).toStringAsFixed(1)}%',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _isLoading ? null : _fetchSensorData,
                        icon: const Icon(Icons.refresh),
                        label: const Text('새로고침'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => _setBuzzer(true),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  backgroundColor: _isBuzzerOn ? Colors.redAccent : const Color(0xFFD87F7F),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('버저 울리기', style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _setBuzzer(false),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  backgroundColor: !_isBuzzerOn ? Colors.grey : Colors.black87,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('버저 끄기', style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
