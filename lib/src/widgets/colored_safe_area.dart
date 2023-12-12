import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:revelationsai/src/utils/build_context_extensions.dart';

class ColoredSafeArea extends StatelessWidget {
  final Widget child;
  final Color? color;
  final bool top;
  final bool bottom;
  final bool left;
  final bool right;
  final EdgeInsets minimum;
  final SystemUiOverlayStyle? overlayStyle;

  const ColoredSafeArea({
    super.key,
    required this.child,
    this.color,
    this.top = true,
    this.bottom = true,
    this.left = true,
    this.right = true,
    this.minimum = EdgeInsets.zero,
    this.overlayStyle,
  });

  @override
  Widget build(BuildContext context) {
    final overlayStyle =
        this.overlayStyle ?? (context.isDarkMode ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Container(
        color: color ?? context.appBarTheme.backgroundColor,
        child: SafeArea(
          top: top,
          bottom: bottom,
          left: left,
          right: right,
          minimum: minimum,
          child: Container(
            color: context.colorScheme.background,
            child: child,
          ),
        ),
      ),
    );
  }
}
