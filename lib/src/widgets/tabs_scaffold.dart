import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:revelationsai/src/providers/user/preferences.dart';
import 'package:revelationsai/src/utils/build_context_extensions.dart';

class TabsScaffold extends HookConsumerWidget {
  final StatefulNavigationShell navShell;

  const TabsScaffold({super.key, required this.navShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hapticFeedback =
        ref.watch(currentUserPreferencesProvider.select((value) => value.valueOrNull?.hapticFeedback ?? true));

    return Scaffold(
      body: navShell,
      bottomNavigationBar: Theme(
        data: ThemeData(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          enableFeedback: hapticFeedback,
          elevation: 10,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.house_fill),
              label: "Home",
            ),
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.chat_bubble_fill),
              label: "Chat",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.image),
              label: "Images",
            ),
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.book_fill),
              label: "Devos",
            ),
          ],
          backgroundColor: context.theme.bottomNavigationBarTheme.backgroundColor,
          selectedItemColor: context.theme.bottomNavigationBarTheme.selectedItemColor,
          unselectedItemColor: context.theme.bottomNavigationBarTheme.unselectedItemColor,
          currentIndex: navShell.currentIndex,
          onTap: (index) {
            if (hapticFeedback) {
              HapticFeedback.lightImpact();
            }
            _goBranch(index);
          },
        ),
      ),
    );
  }

  void _goBranch(int index) {
    navShell.goBranch(
      index,
      initialLocation: index == navShell.currentIndex,
    );
  }
}
