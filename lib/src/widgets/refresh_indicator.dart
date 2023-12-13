import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:revelationsai/src/providers/user/preferences.dart';
import 'package:revelationsai/src/utils/build_context_extensions.dart';

class RAIRefreshIndicator extends ConsumerWidget {
  final Widget child;
  final Future<void> Function() onRefresh;

  const RAIRefreshIndicator({super.key, required this.child, required this.onRefresh});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hapticFeedback =
        ref.watch(currentUserPreferencesProvider.select((value) => value.value?.hapticFeedback ?? true));

    return RefreshIndicator(
      color: context.brightness == Brightness.dark ? context.colorScheme.secondary : context.colorScheme.primary,
      backgroundColor:
          context.brightness == Brightness.dark ? context.colorScheme.primary : context.colorScheme.background,
      onRefresh: () {
        if (hapticFeedback) {
          HapticFeedback.lightImpact();
        }
        return onRefresh().then((value) {
          if (hapticFeedback) {
            HapticFeedback.lightImpact();
          }
        });
      },
      child: child,
    );
  }
}
