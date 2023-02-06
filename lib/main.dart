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
  final _offsetColor = ValueNotifier<OffsetColor>(OffsetColor(const Offset(0, 0), Colors.white));

  // TODO そもそもUIとしてよくないのでデフォルト値を設定するようにする？
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ValueListenableBuilder(
              valueListenable: _offsetColor,
              builder: (_, offsetColor, __) => Column(
                children: [
                  // 選択された色見本の表示
                  CustomPaint(
                    size: const Size(50, 50),
                    painter: PickedPainter(_offsetColor.value.color),
                  ),
                  // 選択された色のカラーコード表示
                  // TODO 初期表示でFFFFFFになってしまうのはどうする？
                  Text('ARGB=${_offsetColor.value.color}'),
                ],
              ),
            ),
            // 画像表示領域
            Container(
              alignment: Alignment.center,
              // TODO 画像表示領域のサイズ設定はもうちょっと考える
              width: MediaQuery.of(context).size.width * imageAreaWidthRatio,
              height: MediaQuery.of(context).size.height * imageAreaHeightRatio,
              child: Stack(
                children: [
                  // 画像を表示してタップ時の挙動を設定
                  ValueListenableBuilder(
                    valueListenable: _imageBytes,
                    builder: (_, imageBytes, __) {
                      // 初期表示時は空
                      if(imageBytes == null) {
                        return const Center();
                      }
                      return GestureDetector(
                        // TODO onPanUpdate にしてなめらかに取れるようにする？
                        // この辺参考になりそう https://note.com/hatchoutschool/n/n1310e5172251
                        onTapDown: pickColor,
                        child: Image.memory(imageBytes),
                      );
                    },
                  ),
                  // タップされた位置に目印を付ける
                  // TODO 初期表示で左上になってしまうのはどうする？別によい？
                  if(_offsetColor.value != null)
                    ValueListenableBuilder(
                      valueListenable: _offsetColor,
                      builder: (_, offsetColor, __) => Positioned(
                        // タップ位置を開始点(0, 0)でなく中央(6, 6)にする
                        left: offsetColor.offset.dx - 6,
                        top: offsetColor.offset.dy - 6,
                        child: CustomPaint(
                          painter: TapPointPainter(),
                        ),
                      ),
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

  /// カメラロールから画像を選択しimageBytesにセット
  void selectImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if(image == null) {
      return;
    }
    _imageBytes.value = await image.readAsBytes();
  }

  /// TapDownDetailsで指定された座標と色をoffsetColorにセットする
  // 色のセットと座標のセットは別々のメソッド内でやることのような気がする
  // ↑むしろ同時に扱う必要があるものだから1オブジェクトにまとめるべき？
  // ↑別々のタイミングで再描画されても困るので1オブジェクトにまとめた
  void pickColor(TapDownDetails details) {
    // 一応未知のエンコード形式ではnullを返すと思われるが省略
    img.Image image = img.decodeImage(_imageBytes.value!)!;

    // 画像の表示領域のサイズ
    double width = MediaQuery.of(context).size.width * imageAreaWidthRatio;
    double height = MediaQuery.of(context).size.height * imageAreaHeightRatio;

    // 画像サイズが表示領域のサイズより大きい場合の縮小率
    double widthRatio = width < image.width ? (width / image.width) : 1;
    double heightRatio = height < image.height ? (height / image.height) : 1;
    double ratio = min(widthRatio, heightRatio);

    // タップ位置を画像の対応する位置に変換
    double x =  details.localPosition.dx / ratio;
    double y =  details.localPosition.dy / ratio;

    // 座標と色を取得してセット
    img.Pixel pixel = image.getPixel(x.toInt(), y.toInt());
    Color color = Color.fromARGB(pixel.a.toInt(), pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt());
    // Offsetはイミュータブルと記載があるのでコピーする必要はない
    Offset offset = details.localPosition;
    _offsetColor.value = OffsetColor(offset, color);
  }
}

/// 座標と色のペア
class OffsetColor {
  final Offset offset;
  final Color color;
  OffsetColor(this.offset, this.color);
}

/// 吸い取った色の表示領域
class PickedPainter extends CustomPainter {
  static const double rectSize = 50;
  Color color;
  PickedPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    // 選択された色で塗りつぶした四角を表示
    Paint p = Paint();
    p.color = color;
    p.style = PaintingStyle.fill;
    Rect r = const Rect.fromLTWH(0, 0, rectSize, rectSize);
    canvas.drawRect(r, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// 吸い取った場所の表示領域
class TapPointPainter extends CustomPainter {
  static const double rectSize = 11;
  @override
  void paint(Canvas canvas, Size size) {
    // 赤い四角で囲う
    Paint p = Paint();
    p.color = const Color.fromARGB(255, 255, 0, 0);
    p.style = PaintingStyle.stroke;
    p.strokeWidth = 2;
    Rect r = const Rect.fromLTWH(0, 0, rectSize, rectSize);
    canvas.drawRect(r, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}