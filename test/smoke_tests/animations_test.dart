import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('smoke test', () {
    goldenTestAnimation(
      'circular animation',
      fileName: 'animation_circular',
      timeout: const Duration(seconds: 15),
      builder: () => const CircularProgressIndicator(),
    );

    goldenTestAnimation(
      'linear animation',
      fileName: 'animation_linear',
      builder: () => const LinearProgressIndicator(),
    );

    goldenTestAnimation(
      'tween animation',
      fileName: 'animation_tween',
      timeout: const Duration(seconds: 2),
      builder: () => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(seconds: 2),
        builder: (context, value, child) => Container(
          decoration: BoxDecoration(
            color: Color.lerp(Colors.red, Colors.blue, value),
            borderRadius: BorderRadius.lerp(
              null,
              BorderRadius.circular(20),
              value,
            ),
          ),
          child: child,
        ),
        child: const FlutterLogo(),
      ),
    );

    goldenTestAnimation(
      'text animation',
      fileName: 'animation_text',
      timeout: const Duration(seconds: 2),
      builder: () => TweenAnimationBuilder<TextStyle>(
        tween: TextStyleTween(
          begin: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w100,
            color: Colors.red,
            fontFamily: 'Roboto',
          ),
          end: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Colors.blue,
            fontFamily: 'Roboto',
          ),
        ),
        duration: const Duration(seconds: 2),
        builder: (context, value, _) => DefaultTextStyle(
          style: value,
          child: const Text('text'),
        ),
      ),
    );
  });
}
