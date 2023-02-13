import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 本当はStateNotifierProviderを使うべきだが手抜き
/// 画像表示領域のサイズ
final imageAreaSizeProvider = Provider<Size>((ref) => const Size(0, 0));
/// 画像関連の情報
final imageProvider = StateProvider<MyImage?>((ref) => null);
/// 選択された座標と色
final offsetColorProvider = StateProvider<OffsetColor>((ref) => OffsetColor(null, null));

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  /// 画像の表示領域の画面サイズに対する比率(横)
  static const imageAreaWidthRatio = 0.95;
  /// 画像の表示領域の画面サイズに対する比率(縦)
  static const imageAreaHeightRatio = 0.65;

  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'スポイトツール',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Builder(builder: (context) {
        Size fullSize = MediaQuery.of(context).size;
        Size imageAreaSize = Size(
            fullSize.width * imageAreaWidthRatio,
            fullSize.height * imageAreaHeightRatio);
        return ProviderScope(
          overrides: [
            imageAreaSizeProvider.overrideWith((ref) => imageAreaSize),
          ],
          child: const MyHomePage(title: 'スポイトツール'),
        );
      }),
    );
  }
}

class MyHomePage extends ConsumerWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Size imageAreaSize = ref.watch(imageAreaSizeProvider);
    MyImage? image = ref.watch(imageProvider);
    OffsetColor offsetColor = ref.watch(offsetColorProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              children: [
                // 選択された色見本を表示
                CustomPaint(
                  size: const Size(50, 50),
                  painter: PickedPainter(offsetColor.color),
                ),
                // 選択された色のカラーコードを表示
                Text('ARGB=${offsetColor.color ?? ''}'),
              ],
            ),
            // 画像表示領域
            Container(
              alignment: Alignment.center,
              width: imageAreaSize.width,
              height: imageAreaSize.height,
              child: Stack(
                children: [
                  // 画像を表示してタップ時の挙動を設定
                  if(image != null)
                    GestureDetector(
                      onPanStart: (details) => pickColor(details.localPosition, ref),
                      onPanUpdate: (details) => pickColor(details.localPosition, ref),
                      child: Image.memory(image.bytes),
                    ),
                  // タップされた位置に目印を付ける
                  if(offsetColor.offset != null)
                    Positioned(
                      // タップ位置が開始点(0, 0)でなく中央になるようにする
                      left: offsetColor.offset!.dx - TapPointPainter.centerOffset,
                      top: offsetColor.offset!.dy - TapPointPainter.centerOffset,
                      child: CustomPaint(
                        painter: TapPointPainter(),
                      ),
                    ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () => selectImage(ref),
              child: const Text('画像を選択'),
            ),
          ],
        ),
      ),
    );
  }

  // TODO refを渡すよりはbytesだけ返してもらって外でstateを変える方がよい？
  /// カメラロールから画像を選択し imageProvider と _imgImage にセット
  /// 同時に _imageRatio もセットする
  void selectImage(WidgetRef ref) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if(image == null) {
      return;
    }
    Uint8List bytes = await image.readAsBytes();
    Size imageAreaSize = ref.read(imageAreaSizeProvider)!;
    ref.read(imageProvider.notifier).state = MyImage(bytes, imageAreaSize);
  }

  /// TapDownDetailsで指定された座標と色をoffsetColorProviderにセットする
  void pickColor(Offset localPosition, WidgetRef ref) {
    MyImage image = ref.watch(imageProvider)!;
    // タップ位置を画像の対応する位置に変換
    double dx = localPosition.dx / image.ratio;
    double dy = localPosition.dy / image.ratio;

    // 座標と色を取得してセット
    img.Pixel pixel = image.imgImage.getPixelSafe(dx.toInt(), dy.toInt());
    // ドラッグしたまま画像の範囲外に行くとRangeErrorになるので対策
    if(pixel == img.Pixel.undefined) {
      return;
    }
    Color color = Color.fromARGB(
        pixel.a.toInt(), pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt());
    // localPositionはイミュータブルなのでコピーする必要はない
    ref.read(offsetColorProvider.notifier).state = OffsetColor(localPosition, color);
  }
}

/// 画像関連のデータ
class MyImage {
  /// 画像のバイト列表現
  final Uint8List bytes;
  /// 画像のimg.Image表現
  final img.Image imgImage;
  /// 画像の縮小率
  late final double ratio;

  // 一応未知のエンコード形式ではnullを返すと思われるがエラー処理は省略
  MyImage(this.bytes, imageArea) : imgImage = img.decodeImage(bytes)! {
    // 一時変数を使わなければlateにする必要ないが見づらいので
    double widthRatio = imageArea.width < imgImage.width ? (imageArea.width / imgImage.width) : 1;
    double heightRatio = imageArea.height < imgImage.height ? (imageArea.height / imgImage.height) : 1;
    ratio = min(widthRatio, heightRatio);
  }
}

/// 座標と色のペア
class OffsetColor {
  final Offset? offset;
  final Color? color;
  OffsetColor(this.offset, this.color);
}

/// 吸い取った色の表示領域
class PickedPainter extends CustomPainter {
  static const double rectSize = 50;
  Color? color;
  PickedPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    // 選択された色で塗りつぶした四角を表示
    Paint p = Paint();
    p.color = color ?? Colors.white;
    p.style = PaintingStyle.fill;
    Rect r = const Rect.fromLTWH(0, 0, rectSize, rectSize);
    canvas.drawRect(r, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// 吸い取った場所の表示領域
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
    Paint p = Paint();
    p.color = Colors.red;
    p.style = PaintingStyle.stroke;
    p.strokeWidth = strokeWidth;
    Rect r = const Rect.fromLTWH(0, 0, rectSize, rectSize);
    canvas.drawRect(r, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}