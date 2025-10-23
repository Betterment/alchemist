import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('smoke test', () {
    goldenTest(
      'succeeds for custom render object drawing text',
      fileName: 'render_object_text_smoke_test',
      builder: () => const SizedBox(
        height: 400,
        width: 400,
        child: _CustomExampleRenderObject(),
      ),
    );
  });
}

class _CustomExampleRenderObject extends LeafRenderObjectWidget {
  const _CustomExampleRenderObject();

  @override
  _CustomExampleRenderBox createRenderObject(BuildContext context) {
    return _CustomExampleRenderBox();
  }
}

class _CustomExampleRenderBox extends RenderBox {
  @override
  void paint(PaintingContext context, Offset offset) {
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'text',
        style: TextStyle(
          fontFamily: 'Roboto',
          color: Colors.black,
          fontSize: 24,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      context.canvas,
      const Offset(200, 200) - textPainter.size.center(Offset.zero),
    );
  }

  @override
  void performLayout() {
    size = computeDryLayout(constraints);
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    return constraints.constrain(Size(200, constraints.maxHeight));
  }
}
