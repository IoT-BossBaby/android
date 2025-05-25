// import 'package:flutter/material.dart';
// import 'package:flutter_mjpeg/flutter_mjpeg.dart';
//
// // 서버 주소를 전역 설정에서 가져옵니다.
// import '../config.dart' as cfg;
//
// /// ESP-EYE MJPEG 스트림을 렌더링하는 위젯
// class VideoStreamScreen extends StatelessWidget {
//   const VideoStreamScreen({Key? key}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     final streamUrl = cfg.serverUrl;
//
//     // URL이 비어있으면 입력 안내
//     if (streamUrl.isEmpty) {
//       return const Center(child: Text('URL을 입력해 주세요'));
//     }
//
//     return Column(
//       children: [
//         const SizedBox(height: 16),
//         Expanded(
//           child: Container(
//             margin: const EdgeInsets.symmetric(horizontal: 16),
//             decoration: BoxDecoration(
//               color: Colors.black,
//               borderRadius: BorderRadius.circular(8),
//             ),
//             child: Mjpeg(
//               stream: streamUrl,
//               isLive: true,
//               error: (ctx, err, st) => const Center(
//                 child: Text(
//                   '영상 로드 실패',
//                   style: TextStyle(color: Colors.white),
//                 ),
//               ),
//               loading: (ctx) => const Center(
//                 child: CircularProgressIndicator(),
//               ),
//             ),
//           ),
//         ),
//         const SizedBox(height: 16),
//       ],
//     );
//   }
// }

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

// 서버 주소를 전역 설정에서 가져옵니다.
import '../config.dart' as cfg;

/// ESP-EYE WebSocket 실시간 영상 렌더링 위젯
class VideoStreamScreen extends StatefulWidget {
  const VideoStreamScreen({Key? key}) : super(key: key);

  @override
  State<VideoStreamScreen> createState() => _VideoStreamScreenState();
}

class _VideoStreamScreenState extends State<VideoStreamScreen> {
  WebSocketChannel? _channel;
  Uint8List? _latestFrame;

  @override
  void initState() {
    super.initState();
    final serverUrl = cfg.serverUrl.trim();
    if (serverUrl.isNotEmpty) {
      final uri = Uri.parse(serverUrl.replaceFirst('http', 'ws') + '/app/stream');
      _channel = WebSocketChannel.connect(uri);
      _channel!.stream.listen((data) {
        if (data is String) {
          try {
            final bytes = base64Decode(data);
            setState(() => _latestFrame = bytes);
          } catch (e) {
            debugPrint('Invalid frame: $e');
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _channel?.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: _latestFrame != null
          ? Image.memory(_latestFrame!)
          : const Text('스트림을 수신 중입니다...'),
    );
  }
}
