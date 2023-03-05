import 'package:eye_dropper/pointer/magnifier_pointer.dart';
import 'package:eye_dropper/pointer/simple_pointer.dart';
import 'package:eye_dropper/widget/eye_dropper.dart';
import 'package:eye_dropper/widget/image_picker_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 画像表示領域のサイズ
final imageAreaSizeProvider = Provider<Size>((ref) => Size.zero);
/// 画像のUint8List表現
final imageBytesProvider = StateProvider<Uint8List?>((ref) => null);
/// 選択された色
// final colorProvider = StateProvider<Color>((ref) => Colors.white);

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
          child: MyHomePage(title: 'スポイトツール'),
        );
      },),
    );
  }
}

class MyHomePage extends ConsumerWidget {
  MyHomePage({super.key, required this.title});

  final String title;

  final ValueNotifier<Color> _color = ValueNotifier(Colors.white);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imageAreaSize = ref.watch(imageAreaSizeProvider);
    final imageBytes = ref.watch(imageBytesProvider);
    // final color = ref.watch(colorProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ValueListenableBuilder(
              valueListenable: _color,
              builder: (_, color, __) {
                return Column(
                  children: [
                    // 選択された色見本を表示
                    CustomPaint(
                      size: const Size(50, 50),
                      painter: PickedPainter(color),
                      // painter: pickedPainter..color = color,
                    ),
                    // 選択された色のカラーコードを表示
                    Text(color.hexTriplet()),
                  ],
                );
              },
            ),
            // 画像表示領域
            EyeDropper.of(
              // TODO XFileで渡す？
              bytes: imageBytes,
              size: imageAreaSize,
              pointerBuilder: DraggableMagnifierPointer.new,
              // pointerBuilder: SimplePointer.instanceOf,
              onSelected: (color) {
                // TODO 画像によってかくつく (stateを更新しない場合は問題ない)
                // TODO stateを更新すると赤枠が表示されない
                // TODO 両方Riverpodにすると表示される(が余計にかくつく)
                // TODO 両方ValueNotifierにすると問題ない
                // ref.read(colorProvider.notifier).state = color;
                _color.value = color;
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
@immutable
class PickedPainter extends CustomPainter {
  const PickedPainter(this.color);

  static const double rectSize = 50;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    const rect = Rect.fromLTWH(0, 0, rectSize, rectSize);
    canvas.drawRect(rect, paint);
    // 選択された色で塗りつぶした四角を表示
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
// class PickedPainter extends CustomPainter {
//   static const double rectSize = 50;
//   Color color = Colors.white;
//
//   @override
//   void paint(Canvas canvas, Size size) {
//     // 選択された色で塗りつぶした四角を表示
//     final p = Paint()
//       ..color = color
//       ..style = PaintingStyle.fill;
//     const r = Rect.fromLTWH(0, 0, rectSize, rectSize);
//     canvas.drawRect(r, p);
//   }
//
//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
// }

extension HexTriplet on Color {
  String hexTriplet() {
    return '#${value.toRadixString(16).padLeft(8, '0')
        .substring(2, 8).toUpperCase()}';
  }
}
