import 'package:eye_dropper/pointer/pointer.dart';
import 'package:eye_dropper/util/multiplex_image.dart';
import 'package:flutter/material.dart';

/// 吸い取った場所の表示領域
/// 拡大表示なしのシンプルな赤枠
class SimplePointer extends Pointer {
  SimplePointer._(): super();
  static SimplePointer instanceOf(MultiplexImage _) => instance;

  /// インスタンス
  static final SimplePointer instance = SimplePointer._();
  /// 囲みの幅
  static const double rectSize = 11;
  /// 囲みの太さ
  static const double strokeWidth = 2;
  /// 囲みの中心点
  @override
  double get centerOffset => rectSize / 2;

  @override
  void paint(Canvas canvas, Size size) {
    // 赤い四角で囲う
    final paint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    final rect = Rect.fromLTWH(
        - centerOffset,
        - centerOffset,
        rectSize,
        rectSize,
    );
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
