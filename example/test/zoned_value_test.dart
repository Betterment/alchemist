import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

const zoneValueKey = #testZoneValueKey;

int? getZoneValue() => Zone.current[zoneValueKey] as int?;

void main() {
  runZoned(
    () {
      group('Zoned value test group', () {
        goldenTest(
          'zoned value test',
          fileName: 'zoned_value',
          builder: () {
            assert(
              getZoneValue() == 42,
              'Expected zone value to be 42, but was ${getZoneValue()}. '
              'Seems like the zone value was not passed to the golden test '
              'properly.',
            );

            return const SizedBox.shrink();
          },
        );
      });
    },
    zoneValues: {zoneValueKey: 42},
  );
}
