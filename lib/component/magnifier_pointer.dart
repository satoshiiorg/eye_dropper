import 'package:eye_dropper/component/multiplex_image.dart';
import 'package:eye_dropper/component/pointer.dart';
import 'package:flutter/material.dart';

/// 吸い取った場所の表示領域
/// 拡大表示を行う
/// 拡大表示領域内をタップした場合は拡大表示領域をドラッグで移動できる
class DraggableMagnifierPointer extends Pointer {
  DraggableMagnifierPointer(this.myImage);
  /// 囲みの幅
  static const double outerRectSize = 51;
  /// 囲みの幅
  static const double innerRectSize = 11;
  /// 囲みの太さ
  static const double strokeWidth = 2;
  /// 拡大倍率
  // TODO 指定できるように
  static const double magnification = 2;
  /// 囲みの中心点
  @override
  double get centerOffset => outerRectSize / 2;
  /// 画像
  MultiplexImage myImage;

  /// 二重の四角で囲んだ拡大画像を表示する
  @override
  Future<void> paint(Canvas canvas, Size size) async {
    if(myImage.uiImage == null) {
      return;
    }

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
      position.dx - (centerOffset / magnification),
      position.dy - (centerOffset / magnification),
      outerRectSize / magnification,
      outerRectSize / magnification,
    );
    canvas.drawImageRect(
      myImage.uiImage!,
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
    const smallRect = Rect.fromLTWH(
      // 中心
      - (strokeWidth * 2.5),
      - (strokeWidth * 2.5),
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
