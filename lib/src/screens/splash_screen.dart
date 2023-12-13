import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:revelationsai/src/constants/colors.dart';
import 'package:revelationsai/src/utils/build_context_extensions.dart';
import 'package:revelationsai/src/widgets/branding/logo.dart';

class SplashScreen extends HookConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: context.colorScheme.background,
      body: Center(
        child: Logo(
          colorScheme: context.brightness == Brightness.light ? RAIColorScheme.dark : RAIColorScheme.light,
        ),
      ),
    );
  }
}
