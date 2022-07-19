import 'dart:async';
import 'dart:typed_data';
import 'dart:io';
import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';
import 'package:opencv_4/opencv_4.dart';
import 'package:opencv_4/factory/colormaps/applycolormap_factory.dart';
import 'package:opencv_4/factory/colorspace/cvtcolor_factory.dart';
import 'package:opencv_4/factory/imagefilter/bilateralfilter_factory.dart';
import 'package:opencv_4/factory/imagefilter/blur_factory.dart';
import 'package:opencv_4/factory/imagefilter/boxfilter_factory.dart';
import 'package:opencv_4/factory/imagefilter/dilate_factory.dart';
import 'package:opencv_4/factory/imagefilter/erode_factory.dart';
import 'package:opencv_4/factory/imagefilter/filter2d_factory.dart';
import 'package:opencv_4/factory/imagefilter/gaussianblur_factoy.dart';
import 'package:opencv_4/factory/imagefilter/laplacian_factory.dart';
import 'package:opencv_4/factory/imagefilter/medianblur_factory.dart';
import 'package:opencv_4/factory/imagefilter/morphologyex_factory.dart';
import 'package:opencv_4/factory/imagefilter/pyrmeanshiftfiltering_factory.dart';
import 'package:opencv_4/factory/imagefilter/scharr_factory.dart';
import 'package:opencv_4/factory/imagefilter/sobel_factory.dart';
import 'package:opencv_4/factory/imagefilter/sqrboxfilter_factory.dart';
import 'package:opencv_4/factory/miscellaneoustransform/adaptivethreshold_factory.dart';
import 'package:opencv_4/factory/miscellaneoustransform/distancetransform_factory.dart';
import 'package:opencv_4/factory/miscellaneoustransform/threshold_factory.dart';
import 'package:opencv_4/factory/pathfrom.dart';
import 'package:image/image.dart' as IMG;
import 'package:flutter/foundation.dart';

import 'package:zerolens100/main.dart';

class SegmentOcrScan extends StatefulWidget {
  const SegmentOcrScan({Key? key}) : super(key: key);

  @override
  _SegmentOcrScanState createState() => _SegmentOcrScanState();
}

class _SegmentOcrScanState extends State<SegmentOcrScan> with WidgetsBindingObserver {
  // 카메라 데이터
  CameraController? controller;
  bool _isCameraInitialized = false;
  final resolutionPresets = ResolutionPreset.values;
  ResolutionPreset currentResolutionPreset = ResolutionPreset.high;

  // Tesseract 데이터
  String _ocrText = '';
  String _ocrHocr = '';
  Map<String, String> tessimgs = {
    "kor": "https://raw.githubusercontent.com/khjde1207/tesseract_ocr/master/example/assets/test1.png",
    "en": "https://tesseract.projectnaptha.com/img/eng_bw.png",
    "ch_sim": "https://tesseract.projectnaptha.com/img/chi_sim.png",
    "ru": "https://tesseract.projectnaptha.com/img/rus.png",
  };
  var LangList = ["kor", "eng", "deu", "chi_sim", "seven_seg"];
  var selectList = ["seven_seg"];
  String path = "";
  bool bload = false;

  bool bDownloadtessFile = false;
  // "https://img1.daumcdn.net/thumb/R1280x0/?scode=mtistory2&fname=https%3A%2F%2Fblog.kakaocdn.net%2Fdn%2FqCviW%2FbtqGWTUaYLo%2FwD3ZE6r3ARZqi4MkUbcGm0%2Fimg.png";
  var urlEditController = TextEditingController()..text = "http://192.168.5.200:3000/index.jpg";

  Future<void> writeToFile(ByteData data, String path) {
    final buffer = data.buffer;
    return new File(path).writeAsBytes(buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
  }

  void runFilePiker() async {
    // android && ios only
    final pickedFile = await ImagePicker().getImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      _ocr(pickedFile.path);
    }
  }

  Future<void> doOcr() async {
    bload = true;

    var captureFile = await controller!.takePicture();
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

    _ocrText =
    await FlutterTesseractOcr.extractText(url, language: langs, args: {
      "preserve_interword_spaces": "1",
      "psm": "6",
      "oem": "3"
    });
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
    controller?.dispose();
    super.dispose();
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
              _isCameraInitialized ?
              AspectRatio(
                aspectRatio: 1,
                child: ClipRect(
                  child: Transform.scale(
                    scale: controller!.value.aspectRatio,
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: 1 / controller!.value.aspectRatio,
                        child: controller!.buildPreview(),
                      ), // this is my CameraPreview
                    ),
                  ),
                ),
              ) : Container(),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 5, 10, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                          onPressed: bload ? null : () {
                            doOcr();
                          },
                          child: const Text("📷 인식")
                      ),
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
                  )
              )
            ],
          ),
          Container(
            color: Colors.black26,
            child: bDownloadtessFile
                ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [CircularProgressIndicator(), Text('download Trained language files')],
                ))
                : SizedBox(),
          )
        ],
      ),

      floatingActionButton: kIsWeb
          ? Container()
          : FloatingActionButton(
        onPressed: () {
          runFilePiker();
          // _ocr("");
        },
        tooltip: 'OCR',
        child: Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
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
