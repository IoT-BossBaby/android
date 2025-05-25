import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// pubspec.yaml 에 반드시 추가하세요!
/// dependencies:
///   http: ^0.13.4

class BuzzerControlScreen extends StatefulWidget {
  const BuzzerControlScreen({super.key});

  @override
  State<BuzzerControlScreen> createState() => _BuzzerControlScreenState();
}

class _BuzzerControlScreenState extends State<BuzzerControlScreen> {
  int _selectedIndex = 3; // BottomNav 에서 네 번째(버저) 탭

  Future<void> _setBuzzer(bool on) async {
    final uri = Uri.parse('https://your.server.com/buzzer');
    try {
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'on': on}),
      );
      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(on ? '버저를 켰습니다' : '버저를 끕니다')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('서버 오류: ${res.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('네트워크 오류가 발생했습니다')),
      );
    }
  }

  void _onNavTap(int idx) {
    setState(() => _selectedIndex = idx);
    // TODO: 각 탭별 화면 전환 로직
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEFCEE),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              const SizedBox(height: 16),
              const Align(
                alignment: Alignment.centerLeft,                child: Text(
                  '버저 울리기',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // 버튼 1: 버저 켜기
              ElevatedButton(
                onPressed: () => _setBuzzer(true),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  backgroundColor: const Color(0xFFD87F7F),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  '버저울리기',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
              const SizedBox(height: 16),

              // 버튼 2: 버저 끄기
              ElevatedButton(
                onPressed: () => _setBuzzer(false),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  backgroundColor: Colors.black87,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  '버저 끄기',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),

              Expanded(child: Container()),
            ],
          ),
        ),
      ),
      // bottomNavigationBar: BottomNavigationBar(
      //   currentIndex: _selectedIndex,
      //   onTap: _onNavTap,
      //   type: BottomNavigationBarType.fixed,
      //   backgroundColor: Colors.white,
      //   showSelectedLabels: false,
      //   showUnselectedLabels: false,
      //   selectedItemColor: const Color(0xFFFFC107),
      //   unselectedItemColor: Colors.grey,
      //   items: const [
      //     BottomNavigationBarItem(icon: Icon(Icons.home, size: 28), label: ''),
      //     BottomNavigationBarItem(icon: Icon(Icons.search, size: 28), label: ''),
      //     BottomNavigationBarItem(icon: Icon(Icons.assignment, size: 28), label: ''),
      //     BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline, size: 28), label: ''),
      //   ],
      // ),
    );
  }
}
