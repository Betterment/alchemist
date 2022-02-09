// ignore_for_file: avoid_slow_async_io

import 'dart:async';
import 'dart:io';

import 'package:alchemist/alchemist.dart';
import 'package:alchemist/src/utilities.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

extension on File {
  /// Regularly checks if this file exists and returns `true` if it does.
  ///
  /// If, after the [timeout] has passed, this file still does not exist,
  /// this method will return `false`.
  Future<bool> waitUntilExists({
    Duration timeout = const Duration(seconds: 1),
  }) async {
    final stopwatch = Stopwatch()..start();
    while (stopwatch.elapsed < timeout) {
      if (existsSync()) {
        return true;
      }
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    return existsSync();
  }

  /// Deletes this file if it exists.
  void deleteIfExists() {
    if (existsSync()) {
      deleteSync();
    }
  }
}

void main() {
  group('goldenTest function', () {
    const rootKey = Key('root');

    final testFileDirectory = '${Directory.current.absolute.path}/test';

    const goldenTestFileName = 'golden_test_example';

    const platformMasterReferenceFileName =
        '${goldenTestFileName}_platform_master_reference';
    const ciMasterReferenceFileName =
        '${goldenTestFileName}_ci_master_reference';

    final platformMasterReferenceFilePath =
        '$testFileDirectory/$platformMasterReferenceFileName.png';
    final ciMasterReferenceFilePath =
        '$testFileDirectory/$ciMasterReferenceFileName.png';
    final expectedPlatformGeneratedFilePath =
        '$testFileDirectory/goldens/${HostPlatform.current().operatingSystem}/$goldenTestFileName.png';
    final expectedCiGeneratedFilePath =
        '$testFileDirectory/goldens/ci/$goldenTestFileName.png';

    final platformMasterReferenceFile = File(platformMasterReferenceFilePath);
    final ciMasterReferenceFile = File(ciMasterReferenceFilePath);
    final expectedPlatformGeneratedFile =
        File(expectedPlatformGeneratedFilePath);
    final expectedCiGeneratedFile = File(expectedCiGeneratedFilePath);

    setUpAll(() async {
      debugSkipGoldenTestSetup = true;
      await loadFontsForTesting();
    });

    tearDownAll(() {
      debugSkipGoldenTestSetup = false;
    });

    tearDown(() {
      expectedPlatformGeneratedFile.deleteIfExists();
      expectedCiGeneratedFile.deleteIfExists();
    });

    GoldenTestGroup buildGroup() {
      return GoldenTestGroup(
        children: [
          GoldenTestScenario(
            name: 'scenario 1',
            child: const SizedBox(
              height: 100,
              width: 100,
              child: Placeholder(),
            ),
          ),
          GoldenTestScenario(
            name: 'scenario 2',
            child: const SizedBox(
              height: 200,
              width: 200,
              child: Placeholder(),
            ),
          ),
        ],
      );
    }

    Future<T> withUpdateGoldenFilesEnabled<T>(FutureOr<T> Function() fn) async {
      final originalValue = autoUpdateGoldenFiles;
      autoUpdateGoldenFiles = true;
      try {
        return await fn();
      } finally {
        autoUpdateGoldenFiles = originalValue;
      }
    }

    Future<void> ensureMasterReferencesExist(
      WidgetTester tester, {
      bool force = false,
    }) async {
      if (!force) {
        final platformFileExists = platformMasterReferenceFile.existsSync();
        final ciFileExists = ciMasterReferenceFile.existsSync();

        final allFilesExist = platformFileExists && ciFileExists;
        if (allFilesExist) {
          return;
        }
      }

      final theme = ThemeData.light();

      await tester.pumpGoldenTest(
        rootKey: rootKey,
        textScaleFactor: 1,
        constraints: const BoxConstraints(),
        theme: theme,
        widget: buildGroup(),
      );

      await withUpdateGoldenFilesEnabled(() async {
        try {
          await expectLater(
            find.byKey(rootKey),
            matchesGoldenFile(platformMasterReferenceFilePath),
          );
        } catch (e) {
          fail('Failed to generate platform master reference file.\n$e');
        }
      });

      await tester.cleanPump();

      await tester.pumpGoldenTest(
        rootKey: rootKey,
        textScaleFactor: 1,
        constraints: const BoxConstraints(),
        theme: theme.copyWith(
          textTheme: theme.textTheme.apply(
            fontFamily: 'Ahem',
          ),
        ),
        widget: buildGroup(),
      );

      await withUpdateGoldenFilesEnabled(() async {
        try {
          await expectLater(
            tester.getBlockedTextImage(find.byKey(rootKey)),
            matchesGoldenFile(ciMasterReferenceFilePath),
          );
        } catch (e) {
          fail('Failed to generate CI master reference file.\n$e');
        }
      });
    }

    testWidgets(
      '[generate golden test master reference files]',
      (tester) async {
        await ensureMasterReferencesExist(tester, force: true);
      },
    );

    testWidgets(
      'generates ci file properly '
      'when update golden files flag is set',
      (tester) async {
        await ensureMasterReferencesExist(tester);

        final masterReferenceFile = ciMasterReferenceFile;
        final generatedFile = expectedCiGeneratedFile..deleteIfExists();

        await withUpdateGoldenFilesEnabled(() async {
          await runGoldenTest(
            tester: tester,
            config: AlchemistConfig.current(),
            fileName: goldenTestFileName,
            widget: buildGroup(),
          );
        });

        await expectLater(
          tester.runAsync(generatedFile.waitUntilExists),
          completion(isTrue),
        );

        expect(
          generatedFile.readAsBytesSync(),
          equals(masterReferenceFile.readAsBytesSync()),
        );
      },
    );

    testWidgets('fails when single test fails', (tester) async {
      // Delete reference file.
      expectedCiGeneratedFile.deleteIfExists();

      Object? error;

      // Should fail.
      try {
        await runGoldenTest(
          tester: tester,
          config: AlchemistConfig(
            ciGoldensConfig: CiGoldensConfig(
              enabled: true,
              comparePredicate: (_) => true,
            ),
            platformGoldensConfig: const PlatformGoldensConfig(enabled: false),
          ),
          fileName: goldenTestFileName,
          widget: buildGroup(),
        );
        fail('Expected test to fail.');
      } catch (e) {
        error = e;
      }

      expect(
        error,
        isA<TestFailure>().having(
          (e) => e.message,
          'message',
          contains('Could not be compared against non-existent file'),
        ),
      );

      expectedCiGeneratedFile.deleteIfExists();
    });

    testWidgets(
      'fails and combines all messages when multiple tests fail',
      (tester) async {
        // Delete reference files.
        expectedCiGeneratedFile.deleteIfExists();
        expectedPlatformGeneratedFile.deleteIfExists();

        Object? error;

        // Should fail.
        try {
          await runGoldenTest(
            tester: tester,
            config: AlchemistConfig(
              ciGoldensConfig: CiGoldensConfig(
                enabled: true,
                comparePredicate: (_) => true,
              ),
              platformGoldensConfig: PlatformGoldensConfig(
                enabled: true,
                comparePredicate: (_) => true,
              ),
            ),
            fileName: goldenTestFileName,
            widget: buildGroup(),
          );
          fail('Expected test to fail.');
        } catch (e) {
          error = e;
        }

        expect(
          error,
          isA<TestFailure>().having((e) => e.message, 'message', isNotNull),
        );

        final message = (error as TestFailure).message!;
        expect(
          message,
          contains(
            'Multiple test failures occurred while running golden tests.',
          ),
        );

        final lines = message.split('\n');
        final errorDetailLines = lines.where(
          (l) => l.contains('Could not be compared against non-existent file'),
        );
        expect(
          errorDetailLines,
          hasLength(2),
        );
      },
    );

    testWidgets('uses config provided by current zone', (tester) async {
      var ciComparisonPredicateCallCount = 0;

      await AlchemistConfig.runWithConfig(
        config: AlchemistConfig(
          ciGoldensConfig: CiGoldensConfig(
            comparePredicate: (_) {
              ciComparisonPredicateCallCount++;
              return false;
            },
          ),
        ),
        run: () => withUpdateGoldenFilesEnabled(() async {
          await runGoldenTest(
            tester: tester,
            config: AlchemistConfig.current(),
            fileName: goldenTestFileName,
            widget: buildGroup(),
          );
        }),
      );

      expectedCiGeneratedFile.deleteIfExists();

      expect(ciComparisonPredicateCallCount, equals(1));
    });

    testWidgets(
      'regenerates golden files '
      'when config force update flag is set',
      (tester) async {
        expectedCiGeneratedFile.deleteIfExists();
        expectedPlatformGeneratedFile.deleteIfExists();

        await AlchemistConfig.runWithConfig(
          config: const AlchemistConfig(
            forceUpdateGoldenFiles: true,
            ciGoldensConfig: CiGoldensConfig(enabled: true),
            platformGoldensConfig: PlatformGoldensConfig(enabled: true),
          ),
          run: () => runGoldenTest(
            tester: tester,
            config: AlchemistConfig.current(),
            fileName: goldenTestFileName,
            widget: buildGroup(),
          ),
        );

        await expectLater(
          tester.runAsync(expectedCiGeneratedFile.waitUntilExists),
          completion(isTrue),
        );

        await expectLater(
          tester.runAsync(expectedPlatformGeneratedFile.waitUntilExists),
          completion(isTrue),
        );
      },
    );

    testWidgets('uses theme defined in config', (tester) async {
      const expectedPrimaryColor = Colors.purple;

      final theme = ThemeData.light().copyWith(
        primaryColor: expectedPrimaryColor,
      );

      Object? providedPrimaryColor;

      await AlchemistConfig.runWithConfig(
        config: AlchemistConfig(
          theme: theme,
        ),
        run: () => withUpdateGoldenFilesEnabled(() async {
          await runGoldenTest(
            tester: tester,
            config: AlchemistConfig.current(),
            fileName: goldenTestFileName,
            widget: GoldenTestGroup(
              children: [
                GoldenTestScenario.builder(
                  name: 'scenario',
                  builder: (context) {
                    providedPrimaryColor = Theme.of(context).primaryColor;
                    return const Text('text');
                  },
                ),
              ],
            ),
          );
        }),
      );

      expectedCiGeneratedFile.deleteIfExists();

      expect(providedPrimaryColor, equals(expectedPrimaryColor));
    });

    group('with custom platform config', () {
      testWidgets(
        'creates platform golden file '
        'when config indicates it should be created',
        (tester) async {
          final generatedFile = expectedPlatformGeneratedFile..deleteIfExists();

          await AlchemistConfig.runWithConfig(
            config: const AlchemistConfig(
              ciGoldensConfig: CiGoldensConfig(enabled: false),
              platformGoldensConfig: PlatformGoldensConfig(enabled: true),
            ),
            run: () => withUpdateGoldenFilesEnabled(() async {
              await runGoldenTest(
                tester: tester,
                config: AlchemistConfig.current(),
                fileName: goldenTestFileName,
                widget: buildGroup(),
              );
            }),
          );

          await expectLater(
            tester.runAsync(generatedFile.waitUntilExists),
            completion(isTrue),
          );
        },
      );

      testWidgets(
        'does not create platform golden file '
        'when config indicates it should not be created',
        (tester) async {
          final generatedFile = expectedPlatformGeneratedFile..deleteIfExists();

          await AlchemistConfig.runWithConfig(
            config: const AlchemistConfig(
              ciGoldensConfig: CiGoldensConfig(enabled: false),
              platformGoldensConfig: PlatformGoldensConfig(enabled: false),
            ),
            run: () => withUpdateGoldenFilesEnabled(() async {
              await runGoldenTest(
                tester: tester,
                config: AlchemistConfig.current(),
                fileName: goldenTestFileName,
                widget: buildGroup(),
              );
            }),
          );

          await expectLater(
            tester.runAsync(generatedFile.waitUntilExists),
            completion(isFalse),
          );
        },
      );

      testWidgets(
        'compares platform golden file '
        'when config indicates it should be compared',
        (tester) async {
          await AlchemistConfig.runWithConfig(
            config: AlchemistConfig(
              ciGoldensConfig: const CiGoldensConfig(enabled: false),
              platformGoldensConfig: PlatformGoldensConfig(
                enabled: true,
                comparePredicate: (_) => true,
              ),
            ),
            run: () => withUpdateGoldenFilesEnabled(() async {
              await runGoldenTest(
                tester: tester,
                config: AlchemistConfig.current(),
                fileName: goldenTestFileName,
                widget: buildGroup(),
              );
            }),
          );
        },
      );

      testWidgets('uses platform file path resolver ', (tester) async {
        const generatedFilePath = 'goldens/custom_platform_golden_file.png';
        final generatedFile = File('$testFileDirectory/$generatedFilePath')
          ..deleteIfExists();
        addTearDown(generatedFile.deleteIfExists);

        await AlchemistConfig.runWithConfig(
          config: AlchemistConfig(
            ciGoldensConfig: const CiGoldensConfig(enabled: false),
            platformGoldensConfig: PlatformGoldensConfig(
              enabled: true,
              filePathResolver: (_) => generatedFilePath,
            ),
          ),
          run: () => withUpdateGoldenFilesEnabled(() async {
            await runGoldenTest(
              tester: tester,
              config: AlchemistConfig.current(),
              fileName: goldenTestFileName,
              widget: buildGroup(),
            );
          }),
        );

        await expectLater(
          tester.runAsync(generatedFile.waitUntilExists),
          completion(isTrue),
        );
      });
    });

    group('with custom ci config', () {
      testWidgets(
        'creates ci golden file '
        'when config indicates it should be created',
        (tester) async {
          final generatedFile = expectedCiGeneratedFile..deleteIfExists();

          await AlchemistConfig.runWithConfig(
            config: const AlchemistConfig(
              platformGoldensConfig: PlatformGoldensConfig(enabled: false),
              ciGoldensConfig: CiGoldensConfig(enabled: true),
            ),
            run: () => withUpdateGoldenFilesEnabled(() async {
              await runGoldenTest(
                tester: tester,
                config: AlchemistConfig.current(),
                fileName: goldenTestFileName,
                widget: buildGroup(),
              );
            }),
          );

          await expectLater(
            tester.runAsync(generatedFile.waitUntilExists),
            completion(isTrue),
          );
        },
      );

      testWidgets(
        'does not create ci golden file '
        'when config indicates it should not be created',
        (tester) async {
          final generatedFile = expectedCiGeneratedFile..deleteIfExists();

          await AlchemistConfig.runWithConfig(
            config: const AlchemistConfig(
              platformGoldensConfig: PlatformGoldensConfig(enabled: false),
              ciGoldensConfig: CiGoldensConfig(enabled: false),
            ),
            run: () => withUpdateGoldenFilesEnabled(() async {
              await runGoldenTest(
                tester: tester,
                config: AlchemistConfig.current(),
                fileName: goldenTestFileName,
                widget: buildGroup(),
              );
            }),
          );

          await expectLater(
            tester.runAsync(generatedFile.waitUntilExists),
            completion(isFalse),
          );
        },
      );

      testWidgets('uses ci file path resolver ', (tester) async {
        const generatedFilePath = 'goldens/ci/custom_ci_golden_file.png';
        final generatedFile = File('$testFileDirectory/$generatedFilePath')
          ..deleteIfExists();
        addTearDown(generatedFile.deleteIfExists);

        await AlchemistConfig.runWithConfig(
          config: AlchemistConfig(
            platformGoldensConfig: const PlatformGoldensConfig(enabled: false),
            ciGoldensConfig: CiGoldensConfig(
              enabled: true,
              filePathResolver: (_) => generatedFilePath,
            ),
          ),
          run: () => withUpdateGoldenFilesEnabled(() async {
            await runGoldenTest(
              tester: tester,
              config: AlchemistConfig.current(),
              fileName: goldenTestFileName,
              widget: buildGroup(),
            );
          }),
        );

        await expectLater(
          tester.runAsync(generatedFile.waitUntilExists),
          completion(isTrue),
        );
      });
    });

    group('smoke test', () {
      late bool initialDebugSkipGoldenTestSetup;

      setUpAll(() {
        initialDebugSkipGoldenTestSetup = debugSkipGoldenTestSetup;
        debugSkipGoldenTestSetup = false;
      });

      tearDownAll(() {
        debugSkipGoldenTestSetup = initialDebugSkipGoldenTestSetup;
      });

      GoldenTestGroup buildSmokeTestGroup() {
        return GoldenTestGroup(
          children: [
            GoldenTestScenario(
              name: 'scenario_text',
              child: const Text('text'),
            ),
            GoldenTestScenario(
              name: 'scenario_button',
              child: ElevatedButton(
                onPressed: () {},
                child: const Text('button'),
              ),
            ),
          ],
        );
      }

      goldenTest(
        'succeeds in regular state',
        fileName: 'smoke_test_regular',
        widget: buildSmokeTestGroup(),
      );

      goldenTest(
        'succeeds while pressed',
        fileName: 'smoke_test_pressed',
        whilePressing: find.byType(ElevatedButton),
        widget: buildSmokeTestGroup(),
      );
    });
  });
}
