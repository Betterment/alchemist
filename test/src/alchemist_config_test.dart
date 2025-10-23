import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:test/test.dart';

void main() {
  group('AlchemistConfig', () {
    test('supports value equality', () {
      expect(
        const AlchemistConfig(forceUpdateGoldenFiles: true),
        const AlchemistConfig(forceUpdateGoldenFiles: true),
      );

      expect(
        const AlchemistConfig(forceUpdateGoldenFiles: false),
        isNot(const AlchemistConfig(forceUpdateGoldenFiles: true)),
      );
    });

    test('has correct defaults', () {
      expect(
        const AlchemistConfig(),
        isA<AlchemistConfig>()
            .having(
              (c) => c.forceUpdateGoldenFiles,
              'forceUpdateGoldenFiles',
              isFalse,
            )
            .having(
              (c) => c.platformGoldensConfig,
              'platformGoldensConfig',
              equals(const PlatformGoldensConfig()),
            )
            .having(
              (c) => c.ciGoldensConfig,
              'ciGoldensConfig',
              equals(const CiGoldensConfig()),
            ),
      );
    });

    group('.current', () {
      test('returns the default config when none is set', () {
        const defaultConfig = AlchemistConfig();

        Object? providedConfig;
        runZoned(
          () => providedConfig = AlchemistConfig.current(),
          zoneValues: {AlchemistConfig.currentConfigKey: null},
        );

        expect(providedConfig, equals(defaultConfig));
      });

      test('returns the config in the current zone', () {
        const expectedConfig = AlchemistConfig(forceUpdateGoldenFiles: true);

        Object? providedConfig;
        runZoned(
          () => providedConfig = AlchemistConfig.current(),
          zoneValues: {AlchemistConfig.currentConfigKey: expectedConfig},
        );

        expect(providedConfig, equals(expectedConfig));
      });
    });

    test(
      'runWithConfig runs given function in a zone with provided config',
      () {
        const outerConfig = AlchemistConfig(forceUpdateGoldenFiles: false);
        const innerConfig = AlchemistConfig(forceUpdateGoldenFiles: true);

        Object? providedConfig;

        runZoned(
          () => AlchemistConfig.runWithConfig<void>(
            config: innerConfig,
            run: () =>
                providedConfig = Zone.current[AlchemistConfig.currentConfigKey],
          ),
          zoneValues: {AlchemistConfig.currentConfigKey: outerConfig},
        );

        expect(providedConfig, equals(innerConfig));
      },
    );

    group('copyWith', () {
      test('does nothing if no arguments are provided', () {
        expect(
          const AlchemistConfig().copyWith(),
          equals(const AlchemistConfig()),
        );
      });

      test('does not replace fields with null values', () {
        final theme = ThemeData.light();

        expect(
          AlchemistConfig(theme: theme).copyWith(),
          equals(AlchemistConfig(theme: theme)),
        );
      });

      test('replaces the given fields', () {
        const platformGoldensConfig = PlatformGoldensConfig();
        const ciGoldensConfig = CiGoldensConfig();

        expect(
          const AlchemistConfig().copyWith(
            forceUpdateGoldenFiles: true,
            platformGoldensConfig: platformGoldensConfig,
            ciGoldensConfig: ciGoldensConfig,
          ),
          isA<AlchemistConfig>()
              .having(
                (c) => c.forceUpdateGoldenFiles,
                'forceUpdateGoldenFiles',
                isTrue,
              )
              .having(
                (c) => c.platformGoldensConfig,
                'platformGoldensConfig',
                same(platformGoldensConfig),
              )
              .having(
                (c) => c.ciGoldensConfig,
                'ciGoldensConfig',
                same(ciGoldensConfig),
              ),
        );
      });
    });

    group('merge', () {
      test('does nothing if provided config is null', () {
        expect(
          const AlchemistConfig(forceUpdateGoldenFiles: true).merge(null),
          equals(const AlchemistConfig(forceUpdateGoldenFiles: true)),
        );
      });

      test('does nothing if provided config is untouched', () {
        expect(
          const AlchemistConfig(
            forceUpdateGoldenFiles: true,
          ).merge(const AlchemistConfig()),
          equals(const AlchemistConfig(forceUpdateGoldenFiles: true)),
        );
      });

      test('merges top-level (shallow) fields', () {
        expect(
          const AlchemistConfig(
            forceUpdateGoldenFiles: true,
          ).merge(const AlchemistConfig(forceUpdateGoldenFiles: false)),
          equals(const AlchemistConfig(forceUpdateGoldenFiles: false)),
        );
      });

      test('merges nested (deep) fields', () {
        final appliedTheme = ThemeData.dark();

        expect(
          const AlchemistConfig(
            forceUpdateGoldenFiles: true,
            platformGoldensConfig: PlatformGoldensConfig(),
            ciGoldensConfig: CiGoldensConfig(),
          ).merge(
            AlchemistConfig(
              platformGoldensConfig: PlatformGoldensConfig(theme: appliedTheme),
              ciGoldensConfig: CiGoldensConfig(theme: appliedTheme),
            ),
          ),
          isA<AlchemistConfig>()
              .having(
                (c) => c.forceUpdateGoldenFiles,
                'forceUpdateGoldenFiles',
                isTrue,
              )
              .having(
                (c) => c.platformGoldensConfig,
                'platformGoldensConfig',
                isA<PlatformGoldensConfig>()
                    .having((c) => c.enabled, 'enabled', isTrue)
                    .having((c) => c.theme, 'theme', same(appliedTheme)),
              )
              .having(
                (c) => c.ciGoldensConfig,
                'ciGoldensConfig',
                isA<CiGoldensConfig>()
                    .having((c) => c.enabled, 'enabled', isTrue)
                    .having((c) => c.theme, 'theme', same(appliedTheme)),
              ),
        );
      });
    });
  });

  group('PlatformGoldensConfig', () {
    test('supports value equality', () {
      expect(const PlatformGoldensConfig(), const PlatformGoldensConfig());

      expect(
        const PlatformGoldensConfig(),
        isNot(PlatformGoldensConfig(filePathResolver: (_, __) async => 'foo')),
      );
    });

    group('environmentName', () {
      final currentHostPlatform = hostPlatform;
      late final HostPlatform nextHostPlatform;

      setUpAll(() {
        // Pick an environment that's different from the current one to ensure
        // a proper test.
        nextHostPlatform = HostPlatform.values.firstWhere(
          (platform) => currentHostPlatform != platform,
        );
        hostPlatform = nextHostPlatform;
      });

      test('returns current operating system', () {
        expect(
          const PlatformGoldensConfig().environmentName,
          nextHostPlatform.operatingSystem,
        );
      });

      tearDownAll(() {
        hostPlatform = currentHostPlatform;
      });
    });

    group('has correct default value', () {
      const defaultValue = PlatformGoldensConfig();

      test('for renderShadows', () {
        expect(defaultValue.renderShadows, isTrue);
      });

      group('for default filePathResolver', () {
        test('generates path correctly', () {
          expect(
            defaultValue.filePathResolver('foo', 'bar'),
            equals('goldens/bar/foo.png'),
          );
        });
      });
    });

    group('copyWith', () {
      test('does nothing if no arguments are provided', () {
        expect(
          const PlatformGoldensConfig().copyWith(),
          equals(const PlatformGoldensConfig()),
        );
      });

      test('does not replace fields with null values', () {
        const enabled = false;

        expect(
          const PlatformGoldensConfig(enabled: enabled).copyWith(),
          equals(const PlatformGoldensConfig(enabled: enabled)),
        );
      });

      test('replaces the given fields', () {
        const enabled = false;

        expect(
          const PlatformGoldensConfig().copyWith(enabled: enabled),
          isA<PlatformGoldensConfig>().having(
            (c) => c.enabled,
            'enabled',
            enabled,
          ),
        );
      });
    });

    group('merge', () {
      test('does nothing if provided config is null', () {
        expect(
          const PlatformGoldensConfig().merge(null),
          equals(const PlatformGoldensConfig()),
        );
      });

      test('does nothing if provided config is untouched', () {
        expect(
          const PlatformGoldensConfig().merge(const PlatformGoldensConfig()),
          equals(const PlatformGoldensConfig()),
        );
      });

      test('merges fields', () {
        const appliedEnabled = false;

        expect(
          const PlatformGoldensConfig().merge(
            const PlatformGoldensConfig(enabled: appliedEnabled),
          ),
          isA<PlatformGoldensConfig>().having(
            (c) => c.enabled,
            'enabled',
            appliedEnabled,
          ),
        );
      });
    });
  });

  group('CiGoldensConfig', () {
    test('supports value equality', () {
      expect(const CiGoldensConfig(), const CiGoldensConfig());

      expect(
        const CiGoldensConfig(),
        isNot(CiGoldensConfig(filePathResolver: (_, __) async => 'foo')),
      );
    });

    group('has correct default value', () {
      const defaultValue = CiGoldensConfig();

      test('for renderShadows', () {
        expect(defaultValue.renderShadows, isFalse);
      });

      test('for filePathResolver', () {
        expect(
          defaultValue.filePathResolver('foo', 'bar'),
          equals('goldens/bar/foo.png'),
        );
      });

      test('environmentName is CI', () {
        expect(defaultValue.environmentName, 'CI');
      });
    });

    group('copyWith', () {
      test('does nothing if no arguments are provided', () {
        expect(
          const CiGoldensConfig().copyWith(),
          equals(const CiGoldensConfig()),
        );
      });

      test('does not replace fields with null values', () {
        const enabled = false;

        expect(
          const CiGoldensConfig(enabled: enabled).copyWith(),
          equals(const CiGoldensConfig(enabled: enabled)),
        );
      });

      test('replaces the given fields', () {
        const enabled = false;

        expect(
          const CiGoldensConfig().copyWith(enabled: enabled),
          isA<CiGoldensConfig>().having((c) => c.enabled, 'enabled', enabled),
        );
      });
    });

    group('merge', () {
      test('does nothing if provided config is null', () {
        expect(
          const CiGoldensConfig().merge(null),
          equals(const CiGoldensConfig()),
        );
      });

      test('does nothing if provided config is untouched', () {
        expect(
          const CiGoldensConfig().merge(const CiGoldensConfig()),
          equals(const CiGoldensConfig()),
        );
      });

      test('merges fields', () {
        const appliedEnabled = false;

        expect(
          const CiGoldensConfig().merge(
            const CiGoldensConfig(enabled: appliedEnabled),
          ),
          isA<CiGoldensConfig>().having(
            (c) => c.enabled,
            'enabled',
            appliedEnabled,
          ),
        );
      });
    });
  });
}
