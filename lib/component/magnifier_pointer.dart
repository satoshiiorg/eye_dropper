import 'package:eye_dropper/component/eye_dropper.dart';
import 'package:flutter/material.dart';
import 'pointer.dart';

/// 吸い取った場所の表示領域
/// 拡大表示を行う
class MagnifierPointer extends Pointer {
  MagnifierPointer(this.myImage);
  /// 囲みの幅
  static const double outerRectSize = 51;
  /// 囲みの幅
  static const double innerRectSize = 11;
  /// 囲みの太さ
  static const double strokeWidth = 2;
  /// 拡大倍率
  static const double magnification = 2;
  /// 囲みの中心点
  @override
  double get centerOffset => outerRectSize / 2;
  /// 画像
  MyImage myImage;
  /// タップ位置
  Offset _position = Offset.zero;

  /// 指定されたpositionに対応する拡大画像を返す
  @override
  Pointer moveTo(Offset position) {
    _position = position;
    return this;
  }

  /// 二重の四角で囲んだ拡大画像を表示する
  @override
  Future<void> paint(Canvas canvas, Size size) async {
    if(myImage.uiImage == null) {
      return;
    }

    final paint = Paint();

    // 外枠
    const largeRect = Rect.fromLTWH(0, 0, outerRectSize, outerRectSize);

    // 透過画像のために背景を白で塗りつぶし
    paint
      ..color = Colors.white
      ..style = PaintingStyle.fill
      ..strokeWidth = 0;
    canvas.drawRect(largeRect, paint);

    // 画像を拡大表示
    final sourceRect = Rect.fromLTWH(
      _position.dx - (centerOffset / magnification),
      _position.dy - (centerOffset / magnification),
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
      (outerRectSize / 2) - (strokeWidth * 2.5),
      (outerRectSize / 2) - (strokeWidth * 2.5),
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
