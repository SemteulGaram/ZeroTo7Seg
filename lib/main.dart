// 종속성
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
// 직접 선언한 스크린들
import 'package:zerolens100/screen/index.dart';
import 'package:zerolens100/screen/camera.dart';
import 'package:zerolens100/utils/logger.dart';

// 루트 카메라 리스트
List<CameraDescription> cameras = [];

// 로거
Logger log = Logger();

Future<void> main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    cameras = await availableCameras();
  } on CameraException catch (e) {
    log.error('Error in fetching the cameras: $e');
  }
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ZeroLens100',
      theme: ThemeData(
        colorSchemeSeed: Colors.pinkAccent,
        // primarySwatch: Colors.blue,
      ),
      routes: {
        '/': (context) => const ScreenCamera(), //const ScreenIndex(),
        '/ocr': (context) => const ScreenCamera(),
      },
    );
  }
}
