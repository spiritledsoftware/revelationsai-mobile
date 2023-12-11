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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserPrefs = ref.watch(currentUserPreferencesProvider).requireValue;

    final hapticFeedbackEnabled = currentUserPrefs.hapticFeedback;

    int calculateCurrentIndex() {
      String path = GoRouter.of(context).routeInformationProvider.value.uri.path;
      debugPrint("Current path: $path");

      if (path.startsWith("/home") || path.startsWith("/account") || path.startsWith("/upgrade")) {
        return 0;
      } else if (path.startsWith("/chat")) {
        return 1;
      } else if (path.startsWith("/images")) {
        return 2;
      } else if (path.startsWith("/devotions")) {
        return 3;
      } else {
        return 0;
      }
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: Theme(
        data: ThemeData(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          enableFeedback: hapticFeedbackEnabled,
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
          currentIndex: calculateCurrentIndex(),
          onTap: (value) {
            switch (value) {
              case 0:
                if (hapticFeedbackEnabled) HapticFeedback.lightImpact();
                context.go("/home");
                break;
              case 1:
                if (hapticFeedbackEnabled) HapticFeedback.lightImpact();
                context.go("/chat");
                break;
              case 2:
                if (hapticFeedbackEnabled) HapticFeedback.lightImpact();
                context.go("/images");
                break;
              case 3:
                if (hapticFeedbackEnabled) HapticFeedback.lightImpact();
                context.go("/devotions");
                break;
              default:
                if (hapticFeedbackEnabled) HapticFeedback.lightImpact();
                context.go("/home");
                break;
            }
          },
        ),
      ),
    );
  }
}
