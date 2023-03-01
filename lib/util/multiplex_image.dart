import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;

/// 画像関連のデータ
// @immutable
class MultiplexImage {
  // 一応未知のエンコード形式ではnullを返すと思われるがエラー処理は省略
  MultiplexImage(this.bytes, Size size) : imgImage = img.decodeImage(bytes)! {
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
  final img.Image imgImage;
  /// 画像のui.Image表現
  late final ui.Image uiImage;
  /// 画像の縮小率
  late final double ratio;
}
