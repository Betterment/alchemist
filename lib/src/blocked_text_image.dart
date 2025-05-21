import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';

/// {@template blocked_text_painting_context}
/// A painting context used to replace all text blocks with colored rectangles.
///
/// This is used in golden tests to circumvent inconsistencies with font
/// rendering between operating systems.
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
  ui.Canvas get canvas {
    return BlockedTextCanvasAdapter(super.canvas);
  }

  @override
  PaintingContext createChildContext(ContainerLayer childLayer, Rect bounds) {
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

/// {@template blocked_text_canvas_adapter}
/// An adapter used to change how a canvas draws text
///
/// This class delegates all drawing operations to the [parent] canvas,
/// except it replaces all text with rectangles. It is used along with
/// [BlockedTextPaintingContext] to circumvent font rendering inconsistencies
/// between platforms.
///
/// Only used internally and should not be used by consumers.
/// {@endtemplate}
class BlockedTextCanvasAdapter implements Canvas {
  /// {@macro blocked_text_canvas_adapter}
  BlockedTextCanvasAdapter(this.parent);

  /// The parent [Canvas] that handles drawing operations
  final Canvas parent;

  /// Draws a rectangle on the canvas where the [paragraph]
  /// would otherwise be rendered
  @override
  void drawParagraph(ui.Paragraph paragraph, ui.Offset offset) =>
      parent.drawRect(
        offset &
            Size(
              paragraph.width.isFinite
                  ? paragraph.width
                  : paragraph.longestLine,
              paragraph.height,
            ),
        Paint(),
      );

  @override
  void clipPath(ui.Path path, {bool doAntiAlias = true}) =>
      parent.clipPath(path, doAntiAlias: doAntiAlias);

  @override
  void clipRRect(ui.RRect rrect, {bool doAntiAlias = true}) =>
      parent.clipRRect(rrect, doAntiAlias: doAntiAlias);

  @override
  void clipRect(
    ui.Rect rect, {
    ui.ClipOp clipOp = ui.ClipOp.intersect,
    bool doAntiAlias = true,
  }) => parent.clipRect(rect, clipOp: clipOp, doAntiAlias: doAntiAlias);

  @override
  void drawArc(
    ui.Rect rect,
    double startAngle,
    double sweepAngle,
    bool useCenter,
    ui.Paint paint,
  ) => parent.drawArc(rect, startAngle, sweepAngle, useCenter, paint);

  @override
  void drawAtlas(
    ui.Image atlas,
    List<ui.RSTransform> transforms,
    List<ui.Rect> rects,
    List<ui.Color>? colors,
    ui.BlendMode? blendMode,
    ui.Rect? cullRect,
    ui.Paint paint,
  ) => parent.drawAtlas(
    atlas,
    transforms,
    rects,
    colors,
    blendMode,
    cullRect,
    paint,
  );

  @override
  void drawCircle(ui.Offset c, double radius, ui.Paint paint) =>
      parent.drawCircle(c, radius, paint);

  @override
  void drawColor(ui.Color color, ui.BlendMode blendMode) =>
      parent.drawColor(color, blendMode);

  @override
  void drawDRRect(ui.RRect outer, ui.RRect inner, ui.Paint paint) =>
      parent.drawDRRect(outer, inner, paint);

  @override
  void drawImage(ui.Image image, ui.Offset offset, ui.Paint paint) =>
      parent.drawImage(image, offset, paint);

  @override
  void drawImageNine(
    ui.Image image,
    ui.Rect center,
    ui.Rect dst,
    ui.Paint paint,
  ) => parent.drawImageNine(image, center, dst, paint);

  @override
  void drawImageRect(
    ui.Image image,
    ui.Rect src,
    ui.Rect dst,
    ui.Paint paint,
  ) => parent.drawImageRect(image, src, dst, paint);

  @override
  void drawLine(ui.Offset p1, ui.Offset p2, ui.Paint paint) =>
      parent.drawLine(p1, p2, paint);

  @override
  void drawOval(ui.Rect rect, ui.Paint paint) => parent.drawOval(rect, paint);

  @override
  void drawPaint(ui.Paint paint) => parent.drawPaint(paint);

  @override
  void drawPath(ui.Path path, ui.Paint paint) => parent.drawPath(path, paint);

  @override
  void drawPicture(ui.Picture picture) => parent.drawPicture(picture);

  @override
  void drawPoints(
    ui.PointMode pointMode,
    List<ui.Offset> points,
    ui.Paint paint,
  ) => parent.drawPoints(pointMode, points, paint);

  @override
  void drawRRect(ui.RRect rrect, ui.Paint paint) =>
      parent.drawRRect(rrect, paint);

  @override
  void drawRawAtlas(
    ui.Image atlas,
    Float32List rstTransforms,
    Float32List rects,
    Int32List? colors,
    ui.BlendMode? blendMode,
    ui.Rect? cullRect,
    ui.Paint paint,
  ) => parent.drawRawAtlas(
    atlas,
    rstTransforms,
    rects,
    colors,
    blendMode,
    cullRect,
    paint,
  );

  @override
  void drawRawPoints(
    ui.PointMode pointMode,
    Float32List points,
    ui.Paint paint,
  ) => parent.drawRawPoints(pointMode, points, paint);

  @override
  void drawRect(ui.Rect rect, ui.Paint paint) => parent.drawRect(rect, paint);

  @override
  void drawShadow(
    ui.Path path,
    ui.Color color,
    double elevation,
    bool transparentOccluder,
  ) => parent.drawShadow(path, color, elevation, transparentOccluder);

  @override
  void drawVertices(
    ui.Vertices vertices,
    ui.BlendMode blendMode,
    ui.Paint paint,
  ) => parent.drawVertices(vertices, blendMode, paint);

  @override
  int getSaveCount() => parent.getSaveCount();

  @override
  void restore() => parent.restore();

  @override
  void rotate(double radians) => parent.rotate(radians);

  @override
  void save() => parent.save();

  @override
  void saveLayer(ui.Rect? bounds, ui.Paint paint) =>
      parent.saveLayer(bounds, paint);

  @override
  void scale(double sx, [double? sy]) => parent.scale(sx, sy);

  @override
  void skew(double sx, double sy) => parent.skew(sx, sy);

  @override
  void transform(Float64List matrix4) => parent.transform(matrix4);

  @override
  void translate(double dx, double dy) => parent.translate(dx, dy);

  @override
  ui.Rect getDestinationClipBounds() => parent.getDestinationClipBounds();

  @override
  ui.Rect getLocalClipBounds() => parent.getLocalClipBounds();

  @override
  Float64List getTransform() => parent.getTransform();

  @override
  void restoreToCount(int count) => parent.restoreToCount(count);

  @override
  void clipRSuperellipse(ui.RSuperellipse rse, {bool doAntiAlias = true}) =>
      parent.clipRSuperellipse(rse, doAntiAlias: doAntiAlias);

  @override
  void drawRSuperellipse(ui.RSuperellipse rse, ui.Paint paint) =>
      parent.drawRSuperellipse(rse, paint);
}
