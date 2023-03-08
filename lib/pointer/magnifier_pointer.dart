import 'dart:ui' as ui;
import 'package:eye_dropper/pointer/pointer.dart';
import 'package:flutter/material.dart';

/// 吸い取った場所の表示領域
/// 拡大表示を行う
/// 拡大表示領域内をタップした場合は拡大表示領域をドラッグで移動できる
class MagnifierPointer extends Pointer {
  MagnifierPointer(
    this.uiImage,
    this.ratio, {
    this.magnification = 2,
    this.outerRectSize = 91,
    this.innerRectSize = 11,
    this.strokeWidth = 2,
  });

  /// 画像
  final ui.Image uiImage;
  /// 画像の縮小率
  final double ratio;
  /// ポインタ部分の拡大倍率
  final double magnification;
  /// 囲みの幅
  final double outerRectSize;
  /// 囲みの幅
  final double innerRectSize;
  /// 囲みの太さ
  final double strokeWidth;
  /// 囲みの中心点
  @override
  double get centerOffset => outerRectSize / 2;

  /// 二重の四角で囲んだ拡大画像を表示する
  @override
  Future<void> paint(Canvas canvas, Size size) async {
    final paint = Paint();

    // 外枠
    final largeRect = Rect.fromLTWH(
        - centerOffset,
        - centerOffset,
        outerRectSize,
        outerRectSize,
    );

    // 透過画像のために背景を白で塗りつぶし
    paint
      ..color = Colors.white
      ..style = PaintingStyle.fill
      ..strokeWidth = 0;
    canvas.drawRect(largeRect, paint);

    // 画像を拡大表示
    final sourceRect = Rect.fromLTWH(
      (position.dx - (centerOffset / magnification)) / ratio,
      (position.dy - (centerOffset / magnification)) / ratio,
      outerRectSize / magnification / ratio,
      outerRectSize / magnification / ratio,
    );
    canvas.drawImageRect(
      uiImage,
      sourceRect,
      largeRect,
      paint,
    );

    // 大きい黒四角
    paint
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawRect(largeRect, paint);

    // 内枠
    final smallRect = Rect.fromLTWH(
      // 中心
      - (innerRectSize / 2),
      - (innerRectSize / 2),
      innerRectSize,
      innerRectSize,
    );
    // 小さい黒四角
    paint
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawRect(smallRect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
