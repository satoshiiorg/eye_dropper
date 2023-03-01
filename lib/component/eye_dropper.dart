import 'dart:ui' as ui;
import 'package:eye_dropper/component/magnifier_pointer.dart';
import 'package:eye_dropper/component/multiplex_image.dart';
import 'package:eye_dropper/component/pointer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;

/// スポイトツールウィジェット
abstract class EyeDropper extends StatelessWidget {
  const EyeDropper._({super.key});

  /// スポイトツールウィジェットのファクトリコンストラクタ
  /// bytesがnullの場合はsizeに合った空の領域を表示する
  factory EyeDropper.of({
    Key? key,
    required Uint8List? bytes,
    required Size size,
    Pointer Function(ui.Image?) pointerFactory = DraggableMagnifierPointer.new,
    required ValueChanged<Color> onSelected,
  }) {
    // 画像が未指定の場合は空の領域を返す
    if(bytes == null) {
      return _EmptyEyeDropper(key: key, size: size);
    }
    return _EyeDropper(
      key: key, bytes: bytes, size: size, pointerFactory: pointerFactory,
      onSelected: onSelected,
    );
  }
}

/// 画像が未指定の場合に表示するための空のウィジェット
class _EmptyEyeDropper extends EyeDropper {
  const _EmptyEyeDropper({super.key, required this.size}): super._();
  /// 表示領域のサイズ
  final Size size;

  @override
  Widget build(BuildContext context) {
    return Container(
        alignment: Alignment.center,
        width: size.width,
        height: size.height,
    );
  }
}

/// スポイトツールウィジェット本体
class _EyeDropper extends EyeDropper {
  _EyeDropper(
      {super.key,
      required Uint8List bytes,
      required this.size,
      required Pointer Function(ui.Image?) pointerFactory,
      required this.onSelected,}) : _multiplexImage = MultiplexImage(bytes, size), super._() {
    pointer = pointerFactory(_multiplexImage.uiImage);
  }

  /// 画像のMultiplexImage表現
  final MultiplexImage _multiplexImage;
  /// 表示領域のサイズ
  final Size size;
  /// 指定位置を表示する
  late final Pointer pointer;
  /// タップ時のコールバック
  final ValueChanged<Color> onSelected;
  /// 前回のタップ/ドラッグ位置
  //TODO 一応(-1, -1)とかにする
  final ValueNotifier<Offset> _oldPosition = ValueNotifier(Offset.zero);

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      width: size.width,
      height: size.height,
      child: Stack(
        children: [
          // 画像を表示してタップ時の挙動を設定
          GestureDetector(
            onPanStart: (details) {
              final localPosition = details.localPosition;
              // タップ位置をセット
              _oldPosition.value = localPosition;
              // ポインタ枠外をタップした場合はポインタをそこへ直接移動
              if(!pointer.contains(localPosition)) {
                pickColor(localPosition);
                // タップ位置に移動
                pointer.position = localPosition;
              }
            },
            onPanUpdate: (details) {
              // 前回のタップ/ドラッグ位置から移動した距離分ポインタを移動させる
              final localPosition = details.localPosition;
              final distance = localPosition - _oldPosition.value;
              pointer.position = pointer.position + distance;
              pickColor(pointer.position);
              _oldPosition.value = localPosition;
            },
            child: Image.memory(_multiplexImage.bytes),
          ),
          ValueListenableBuilder(
            valueListenable: _oldPosition,
            builder: (_, oldPosition, __) {
              if(oldPosition == Offset.zero) {
                return const SizedBox.shrink();
              }
              // ポインタを適切な位置に移動する
              return Positioned(
                left: pointer.position.dx,
                top: pointer.position.dy,
                child: CustomPaint(
                  painter: pointer,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// 指定位置の色を引数にしてコールバックを呼び出す
  void pickColor(Offset position) {
    // 指定位置を画像の対応する位置に変換
    final dx = position.dx / _multiplexImage.ratio;
    final dy = position.dy / _multiplexImage.ratio;

    // 座標と色を取得してセット
    final pixel = _multiplexImage.imgImage.getPixelSafe(dx.toInt(), dy.toInt());
    // ドラッグしたまま画像の範囲外に行くとRangeErrorになるので
    if(pixel == img.Pixel.undefined) {
      return;
    }
    final color = Color.fromARGB(
      pixel.a.toInt(), pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt(),
    );

    // 選択した色を渡してコールバックを呼び出す
    onSelected(color);
  }
}
