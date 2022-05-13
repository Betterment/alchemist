import 'dart:math';
import 'dart:ui' as ui;

import 'package:alchemist/src/golden_test_runner.dart';
import 'package:flutter/material.dart' hide Animation;
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

extension on Duration {
  double operator /(Duration other) => inMicroseconds / other.inMicroseconds;
}

/// {@template capture_animation}
/// A class that can be used to wrap a [GetImageFn] and return an image showing
/// a grid of all the frames captured from the animated widget.
/// {@endtemplate}
class CaptureAnimation {
  /// {@macro capture_animation}
  const CaptureAnimation({
    required this.frameInterval,
    required this.timeout,
    required this.captureImage,
  });

  /// The amount of time in between each frame.
  final Duration frameInterval;

  /// The max amount of time to elapse during the animation. This is useful
  /// for infinite animations.
  final Duration timeout;

  /// Delegate to this function for actually capturing the image.
  final GetImageFn captureImage;

  /// Use this as a [GetImageFn] for capturing all frames of the animated widget
  /// and outputting an image of them layed out in a grid.
  Future<ui.Image> getFrames({
    required Finder finder,
    required WidgetTester tester,
    required bool obscureText,
  }) async {
    final frameCount = (timeout / frameInterval).ceil();
    final frames = <Future<ui.Image>>[];

    for (var frame = 0; frame < frameCount; frame++) {
      if (!tester.binding.hasScheduledFrame) break;
      if (frame < frameCount) {
        frames.add(
          captureImage(
            finder: finder,
            tester: tester,
            obscureText: obscureText,
          ),
        );
      }

      await tester.pump(frameInterval);
    }

    return _makeGrid(await Future.wait(frames));
  }

  Future<ui.Image> _makeGrid(List<ui.Image> images) {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final cellSize = images.fold<Size>(
      Size.zero,
      (size, image) => Size(
        max(size.width, image.width.toDouble()),
        max(size.height, image.height.toDouble()),
      ),
    );
    final area = cellSize.width * cellSize.height * images.length;
    final horizontalImageCount = (sqrt(area) / cellSize.width).round();
    final verticalImageCount = (images.length / horizontalImageCount).ceil();

    for (var y = 0; y < verticalImageCount; y++) {
      for (var x = 0; x < horizontalImageCount; x++) {
        final index = y * horizontalImageCount + x;
        if (index < images.length) {
          canvas.drawImage(
            images[index],
            Offset(cellSize.width * x, cellSize.height * y),
            Paint(),
          );
        } else {
          break;
        }
      }
    }

    final width = (horizontalImageCount * cellSize.width).toInt();
    final height = (verticalImageCount * cellSize.height).toInt();
    return recorder.endRecording().toImage(width, height);
  }
}
