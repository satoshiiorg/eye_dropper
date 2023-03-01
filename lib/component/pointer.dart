import 'package:flutter/material.dart';

abstract class Pointer extends CustomPainter {
  Pointer();

  /// 中心からの距離
  abstract final double centerOffset;

  /// 再描画するための位置
  Offset position = Offset.zero;

  /// otherPositionをこのポインタの描画範囲に含むか
  bool contains(Offset otherPosition) {
    // EyeDropper側でcenterOffset分ずらしているのでこちらでも補正が必要
    // TODO ↑あちらでもこちらでも補正をするのはあまりよろしくない
    return position.dx <= otherPosition.dx + centerOffset
        && position.dy <= otherPosition.dy + centerOffset
        && otherPosition.dx + centerOffset <= position.dx + centerOffset * 2
        && otherPosition.dy + centerOffset <= position.dy + centerOffset * 2;
  }
}
