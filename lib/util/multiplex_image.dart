import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;

/// 画像関連のデータ
// @immutable
class MultiplexImage {
  // MultiplexImage(this.bytes, Size size) :
  //      imgImage = img.decodeImage(bytes)! {
  MultiplexImage(this.bytes, Size size) {
    final pngImgImage = img.decodePng(bytes);
    if(pngImgImage == null) {
      final nullableImgImage = img.decodeImage(bytes);
      if(nullableImgImage == null) {
        throw const FormatException('Unknown image format.');
      }
      imgImage = nullableImgImage;
    } else {
      // アルファ付きPNG暫定対応
      imgImage = img.decodeJpg(img.encodeJpg(pngImgImage))!;
    }

    // 縮小比率を計算
    final widthRatio = size.width < imgImage.width ?
    (size.width / imgImage.width) : 1.0;
    final heightRatio = size.height < imgImage.height ?
    (size.height / imgImage.height) : 1.0;
    ratio = min(widthRatio, heightRatio);

    // ui.Imageを設定
    () async {
      final codec = await ui.instantiateImageCodec(bytes);
      final frameInfo = await codec.getNextFrame();
      uiImage = frameInfo.image;
    }();
  }

  /// 画像のバイト列表現
  final Uint8List bytes;
  /// 画像のimg.Image表現
  late final img.Image imgImage;
  /// 画像のui.Image表現
  ui.Image? uiImage;
  /// 画像の縮小率
  late final double ratio;
}
