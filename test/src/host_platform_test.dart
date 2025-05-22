import 'dart:io';

import 'package:alchemist/alchemist.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockHostPlatform extends Mock implements HostPlatform {}

void main() {
  group('hostPlatform override', () {
    test('overrides and returns the given value', () {
      final nextHostPlatform = HostPlatform.values.firstWhere(
        (platform) => platform != hostPlatform,
      );
      hostPlatform = nextHostPlatform;
      expect(hostPlatform, nextHostPlatform);
      hostPlatform = defaultHostPlatform;
    });
  });

  group('HostPlatform', () {
    group('.current', () {
      test(
        'returns current host platform',
        () {
          if (Platform.isMacOS) {
            expect(HostPlatform.current(), HostPlatform.macOS);
          } else if (Platform.isLinux) {
            expect(HostPlatform.current(), HostPlatform.linux);
          } else if (Platform.isWindows) {
            expect(HostPlatform.current(), HostPlatform.windows);
          }
        },
        skip: !Platform.isMacOS && !Platform.isLinux && !Platform.isWindows,
      );
    });

    test('has correct string representation', () {
      expect(HostPlatform.macOS.toString(), 'HostPlatform(macOS)');
    });

    group('compareTo', () {
      test('is correct when compared to self', () {
        expect(HostPlatform.macOS.compareTo(HostPlatform.macOS), 0);
        expect(HostPlatform.linux.compareTo(HostPlatform.linux), 0);
        expect(HostPlatform.windows.compareTo(HostPlatform.windows), 0);
      });

      test('is consistent', () {
        expect(
          HostPlatform.macOS.compareTo(HostPlatform.linux),
          -1 * HostPlatform.linux.compareTo(HostPlatform.macOS),
        );
        expect(
          HostPlatform.macOS.compareTo(HostPlatform.windows),
          -1 * HostPlatform.windows.compareTo(HostPlatform.macOS),
        );
        expect(
          HostPlatform.windows.compareTo(HostPlatform.linux),
          -1 * HostPlatform.linux.compareTo(HostPlatform.windows),
        );
      });
    });

    group('macOS', () {
      test('returns true for platform check', () {
        expect(HostPlatform.macOS.isMacOS, isTrue);

        expect(HostPlatform.macOS.isLinux, isFalse);
        expect(HostPlatform.macOS.isWindows, isFalse);
      });

      test('has correct operating system name', () {
        expect(HostPlatform.macOS.operatingSystem, 'macOS');
      });
    });

    group('linux', () {
      test('returns true for platform check', () {
        expect(HostPlatform.linux.isLinux, isTrue);

        expect(HostPlatform.linux.isMacOS, isFalse);
        expect(HostPlatform.linux.isWindows, isFalse);
      });

      test('has correct operating system name', () {
        expect(HostPlatform.linux.operatingSystem, 'Linux');
      });
    });

    group('windows', () {
      test('returns true for platform check', () {
        expect(HostPlatform.windows.isWindows, isTrue);

        expect(HostPlatform.windows.isLinux, isFalse);
        expect(HostPlatform.windows.isMacOS, isFalse);
      });

      test('has correct operating system name', () {
        expect(HostPlatform.windows.operatingSystem, 'Windows');
      });
    });
  });
}
