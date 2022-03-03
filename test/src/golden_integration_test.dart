import 'dart:async';
import 'dart:typed_data';

import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class MemoryFileSystemComparator extends LocalFileComparator {
  MemoryFileSystemComparator(Uri testFile) : super(testFile);

  final Map<Uri, Uint8List> files = <Uri, Uint8List>{};

  @override
  Future<void> update(Uri golden, Uint8List imageBytes) async {
    files[golden] = imageBytes;
  }

  @override
  Future<List<int>> getGoldenBytes(Uri golden) async {
    return Future.value(files[golden]);
  }
}

Future<void> goldenIntegrationTest() async {
  await goldenTest(
    'Golden Integration Test',
    fileName: 'golden_integration_test',
    widget: const Text('Hello, Alchemist!'),
  );
}

Future<void> main() async {
  final originalGoldenFileComparator = goldenFileComparator;

  try {
    goldenFileComparator = MemoryFileSystemComparator(
      Uri.parse('file://golden_integration_test.png'),
    );

    final config = AlchemistConfig(
      forceUpdateGoldenFiles: true,
      platformGoldensConfig: PlatformGoldensConfig(
        platforms: {HostPlatform.linux},
        filePathResolver: (fileName, environmentName) => fileName,
      ),
    );

    // Create a golden file in memory.
    await AlchemistConfig.runWithConfig(
      config: config,
      run: goldenIntegrationTest,
    );

    // Compare to golden file in memory.
    await AlchemistConfig.runWithConfig(
      config: config.copyWith(forceUpdateGoldenFiles: false),
      run: goldenIntegrationTest,
    );
  } catch (e) {
    fail('Golden integration test failed: $e');
  } finally {
    // goldenFileComparator = originalGoldenFileComparator;
  }
}
