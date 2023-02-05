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
  /// 画像のバイト列
  final imageBytes = ValueNotifier<Uint8List?>(null);
  /// 選択された座標
  final tapPoint = ValueNotifier<Offset?>(null);
  /// 選択されたピクセルのカラーコード
  final pickedColor = ValueNotifier<Color?>(null);
  /// 画像の表示領域の画面サイズに対する比率(横)
  static const imageAreaWidthRatio = 0.95;
  /// 画像の表示領域の画面サイズに対する比率(縦)
  static const imageAreaHeightRatio = 0.65;

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
            if(pickedColor.value != null)
              CustomPaint(
                  size: const Size(50, 50),
                  painter: PickedPainter(pickedColor.value!),
              ),
            if(pickedColor.value != null)
              Text('ARGB=${pickedColor.value}'),
            Container(
              alignment: Alignment.center,
              // TODO 画像表示領域のサイズ設定はもうちょっと考える
              width: MediaQuery.of(context).size.width * imageAreaWidthRatio,
              height: MediaQuery.of(context).size.height * imageAreaHeightRatio,
              child: Stack(
                children: [
                  if(imageBytes.value != null)
                    GestureDetector(
                      // TODO onPanUpdate にしてなめらかに取れるようにする？
                      // この辺参考になりそう https://note.com/hatchoutschool/n/n1310e5172251
                      onTapDown: pickColor,
                      child: Image.memory(imageBytes.value!),
                    ),
                  if(tapPoint.value != null)
                    Positioned(
                      // タップ位置を開始点(0, 0)でなく中央(5, 5)にする
                      left: tapPoint.value!.dx - 5,
                      top: tapPoint.value!.dy - 5,
                      child: CustomPaint(
                        painter: TapPointPainter(),
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
    imageBytes.value = await image.readAsBytes();
    setState(() {});
  }

  /// TapDownDetailsで指定された座標をtapPointにセットし、色をpickedColorにセットする
  // TODO 色のセットと座標のセットは別々のメソッド内でやることのような気がする
  void pickColor(TapDownDetails details) async {
    // 一応未知のエンコード形式ではnullを返すと思われるが省略
    img.Image image = img.decodeImage(imageBytes.value!)!;

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

    // 色を取得してセット
    img.Pixel pixel = image.getPixel(x.toInt(), y.toInt());
    pickedColor.value = Color.fromARGB(pixel.a.toInt(), pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt());

    // Offsetはイミュータブルと記載があるのでコピーする必要はない
    tapPoint.value = details.localPosition;

    setState(() {
    });
  }
}

/// 吸い取った色の表示領域
class PickedPainter extends CustomPainter {
  Color color;
  PickedPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    Paint p = Paint();
    p.color = color;
    p.style = PaintingStyle.fill;
    Rect r = const Rect.fromLTWH(0, 0, 50, 50);
    canvas.drawRect(r, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// 吸い取った場所の表示領域
class TapPointPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Paint p = Paint();
    p.color = const Color.fromARGB(255, 255, 0, 0);
    p.style = PaintingStyle.stroke;
    p.strokeWidth = 2;
    Rect r = const Rect.fromLTWH(0, 0, 10, 10);
    canvas.drawRect(r, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}