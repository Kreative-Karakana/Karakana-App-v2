import 'package:flutter/material.dart';

class MinimumTapTarget extends StatelessWidget {
  static const double minimumWidth = 44;
  static const double minimumHeight = 48;

  final VoidCallback onTap;
  final String semanticsLabel;
  final Widget child;

  const MinimumTapTarget({
    super.key,
    required this.onTap,
    required this.semanticsLabel,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticsLabel,
      child: Tooltip(
        message: semanticsLabel,
        excludeFromSemantics: true,
        child: SizedBox(
          width: minimumWidth,
          height: minimumHeight,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}
