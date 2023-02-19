import 'package:flutter/material.dart';

abstract class Pointer extends CustomPainter {
  const Pointer();
  /// 中心からの距離
  abstract final double centerOffset;
}
