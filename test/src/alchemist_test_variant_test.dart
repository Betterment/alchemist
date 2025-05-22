import 'package:alchemist/src/alchemist_config.dart';
import 'package:alchemist/src/alchemist_test_variant.dart';
import 'package:alchemist/src/host_platform.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAlchemistConfig extends Mock implements AlchemistConfig {}

class MockPlatformGoldensConfig extends Mock implements PlatformGoldensConfig {}

class MockCiGoldensConfig extends Mock implements CiGoldensConfig {}

class FakeImageStreamCompleter extends ImageStreamCompleter {}

void main() {
  group('AlchemistTestVariant', () {
    test('returns values', () {
      const platform = HostPlatform.linux;
      final ciConfig = MockCiGoldensConfig();
      when(() => ciConfig.enabled).thenReturn(true);
      final platformConfig = MockPlatformGoldensConfig();
      when(() => platformConfig.enabled).thenReturn(true);
      when(() => platformConfig.platforms).thenReturn({platform});
      final config = MockAlchemistConfig();
      when(() => config.platformGoldensConfig).thenReturn(platformConfig);
      when(() => config.ciGoldensConfig).thenReturn(ciConfig);
      final variant = AlchemistTestVariant(
        config: config,
        currentPlatform: platform,
      );
      expect(variant.values, {platformConfig, ciConfig});
    });

    group('Lifecycle', () {
      late AlchemistTestVariant variant;
      late MockAlchemistConfig config;

      setUp(() {
        config = MockAlchemistConfig();
        variant = AlchemistTestVariant(
          config: config,
          currentPlatform: HostPlatform.linux,
        );
      });

      test('instantiates', () {
        expect(variant, isA<AlchemistTestVariant>());
      });

      test('tearDown clears the image cache', () async {
        TestWidgetsFlutterBinding.ensureInitialized();
        imageCache.putIfAbsent('key', FakeImageStreamCompleter.new);
        expect(imageCache.containsKey('key'), isTrue);
        await variant.tearDown(MockCiGoldensConfig(), null);
        expect(imageCache.containsKey('key'), isFalse);
      });

      test('setUp sets current value', () async {
        final value = MockCiGoldensConfig();
        await expectLater(variant.setUp(value), completes);
        expect(variant.currentConfig, value);
      });

      test('describeValue returns environment name', () async {
        final value = MockCiGoldensConfig();
        const environmentName = 'TEST';
        when(() => value.environmentName).thenReturn(environmentName);
        expect(variant.describeValue(value), environmentName);
      });
    });
  });
}
