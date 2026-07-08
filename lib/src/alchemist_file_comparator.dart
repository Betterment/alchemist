import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// A [LocalFileComparator] that passes golden tests within a configurable
/// pixel-diff diffThreshold and writes failure artifacts to
/// environment-scoped directories.
///
/// When [diffThreshold] is greater than 0 and the diff percentage is within
/// diffThreshold, the test passes. This is useful for handling minor
/// cross-platform or cross-architecture rendering differences.
///
/// When [environmentName] is provided, failure images are written to
/// `failures/<environmentName>/` instead of the flat `failures/` directory.
/// This prevents collisions when `goldenTest` runs multiple variants (e.g.
/// platform and CI) in the same test process.
class AlchemistFileComparator extends LocalFileComparator {
  /// Creates an [AlchemistFileComparator] with the given [testUri],
  /// [diffThreshold], and optional [environmentName].
  ///
  /// The [diffThreshold] must be between 0.0 (inclusive) and 1.0 (exclusive).
  AlchemistFileComparator(
    super.testUri,
    this.diffThreshold, {
    this.environmentName,
  }) : assert(
         diffThreshold >= 0.0 && diffThreshold < 1.0,
         'diffThreshold must be between 0.0 (inclusive) and 1.0 (exclusive)',
       );

  /// Creates an [AlchemistFileComparator] from an [existing]
  /// [LocalFileComparator], preserving its base directory.
  factory AlchemistFileComparator.fromExisting(
    LocalFileComparator existing,
    double diffThreshold, {
    String? environmentName,
  }) {
    return AlchemistFileComparator(
      existing.basedir.resolve('_alchemist.dart'),
      diffThreshold,
      environmentName: environmentName,
    );
  }

  /// The maximum fraction of differing pixels that is still considered a
  /// passing test.
  ///
  /// Must be between 0.0 (inclusive) and 1.0 (exclusive). When the diff
  /// percentage exceeds 0 but is within this threshold, the test passes.
  /// A value of 0.0 means no threshold is applied.
  final double diffThreshold;

  /// The name of the environment (e.g. `"macOS"`, `"CI"`) for
  /// environment-scoped failure artifacts. When `null`, failure files are
  /// written to the default flat `failures/` directory.
  final String? environmentName;

  /// Compares the given [imageBytes] to the [goldenBytes] and returns the
  /// [ComparisonResult].
  ///
  /// Exposed for testing. In production, [compare] calls this method
  /// internally.
  @protected
  @visibleForTesting
  Future<ComparisonResult> compareImageBytes(
    Uint8List imageBytes,
    Uint8List goldenBytes,
  ) {
    return GoldenFileComparator.compareLists(imageBytes, goldenBytes);
  }

  /// Compares [imageBytes] to the golden file identified by [golden].
  ///
  /// Returns `true` if the images match, or if the diff percentage is within
  /// [diffThreshold]. Throws [FlutterError] with a detailed failure message
  /// and writes environment-scoped failure images otherwise.
  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final goldenBytes = await getGoldenBytes(golden);
    final result = await compareImageBytes(
      imageBytes,
      Uint8List.fromList(goldenBytes),
    );

    if (result.passed) {
      result.dispose();
      return true;
    }

    if (diffThreshold > 0 && result.diffPercent <= diffThreshold) {
      result.dispose();
      return true;
    }

    final error = await generateFailureOutput(result, golden, basedir);
    result.dispose();
    throw FlutterError(error);
  }

  @override
  File getFailureFile(String failure, Uri golden, Uri basedir) {
    final file = super.getFailureFile(failure, golden, basedir);
    final env = environmentName?.toLowerCase();
    if (env == null || env.isEmpty) return file;
    final parent = file.parent;
    final name = file.path.substring(parent.path.length + 1);
    return File('${parent.path}/$env/$name');
  }
}
