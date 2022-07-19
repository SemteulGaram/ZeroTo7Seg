import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../main.dart';

class ScreenCamera extends StatefulWidget {
  const ScreenCamera({Key? key}) : super(key: key);

  @override
  _ScreenCameraState createState() => _ScreenCameraState();
}

class _ScreenCameraState extends State<ScreenCamera> with WidgetsBindingObserver {
  CameraController? controller;
  bool _isCameraInitialized = false;
  final resolutionPresets = ResolutionPreset.values;
  ResolutionPreset currentResolutionPreset = ResolutionPreset.high;

  @override
  void initState() {
    // 기본값은 카메라 0번 선택
    onNewCameraSelected(cameras[0]);
    super.initState();
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isCameraInitialized
        ? Center(
          child: AspectRatio(
            aspectRatio: 1 / controller!.value.aspectRatio,
            child: controller!.buildPreview(),
          )
        )
        : Container(),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = controller;

    // 초기화 하기 전에 상태가 바뀌는 경우
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      // 앱이 비활성 상태일때 메모리 해제
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      // 앱이 다시 활성되면 동일한 속성으로 카메라 재 초기화
      onNewCameraSelected(cameraController.description);
    }
  }

  void onNewCameraSelected(CameraDescription cameraDescription) async {
    final previousCameraController = controller;
    // 카메라 컨트롤러 인스턴스화
    final CameraController cameraController = CameraController(
      cameraDescription,
      currentResolutionPreset,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    // 이전 컨트롤러 dispose
    await previousCameraController?.dispose();

    // 새 컨트롤러로 교체
    if (mounted) {
      setState(() {
        controller = cameraController;
      });
    }

    // 컨트롤러가 바뀌였다면, UI 업데이트
    cameraController.addListener(() {
      if (mounted) setState(() {});
    });

    // 컨트롤러 초기화
    try {
      await cameraController.initialize();
    } on CameraException catch (e) {
      // TODO: 더 나은 로깅 옵션 찾기
      print('Error initializing camera: $e');
    }

    // 준비 완료 플래그
    if (mounted) {
      setState(() {
        _isCameraInitialized = controller!.value.isInitialized;
      });
    }
  }
}