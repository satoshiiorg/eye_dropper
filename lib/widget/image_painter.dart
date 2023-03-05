import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// 画像を指定サイズで表示する
class ImagePainter extends CustomPainter {
  ImagePainter(this.uiImage, this.size, this.ratio);

  final ui.Image uiImage;
  final Size size;
  final double ratio;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final source = Rect.fromLTWH(0, 0, size.width / ratio, size.height / ratio);
    final dest = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawImageRect(
      uiImage,
      source,
      dest,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
