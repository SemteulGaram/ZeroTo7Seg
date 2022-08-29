import 'package:flutter/material.dart';

class OcrDrawDto {
  final String text;
  final Rect rect;

  OcrDrawDto({
    required this.text,
    required this.rect,
  });

  isEqual(OcrDrawDto other) {
    return text == other.text &&
        rect.top == other.rect.top &&
        rect.left == other.rect.left &&
        rect.right == other.rect.right &&
        rect.bottom == other.rect.bottom;
  }
}

class SOSPCtx {
  Canvas canvas;
  Offset crosshairCenter;
  double crosshairWidth;
  double crosshairHeight;
  double crosshairX;
  double crosshairY;

  SOSPCtx({
    required this.canvas,
    required this.crosshairCenter,
    required this.crosshairWidth,
    required this.crosshairHeight,
    required this.crosshairX,
    required this.crosshairY,
  });
}

class SegmentOcrScanPainter extends CustomPainter {
  final List<OcrDrawDto> ocrDrawDtoList;

  SegmentOcrScanPainter({
    required this.ocrDrawDtoList,
  });

  void drawOcrResult(SOSPCtx ctx) {
    final paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (var ocrDrawDto in ocrDrawDtoList) {
      final rect = ocrDrawDto.rect;
      final text = ocrDrawDto.text;

      final left = rect.left;
      final top = rect.top;
      final right = rect.right;
      final bottom = rect.bottom;
      final center = rect.center;

      ctx.canvas.drawRect(Rect.fromLTRB(left, top, right, bottom), paint);

      final textPainter = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            color: Colors.red,
            fontSize: rect.height * 0.75,
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();
      textPainter.paint(
        ctx.canvas,
        Offset(
          // 수직 수평 가운데 정렬
          (center.dx - textPainter.width * 0.5),
          (center.dy - textPainter.height * 0.5),
        ),
      );
    }
  }

  void drawCrosshairPart(SOSPCtx ctx) {
    var mainPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.square;
    var strokePaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.square;
    var crosshair = Path()
      // -, -
      ..moveTo(ctx.crosshairCenter.dx, ctx.crosshairCenter.dy)
      ..relativeMoveTo(
          -ctx.crosshairWidth / 2, -ctx.crosshairHeight / 2 + ctx.crosshairY)
      ..relativeLineTo(0, -ctx.crosshairY)
      ..relativeLineTo(ctx.crosshairX, 0)
      // +, -
      ..moveTo(ctx.crosshairCenter.dx, ctx.crosshairCenter.dy)
      ..relativeMoveTo(
          ctx.crosshairWidth / 2, -ctx.crosshairHeight / 2 + ctx.crosshairY)
      ..relativeLineTo(0, -ctx.crosshairY)
      ..relativeLineTo(-ctx.crosshairX, 0)
      // +, +
      ..moveTo(ctx.crosshairCenter.dx, ctx.crosshairCenter.dy)
      ..relativeMoveTo(
          ctx.crosshairWidth / 2, ctx.crosshairHeight / 2 - ctx.crosshairY)
      ..relativeLineTo(0, ctx.crosshairY)
      ..relativeLineTo(-ctx.crosshairX, 0)
      // -, +
      ..moveTo(ctx.crosshairCenter.dx, ctx.crosshairCenter.dy)
      ..relativeMoveTo(
          -ctx.crosshairWidth / 2, ctx.crosshairHeight / 2 - ctx.crosshairY)
      ..relativeLineTo(0, ctx.crosshairY)
      ..relativeLineTo(ctx.crosshairX, 0);

    ctx.canvas.drawPath(crosshair, strokePaint);
    ctx.canvas.drawPath(crosshair, mainPaint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    // 임의 설정 그리기 기초 단위
    var base = size.width / 500.0;
    var ctx = SOSPCtx(
      canvas: canvas,
      crosshairCenter: Offset(size.width / 2, size.height / 3),
      crosshairWidth: 300.0 * base,
      crosshairHeight: 200.0 * base,
      crosshairX: 50.0 * base,
      crosshairY: 50.0 * base,
    );

    // OCR 결과 그리기
    drawOcrResult(ctx);
    // OCR 심박수 인식 가이드 영역 그리기
    drawCrosshairPart(ctx);
  }

  @override
  bool shouldRepaint(covariant SegmentOcrScanPainter oldDelegate) {
    // 최적화를 위해 이전과 OCR 결과가 다른 경우만 다시 그린다.
    if (ocrDrawDtoList.length != oldDelegate.ocrDrawDtoList.length) {
      return true;
    } else {
      return ocrDrawDtoList.asMap().entries.any((element) =>
          !element.value.isEqual(oldDelegate.ocrDrawDtoList[element.key]));
    }
  }
}
