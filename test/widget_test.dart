import 'package:eye_dropper/pointer/simple_pointer.dart';
import 'package:eye_dropper/widget/eye_dropper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('EyeDropper smoke test', (WidgetTester tester) async {
    Color? actualColor;

    await tester.runAsync(() async {
      final bytes = await rootBundle.load('test/music_castanet_girl.png');
      final eyeDropper = EyeDropper.of(
        bytes: bytes.buffer.asUint8List(),
        size: const Size(100, 200),
        pointerBuilder: SimplePointer.instanceOf,
        onSelected: (color) => actualColor = color,
      );
      await tester.pumpWidget(MaterialApp(home: eyeDropper));

      // Initial display is CircularProgressIndicator.
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      // Wait for FutureBuilder.
      await Future<void>.delayed(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      // Pointer and ImagePainter.
      expect(find.byType(CustomPaint), findsNWidgets(2));

      // Combination of offsets and colors.
      final map = {
        const Offset(390, 250): const Color(0xff312124),
        const Offset(390, 300): const Color(0xffffffff),
        const Offset(390, 350): const Color(0x00000000),
        const Offset(400, 250): const Color(0xff1a1112),
        const Offset(400, 290): const Color(0xffb82444),
        const Offset(400, 300): const Color(0xffffcba0), // center
        const Offset(400, 310): const Color(0xff51a4dd),
        const Offset(400, 350): const Color(0xffe5ded3),
        const Offset(420, 250): const Color(0x00000000),
        const Offset(420, 300): const Color(0xff170f0f),
        const Offset(420, 350): const Color(0x00000000),
      };
      for(final offsetColor in map.entries) {
        await tester.tapAt(offsetColor.key);
        await tester.pump();
        expect(actualColor, offsetColor.value);
      }
    });
  });
}
