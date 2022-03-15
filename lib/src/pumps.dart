import 'package:alchemist/alchemist.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// A function that may perform pumping actions to prime a golden test.
///
/// Used in the [goldenTest] function to perform any actions necessary to prime
/// the widget tree before the golden test is compared or generated.
typedef PumpAction = Future<void> Function(WidgetTester tester);

/// A function used to render a given [Widget].
typedef PumpWidget = Future<void> Function(WidgetTester tester, Widget widget);

/// Returns a custom [PumpAction] that pumps the widget tree [n] times before
/// golden evaluation.
///
/// See [PumpAction] for more details.
PumpAction pumpNTimes(int n, [Duration? duration]) {
  return (tester) async {
    for (var i = 0; i < n; i++) {
      await tester.pump(duration);
    }
  };
}

/// A custom [PumpAction] that pumps the widget tree once before golden
/// evaluation.
///
/// See [PumpAction] for more details.
final pumpOnce = pumpNTimes(1);

/// A custom [PumpAction] that pumps and settles the widget tree before golden
/// evaluation.
///
/// See [PumpAction] for more details.
Future<void> onlyPumpAndSettle(WidgetTester tester) => tester.pumpAndSettle();

/// A custom [PumpAction] to ensure that the images for all [Image],
/// [FadeInImage], and [DecoratedBox] widgets are loaded before the golden file
/// is generated.
///
/// See [PumpAction] for more details.
Future<void> precacheImages(WidgetTester tester) async {
  await tester.runAsync(() async {
    final images = <Future<void>>[];
    for (final element in find.byType(Image).evaluate()) {
      final widget = element.widget as Image;
      final image = widget.image;
      images.add(precacheImage(image, element));
    }
    for (final element in find.byType(FadeInImage).evaluate()) {
      final widget = element.widget as FadeInImage;
      final image = widget.image;
      images.add(precacheImage(image, element));
    }
    for (final element in find.byType(DecoratedBox).evaluate()) {
      final widget = element.widget as DecoratedBox;
      final decoration = widget.decoration;
      if (decoration is BoxDecoration && decoration.image != null) {
        final image = decoration.image!.image;
        images.add(precacheImage(image, element));
      }
    }
    await Future.wait(images);
  });
  await tester.pumpAndSettle();
}

/// A custom [PumpWidget] that pumps the widget tree before golden
/// evaluation.
///
/// See [PumpWidget] for more details.
Future<void> onlyPumpWidget(WidgetTester tester, Widget widget) {
  return tester.pumpWidget(widget);
}
