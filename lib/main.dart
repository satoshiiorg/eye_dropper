import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'dart:math';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'スポイトツール',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'スポイトツール'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  /// 画像の表示領域の画面サイズに対する比率(横)
  static const imageAreaWidthRatio = 0.95;
  /// 画像の表示領域の画面サイズに対する比率(縦)
  static const imageAreaHeightRatio = 0.65;
  /// 画像のバイト列
  final _imageBytes = ValueNotifier<Uint8List?>(null);
  /// 選択された座標と色
  final _offsetColor = ValueNotifier<OffsetColor>(OffsetColor(null, null));
  // このあたりはごちゃごちゃするが pickColor() 内で同じ処理が複数回走らないようプロパティにする
  /// 画像の表示領域の横幅
  late double _imageAreWidth;
  /// 画像の表示領域の縦幅
  late double _imageAreHeight;
  /// 画像のimg.Image表現
  late img.Image _imgImage;
  /// 画像の縮小率
  late double _imageRatio;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _imageAreWidth = MediaQuery.of(context).size.width * imageAreaWidthRatio;
    _imageAreHeight = MediaQuery.of(context).size.height * imageAreaHeightRatio;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // _offsetColorを監視して再描画する
            ValueListenableBuilder(
              valueListenable: _offsetColor,
              builder: (_, offsetColor, __) => Column(
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
            ),
            // 画像表示領域
            Container(
              alignment: Alignment.center,
              width: _imageAreWidth,
              height: _imageAreHeight,
              child: Stack(
                children: [
                  // 選択された画像を描画する
                  ValueListenableBuilder(
                    valueListenable: _imageBytes,
                    builder: (_, imageBytes, __) {
                      // 初期表示時は空
                      if(imageBytes == null) {
                        return const SizedBox.shrink();
                      }
                      // 画像を表示してタップ時の挙動を設定
                      return GestureDetector(
                        onPanStart: pickColor,
                        onPanUpdate: pickColor,
                        child: Image.memory(imageBytes),
                      );
                    },
                  ),
                  // タップされた位置に目印を付ける
                  ValueListenableBuilder(
                    valueListenable: _offsetColor,
                    builder: (_, offsetColor, __) {
                      // 初期表示時は非表示
                      if(offsetColor.offset == null) {
                        return const SizedBox.shrink();
                      }
                      return Positioned(
                        // タップ位置が開始点(0, 0)でなく中央になるようにする
                        left: offsetColor.offset!.dx - TapPointPainter.centerOffset,
                        top: offsetColor.offset!.dy - TapPointPainter.centerOffset,
                        child: CustomPaint(
                          painter: TapPointPainter(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: selectImage,
              child: const Text('画像を選択'),
            ),
          ],
        ),
      ),
    );
  }

  /// カメラロールから画像を選択し _imageBytes と _imgImage にセット
  /// 同時に _imageRatio もセットする
  void selectImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if(image == null) {
      return;
    }
    Uint8List bytes = await image.readAsBytes();
    // 一応未知のエンコード形式ではnullを返すと思われるがエラー処理は省略
    _imgImage = img.decodeImage(bytes)!;

    // 画像サイズが表示領域のサイズより大きい場合の縮小率
    double widthRatio = _imageAreWidth < _imgImage.width ? (_imageAreWidth / _imgImage.width) : 1;
    double heightRatio = _imageAreHeight < _imgImage.height ? (_imageAreHeight / _imgImage.height) : 1;
    _imageRatio = min(widthRatio, heightRatio);

    _imageBytes.value = bytes;
  }

  /// TapDownDetailsで指定された座標と色をoffsetColorにセットする
  /// 引数のdetailsはGestureDragStartCallbackまたはGestureDragUpdateCallback
  void pickColor(details) {
    // タップ位置を画像の対応する位置に変換
    int x =  details.localPosition.dx ~/ _imageRatio;
    int y =  details.localPosition.dy ~/ _imageRatio;

    // 座標と色を取得してセット
    img.Pixel pixel = _imgImage.getPixel(x, y);
    Color color = Color.fromARGB(pixel.a.toInt(), pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt());
    // Offsetはイミュータブルなのでコピーする必要はない
    Offset offset = details.localPosition;
    _offsetColor.value = OffsetColor(offset, color);
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
  static final int centerOffset = (rectSize / 2 + strokeWidth / 2).ceil();
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