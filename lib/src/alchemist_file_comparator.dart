import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// A [LocalFileComparator] that passes golden tests within a configurable
/// pixel-diff diffThreshold.
///
/// When [diffThreshold] is greater than 0 and the diff percentage is within
/// diffThreshold, the test passes and a warning is printed. This is useful for
/// handling minor cross-platform or cross-architecture rendering differences.
class AlchemistFileComparator extends LocalFileComparator {
  /// Creates an [AlchemistFileComparator] with the given [testUri] and
  /// [diffThreshold].
  ///
  /// The [diffThreshold] must be between 0.0 (inclusive) and 1.0 (exclusive).
  AlchemistFileComparator(super.testUri, this.diffThreshold)
    : assert(
        diffThreshold >= 0.0 && diffThreshold < 1.0,
        'diffThreshold must be between 0.0 (inclusive) and 1.0 (exclusive)',
      );

  /// Creates an [AlchemistFileComparator] from an [existing]
  /// [LocalFileComparator], preserving its base directory.
  factory AlchemistFileComparator.fromExisting(
    LocalFileComparator existing,
    double diffThreshold,
  ) {
    return AlchemistFileComparator(existing.basedir, diffThreshold);
  }

  /// The maximum fraction of differing pixels that is still considered a
  /// passing test.
  ///
  /// Must be between 0.0 (inclusive) and 1.0 (exclusive). When the diff
  /// percentage exceeds 0 but is within this threshold, the test passes and a
  /// warning is printed. A value of 0.0 means no threshold is applied.
  final double diffThreshold;

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
  /// [diffThreshold]. Returns `false` and generates failure output otherwise.
  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final goldenBytes = await getGoldenBytes(golden);
    final result = await compareImageBytes(
      imageBytes,
      Uint8List.fromList(goldenBytes),
    );

    if (result.passed) return true;

    if (diffThreshold > 0 && result.diffPercent <= diffThreshold) {
      return true;
    }

    await generateFailureOutput(result, golden, basedir);
    return false;
  }
}
