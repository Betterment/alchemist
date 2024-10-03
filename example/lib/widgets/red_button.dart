import 'package:flutter/material.dart';

class RedButton extends StatelessWidget {
  const RedButton({
    super.key,
    required this.onPressed,
    this.icon,
    required this.child,
  });

  final VoidCallback? onPressed;
  final Widget? icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final style = ElevatedButton.styleFrom(
      backgroundColor: Colors.red,
      foregroundColor: Colors.white,
    );
    if (icon != null) {
      return ElevatedButton.icon(
        style: style,
        onPressed: onPressed,
        icon: icon,
        label: child,
      );
    } else {
      return ElevatedButton(
        style: style,
        onPressed: onPressed,
        child: child,
      );
    }
  }
}
