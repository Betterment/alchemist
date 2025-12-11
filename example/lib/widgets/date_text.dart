import 'package:clock/clock.dart';
import 'package:flutter/material.dart';

class DateText extends StatelessWidget {
  const DateText({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      clock.now().toIso8601String(),
      textAlign: TextAlign.center,
    );
  }
}
