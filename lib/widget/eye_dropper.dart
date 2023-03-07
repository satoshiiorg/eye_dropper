import 'dart:math';
import 'dart:ui' as ui;
import 'package:eye_dropper/exception/image_initialize_exception.dart';
import 'package:eye_dropper/pointer/magnifier_pointer.dart';
import 'package:eye_dropper/pointer/pointer.dart';
import 'package:eye_dropper/widget/image_painter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
      required this.bytes,
      required this.size,
      required this.pointerBuilder,
      required this.onSelected,
      }) : super._();

  /// 未定義オフセット
  static const nullOffset = Offset(-1, -1);
  final Uint8List bytes;
  /// 表示領域のサイズ
  final Size size;
  /// 画像の縮小率
  late final double _ratio;
  /// ポインタのビルダー
  late final Pointer Function(ui.Image, double ratio) pointerBuilder;
  /// 指定位置を表示する
  late final Pointer _pointer;
  /// 画像のui.Image表現
  late final ui.Image _uiImage;
  /// 画像のRawStraightRgba形式のByteData
  late final ByteData _bytesRgba;
  /// タップ時のコールバック
  final ValueChanged<Color> onSelected;
  /// 前回のタップ/ドラッグ位置
  final ValueNotifier<Offset> _oldPosition = ValueNotifier(nullOffset);

  /// 初期化処理
  /// ui.Imageの初期化とByteDataへの変換、縮小率の計算を行う
  /// Future<void>だとFutureBuilderがうまく動かないためダミーの値を返す
  Future<bool> _initImage() async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frameInfo = await codec.getNextFrame();
    _uiImage = frameInfo.image;

    _bytesRgba = (await _uiImage.toByteData(
        format: ui.ImageByteFormat.rawStraightRgba,
    ))!;

    // 縮小比率を計算
    final widthRatio = size.width < _uiImage.width ?
                      (size.width / _uiImage.width) : 1.0;
    final heightRatio = size.height < _uiImage.height ?
                      (size.height / _uiImage.height) : 1.0;
    _ratio = min(widthRatio, heightRatio);

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      width: size.width,
      height: size.height,
      child: FutureBuilder<void>(
        future: _initImage(),
        builder: (_, snapshot) {
          if (snapshot.connectionState == ConnectionState.done
              && snapshot.hasData) {
            return _mainArea();
          } else if (snapshot.hasError) {
            throw ImageInitializeException('${snapshot.error!}');
          }
          return const CircularProgressIndicator();
        },
      ),
    );
  }

  Widget _mainArea() {
    _pointer = pointerBuilder(
      _uiImage,
      _ratio,
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
            painter: ImagePainter(_uiImage, size, _ratio),
            size: Size(
              _uiImage.width * _ratio,
              _uiImage.height * _ratio,
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
    final dx = position.dx ~/ _ratio;
    final dy = position.dy ~/ _ratio;

    // RangeError対策
    final position1d = (dy * _uiImage.width + dx) * 4;
    final length = _bytesRgba.lengthInBytes;
    if(position1d < 0 || length < position1d) {
      return;
    }

    // 32ビットintから各チャンネルを切り出し
    final rgba = _bytesRgba.getUint32(position1d);
    final r = rgba ~/ (256 * 256 * 256);
    final g = rgba ~/ (256 * 256) % 256;
    final b = rgba ~/ 256 % 256 % 256;
    final a = rgba % 256 % 256 % 256;
    final color = Color.fromARGB(a, r, g, b);

    // 選択した色を渡してコールバックを呼び出す
    onSelected(color);
  }
}
