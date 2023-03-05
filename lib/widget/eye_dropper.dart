import 'dart:ui' as ui;
import 'package:eye_dropper/pointer/magnifier_pointer.dart';
import 'package:eye_dropper/pointer/pointer.dart';
import 'package:eye_dropper/util/multiplex_image.dart';
import 'package:eye_dropper/widget/image_painter.dart';
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
    Pointer Function(ui.Image, double ratio) pointerBuilder =
        DraggableMagnifierPointer.new,
    required ValueChanged<Color> onSelected,
  }) {
    // 画像が未指定の場合は空の領域を返す
    if(bytes == null) {
      return _EmptyEyeDropper(key: key, size: size);
    }
    return _EyeDropper(
      key: key, bytes: bytes, size: size, pointerBuilder: pointerBuilder,
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
      required this.pointerBuilder,
      required this.onSelected,}) :
        _multiplexImage = MultiplexImage(bytes, size),
        super._() {
    _uiImage = _multiplexImage.uiImage;
  }

  /// 未定義オフセット
  static const nullOffset = Offset(-1, -1);
  /// 画像のMultiplexImage表現
  final MultiplexImage _multiplexImage;
  /// 表示領域のサイズ
  final Size size;
  /// ポインタのビルダー
  late final Pointer Function(ui.Image, double ratio) pointerBuilder;
  /// 指定位置を表示する
  late final Pointer _pointer;
  /// 画像のui.Image表現
  late final Future<ui.Image> _uiImage;
  /// タップ時のコールバック
  final ValueChanged<Color> onSelected;
  /// 前回のタップ/ドラッグ位置
  final ValueNotifier<Offset> _oldPosition = ValueNotifier(nullOffset);

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      width: size.width,
      height: size.height,
      child: FutureBuilder<ui.Image>(
        future: _uiImage,
        builder: (_, snapshot) {
          if (snapshot.connectionState == ConnectionState.done
              && snapshot.hasData) {
            return _mainArea(snapshot.data!);
          } else if (snapshot.hasError) {
            throw Exception('${snapshot.error!}');
          }
          return const CircularProgressIndicator();
        },
      ),
    );
  }

  Widget _mainArea(ui.Image uiImage) {
    _pointer = pointerBuilder(
      uiImage,
      _multiplexImage.ratio,
    );
    return Stack(
      children: [
        // 画像を表示してタップ時の挙動を設定
        GestureDetector(
          onPanStart: (details) {
            final localPosition = details.localPosition;
            // タップ位置をセット
            _oldPosition.value = localPosition;
            // ポインタ枠外をタップした場合はポインタをそこへ直接移動
            if(!_pointer.contains(localPosition)) {
              _pickColor(localPosition);
              // タップ位置に移動
              _pointer.position = localPosition;
            }
          },
          onPanUpdate: (details) {
            // 前回のタップ/ドラッグ位置から移動した距離分ポインタを移動させる
            final localPosition = details.localPosition;
            final distance = localPosition - _oldPosition.value;
            _pointer.position = _pointer.position + distance;
            _pickColor(_pointer.position);
            _oldPosition.value = localPosition;
          },
          // アニメーションGIFを動かなさないようにするためui.Image化して描画
          // child: Image.memory(_bytes),
          child: CustomPaint(
            painter: ImagePainter(uiImage, size, _multiplexImage.ratio),
            size: Size(
              uiImage.width * _multiplexImage.ratio,
              uiImage.height * _multiplexImage.ratio,
            ),
          ),
        ),
        ValueListenableBuilder(
          valueListenable: _oldPosition,
          builder: (_, oldPosition, __) {
            if(oldPosition == nullOffset) {
              return const SizedBox.shrink();
            }
            // ポインタを適切な位置に移動する
            return Positioned(
              left: _pointer.position.dx,
              top: _pointer.position.dy,
              child: CustomPaint(
                painter: _pointer,
              ),
            );
          },
        ),
      ],
    );
  }

  /// 指定位置の色を引数にしてコールバックを呼び出す
  void _pickColor(Offset position) {
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
