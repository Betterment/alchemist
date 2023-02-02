import 'dart:typed_data';

import 'package:alchemist/alchemist.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;
import 'package:universal_io/io.dart';

/// {@template alchemist_file_comparator}
/// A golden testing file comparator that allows for more flexible image
/// comparisons
///
/// This is based on the [LocalFileComparator] from the Flutter test framework,
/// and is used by Alchemist to allow for image comparison with a tolerance
/// value (i.e., a margin of error that is allowed when comparing images).
/// {@endtemplate}
class AlchemistFileComparator extends GoldenFileComparator
    with LocalComparisonOutput {
  /// {@macro alchemist_file_comparator}
  AlchemistFileComparator({
    required this.basedir,
    required this.tolerance,
    p.Style? pathStyle,
  }) : path = p.Context(style: pathStyle ?? p.Style.platform);

  /// Builds a [AlchemistFileComparator] based on a [LocalFileComparator].
  ///
  /// {@macro alchemist_file_comparator}
  factory AlchemistFileComparator.fromLocalFileComparator(
    LocalFileComparator localFileComparator, {
    required double tolerance,
  }) {
    return AlchemistFileComparator(
      basedir: localFileComparator.basedir,
      tolerance: tolerance,
      pathStyle: p.Style.platform,
    );
  }

  /// The directory in which the test was loaded.
  ///
  /// Golden file keys will be interpreted as file paths relative to this
  /// directory.
  @internal
  final Uri basedir;

  /// The tolerance to use when comparing images.
  ///
  /// When set to `0.0`, images must match exactly. When set to `1.0`, images
  /// may be completely different and still match.
  ///
  /// This is set to `0.0` by Alchemist by default.
  @internal
  final double tolerance;

  /// Path context exists as an instance variable rather than just using the
  /// system path context in order to support testing, where we can spoof the
  /// platform to test behaviors with arbitrary path styles.
  ///
  /// Only exposed for testing purposes.
  @internal
  @visibleForTesting
  final p.Context path;

  File _getGoldenFile(Uri golden) {
    return File(path.join(path.fromUri(basedir), path.fromUri(golden.path)));
  }

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final result = await GoldenFileComparator.compareLists(
      imageBytes,
      await getGoldenBytes(golden),
    );

    final didPass = result.passed || result.diffPercent <= tolerance;
    if (!didPass) {
      final error = '''
${await generateFailureOutput(result, golden, basedir)}

Tip: Alchemist's tolerance is set to $tolerance (${(tolerance * 100).toStringAsFixed(2)}%).

Use the tolerance property on the $PlatformGoldensConfig and $CiGoldensConfig classes to adjust this.''';

      throw FlutterError(error);
    }

    return true;
  }

  @override
  Future<void> update(Uri golden, Uint8List imageBytes) async {
    final goldenFile = _getGoldenFile(golden);
    await goldenFile.parent.create(recursive: true);
    await goldenFile.writeAsBytes(imageBytes, flush: true);
  }

  /// Returns the bytes of the given [golden] file.
  ///
  /// If the file cannot be found, an error will be thrown.
  @protected
  Future<List<int>> getGoldenBytes(Uri golden) async {
    final goldenFile = _getGoldenFile(golden);
    if (!goldenFile.existsSync()) {
      fail(
        'Could not be compared against non-existent file: "$golden"',
      );
    }
    final List<int> goldenBytes = await goldenFile.readAsBytes();
    return goldenBytes;
  }
}
