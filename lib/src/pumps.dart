import 'package:alchemist/alchemist.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meta/meta.dart';

/// A function that takes a generic argument `T` and returns an instance of `T`.
typedef GenericBuilder = T Function<T>(T Function() fn);

/// A function that may perform pumping actions to prime a golden test.
///
/// Used in the [goldenTest] function to perform any actions necessary to prime
/// the widget tree before the golden test is compared or generated.
///
/// {@template run_in_outer_zone_arg}
/// The [runInOuterZone] function allows you to run code in the outer zone where
/// the golden test was defined. Code within the callback provided to this
/// function allows you to access any values defined in the outer zone, such as
/// the time from `package:clock`.
///
/// **Note that calls to the provided `WidgetTester` will NOT work inside this
/// callback.**
///
/// See [AlchemistConfig.runInOuterZone] for more details. Note that, regardless
/// of what that value is, the [runInOuterZone] function will always work the
/// same way.
/// {@endtemplate}
typedef PumpAction = Future<void> Function(
  WidgetTester tester,
  GenericBuilder runInOuterZone,
);

/// The equivalent of [PumpAction] for internal use.
@internal
typedef PumpActionInternal = Future<void> Function(WidgetTester tester);

/// A function used to render a given [Widget].
///
/// {@macro run_in_outer_zone_arg}
typedef PumpWidget = Future<void> Function(
  WidgetTester tester,
  Widget widget,
  GenericBuilder runInOuterZone,
);

/// The equivalent of [PumpWidget] for internal use.
@internal
typedef PumpWidgetInternal = Future<void> Function(
  WidgetTester tester,
  Widget widget,
);

/// Returns a custom [PumpAction] that pumps the widget tree [n] times before
/// golden evaluation.
///
/// See [PumpAction] for more details.
PumpAction pumpNTimes(int n, [Duration? duration]) {
  return (tester, _) async {
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
Future<void> onlyPumpAndSettle(
  WidgetTester tester,
  GenericBuilder _,
) {
  return onlyPumpAndSettleInternal(tester);
}

/// The equivalent of [onlyPumpAndSettle] for internal use.
@internal
Future<void> onlyPumpAndSettleInternal(WidgetTester tester) {
  return tester.pumpAndSettle();
}

/// A custom [PumpAction] to ensure that the images for all [Image],
/// [FadeInImage], and [DecoratedBox] widgets are loaded before the golden file
/// is generated.
///
/// See [PumpAction] for more details.
Future<void> precacheImages(WidgetTester tester, GenericBuilder _) async {
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
/// evaluation, analogous to [WidgetTester.pumpWidget].
///
/// See [PumpWidget] for more details.
Future<void> onlyPumpWidget(
  WidgetTester tester,
  Widget widget,
  GenericBuilder _,
) {
  return onlyPumpWidgetInternal(tester, widget);
}

/// The equivalent of [onlyPumpWidget] for internal use.
@internal
Future<void> onlyPumpWidgetInternal(
  WidgetTester tester,
  Widget widget,
) {
  return tester.pumpWidget(widget);
}
