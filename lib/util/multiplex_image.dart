import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;

/// 画像関連のデータ
// @immutable
class MultiplexImage {
  // 一応未知のエンコード形式ではnullを返すと思われるがエラー処理は省略
  MultiplexImage(this.bytes, Size size) : imgImage = img.decodeImage(bytes)! {
    final widthRatio = size.width < imgImage.width ?
    (size.width / imgImage.width) : 1.0;
    final heightRatio = size.height < imgImage.height ?
    (size.height / imgImage.height) : 1.0;
    ratio = min(widthRatio, heightRatio);
  }

  /// 画像のバイト列表現
  final Uint8List bytes;
  /// 画像のimg.Image表現
  final img.Image imgImage;
  /// 画像の縮小率
  late final double ratio;
  Future<ui.Image> get uiImage => imgImageToUiImage(imgImage);

  /// img.Imageをui.Imageに変換する
  static Future<ui.Image> imgImageToUiImage(img.Image imgImage) async {
    final buffer = await ui.ImmutableBuffer.fromUint8List(imgImage.getBytes());
    final imageDescriptor = ui.ImageDescriptor.raw(
      buffer,
      height: imgImage.height,
      width: imgImage.width,
      pixelFormat: ui.PixelFormat.rgba8888,
    );
    final codec = await imageDescriptor.instantiateCodec(
      targetHeight: imgImage.height,
      targetWidth: imgImage.width,
    );
    final frameInfo = await codec.getNextFrame();
    return frameInfo.image;
  }
}
