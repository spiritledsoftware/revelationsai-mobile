import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:revelationsai/src/providers/user/preferences.dart';
import 'package:revelationsai/src/utils/build_context_extensions.dart';

class TabsScaffold extends HookConsumerWidget {
  final Widget child;

  const TabsScaffold({super.key, required this.child});

  int _calculateCurrentIndex(String path) {
    switch (path) {
      case String p when p.startsWith("/home"):
      case String p when p.startsWith("/account"):
      case String p when p.startsWith("/upgrade"):
        return 0;
      case String p when p.startsWith("/chat"):
        return 1;
      case String p when p.startsWith("/images"):
        return 2;
      case String p when p.startsWith("/devotions"):
        return 3;
      default:
        debugPrint("Unknown path: $path");
        return 0;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hapticFeedback =
        ref.watch(currentUserPreferencesProvider.select((value) => value.valueOrNull?.hapticFeedback ?? true));

    return Scaffold(
      body: child,
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
          currentIndex: _calculateCurrentIndex(context.path),
          onTap: (value) {
            switch (value) {
              case 0:
                if (hapticFeedback) HapticFeedback.lightImpact();
                context.go("/home");
                break;
              case 1:
                if (hapticFeedback) HapticFeedback.lightImpact();
                context.go("/chat");
                break;
              case 2:
                if (hapticFeedback) HapticFeedback.lightImpact();
                context.go("/images");
                break;
              case 3:
                if (hapticFeedback) HapticFeedback.lightImpact();
                context.go("/devotions");
                break;
              default:
                if (hapticFeedback) HapticFeedback.lightImpact();
                context.go("/home");
                break;
            }
          },
        ),
      ),
    );
  }
}
