import 'dart:ffi';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tesseract_ocr/android_ios.dart';
import 'package:image/image.dart' as lib_image;

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

  Future<String> ocr(imgPath) async {
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
    print(imgPath);
    // 버퍼 사이즈 변수 + 세그먼트 감지된 영역 x, y, w, h * 2영역 = 8

    // 전체 이미지를 담아도 남을 사이즈의 버퍼

    Uint8List bytes = await File(imgPath).readAsBytes();

    lib_image.Image? src = lib_image.decodeImage(bytes);
    int width = (src != null) ? src.width : 1;
    int height = (src != null) ? src.height : 1;

    Pointer<Int32> nativeSize = malloc.allocate<Int32>(1);
    Pointer<Uint8> nativeBuffer = malloc.allocate<Uint8>(3 * width * height);
    nativeSize[0] = bytes.length;
    print(3 * width * height);
    print(nativeSize[0]);

    nativeBuffer.asTypedList(nativeSize[0]).setRange(0, nativeSize[0], bytes);
    final ffiOcrPreprocess = dylib.lookupFunction<
        Pointer<Float> Function(Pointer<Uint8>, Pointer<Int32>),
        Pointer<Float> Function(
            Pointer<Uint8>, Pointer<Int32>)>('ffi_ocr_preprocess');

    // FFI 호출
    var res = ffiOcrPreprocess(nativeBuffer, nativeSize);
    print(res.asTypedList(8).toString());

    // 반환값 정리
    /*
    final segmentAreaImg = lib_image.Image.fromBytes(
      img.width,
      img.height,
      nativeBuffer.asTypedList(nativeSize[0]),
    );
    */
    String need_to_OCR_img_path = imgPath;
    final segmentAreaRect;

    bool nullFlag = false;
    if (nativeSize[0] != 0) {
      final pathOfImage = await File(imgPath);
      final Uint8List result_img = nativeBuffer.asTypedList(nativeSize[0]);
      await pathOfImage.writeAsBytes(result_img);

      double x1, y1, w1, h1, x2, y2, w2, h2;
      x1 = res[0];
      y1 = res[1];
      w1 = res[2];
      h1 = res[3];
      x2 = res[4];
      y2 = res[5];
      w2 = res[6];
      h2 = res[7];
      // segment 인식 실패시 rectangle 값이 0으로 채워짐
      segmentAreaRect = [
        Rect.fromLTWH(
          x1,
          y1,
          w1,
          h1,
        ),
        Rect.fromLTWH(
          x2,
          y2,
          w2,
          h2,
        ),
      ];
    } else {
      nullFlag = true;
      segmentAreaRect = [
        const Rect.fromLTWH(
          0.0,
          0.0,
          0.0,
          0.0,
        ),
        const Rect.fromLTWH(
          0.0,
          0.0,
          0.0,
          0.0,
        ),
      ];
    }
    // 메모리 해제
    malloc.free(nativeSize);
    malloc.free(nativeBuffer);

    /// OcrPreprocessResult 반환
    if (nullFlag) {
      return null;
    } else {
      return OcrPreprocessResult(
        need_to_OCR_img_path: need_to_OCR_img_path,
        segmentAreaRect: segmentAreaRect,
      );
    }
  }
}
