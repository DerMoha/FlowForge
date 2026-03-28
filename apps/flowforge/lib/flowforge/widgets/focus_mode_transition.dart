import 'package:flutter/material.dart';

class FocusModeTransition extends StatelessWidget {
  const FocusModeTransition({
    super.key,
    required this.isFocusMode,
    required this.child,
  });

  final bool isFocusMode;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      alignment: Alignment.topCenter,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 400),
        opacity: isFocusMode ? 0.0 : 1.0,
        child: isFocusMode ? const SizedBox.shrink() : child,
      ),
    );
  }
}
