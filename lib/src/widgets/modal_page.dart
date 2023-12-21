import 'package:flutter/material.dart';

class ModalPage<T> extends Page<T> {
  final WidgetBuilder builder;
  final double elevation;

  const ModalPage({
    required this.builder,
    this.elevation = 10,
    super.key,
    super.name,
    super.arguments,
  });

  @override
  Route<T> createRoute(BuildContext context) {
    return ModalBottomSheetRoute(
      builder: builder,
      isScrollControlled: true,
      settings: this,
      elevation: elevation,
    );
  }
}
