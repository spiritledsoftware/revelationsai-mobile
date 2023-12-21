import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

extension ThemeBuildContextExtension on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colorScheme => theme.colorScheme;
  Brightness get brightness => theme.brightness;
  TextTheme get textTheme => theme.textTheme;
  AppBarTheme get appBarTheme => theme.appBarTheme;
  Color get scaffoldBackgroundColor => theme.scaffoldBackgroundColor;
  Color get primaryColor => theme.colorScheme.primary;
  Color get secondaryColor => theme.colorScheme.secondary;

  bool get isDarkMode => brightness == Brightness.dark;
  bool get isLightMode => brightness == Brightness.light;
}

extension MediaBuildContextExtension on BuildContext {
  MediaQueryData get mediaQuery => MediaQuery.of(this);
  Size get screenSize => mediaQuery.size;
  double get width => screenSize.width;
  double get height => screenSize.height;

  bool get isTablet => width >= 600;

  bool get isPortrait => mediaQuery.orientation == Orientation.portrait;
  bool get isLandscape => mediaQuery.orientation == Orientation.landscape;
}

extension GoRouterContextX on BuildContext {
  GoRouterState get goRouterState => GoRouterState.of(this);
  GoRouteInformationProvider get goRouteInformationProvider => GoRouter.of(this).routeInformationProvider;
  Uri get uri => goRouteInformationProvider.value.uri;
  String get path => uri.path;
  String get query => uri.query;
  String get fragment => uri.fragment;
  Map<String, String> get queryParameters => uri.queryParameters;
}
