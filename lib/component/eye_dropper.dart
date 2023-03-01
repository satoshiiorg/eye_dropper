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
    Pointer Function(MultiplexImage) pointerFactory = DraggableMagnifierPointer.new,
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
      required Pointer Function(MultiplexImage) pointerFactory,
      required this.onSelected,}) : _myImage = MultiplexImage(bytes, size), super._() {
    // TODO ファクトリでなく普通にインスタンスをもらってここでsetImageする方がよい
    pointer = pointerFactory(_myImage);
  }

  /// 画像のMyImage表現
  final MultiplexImage _myImage;
  /// 表示領域のサイズ
  final Size size;
  /// 指定位置を表示する
  late final Pointer pointer;
  /// タップ時のコールバック
  final ValueChanged<Color> onSelected;
  /// 移動先のValueNotifier
  final ValueNotifier<Offset?> _destPosition = ValueNotifier(null);
  // TODO
  bool _drag = false;
  Offset _oldPosition = Offset.zero;

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
              if(pointer.contains(localPosition)) {
                _drag = true;
                _oldPosition = details.localPosition;
              } else {
                _drag = false;
                // タップ位置に移動
                pickColor(details.localPosition);
                // タップ位置をセット
                _destPosition.value = details.localPosition;
              }
            },
            onPanUpdate: (details) {
              if(_drag) {
                // TODO
                final distance = details.localPosition - _oldPosition;
                pointer.position = pointer.position + distance;
                pickColor(pointer.position);
                _oldPosition = details.localPosition;
                _destPosition.value = pointer.position;
              } else {
                // そのままドラッグ位置を中心に移動
                pickColor(details.localPosition);
                // ドラッグ位置をセット
                _destPosition.value = details.localPosition;
              }
            },
            child: Image.memory(_myImage.bytes),
          ),
          ValueListenableBuilder(
            valueListenable: _destPosition,
            builder: (_, destPosition, __) {
              if(destPosition == null) {
                return const SizedBox.shrink();
              }
              // ポインタを適切な位置に移動する
              return _drag
                  ?
                Positioned(
                  // タップ位置が開始点(0, 0)でなく中央になるようにする
                  left: pointer.position.dx - pointer.centerOffset,
                  top: pointer.position.dy - pointer.centerOffset,
                  child: Stack(
                    children: [
                      CustomPaint(
                        painter: pointer,
                      ),
                    ],
                  ),
                )
                  :
                Positioned(
                  // タップ位置が開始点(0, 0)でなく中央になるようにする
                  left: destPosition.dx - pointer.centerOffset,
                  top: destPosition.dy - pointer.centerOffset,
                  child: Stack(
                    children: [
                      CustomPaint(
                        painter: pointer..position = destPosition,
                      ),
                    ],
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
    final dx = position.dx / _myImage.ratio;
    final dy = position.dy / _myImage.ratio;

    // 座標と色を取得してセット
    final pixel = _myImage.imgImage.getPixelSafe(dx.toInt(), dy.toInt());
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
