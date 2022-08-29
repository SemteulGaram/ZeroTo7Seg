import 'dart:async';
import 'dart:typed_data';
import 'dart:io';
import 'dart:math';
import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';
import 'package:image/image.dart' as IMG;
import 'package:flutter/foundation.dart';

import 'package:zerolens100/main.dart';
import 'package:zerolens100/screen/segment_ocr_scan/painter.dart';

class ScreenSegmentOcrScan extends StatefulWidget {
  const ScreenSegmentOcrScan({Key? key}) : super(key: key);

  @override
  _SegmentOcrScanState createState() => _SegmentOcrScanState();
}

class _SegmentOcrScanState extends State<ScreenSegmentOcrScan>
    with WidgetsBindingObserver {
  // === OpenCV FFI ===
  final dylib = Platform.isAndroid
      ? DynamicLibrary.open("libOpenCV_ffi.so")
      : DynamicLibrary.process();

  // === 카메라 데이터 ===
  CameraController? _controller;
  late Future<void> _initializeControllerFuture;
  bool _isCameraInitialized = false;
  bool _isStreaming = false;
  Image _img = Image.asset('assets/default.jpg');
  Image _old = Image.asset('assets/default.jpg');
  final resolutionPresets = ResolutionPreset.values;
  ResolutionPreset currentResolutionPreset = ResolutionPreset.low;

  // === Tesseract 데이터 ===
  String _ocrText = '';
  // var LangList = ["kor", "eng", "deu", "chi_sim", "seven_seg"];
  var selectList = ["seven_seg"];
  String path = "";
  bool bload = false;
  bool bDownloadtessFile = false;

  Future<void> writeToFile(ByteData data, String path) {
    final buffer = data.buffer;
    return new File(path).writeAsBytes(
        buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
  }

  void runFilePiker() async {
    // android && ios only
    final pickedFile =
        await ImagePicker().getImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      _ocr(pickedFile.path);
    }
  }

  Future<void> doOcr() async {
    bload = true;

    var captureFile = await _controller!.takePicture();
    _ocrText = captureFile.path;
    await imagePreprocess(_ocrText);
    await _ocr(_ocrText);

    bload = false;
  }

  Future<void> imagePreprocess(String filePath) async {
    // Uint8List _byte = await Cv2.adaptiveThreshold(
    //     pathFrom: CVPathFrom.ASSETS,
    //     pathString: filePath,
    //     maxValue: 220,
    //     adaptiveMethod: Cv2.ADAPTIVE_THRESH_MEAN_C,
    //     thresholdType: Cv2.THRESH_BINARY,
    //     blockSize: 11,
    //     constantValue: 12
    // );

    Uint8List bytes = await File(filePath).readAsBytes();
    IMG.Image? src = IMG.decodeImage(bytes);

    if (src == null) {
      // TODO: alert dialog
      print("src is NULL");
      return;
    }

    var cropSize = min(src.width, src.height);
    int offsetX = (src.width - min(src.width, src.height)) ~/ 2;
    int offsetY = (src.height - min(src.width, src.height)) ~/ 2;

    IMG.Image destImage =
        IMG.copyCrop(src, offsetX, offsetY, cropSize, cropSize);

    // if (flip) {
    //   destImage = IMG.flipVertical(destImage);
    // }

    var jpg = IMG.encodeJpg(destImage);
    await File(filePath).writeAsBytes(jpg);
  }

  Future<void> _ocr(url) async {
    if (selectList.length <= 0) {
      print("Please select language");
      return;
    }
    path = url;
    if (kIsWeb == false &&
        (url.indexOf("http://") == 0 || url.indexOf("https://") == 0)) {
      Directory tempDir = await getTemporaryDirectory();
      HttpClient httpClient = new HttpClient();
      HttpClientRequest request = await httpClient.getUrl(Uri.parse(url));
      HttpClientResponse response = await request.close();
      Uint8List bytes = await consolidateHttpClientResponseBytes(response);
      String dir = tempDir.path;
      print('$dir/test.jpg');
      File file = new File('$dir/test.jpg');
      await file.writeAsBytes(bytes);
      url = file.path;
    }
    var langs = selectList.join("+");

    setState(() {});

    _ocrText = await FlutterTesseractOcr.extractText(url,
        language: langs,
        args: {"preserve_interword_spaces": "1", "psm": "6", "oem": "3"});
    //  ========== Test performance  ==========
    // DateTime before1 = DateTime.now();
    // print('init : start');
    // for (var i = 0; i < 10; i++) {
    //   _ocrText =
    //       await FlutterTesseractOcr.extractText(url, language: langs, args: {
    //     "preserve_interword_spaces": "1",
    //   });
    // }
    // DateTime after1 = DateTime.now();
    // print('init : ${after1.difference(before1).inMilliseconds}');
    //  ========== Test performance  ==========

    // _ocrHocr =
    //     await FlutterTesseractOcr.extractHocr(url, language: langs, args: {
    //   "preserve_interword_spaces": "1",
    // });
    // print(_ocrText);
    // print(_ocrText);

    // === web console test code ===
    // var worker = Tesseract.createWorker();
    // await worker.load();
    // await worker.loadLanguage("eng");
    // await worker.initialize("eng");
    // // await worker.setParameters({ "tessjs_create_hocr": "1"});
    // var rtn = worker.recognize("https://tesseract.projectnaptha.com/img/eng_bw.png");
    // console.log(rtn.data);
    // await worker.terminate();
    // === web console test code ===

    setState(() {});
  }

  @override
  void initState() {
    // 카메라 선택 (기본값 0)
    onNewCameraSelected(cameras[0]);
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

  @override
  Widget build(BuildContext context) {
    var vw100 = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Text("🥼 0to100 7-Segment OCR Camera"),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Stack(
                children: [
                  _isCameraInitialized
                      ? AspectRatio(
                          aspectRatio: 1,
                          child: ClipRect(
                            child: Transform.scale(
                              scale: _controller!.value.aspectRatio,
                              child: Center(
                                child: AspectRatio(
                                  aspectRatio:
                                      1 / _controller!.value.aspectRatio,
                                  child: /*_controller!.buildPreview()*/ Stack(
                                      children: [_old, _img]),
                                ), // this is my CameraPreview
                              ),
                            ),
                          ),
                        )
                      : Container(),
                  CustomPaint(
                    foregroundPainter: SegmentOcrScanPainter(),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Container(
                        padding: const EdgeInsets.all(5.0),
                        alignment: Alignment.bottomCenter,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: <Color>[
                              Colors.black.withAlpha(0),
                              Colors.black12,
                              Colors.black87
                            ],
                          ),
                        ),
                        child: const Text(
                          '혈압계 화면이 사각형 영역에 겹치도록 놓아주세요',
                          style: TextStyle(color: Colors.white, fontSize: 20.0),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 5, 10, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                          onPressed: bload
                              ? null
                              : () {
                                  doOcr();
                                },
                          child: const Text("📷 인식")),
                    ),
                  ],
                ),
              ),
              Expanded(
                  child: ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                    child: bload
                        ? Column(children: const [CircularProgressIndicator()])
                        : Text(
                            '$_ocrText',
                          ),
                  ),
                  path.isEmpty
                      ? Container()
                      : path.contains("http")
                          ? Image.network(path)
                          : Image.file(File(path)),
                ],
              ))
            ],
          ),
          Container(
            color: Colors.black26,
            child: bDownloadtessFile
                ? Center(
                    child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      Text('download Trained language files')
                    ],
                  ))
                : SizedBox(),
          )
        ],
      ),

      floatingActionButton: kIsWeb
          ? Container()
          : FloatingActionButton(
              onPressed: () async {
                // runFilePiker();
                // Take the Picture in a try / catch block. If anything goes wrong,
                // catch the error.
                try {
                  // Ensure that the camera is initialized.
                  await _initializeControllerFuture;
                  if (_isStreaming) {
                    await _controller!.stopImageStream();
                    print("Stopped");
                    setState(() => _isStreaming = false);
                  } else {
                    setState(() => _isStreaming = true);
                    print("Starting");

                    await _controller!
                        .startImageStream((CameraImage availableImage) async {
                      Pointer<Uint32> s = malloc.allocate(1);
                      s[0] = availableImage.planes[0].bytes.length;
                      Pointer<Uint8> p = malloc.allocate(3 *
                          availableImage.height *
                          availableImage
                              .width); // Taking extra space for buffer
                      p
                          .asTypedList(s[0])
                          .setRange(0, s[0], availableImage.planes[0].bytes);

                      final imageffi = dylib.lookupFunction<
                          Void Function(Pointer<Uint8>, Pointer<Uint32>),
                          void Function(
                              Pointer<Uint8>, Pointer<Uint32>)>('image_ffi');
                      imageffi(p, s);

                      if (mounted) {
                        setState(() {
                          _old = _img;
                          _img = Image.memory(p.asTypedList(s[0]));
                        });
                      }

                      malloc.free(p);
                      malloc.free(s);
                    });
                  }
                } catch (e) {
                  // If an error occurs, log the error to the console.
                  print(e);
                }
              },
              tooltip: 'OCR',
              child: const Icon(Icons.lens),
            ), // This trailing comma makes auto-formatting nicer for build methods.
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
      print('Error initializing camera: $e');
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
}
