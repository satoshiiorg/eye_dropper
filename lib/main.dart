import 'package:eye_dropper/pointer/magnifier_pointer.dart';
import 'package:eye_dropper/widget/eye_dropper.dart';
import 'package:eye_dropper/widget/image_picker_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  /// 画像の表示領域の画面サイズに対する比率(横)
  static const imageAreaWidthRatio = 0.95;
  /// 画像の表示領域の画面サイズに対する比率(縦)
  static const imageAreaHeightRatio = 0.65;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Eye Dropper',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Builder(builder: (context) {
        // 画像の表示サイズ
        final screenSize = MediaQuery.of(context).size;
        final imageAreaSize = Size(
          screenSize.width * imageAreaWidthRatio,
          screenSize.height * imageAreaHeightRatio,
        );
        return MyHomePage(title: 'Eye Dropper', imageAreaSize: imageAreaSize);
      },),
    );
  }
}

class MyHomePage extends StatelessWidget {
  MyHomePage({super.key, required this.title, required this.imageAreaSize});

  final String title;
  final Size imageAreaSize;
  final ValueNotifier<Uint8List?> _bytes = ValueNotifier(null);
  final ValueNotifier<Color> _color = ValueNotifier(Colors.white);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 抽出した色の表示部分
            ValueListenableBuilder(
              valueListenable: _color,
              builder: (_, color, __) {
                return Column(
                  children: [
                    // 選択された色の色見本を表示
                    CustomPaint(
                      size: const Size(50, 50),
                      painter: PickedPainter(color),
                    ),
                    // 選択された色のカラーコードを表示
                    Text(color.hexTriplet()),
                  ],
                );
              },
            ),
            // 画像から色を抽出する部分
            ValueListenableBuilder(
              valueListenable: _bytes,
              builder: (_, bytes, __) {
                // Eye dropper instantiation
                return EyeDropper.of(
                  bytes: bytes, // raw image bytes
                  size: imageAreaSize,
                  // Pointerクラスを拡張して好きなポインタを作れる
                  // デフォルト
                  // pointerBuilder: MagnifierPointer.new,
                  // より簡単なの
                  // pointerBuilder: SimplePointer.instanceOf,
                  pointerBuilder: (uiImage, ratio) => MagnifierPointer(
                    uiImage,
                    ratio,
                    magnification: 2.5,
                    outerRectSize: 101,
                    innerRectSize: 9,
                    strokeWidth: 3,
                  ),
                  onSelected: (color) => _color.value = color,
                );
              },
            ),
            ImagePickerButton(
              onSelected: (bytes) => _bytes.value = bytes,
            ),
          ],
        ),
      ),
    );
  }
}

/// 渡された色を表示するだけ
@immutable
class PickedPainter extends CustomPainter {
  const PickedPainter(this.color);

  static const double rectSize = 50;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    const rect = Rect.fromLTWH(0, 0, rectSize, rectSize);
    paint
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

/// Uint32をRGBカラーコードに変換
extension HexTriplet on Color {
  String hexTriplet() {
    return '#${value.toRadixString(16).padLeft(8, '0')
        .substring(2, 8).toUpperCase()}';
  }
}
