import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Logo(
              colorScheme: context.brightness == Brightness.light ? RAIColorScheme.dark : RAIColorScheme.light,
              width: context.width * 0.75,
            ),
            const SizedBox(height: 20),
            SpinKitSpinningLines(
              color: context.secondaryColor,
              size: 40.0,
            )
          ],
        ),
      ),
    );
  }
}
