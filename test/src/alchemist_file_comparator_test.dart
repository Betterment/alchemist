import 'dart:typed_data';

import 'package:alchemist/src/alchemist_file_comparator.dart';
import 'package:flutter_test/flutter_test.dart';

class _TestAlchemistFileComparator extends AlchemistFileComparator {
  _TestAlchemistFileComparator({
    required double diffThreshold,
    required ComparisonResult result,
  }) : _result = result,
       super(Uri.parse('file:///test/_alchemist.dart'), diffThreshold);

  final ComparisonResult _result;

  @override
  Future<ComparisonResult> compareImageBytes(
    Uint8List imageBytes,
    Uint8List goldenBytes,
  ) async {
    return _result;
  }

  @override
  Future<Uint8List> getGoldenBytes(Uri golden) async {
    return Uint8List(0);
  }

  @override
  Future<String> generateFailureOutput(
    ComparisonResult result,
    Uri golden,
    Uri basedir, {
    String key = '',
  }) async {
    return '';
  }
}

void main() {
  group('AlchemistFileComparator', () {
    group('constructor', () {
      test('asserts when diffThreshold is negative', () {
        expect(
          () => AlchemistFileComparator(
            Uri.parse('file:///test/_alchemist.dart'),
            -0.1,
          ),
          throwsAssertionError,
        );
      });

      test('asserts when diffThreshold exceeds 1.0', () {
        expect(
          () => AlchemistFileComparator(
            Uri.parse('file:///test/_alchemist.dart'),
            1.1,
          ),
          throwsAssertionError,
        );
      });

      test('asserts when diffThreshold is 1.0', () {
        expect(
          () => AlchemistFileComparator(
            Uri.parse('file:///test/_alchemist.dart'),
            1,
          ),
          throwsAssertionError,
        );
      });

      test('accepts 0.0 as boundary value', () {
        expect(
          () => AlchemistFileComparator(
            Uri.parse('file:///test/_alchemist.dart'),
            0,
          ),
          returnsNormally,
        );
      });
    });

    group('fromExisting', () {
      test('sets basedir and diffThreshold from existing comparator', () {
        final existing = LocalFileComparator(
          Uri.parse('file:///some/path/test.dart'),
        );
        final comparator = AlchemistFileComparator.fromExisting(
          existing,
          0.001,
        );
        expect(comparator.basedir, existing.basedir);
        expect(comparator.diffThreshold, 0.001);
      });
    });

    group('compare', () {
      test('passes when underlying comparison passes', () async {
        final comparator = _TestAlchemistFileComparator(
          diffThreshold: 0,
          result: ComparisonResult(passed: true, diffPercent: 0),
        );

        final result = await comparator.compare(
          Uint8List(0),
          Uri.parse('golden.png'),
        );

        expect(result, isTrue);
      });

      test('passes when diff is within diffThreshold', () async {
        final comparator = _TestAlchemistFileComparator(
          diffThreshold: 0.01,
          result: ComparisonResult(passed: false, diffPercent: 0.005),
        );

        final result = await comparator.compare(
          Uint8List(0),
          Uri.parse('golden.png'),
        );

        expect(result, isTrue);
      });

      test('fails when diff exceeds diffThreshold', () async {
        final comparator = _TestAlchemistFileComparator(
          diffThreshold: 0.001,
          result: ComparisonResult(passed: false, diffPercent: 0.005),
        );

        final result = await comparator.compare(
          Uint8List(0),
          Uri.parse('golden.png'),
        );

        expect(result, isFalse);
      });

      test('fails when diffThreshold is 0 and diff > 0', () async {
        final comparator = _TestAlchemistFileComparator(
          diffThreshold: 0,
          result: ComparisonResult(passed: false, diffPercent: 0.001),
        );

        final result = await comparator.compare(
          Uint8List(0),
          Uri.parse('golden.png'),
        );

        expect(result, isFalse);
      });
    });
  });
}
