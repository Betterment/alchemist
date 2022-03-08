// ignore_for_file: prefer_const_constructors

import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:test/test.dart';

void main() {
  group('AlchemistConfig', () {
    test('supports value equality', () {
      expect(
        AlchemistConfig(forceUpdateGoldenFiles: true),
        AlchemistConfig(forceUpdateGoldenFiles: true),
      );

      expect(
        AlchemistConfig(forceUpdateGoldenFiles: false),
        isNot(AlchemistConfig(forceUpdateGoldenFiles: true)),
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

    test('runWithConfig runs given function in a zone with provided config',
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
    });

    group('copyWith', () {
      test('does nothing if no arguments are provided', () {
        expect(
          AlchemistConfig().copyWith(),
          equals(AlchemistConfig()),
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
        final platformGoldensConfig = PlatformGoldensConfig();
        final ciGoldensConfig = CiGoldensConfig();

        expect(
          AlchemistConfig().copyWith(
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
          AlchemistConfig(forceUpdateGoldenFiles: true).merge(null),
          equals(AlchemistConfig(forceUpdateGoldenFiles: true)),
        );
      });

      test('does nothing if provided config is untouched', () {
        expect(
          AlchemistConfig(forceUpdateGoldenFiles: true)
              .merge(AlchemistConfig()),
          equals(AlchemistConfig(forceUpdateGoldenFiles: true)),
        );
      });

      test('merges top-level (shallow) fields', () {
        expect(
          AlchemistConfig(
            forceUpdateGoldenFiles: true,
          ).merge(
            AlchemistConfig(
              forceUpdateGoldenFiles: false,
            ),
          ),
          equals(AlchemistConfig(forceUpdateGoldenFiles: false)),
        );
      });

      test('merges nested (deep) fields', () {
        final appliedTheme = ThemeData.dark();

        expect(
          AlchemistConfig(
            forceUpdateGoldenFiles: true,
            platformGoldensConfig: PlatformGoldensConfig(),
            ciGoldensConfig: CiGoldensConfig(),
          ).merge(
            AlchemistConfig(
              platformGoldensConfig: PlatformGoldensConfig(
                theme: appliedTheme,
              ),
              ciGoldensConfig: CiGoldensConfig(
                theme: appliedTheme,
              ),
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
      expect(
        PlatformGoldensConfig(),
        PlatformGoldensConfig(),
      );

      expect(
        PlatformGoldensConfig(),
        isNot(
          PlatformGoldensConfig(
            filePathResolver: (_, __) async => 'foo',
          ),
        ),
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
          PlatformGoldensConfig().environmentName,
          nextHostPlatform.operatingSystem,
        );
      });

      tearDownAll(() {
        hostPlatform = currentHostPlatform;
      });
    });

    group('has correct default value', () {
      const defaultValue = PlatformGoldensConfig();

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
          PlatformGoldensConfig().copyWith(),
          equals(PlatformGoldensConfig()),
        );
      });

      test('does not replace fields with null values', () {
        const enabled = false;

        expect(
          PlatformGoldensConfig(enabled: enabled).copyWith(),
          equals(PlatformGoldensConfig(enabled: enabled)),
        );
      });

      test('replaces the given fields', () {
        const enabled = false;

        expect(
          PlatformGoldensConfig().copyWith(enabled: enabled),
          isA<PlatformGoldensConfig>()
              .having((c) => c.enabled, 'enabled', enabled),
        );
      });
    });

    group('merge', () {
      test('does nothing if provided config is null', () {
        expect(
          PlatformGoldensConfig().merge(null),
          equals(PlatformGoldensConfig()),
        );
      });

      test('does nothing if provided config is untouched', () {
        expect(
          PlatformGoldensConfig().merge(PlatformGoldensConfig()),
          equals(PlatformGoldensConfig()),
        );
      });

      test('merges fields', () {
        const appliedEnabled = false;

        expect(
          PlatformGoldensConfig().merge(
            PlatformGoldensConfig(
              enabled: appliedEnabled,
            ),
          ),
          isA<PlatformGoldensConfig>()
              .having((c) => c.enabled, 'enabled', appliedEnabled),
        );
      });
    });
  });

  group('CiGoldensConfig', () {
    test('supports value equality', () {
      expect(
        CiGoldensConfig(),
        CiGoldensConfig(),
      );

      expect(
        CiGoldensConfig(),
        isNot(
          CiGoldensConfig(
            filePathResolver: (_, __) async => 'foo',
          ),
        ),
      );
    });

    group('has correct default value', () {
      const defaultValue = CiGoldensConfig();

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
          CiGoldensConfig().copyWith(),
          equals(CiGoldensConfig()),
        );
      });

      test('does not replace fields with null values', () {
        const enabled = false;

        expect(
          CiGoldensConfig(enabled: enabled).copyWith(),
          equals(CiGoldensConfig(enabled: enabled)),
        );
      });

      test('replaces the given fields', () {
        const enabled = false;

        expect(
          CiGoldensConfig().copyWith(enabled: enabled),
          isA<CiGoldensConfig>().having((c) => c.enabled, 'enabled', enabled),
        );
      });
    });

    group('merge', () {
      test('does nothing if provided config is null', () {
        expect(
          CiGoldensConfig().merge(null),
          equals(CiGoldensConfig()),
        );
      });

      test('does nothing if provided config is untouched', () {
        expect(
          CiGoldensConfig().merge(CiGoldensConfig()),
          equals(CiGoldensConfig()),
        );
      });

      test('merges fields', () {
        const appliedEnabled = false;

        expect(
          CiGoldensConfig().merge(
            CiGoldensConfig(
              enabled: appliedEnabled,
            ),
          ),
          isA<CiGoldensConfig>()
              .having((c) => c.enabled, 'enabled', appliedEnabled),
        );
      });
    });
  });
}
