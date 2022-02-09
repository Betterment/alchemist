import 'dart:ui' as ui;

import 'package:alchemist/alchemist.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Extensions on [WidgetTester] to help with image manipulation when running
/// golden tests.
///
/// Used internally by [goldenTest].
@protected
extension BlockedTextImageWidgetTesterExtensions on WidgetTester {
  /// Generates an image of the widget at the given [finder] with all text
  /// represented as colored rectangles.
  ///
  /// See [BlockedTextPaintingContext] for more details.
  ///
  /// Only used internally and should not be used by consumers.
  @protected
  Future<ui.Image> getBlockedTextImage(Finder finder) {
    var renderObject = this.renderObject(finder);
    while (!renderObject.isRepaintBoundary) {
      renderObject = renderObject.parent! as RenderObject;
    }
    final layer = OffsetLayer();
    BlockedTextPaintingContext(
      containerLayer: layer,
      estimatedBounds: renderObject.paintBounds,
    ).paintSingleChild(renderObject);

    return layer.toImage(renderObject.paintBounds);
  }
}

/// {@template blocked_text_painting_context}
/// A painting context used to replace all text blocks with colored rectangles.
///
/// This is used in golden tests to circumvent inconsistencies with font
/// rendering between operating systems.
///
/// To use in a golden test, see
/// [BlockedTextImageWidgetTesterExtensions.getBlockedTextImage].
///
/// Only used internally and should not be used by consumers.
/// {@endtemplate}
class BlockedTextPaintingContext extends PaintingContext {
  /// {@macro blocked_text_painting_context}
  BlockedTextPaintingContext({
    required ContainerLayer containerLayer,
    required Rect estimatedBounds,
  }) : super(containerLayer, estimatedBounds);

  @override
  PaintingContext createChildContext(
    ContainerLayer childLayer,
    Rect bounds,
  ) {
    return BlockedTextPaintingContext(
      containerLayer: childLayer,
      estimatedBounds: bounds,
    );
  }

  @override
  void paintChild(RenderObject child, Offset offset) {
    if (child is RenderParagraph) {
      final paint = Paint()
        ..color = child.text.style?.color ?? const Color(0xFF000000);
      canvas.drawRect(offset & child.size, paint);
    } else {
      return child.paint(this, offset);
    }
  }

  /// Paints the single given [RenderObject].
  void paintSingleChild(RenderObject child) {
    paintChild(child, Offset.zero);
    stopRecordingIfNeeded();
  }
}
