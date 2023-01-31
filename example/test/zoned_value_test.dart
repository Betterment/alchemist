import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

const zoneValueKey = #testZoneValueKey;
const providedValue = 42;

int? getZoneValue() => Zone.current[zoneValueKey] as int?;

void main() {
  runZoned(
    () {
      group('Zoned value test group', () {
        goldenTest(
          'zoned value test',
          fileName: 'zoned_value',
          textScaleFactor: 4,
          builder: () {
            final retrievedValue = getZoneValue();
            final isCorrect = retrievedValue == providedValue;

            if (!isCorrect) {
              print(
                'Expected zone value to be $providedValue, but '
                'was $retrievedValue instead. '
                'Seems like the zone value was not passed to the golden test '
                'properly.',
              );
            }

            return Text(
              '${isCorrect ? 'Correct' : 'Incorrect'}: $retrievedValue',
            );
          },
          pumpWidget: (tester, widget, runInOuterZone) {
            runInOuterZone(() {
              print('Zone value in pumpWidget: ${getZoneValue()}');
            });
            return onlyPumpWidget(tester, widget, runInOuterZone);
          },
          pumpBeforeTest: (tester, runInOuterZone) {
            runInOuterZone(() {
              print('Zone value in pumpBeforeTest: ${getZoneValue()}');
            });
            return onlyPumpAndSettle(tester, runInOuterZone);
          },
          whilePerforming: (tester, runInOuterZone) async {
            runInOuterZone(() {
              print('Zone value in whilePerforming: ${getZoneValue()}');
            });
          },
        );
      });
    },
    zoneValues: {zoneValueKey: providedValue},
  );
}
