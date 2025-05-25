import 'package:flutter/material.dart';
import 'package:flutter_mjpeg/flutter_mjpeg.dart';
import 'Screen/temperture_2.dart';
import 'Screen/buzzer.dart';
import 'Screen/VideoStream.dart';

// config 파일 -> 서버 주소 저장(없으면 수동 입력)
import 'config.dart' as cfg;

//임시로 넣은 class
class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});
  @override
  Widget build(BuildContext c) => const Center(child: Text('Search Screen'));
}

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.text = cfg.serverUrl;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _applyUrl() {
    // 버튼 누를 때만 URL 설정
    setState(() {
      cfg.serverUrl = _controller.text.trim();
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const SearchScreen(),
      VideoStreamScreen(),
      const HumidityBuzzerScreen(),
      const BuzzerControlScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('서버 주소'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: Column(
        children: [
          // URL 입력
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'https://your.server.com/camera/stream',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _applyUrl,
                  child: const Text('적용'),
                ),
              ],
            ),
          ),
          // 현재 페이지
          Expanded(child: pages[_currentIndex]),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        selectedItemColor: const Color(0xFFFFC107),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.thermostat), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.volume_up), label: ''),
        ],
      ),
    );
  }
}

// 이하 AnalyzeScreen, HumidityCheckScreen, BuzzerControlScreen 은
// 각자의 파일(Screen/analyze.dart 등)에 구현되어 있다고 가정합니다.

