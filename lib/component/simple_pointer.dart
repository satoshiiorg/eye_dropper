import 'package:eye_dropper/component/eye_dropper.dart';
import 'package:flutter/material.dart';
import 'pointer.dart';

/// 吸い取った場所の表示領域
/// 拡大表示なしのシンプルな赤枠
@immutable
class SimplePointer extends Pointer {
  const SimplePointer._(): super();
  static SimplePointer instanceOf(MyImage _) => instance;

  /// インスタンス
  static const SimplePointer instance = SimplePointer._();
  /// 囲みの幅
  static const double rectSize = 11;
  /// 囲みの太さ
  static const double strokeWidth = 2;
  /// 囲みの中心点
  @override
  double get centerOffset => rectSize / 2;

  /// 位置に関係なく唯一のインスタンスを返す
  @override
  Pointer moveTo(Offset offset) {
    return this;
  }

  @override
  void paint(Canvas canvas, Size size) {
    // 赤い四角で囲う
    final paint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    const rect = Rect.fromLTWH(0, 0, rectSize, rectSize);
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
