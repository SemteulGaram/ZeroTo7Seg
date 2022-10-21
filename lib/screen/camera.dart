import 'dart:async';
import 'dart:io';
import 'dart:ffi';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as lib_image;
import 'package:path_provider/path_provider.dart';

import 'package:zerolens100/main.dart';
import 'package:zerolens100/screen/segment_ocr_scan/ocr.dart';
import 'package:zerolens100/screen/segment_ocr_scan/painter.dart';
import 'package:zerolens100/utils/logger.dart';

/// tesseract_ocr와 OpenCV FFI 를 사용해 7-Segment OCR을 수행하는 카메라 스크린
class ScreenCamera extends StatefulWidget {
  const ScreenCamera({Key? key}) : super(key: key);

  @override
  _ScreenCameraState createState() => _ScreenCameraState();
}

class _ScreenCameraState extends State<ScreenCamera>
    with WidgetsBindingObserver {
  final Logger log = Logger();

  /// OpenCV FFI
  final dylib = Platform.isAndroid
      ? DynamicLibrary.open("libOpenCV_ffi.so")
      : DynamicLibrary.process();

  /// 주 카메라 컨트롤러
  CameraController? _controller;

  /// 카메라 초기화 대기용 Future
  late Future<void> _initializeControllerFuture;

  /// 카메라 이미지 스트림 활성화
  bool _isStreaming = false;

  /// 카메라 초기화 여부
  bool _isCameraInitialized = false;

  /// 카메라 화질 프리셋들
  final resolutionPresets = ResolutionPreset.values;

  /// 카메라 화질 프리셋 (속도를 위해 너무 높이지 않기)
  ResolutionPreset currentResolutionPreset = ResolutionPreset.medium;

  /// 카메라 플래시 작동 여부
  bool flashMode = false;

  /// 카메라 초점 고정 여부
  bool focusLockMode = false;

  /// 이미지 버퍼
  final Image _imageBuffer1 = Image.asset('assets/default.jpg');
  final Image _imageBuffer2 = Image.asset('assets/default.jpg');

  /// 외부 OCR 인스턴스
  SegmentOcrScanOcr ocrManager = SegmentOcrScanOcr();

  /// OCR 인스턴스로 부터 받은 OCR 결과 정보
  // ! 임시 코드. 나중에 빈 배열로 바꿀 것
  List<OcrDrawDto> ocrDrawDtoList = [
    OcrDrawDto(
      rect: const Rect.fromLTWH(0, 0, 0, 0),
      text: '',
    ),
    OcrDrawDto(
      rect: const Rect.fromLTWH(0, 0, 0, 0),
      text: '',
    ),
  ];

  /// 유저 인터렉션과 추가적인 OCR 요청을 막기 위해 화면을 가리는 로딩창 표시 여부
  bool bload = false;

  /// OCR용 임시 변수
  String _ocrText = '';

  Future<void> startStream() async {
    try {
      await _initializeControllerFuture;
      setState(() => _isStreaming = true);

      // 이미지 스트림 콜백 처리
      await _controller!.startImageStream((CameraImage availableImage) async {
        if (availableImage.planes.isEmpty) {
          log.error('availableImage must not be null');
          return;
        }

        // 요청중이 아닐때만 실행
        if (!bload) {
          bload = true;
          // Save Image plane to gallery
          var image = lib_image.decodeJpg(availableImage.planes[0].bytes);
          if (image == null) {
            log.error('decodeJpg image must not be null');
            return;
          }
          image = lib_image.copyRotate(image, 90);

          var temp = await getTemporaryDirectory();
          var path = temp.path + '/ocr.jpg';
          var file = File(path);
          file.writeAsBytesSync(lib_image.encodeJpg(image, quality: 80));
          log.info('abs path ${file.absolute.path}');
          await requestOCR(file.absolute.path);
          bload = false;
        }
      });
    } catch (e) {
      log.error('image stream callback error: $e');
    }
  }

  /// segment_ocr_scan/ocr.dart 파일에 비동기 OCR 요청 방법
  Future<void> requestOCR(String jpgImagePath) async {
    var result = await ocrManager.computeOcrPreprocess2(jpgImagePath);

    if (result == null || result.need_to_OCR_img_path.isEmpty) {
      return;
    }

    _ocrText = await ocrManager.ocr(result.need_to_OCR_img_path);

    // 스페이스바 인식 다 제거,
    // 추후 정규표현식 사용하여 숫자 이외에 다 제거하는 식으로 변경해야함

    // SYS, DIA
    var ocrTextSplit = _ocrText.split("\n");
    print(_ocrText);
    if (ocrTextSplit.length < 2) {
      return;
    }
    String sys = ocrTextSplit[0];
    String dia = ocrTextSplit[1];
    String pulse = ocrTextSplit.length != 2 ? ocrTextSplit[2] : "";
    //OCR 인식이 제대로 돼서 화면에 그릴 지, 말 지
    bool is_draw = false;
    if (sys.length >= 2 && dia.length >= 2) is_draw = true;
    //OCR 결과 출력

    print("sys, dia, pulse: $sys, $dia, $pulse");

    if (is_draw) {
      List<OcrDrawDto> ocrDrawList = [];
      for (var i = 0; i < result.segmentAreaRect.length; i++) {
        if (i < ocrTextSplit.length) {
          ocrDrawList.add(OcrDrawDto(
            text: ocrTextSplit[i],
            rect: Rect.fromLTWH(
                result.segmentAreaRect[i].left,
                result.segmentAreaRect[i].top,
                result.segmentAreaRect[i].width,
                result.segmentAreaRect[i].height),
          ));
        }
      }
      setState(() {
        // ! 작동 안될때의 임시 예제 코드 !
        /*
        ocrDrawDtoList = [
          OcrDrawDto(
            rect: const Rect.fromLTWH(50, 200, 200, 100),
            text: '127',
          ),
          OcrDrawDto(
            rect: const Rect.fromLTWH(80, 500, 100, 70),
            text: '74',
          ),
        ];
        // ! 작동되면 아래 코드를 대신 이용할 것 !

         */
        ocrDrawDtoList = ocrDrawList;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const textStyleP = TextStyle(color: Colors.white, fontSize: 20.0);
    // var deviceSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: (_isCameraInitialized &&
              _controller != null &&
              _controller!.value.previewSize != null)
          ? Stack(
              children: [
                AspectRatio(
                  aspectRatio: 1 / _controller!.value.aspectRatio,
                  child: Stack(
                    children: [
                      _controller!.buildPreview(),
                      CustomPaint(
                        foregroundPainter: SegmentOcrScanPainter(
                            ocrDrawDtoList: ocrDrawDtoList),
                        child: Container(
                          padding: const EdgeInsets.all(5.0),
                          alignment: Alignment.bottomCenter,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: <Color>[
                                Colors.black.withAlpha(0),
                                Colors.black.withAlpha(0),
                                Colors.black.withAlpha(0),
                                Colors.black.withAlpha(0),
                                Colors.black.withAlpha(0),
                                Colors.black.withAlpha(0),
                                Colors.black12,
                                Colors.black
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                          top: 40.0, left: 20.0, right: 20.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('혈압계 OCR 인식', style: textStyleP),
                          Expanded(
                            child: Container(),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Container(),
                    ),
                    const Text(
                      '최고 혈압 부분이 사각형 영역에 겹치도록 놓아주세요',
                      style: textStyleP,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                          bottom: 40.0, left: 20.0, right: 20.0, top: 20.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            icon: const Icon(Icons.arrow_back_ios_new),
                            color: Colors.white,
                            tooltip: '뒤로가기',
                          ),
                          IconButton(
                            onPressed: () {
                              // ! 디버깅 목적으로 포커스 버튼을 누를 때 OCR을 실행하도록 바꿔둠 !
                              //requestOCR();
                              startStream();
                              return;

                              if (focusLockMode) {
                                _controller!.setFocusMode(FocusMode.auto);
                              } else {
                                _controller!.setFocusMode(FocusMode.locked);
                              }
                              setState((() {
                                focusLockMode = !focusLockMode;
                              }));
                            },
                            icon: Icon(focusLockMode
                                ? Icons.do_not_disturb
                                : Icons.filter_center_focus),
                            color: Colors.white,
                            tooltip: '포커싱 잠금',
                          ),
                          IconButton(
                            onPressed: () async {
                              // 플래시 모드 변경
                              if (flashMode) {
                                await _controller?.setFlashMode(FlashMode.off);
                              } else {
                                await _controller
                                    ?.setFlashMode(FlashMode.torch);
                              }
                              setState(() {
                                flashMode = !flashMode;
                              });
                            },
                            icon: Icon(flashMode
                                ? Icons.lightbulb
                                : Icons.lightbulb_outline),
                            color: Colors.white,
                            tooltip: '플래시',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            )
          : Center(
              child: Column(
                children: [
                  Expanded(child: Container()),
                  const Padding(
                    padding: EdgeInsets.all(10.0),
                    child: CircularProgressIndicator(),
                  ),
                  const Text(
                    '카메라 준비 중...',
                    style: TextStyle(color: Colors.white, fontSize: 20.0),
                  ),
                  Expanded(child: Container()),
                ],
              ),
            ),
    );
  }

  void onNewCameraSelected(CameraDescription cameraDescription) async {
    final previousCameraController = _controller;
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
        _controller = cameraController;
      });
    }

    // 컨트롤러가 바뀌였다면, UI 업데이트
    cameraController.addListener(() {
      if (mounted) setState(() {});
    });

    // 컨트롤러 초기화
    _initializeControllerFuture = cameraController.initialize();
    _initializeControllerFuture.catchError((e) {
      log.error('Error initializing camera: $e');
    });

    _initializeControllerFuture.then((value) {
      // 준비 완료 플래그
      if (mounted) {
        setState(() {
          _isCameraInitialized = _controller!.value.isInitialized;
        });
      }
    });
  }

  @override
  void initState() {
    // 카메라 선택 (기본값 0)
    if (cameras.isNotEmpty) {
      onNewCameraSelected(cameras[0]);
    }
    super.initState();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _controller;

    // 초기화 하기 전에 상태가 바뀌는 경우 무시
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
}
