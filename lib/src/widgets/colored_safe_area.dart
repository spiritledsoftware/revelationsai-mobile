import 'package:flutter/material.dart';
import 'package:revelationsai/src/utils/build_context_extensions.dart';

class ColoredSafeArea extends StatelessWidget {
  final Widget child;
  final Color? color;

  const ColoredSafeArea({
    super.key,
    required this.child,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color ?? context.appBarTheme.backgroundColor,
      child: SafeArea(
        child: Container(
          color: context.colorScheme.background,
          child: child,
        ),
      ),
    );
  }
}
