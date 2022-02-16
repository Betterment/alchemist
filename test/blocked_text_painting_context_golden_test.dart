import 'dart:ui' as ui;

import 'package:alchemist/src/blocked_text_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _TextCustomPainter extends CustomPainter {
  const _TextCustomPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paragraphBuilder = ui.ParagraphBuilder(ui.ParagraphStyle())
      ..pushStyle(ui.TextStyle(color: const Color(0xFF0000FF)))
      ..addText('blue text');
    final paragraph = paragraphBuilder.build()
      ..layout(
        ui.ParagraphConstraints(
          width: size.width,
        ),
      );
    canvas.drawParagraph(paragraph, Offset.zero);
  }

  @override
  bool shouldRepaint(covariant _TextCustomPainter oldDelegate) {
    return true;
  }
}

void main() {
  group('BlockedTextPaintingContext', () {
    const goldenFilePath = 'goldens/blocked_text_image_reference.png';

    Future<void> setUpSurface(WidgetTester tester) async {
      final originalSize = tester.binding.window.physicalSize;
      const adjustedSize = Size(250, 100);

      tester.binding.window.physicalSizeTestValue = adjustedSize;
      await tester.binding.setSurfaceSize(adjustedSize);
      tester.binding.window.devicePixelRatioTestValue = 1.0;

      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
      addTearDown(() => tester.binding.setSurfaceSize(originalSize));
      addTearDown(tester.binding.window.clearDevicePixelRatioTestValue);
    }

    Widget buildSubject({
      Key? key,
    }) {
      return MaterialApp(
        key: key,
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'black text',
                  style: TextStyle(color: Color(0xFF000000)),
                ),
                SizedBox(height: 3),
                Text(
                  'red text',
                  style: TextStyle(color: Color(0xFFFF0000)),
                ),
                SizedBox(height: 3),
                CustomPaint(
                  painter: _TextCustomPainter(),
                  size: Size(250, 20),
                ),
              ],
            ),
          ),
        ),
      );
    }

    testWidgets('paints paragraphs in colored blocks', (tester) async {
      await setUpSurface(tester);

      const rootKey = Key('root');
      await tester.pumpWidget(
        buildSubject(
          key: rootKey,
        ),
      );

      final image = await tester.getBlockedTextImage(find.byKey(rootKey));

      await expectLater(
        image,
        matchesGoldenFile(goldenFilePath),
      );
    });
  });
}
