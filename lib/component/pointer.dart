import 'package:flutter/material.dart';

abstract class Pointer extends CustomPainter {
  const Pointer();
  /// 中心からの距離
  abstract final double centerOffset;
  /// 再描画するための位置
  Pointer moveTo(Offset offset);
}
