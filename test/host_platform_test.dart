import 'dart:io';

import 'package:alchemist/alchemist.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockHostPlatform extends Mock implements HostPlatform {}

void main() {
  group('HostPlatform', () {
    group('.current', () {
      test(
        'returns current host platform',
        () {
          if (Platform.isMacOS) {
            expect(
              HostPlatform.current(),
              HostPlatform.macOS,
            );
          } else if (Platform.isLinux) {
            expect(
              HostPlatform.current(),
              HostPlatform.linux,
            );
          } else if (Platform.isWindows) {
            expect(
              HostPlatform.current(),
              HostPlatform.windows,
            );
          }
        },
        skip: !Platform.isMacOS && !Platform.isLinux && !Platform.isWindows,
      );

      test('returns test value when set', () {
        final testValue = MockHostPlatform();

        HostPlatform.overrideTestValue = testValue;
        addTearDown(HostPlatform.clearOverrideTestValue);

        expect(HostPlatform.current(), same(testValue));
      });
    });

    test('clearOverrideTestValue reset value to current platform', () {
      final testValue = MockHostPlatform();

      HostPlatform.overrideTestValue = testValue;
      HostPlatform.clearOverrideTestValue();

      expect(HostPlatform.current(), isNot(same(testValue)));
    });

    test('has correct string representation', () {
      expect(
        HostPlatform.macOS.toString(),
        'HostPlatform(macos)',
      );
    });

    group('macOS', () {
      test('returns true for platform check', () {
        expect(HostPlatform.macOS.isMacOS, isTrue);

        expect(HostPlatform.macOS.isLinux, isFalse);
        expect(HostPlatform.macOS.isWindows, isFalse);
      });

      test('has correct operating system name', () {
        expect(HostPlatform.macOS.operatingSystem, 'macos');
      });
    });

    group('linux', () {
      test('returns true for platform check', () {
        expect(HostPlatform.linux.isLinux, isTrue);

        expect(HostPlatform.linux.isMacOS, isFalse);
        expect(HostPlatform.linux.isWindows, isFalse);
      });

      test('has correct operating system name', () {
        expect(HostPlatform.linux.operatingSystem, 'linux');
      });
    });

    group('windows', () {
      test('returns true for platform check', () {
        expect(HostPlatform.windows.isWindows, isTrue);

        expect(HostPlatform.windows.isLinux, isFalse);
        expect(HostPlatform.windows.isMacOS, isFalse);
      });

      test('has correct operating system name', () {
        expect(HostPlatform.windows.operatingSystem, 'windows');
      });
    });
  });
}
