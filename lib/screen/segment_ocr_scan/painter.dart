import 'package:flutter/material.dart';

class SOSPCtx {
  Offset center = const Offset(0, 0);
  double width = 0.0;
  double height = 0.0;
  double crosshairX = 0.0;
  double crosshairY = 0.0;
}

class SegmentOcrScanPainter extends CustomPainter {
  Path genCrosshairPart(SOSPCtx ctx) {
    return Path()
      // -, -
      ..moveTo(ctx.center.dx, ctx.center.dy)
      ..relativeMoveTo(-ctx.width/2, -ctx.height/2 + ctx.crosshairY)
      ..relativeLineTo(0, -ctx.crosshairY)
      ..relativeLineTo(ctx.crosshairX, 0)
      // +, -
      ..moveTo(ctx.center.dx, ctx.center.dy)
      ..relativeMoveTo(ctx.width/2, -ctx.height/2 + ctx.crosshairY)
      ..relativeLineTo(0, -ctx.crosshairY)
      ..relativeLineTo(-ctx.crosshairX, 0)
      // +, +
      ..moveTo(ctx.center.dx, ctx.center.dy)
      ..relativeMoveTo(ctx.width/2, ctx.height/2 - ctx.crosshairY)
      ..relativeLineTo(0, ctx.crosshairY)
      ..relativeLineTo(-ctx.crosshairX, 0)
      // -, +
      ..moveTo(ctx.center.dx, ctx.center.dy)
      ..relativeMoveTo(-ctx.width/2, ctx.height/2 - ctx.crosshairY)
      ..relativeLineTo(0, ctx.crosshairY)
      ..relativeLineTo(ctx.crosshairX, 0);

  }

  @override
  void paint(Canvas canvas, Size size) {
    var ctx = SOSPCtx()
      ..center = Offset(size.width/2, size.height/2)
      ..width = 300.0
      ..height = 200.0
      ..crosshairX = 50.0
      ..crosshairY = 50.0;

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

    Path crosshair = genCrosshairPart(ctx);
    canvas.drawPath(crosshair, strokePaint);
    canvas.drawPath(crosshair, mainPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
    throw UnimplementedError();
  }
}