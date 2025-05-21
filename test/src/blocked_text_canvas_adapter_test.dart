import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:alchemist/alchemist.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockCanvas extends Mock implements ui.Canvas {}

class MockParagraph extends Mock implements ui.Paragraph {}

class FakeImage extends Fake implements ui.Image {}

class FakePicture extends Fake implements ui.Picture {}

void main() {
  group('BlockedTextCanvasAdapter', () {
    late ui.Canvas parent;
    late BlockedTextCanvasAdapter subject;

    setUpAll(() {
      registerFallbackValue(ui.Paint());
    });

    setUp(() {
      parent = MockCanvas();
      subject = BlockedTextCanvasAdapter(parent);
    });

    test('drawParagraph draws a rectangle', () {
      const offset = ui.Offset(20, 40);
      final paragraph = MockParagraph();
      when(() => paragraph.width).thenReturn(200);
      when(() => paragraph.height).thenReturn(400);
      subject.drawParagraph(paragraph, offset);
      verify(
        () => parent.drawRect(
          offset & const ui.Size(200, 400),
          any(that: isA<ui.Paint>()),
        ),
      ).called(1);
    });

    test('drawParagraph draws a rectangle for infinite width', () {
      const offset = ui.Offset(20, 40);
      final paragraph = MockParagraph();
      when(() => paragraph.width).thenReturn(double.infinity);
      when(() => paragraph.longestLine).thenReturn(400);
      when(() => paragraph.height).thenReturn(400);
      subject.drawParagraph(paragraph, offset);
      verify(
        () => parent.drawRect(
          offset & const ui.Size(400, 400),
          any(that: isA<ui.Paint>()),
        ),
      ).called(1);
    });

    test('clipPath delegates to parent implementation', () {
      final path = ui.Path();
      const doAntiAlias = false;
      subject.clipPath(path, doAntiAlias: doAntiAlias);
      verify(() => parent.clipPath(path, doAntiAlias: doAntiAlias));
    });

    test('clipRRect delegates to parent implementation', () {
      const rrect = ui.RRect.fromLTRBXY(0, 0, 0, 0, 10, 10);
      const doAntiAlias = false;
      subject.clipRRect(rrect, doAntiAlias: doAntiAlias);
      verify(() => parent.clipRRect(rrect, doAntiAlias: doAntiAlias)).called(1);
    });

    test('clipRect delegates to parent implementation', () {
      const rect = ui.Rect.fromLTWH(0, 0, 10, 10);
      const clipOp = ui.ClipOp.difference;
      const doAntiAlias = false;
      subject.clipRect(rect, clipOp: clipOp, doAntiAlias: doAntiAlias);
      verify(
        () => parent.clipRect(rect, clipOp: clipOp, doAntiAlias: doAntiAlias),
      ).called(1);
    });

    test('drawArc delegates to parent implementation', () {
      const rect = ui.Rect.fromLTWH(0, 0, 15, 20);
      const startAngle = 0.0;
      const sweepAngle = 1.0;
      const useCenter = true;
      final paint = ui.Paint();
      subject.drawArc(rect, startAngle, sweepAngle, useCenter, paint);
      verify(
        () => parent.drawArc(rect, startAngle, sweepAngle, useCenter, paint),
      ).called(1);
    });

    test('drawAtlas delegates to parent implementation', () {
      final atlas = FakeImage();
      final transforms = [ui.RSTransform(0, 0, 0, 0)];
      const rects = [ui.Rect.zero];
      const colors = [ui.Color.fromRGBO(0, 0, 0, 0.5)];
      const blendMode = ui.BlendMode.clear;
      const cullRect = ui.Rect.zero;
      final paint = ui.Paint();
      subject.drawAtlas(
        atlas,
        transforms,
        rects,
        colors,
        blendMode,
        cullRect,
        paint,
      );
      verify(
        () => parent.drawAtlas(
          atlas,
          transforms,
          rects,
          colors,
          blendMode,
          cullRect,
          paint,
        ),
      ).called(1);
    });

    test('drawCircle delegates to parent implementation', () {
      const c = ui.Offset.zero;
      const radius = 15.0;
      final paint = ui.Paint();
      subject.drawCircle(c, radius, paint);
      verify(() => parent.drawCircle(c, radius, paint)).called(1);
    });

    test('drawColor delegates to parent implementation', () {
      const color = ui.Color.fromRGBO(0, 0, 0, 0.5);
      const blendMode = ui.BlendMode.clear;
      subject.drawColor(color, blendMode);
      verify(() => parent.drawColor(color, blendMode)).called(1);
    });

    test('drawDRRect delegates to parent implementation', () {
      const outer = ui.RRect.fromLTRBXY(0, 0, 0, 0, 10, 10);
      const inner = ui.RRect.fromLTRBXY(0, 0, 0, 0, 20, 20);
      final paint = ui.Paint();
      subject.drawDRRect(outer, inner, paint);
      verify(() => parent.drawDRRect(outer, inner, paint)).called(1);
    });

    test('drawImage delegates to parent implementation', () {
      final image = FakeImage();
      const offset = ui.Offset.zero;
      final paint = ui.Paint();
      subject.drawImage(image, offset, paint);
      verify(() => parent.drawImage(image, offset, paint)).called(1);
    });

    test('drawImageNine delegates to parent implementation', () {
      final image = FakeImage();
      const center = ui.Rect.fromLTWH(0, 0, 10, 20);
      const dst = ui.Rect.fromLTWH(10, 0, 0, 10);
      final paint = ui.Paint();
      subject.drawImageNine(image, center, dst, paint);
      verify(() => parent.drawImageNine(image, center, dst, paint)).called(1);
    });

    test('drawImageRect delegates to parent implementation', () {
      final image = FakeImage();
      const src = ui.Rect.fromLTWH(0, 0, 10, 20);
      const dst = ui.Rect.fromLTWH(10, 0, 0, 10);
      final paint = ui.Paint();
      subject.drawImageRect(image, src, dst, paint);
      verify(() => parent.drawImageRect(image, src, dst, paint)).called(1);
    });

    test('drawLine delegates to parent implementation', () {
      const p1 = ui.Offset(0, 10);
      const p2 = ui.Offset(10, 0);
      final paint = ui.Paint();
      subject.drawLine(p1, p2, paint);
      verify(() => parent.drawLine(p1, p2, paint)).called(1);
    });

    test('drawOval delegates to parent implementation', () {
      const rect = ui.Rect.fromLTWH(0, 0, 15, 15);
      final paint = ui.Paint();
      subject.drawOval(rect, paint);
      verify(() => parent.drawOval(rect, paint)).called(1);
    });

    test('drawPaint delegates to parent implementation', () {
      final paint = ui.Paint();
      subject.drawPaint(paint);
      verify(() => parent.drawPaint(paint)).called(1);
    });

    test('drawPath delegates to parent implementation', () {
      final path = ui.Path();
      final paint = ui.Paint();
      subject.drawPath(path, paint);
      verify(() => parent.drawPath(path, paint)).called(1);
    });

    test('drawPicture delegates to parent implementation', () {
      final picture = FakePicture();
      subject.drawPicture(picture);
      verify(() => parent.drawPicture(picture)).called(1);
    });

    test('drawPoints delegates to parent implementation', () {
      const pointMode = ui.PointMode.points;
      const points = [ui.Offset.zero];
      final paint = ui.Paint();
      subject.drawPoints(pointMode, points, paint);
      verify(() => parent.drawPoints(pointMode, points, paint)).called(1);
    });

    test('drawRRect delegates to parent implementation', () {
      const rrect = ui.RRect.fromLTRBXY(0, 0, 0, 0, 10, 10);
      final paint = ui.Paint();
      subject.drawRRect(rrect, paint);
      verify(() => parent.drawRRect(rrect, paint)).called(1);
    });

    test('drawRawAtlas delegates to parent implementation', () {
      final atlas = FakeImage();
      final rstTransforms = Float32List(9);
      final rects = Float32List(5);
      final colors = Int32List(4);
      const blendMode = ui.BlendMode.clear;
      const cullRect = ui.Rect.zero;
      final paint = ui.Paint();
      subject.drawRawAtlas(
        atlas,
        rstTransforms,
        rects,
        colors,
        blendMode,
        cullRect,
        paint,
      );
      verify(
        () => parent.drawRawAtlas(
          atlas,
          rstTransforms,
          rects,
          colors,
          blendMode,
          cullRect,
          paint,
        ),
      ).called(1);
    });

    test('drawRawPoints delegates to parent implementation', () {
      const pointMode = ui.PointMode.points;
      final points = Float32List(10);
      final paint = ui.Paint();
      subject.drawRawPoints(pointMode, points, paint);
      verify(() => parent.drawRawPoints(pointMode, points, paint)).called(1);
    });

    test('drawRect delegates to parent implementation', () {
      const rect = ui.Rect.fromLTWH(0, 0, 10, 50);
      final paint = ui.Paint();
      subject.drawRect(rect, paint);
      verify(() => parent.drawRect(rect, paint)).called(1);
    });

    test('drawShadow delegates to parent implementation', () {
      final path = ui.Path();
      const color = ui.Color.fromRGBO(0, 0, 0, 0.5);
      const elevation = 0.5;
      const transparentOccluder = false;
      subject.drawShadow(path, color, elevation, transparentOccluder);
      verify(
        () => parent.drawShadow(path, color, elevation, transparentOccluder),
      ).called(1);
    });

    test('drawVertices delegates to parent implementation', () {
      final vertices = ui.Vertices(ui.VertexMode.triangles, [Offset.zero]);
      const blendMode = ui.BlendMode.color;
      final paint = ui.Paint();
      subject.drawVertices(vertices, blendMode, paint);
      verify(() => parent.drawVertices(vertices, blendMode, paint)).called(1);
    });

    test('getSaveCount delegates to parent implementation', () {
      when(parent.getSaveCount).thenReturn(5);
      expect(subject.getSaveCount(), 5);
      verify(parent.getSaveCount).called(1);
    });

    test('restore delegates to parent implementation', () {
      subject.restore();
      verify(parent.restore).called(1);
    });

    test('rotate delegates to parent implementation', () {
      const radians = 0.25;
      subject.rotate(radians);
      verify(() => parent.rotate(radians)).called(1);
    });

    test('save delegates to parent implementation', () {
      subject.save();
      verify(parent.save).called(1);
    });

    test('saveLayer delegates to parent implementation', () {
      const bounds = ui.Rect.fromLTWH(0, 0, 10, 50);
      final paint = ui.Paint();
      subject.saveLayer(bounds, paint);
      verify(() => parent.saveLayer(bounds, paint)).called(1);
    });

    test('scale delegates to parent implementation', () {
      const sx = 5.5;
      const sy = 4.4;
      subject.scale(sx, sy);
      verify(() => parent.scale(sx, sy)).called(1);
    });

    test('skew delegates to parent implementation', () {
      const sx = 5.5;
      const sy = 4.4;
      subject.skew(sx, sy);
      verify(() => parent.skew(sx, sy));
    });

    test('transform delegates to parent implementation', () {
      final matrix4 = Float64List(5);
      subject.transform(matrix4);
      verify(() => parent.transform(matrix4)).called(1);
    });

    test('translate delegates to parent implementation', () {
      const dx = 5.5;
      const dy = 4.4;
      subject.translate(dx, dy);
      verify(() => parent.translate(dx, dy)).called(1);
    });

    test('getDestinationClipBounds delegates to parent implementation', () {
      when(parent.getDestinationClipBounds).thenReturn(ui.Rect.zero);
      subject.getDestinationClipBounds();
      verify(parent.getDestinationClipBounds).called(1);
    });

    test('getLocalClipBounds delegates to parent implementation', () {
      when(parent.getLocalClipBounds).thenReturn(ui.Rect.zero);
      subject.getLocalClipBounds();
      verify(parent.getLocalClipBounds).called(1);
    });

    test('getTransform delegates to parent implementation', () {
      when(parent.getTransform).thenReturn(Float64List(0));
      subject.getTransform();
      verify(parent.getTransform).called(1);
    });

    test('restoreToCount delegates to parent implementation', () {
      subject.restoreToCount(0);
      verify(() => parent.restoreToCount(0)).called(1);
    });
  });
}
