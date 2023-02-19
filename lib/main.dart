import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'component/eye_dropper.dart';
import 'component/image_picker_button.dart';

/// 画像表示領域のサイズ
final imageAreaSizeProvider = Provider<Size>((ref) => Size.zero);
/// 画像のUint8List表現
final imageBytesProvider = StateProvider<Uint8List?>((ref) => null);
/// 選択された色
final colorProvider = StateProvider<Color>((ref) => Colors.white);

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  /// 画像の表示領域の画面サイズに対する比率(横)
  static const imageAreaWidthRatio = 0.95;
  /// 画像の表示領域の画面サイズに対する比率(縦)
  static const imageAreaHeightRatio = 0.65;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'スポイトツール',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Builder(builder: (context) {
        // 画像表示領域のサイズを設定
        final screenSize = MediaQuery.of(context).size;
        final imageAreaSize = Size(
            screenSize.width * imageAreaWidthRatio,
            screenSize.height * imageAreaHeightRatio,
        );
        return ProviderScope(
          overrides: [
            imageAreaSizeProvider.overrideWith((ref) => imageAreaSize),
          ],
          child: const MyHomePage(title: 'スポイトツール'),
        );
      },),
    );
  }
}

class MyHomePage extends ConsumerWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imageAreaSize = ref.watch(imageAreaSizeProvider);
    final imageBytes = ref.watch(imageBytesProvider);
    final color = ref.watch(colorProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 選択された色見本を表示
            CustomPaint(
              size: const Size(50, 50),
              painter: PickedPainter(color),
            ),
            // 選択された色のカラーコードを表示
            Text(color.hexTriplet()),
            // 画像表示領域
            // TODO やっぱり統一したい
            if(imageBytes == null)
              Container(
                alignment: Alignment.center,
                width: imageAreaSize.width,
                height: imageAreaSize.height,
              ),
            if(imageBytes != null)
              EyeDropper(
                bytes: imageBytes,
                size: imageAreaSize,
                onSelected: (color) {
                  // TODO かくつく？
                  // TODO 赤枠が表示されない
                  ref.read(colorProvider.notifier).state = color;
                },
              ),
            ImagePickerButton(
              onSelected: (bytes) {
                ref.read(imageBytesProvider.notifier).state = bytes;
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// 吸い取った色の表示領域
class PickedPainter extends CustomPainter {
  PickedPainter(this.color);

  static const double rectSize = 50;
  Color color;

  @override
  void paint(Canvas canvas, Size size) {
    // 選択された色で塗りつぶした四角を表示
    final p = Paint()
              ..color = color
              ..style = PaintingStyle.fill;
    const r = Rect.fromLTWH(0, 0, rectSize, rectSize);
    canvas.drawRect(r, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

extension HexTriplet on Color {
  String hexTriplet() {
    return '#${value.toRadixString(16).padLeft(8, '0')
        .substring(2, 8).toUpperCase()}';
  }
}
