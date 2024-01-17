import 'package:flutter/material.dart';

final class RAIVisualDensity {
  static const VisualDensity tightest = VisualDensity(
    horizontal: VisualDensity.minimumDensity,
    vertical: VisualDensity.minimumDensity,
  );

  static const VisualDensity loosest = VisualDensity(
    horizontal: VisualDensity.maximumDensity,
    vertical: VisualDensity.maximumDensity,
  );
}
