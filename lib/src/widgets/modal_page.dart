import 'package:flutter/material.dart';

class ModalPage<T> extends Page<T> {
  final WidgetBuilder builder;
  final double elevation;

  const ModalPage({
    super.key,
    super.name,
    super.arguments,
    required this.builder,
    this.elevation = 10,
  });

  @override
  Route<T> createRoute(BuildContext context) {
    return ModalBottomSheetRoute(
      enableDrag: true,
      isScrollControlled: true,
      settings: this,
      elevation: elevation,
      builder: builder,
    );
  }
}
