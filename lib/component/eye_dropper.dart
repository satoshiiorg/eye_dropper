import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;

class EyeDropper extends StatelessWidget {
  EyeDropper(
      {super.key,
      required this.onSelected,
      required Uint8List bytes,
      required this.size,}) : _myImage = _MyImage(bytes, size);

  /// 画像のMyImage表現
  final _MyImage _myImage;
  final Size size;
  final ValueChanged<Color> onSelected;
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
                left: tapPosition.dx - TapPointPainter.centerOffset,
                top: tapPosition.dy - TapPointPainter.centerOffset,
                child: CustomPaint(
                  painter: TapPointPainter(),
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

    _tapPosition.value = localPosition;
    onSelected(color);
  }
}

//TODO シングルトン
/// 吸い取った場所の表示領域
@immutable
class TapPointPainter extends CustomPainter {
  /// 囲みの幅
  static const double rectSize = 11;

  /// 囲みの太さ
  static const double strokeWidth = 2;

  /// 囲みの中心点
  static const double centerOffset = rectSize / 2;
  @override
  void paint(Canvas canvas, Size size) {
    // 赤い四角で囲う
    final p = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    const r = Rect.fromLTWH(0, 0, rectSize, rectSize);
    canvas.drawRect(r, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
