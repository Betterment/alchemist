import 'dart:ui' as ui;

import 'package:alchemist/src/alchemist_file_comparator.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

class _TestAlchemistFileComparator extends AlchemistFileComparator {
  _TestAlchemistFileComparator({
    required double diffThreshold,
    required ComparisonResult result,
    String? environmentName,
  }) : _result = result,
       super(
         Uri.parse('file:///test/_alchemist.dart'),
         diffThreshold,
         environmentName: environmentName,
       );

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
      test('accepts optional environmentName', () {
        final comparator = AlchemistFileComparator(
          Uri.parse('file:///test/_alchemist.dart'),
          0,
          environmentName: 'macOS',
        );
        expect(comparator.environmentName, 'macOS');
      });

      test('defaults environmentName to null', () {
        final comparator = AlchemistFileComparator(
          Uri.parse('file:///test/_alchemist.dart'),
          0,
        );
        expect(comparator.environmentName, isNull);
      });

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

      test('forwards environmentName from existing comparator', () {
        final existing = LocalFileComparator(
          Uri.parse('file:///some/path/test.dart'),
        );
        final comparator = AlchemistFileComparator.fromExisting(
          existing,
          0.001,
          environmentName: 'macOS',
        );
        expect(comparator.environmentName, 'macOS');
      });
    });

    group('compareImageBytes', () {
      test('returns passed result when images are identical', () async {
        final comparator = AlchemistFileComparator(
          Uri.parse('file:///test/_alchemist.dart'),
          0,
        );

        final recorder = ui.PictureRecorder();
        ui.Canvas(
          recorder,
        ).drawColor(const ui.Color(0xFFFFFFFF), ui.BlendMode.src);
        final picture = recorder.endRecording();
        final image = await picture.toImage(1, 1);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        final pngBytes = byteData!.buffer.asUint8List();

        final result = await comparator.compareImageBytes(pngBytes, pngBytes);
        expect(result.passed, isTrue);
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

        await expectLater(
          comparator.compare(Uint8List(0), Uri.parse('golden.png')),
          throwsA(isA<FlutterError>()),
        );
      });

      test('fails when diffThreshold is 0 and diff > 0', () async {
        final comparator = _TestAlchemistFileComparator(
          diffThreshold: 0,
          result: ComparisonResult(passed: false, diffPercent: 0.001),
        );

        await expectLater(
          comparator.compare(Uint8List(0), Uri.parse('golden.png')),
          throwsA(isA<FlutterError>()),
        );
      });
    });

    group('getFailureFile', () {
      test(
        'when environmentName is null, returns default flat failures path',
        () {
          final comparator = AlchemistFileComparator(
            Uri.parse('file:///test/_alchemist.dart'),
            0,
          );
          final golden = Uri.parse('goldens/macos/test.png');
          final basedir = Uri.parse('file:///project/test');

          final file = comparator.getFailureFile(
            'masterImage',
            golden,
            basedir,
          );

          expect(file.path, contains('failures/test_masterImage.png'));
        },
      );

      test('when environmentName is set, writes to failures/{env}/', () {
        final comparator = AlchemistFileComparator(
          Uri.parse('file:///test/_alchemist.dart'),
          0,
          environmentName: 'macOS',
        );
        final golden = Uri.parse('goldens/macos/test.png');
        final basedir = Uri.parse('file:///project/test');

        final file = comparator.getFailureFile('masterImage', golden, basedir);

        expect(file.path, contains('failures/macos/test_masterImage.png'));
      });

      test('when environmentName is CI, writes to failures/ci/', () {
        final comparator = AlchemistFileComparator(
          Uri.parse('file:///test/_alchemist.dart'),
          0,
          environmentName: 'CI',
        );
        final golden = Uri.parse('goldens/ci/test.png');
        final basedir = Uri.parse('file:///project/test');

        final file = comparator.getFailureFile('masterImage', golden, basedir);

        expect(file.path, contains('failures/ci/test_masterImage.png'));
      });
    });
  });
}
