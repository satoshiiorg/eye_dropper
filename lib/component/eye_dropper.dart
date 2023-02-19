import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'pointer.dart';
import 'simple_pointer.dart';

/// スポイトツールウィジェット
abstract class EyeDropper extends StatelessWidget {
  const EyeDropper._({super.key});

  /// スポイトツールウィジェットのファクトリコンストラクタ
  /// bytesがnullの場合はsizeに合った空の領域を表示する
  factory EyeDropper.of({
    Key? key,
    required Uint8List? bytes,
    required Size size,
    Pointer pointer = SimplePointer.instance,
    required ValueChanged<Color> onSelected,
  }) {
    // 画像が未指定の場合は空の領域を返す
    if(bytes == null) {
      return _EmptyEyeDropper(key: key, size: size);
    }
    return _EyeDropper(
      key: key, bytes: bytes, size: size, pointer: pointer,
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
      required this.pointer,
      required this.onSelected,}) : _myImage = _MyImage(bytes, size), super._();

  /// 画像のMyImage表現
  final _MyImage _myImage;
  /// 表示領域のサイズ
  final Size size;
  /// 指定位置を表示する
  final Pointer pointer;
  /// タップ時のコールバック
  final ValueChanged<Color> onSelected;
  /// タップ位置のValueNotifier
  final ValueNotifier<Offset?> _tapPosition = ValueNotifier(null);

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
            // TODO onPanStartとonPanUpdateを別々に拾えるようにする？
            onPanStart: (details) => pickColor(details.localPosition),
            onPanUpdate: (details) => pickColor(details.localPosition),
            child: Image.memory(_myImage.bytes),
          ),
          ValueListenableBuilder(
            valueListenable: _tapPosition,
            builder: (_, tapPosition, __) {
              if(tapPosition == null) {
                return const SizedBox.shrink();
              }
              // タップされた位置に目印を付ける
              return Positioned(
                // タップ位置が開始点(0, 0)でなく中央になるようにする
                left: tapPosition.dx - pointer.centerOffset,
                top: tapPosition.dy - pointer.centerOffset,
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

  /// TapDownDetailsで指定された座標を_tapPositionにセットし
  /// 色を引数にしてコールバックを呼び出す
  void pickColor(Offset localPosition) {
    // タップ位置を画像の対応する位置に変換
    final dx = localPosition.dx / _myImage.ratio;
    final dy = localPosition.dy / _myImage.ratio;

    // 座標と色を取得してセット
    final pixel = _myImage.imgImage.getPixelSafe(dx.toInt(), dy.toInt());
    // ドラッグしたまま画像の範囲外に行くとRangeErrorになるので対策
    if(pixel == img.Pixel.undefined) {
      return;
    }
    final color = Color.fromARGB(
      pixel.a.toInt(), pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt(),
    );

    // タップ位置をセット
    _tapPosition.value = localPosition;
    // 選択した色を渡してコールバックを呼び出す
    onSelected(color);
  }
}

/// 画像関連のデータ
@immutable
class _MyImage {
  // 一応未知のエンコード形式ではnullを返すと思われるがエラー処理は省略
  _MyImage(this.bytes, Size size) : imgImage = img.decodeImage(bytes)! {
    final widthRatio = size.width < imgImage.width ?
                      (size.width / imgImage.width) : 1.0;
    final heightRatio = size.height < imgImage.height ?
                      (size.height / imgImage.height) : 1.0;
    ratio = min(widthRatio, heightRatio);
  }

  /// 画像のバイト列表現
  final Uint8List bytes;
  /// 画像のimg.Image表現
  late final img.Image imgImage;
  /// 画像の縮小率
  late final double ratio;
}
