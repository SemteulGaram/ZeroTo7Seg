import 'dart:ffi';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tesseract_ocr/android_ios.dart';
import 'package:image/image.dart' as lib_image;
import 'package:path_provider/path_provider.dart';

class OcrPreprocessResult {
  String need_to_OCR_img_path;
  List<Rect> segmentAreaRect;

  OcrPreprocessResult({
    required this.need_to_OCR_img_path,
    required this.segmentAreaRect,
  });
}

class SegmentOcrScanOcr {
  // === OpenCV FFI ===
  static final dylib = Platform.isAndroid
      ? DynamicLibrary.open("libOpenCV_ffi.so")
      : DynamicLibrary.process();

  // 최초에 구현했던 OCR 메서드 (ocrPreprocess, ocr) (사용되지 않음 DEPRECATED)
  Future<void> ocrPreprocess(String filePath) async {
    Uint8List bytes = await File(filePath).readAsBytes();
    lib_image.Image? src = lib_image.decodeImage(bytes);

    if (src == null) {
      // TODO: alert dialog
      print("src is NULL");
      return;
    }

    var cropSize = min(src.width, src.height);
    int offsetX = (src.width - min(src.width, src.height)) ~/ 2;
    int offsetY = (src.height - min(src.width, src.height)) ~/ 2;

    lib_image.Image destImage =
        lib_image.copyCrop(src, offsetX, offsetY, cropSize, cropSize);

    var jpg = lib_image.encodeJpg(destImage);
    await File(filePath).writeAsBytes(jpg);
  }

  Future<String> ocr(String imgPath) async {
    print('WAT: $imgPath');
    final ocrText = await FlutterTesseractOcr.extractText(imgPath,
        language: 'seven_seg',
        args: {"preserve_interword_spaces": "1", "psm": "6", "oem": "3"});

    return ocrText;
  }

  // 현재 사용하는 비동기 compute 기반 멀티 스래드 OCR 처리 (computeOcrPreprocess2, _computeOcrPreprocess2, computeOcr2)
  Future<OcrPreprocessResult?> computeOcrPreprocess2(String imgPath) async {
    return await compute(_computeOcrPreprocess2, imgPath);
  }

  static Future<OcrPreprocessResult?> _computeOcrPreprocess2(
      String imgPath) async {
    try {
      // 버퍼 사이즈 변수 + 세그먼트 감지된 영역 x, y, w, h * 2영역 = 8
      Pointer<Uint32> nativeSize = malloc.allocate(9);
      // 전체 이미지를 담아도 남을 사이즈의 버퍼

      Uint8List bytes = await File(imgPath).readAsBytes();
      lib_image.Image? src = lib_image.decodeJpg(bytes);
      int width = (src != null) ? src.width : 1;
      int height = (src != null) ? src.height : 1;
      print(3 * width * height);
      Pointer<Uint8> nativeBuffer = malloc.allocate(3 * width * height);
      nativeSize[0] = bytes.length;
      print(nativeSize[0]);

      nativeBuffer.asTypedList(nativeSize[0]).setRange(0, nativeSize[0], bytes);

      final ffiOcrPreprocess = dylib.lookupFunction<
          Void Function(Pointer<Uint8>, Pointer<Uint32>),
          void Function(Pointer<Uint8>, Pointer<Uint32>)>('ffi_ocr_preprocess');

      // FFI 호출
      ffiOcrPreprocess(nativeBuffer, nativeSize);
      // 반환값 정리
      /*
    final segmentAreaImg = lib_image.Image.fromBytes(
      img.width,
      img.height,
      nativeBuffer.asTypedList(nativeSize[0]),
    );
    */
      // final pathOfImage = await File(imgPath);
      // final Uint8List result_img = nativeBuffer.asTypedList(nativeSize[0]);
      // await pathOfImage.writeAsBytes(result_img);
      String need_to_OCR_img_path = imgPath;

      // segment 인식 실패시 rectangle 값이 0으로 채워짐
      // final segmentAreaRect = [
      //   Rect.fromLTWH(
      //     nativeSize[1].toDouble(),
      //     nativeSize[2].toDouble(),
      //     nativeSize[3].toDouble(),
      //     nativeSize[4].toDouble(),
      //   ),
      //   Rect.fromLTWH(
      //     nativeSize[5].toDouble(),
      //     nativeSize[6].toDouble(),
      //     nativeSize[7].toDouble(),
      //     nativeSize[8].toDouble(),
      //   ),
      // ];
      final segmentAreaRect = [
        const Rect.fromLTWH(0, 0, 0, 0),
        const Rect.fromLTWH(0, 0, 0, 0),
      ];
      // 메모리 해제

      malloc.free(nativeSize);
      malloc.free(nativeBuffer);

      // OcrPreprocessResult 반환
      //
      return OcrPreprocessResult(
        need_to_OCR_img_path: need_to_OCR_img_path,
        segmentAreaRect: segmentAreaRect,
      );
    } catch (e) {
      print('Safely ignored error: $e');

      return null;
    }
  }
}
