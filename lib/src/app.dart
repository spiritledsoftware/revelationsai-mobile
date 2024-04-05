import 'package:another_flushbar/flushbar.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:revelationsai/src/constants/colors.dart';
import 'package:revelationsai/src/constants/theme.dart';
import 'package:revelationsai/src/providers/chat/current_id.dart';
import 'package:revelationsai/src/providers/devotion/current_id.dart';
import 'package:revelationsai/src/providers/user/preferences.dart';
import 'package:revelationsai/src/routes/routes.dart';
import 'package:revelationsai/src/screens/error_screen.dart';

import 'routes/router_listenable.dart';

class RAIApp extends HookConsumerWidget {
  final String initLocation;

  const RAIApp({
    super.key,
    String? initialLocation,
  }) : initLocation = initialLocation ?? '/';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routerListenableNotifier =
        ref.watch(routerListenableProvider.notifier);

    final rootNavigatorKey = useRef(GlobalKey<NavigatorState>());
    final shellHomeNavigatorKey = useRef(GlobalKey<NavigatorState>());
    final shellChatNavigatorKey = useRef(GlobalKey<NavigatorState>());
    final shellImagesNavigatorKey = useRef(GlobalKey<NavigatorState>());
    final shellDevotionsNavigatorKey = useRef(GlobalKey<NavigatorState>());

    final router = useMemoized(
      () => GoRouter(
        navigatorKey: rootNavigatorKey.value,
        refreshListenable: routerListenableNotifier,
        debugLogDiagnostics: true,
        initialLocation: initLocation,
        routes: getRoutes(
          rootNavigatorKey: rootNavigatorKey.value,
          shellHomeNavigatorKey: shellHomeNavigatorKey.value,
          shellChatNavigatorKey: shellChatNavigatorKey.value,
          shellImagesNavigatorKey: shellImagesNavigatorKey.value,
          shellDevotionsNavigatorKey: shellDevotionsNavigatorKey.value,
        ),
        redirect: routerListenableNotifier.redirect,
        errorPageBuilder: (context, state) {
          return const NoTransitionPage(
            child: ErrorScreen(),
          );
        },
      ),
      [
        routerListenableNotifier,
        initLocation,
        getRoutes,
        rootNavigatorKey.value,
        shellHomeNavigatorKey.value,
        shellChatNavigatorKey.value,
        shellImagesNavigatorKey.value,
        shellDevotionsNavigatorKey.value,
        routerListenableNotifier.redirect,
      ],
    );

    final onMessage = useCallback((RemoteMessage message) {
      debugPrint(
          'Handling message: ${message.messageId} ${message.data.toString()}');
      switch (message.data['task']) {
        case 'daily-devo':
          final id = message.data['id'] ?? '';
          Flushbar(
            backgroundColor: RAIColors.secondary,
            titleColor: RAIColors.primary,
            messageColor: RAIColors.primary,
            title: message.notification?.title ?? '',
            message: message.notification?.body ?? '',
            duration: const Duration(seconds: 8),
            isDismissible: true,
            flushbarPosition: FlushbarPosition.TOP,
            flushbarStyle: FlushbarStyle.GROUNDED,
            padding: const EdgeInsets.all(30),
            dismissDirection: FlushbarDismissDirection.VERTICAL,
            animationDuration: const Duration(milliseconds: 200),
            onTap: (flushbar) {
              router.go('/?redirect=${Uri.encodeComponent('/devotions/$id')}');
              flushbar.dismiss();
            },
          ).show(rootNavigatorKey.value.currentContext!);
          break;
        case "chat-query":
          final query = message.data['query'] ?? '';
          Flushbar(
            backgroundColor: RAIColors.secondary,
            titleColor: RAIColors.primary,
            messageColor: RAIColors.primary,
            title: message.notification?.title ?? '',
            message: message.notification?.body ?? '',
            duration: const Duration(seconds: 8),
            isDismissible: true,
            flushbarPosition: FlushbarPosition.TOP,
            flushbarStyle: FlushbarStyle.GROUNDED,
            padding: const EdgeInsets.all(30),
            dismissDirection: FlushbarDismissDirection.VERTICAL,
            animationDuration: const Duration(milliseconds: 200),
            onTap: (flushbar) {
              router.go(
                  '/?redirect=${Uri.encodeComponent('/chat?query=$query')}');
              flushbar.dismiss();
            },
          ).show(rootNavigatorKey.value.currentContext!);
          break;
        default:
          break;
      }
    }, [router, rootNavigatorKey.value]);

    final onMessageOpenedApp = useCallback((RemoteMessage message) {
      debugPrint(
          'Handling message opened app: ${message.messageId} ${message.data.toString()}');
      switch (message.data['task']) {
        case 'daily-devo':
          final id = message.data['id'] ?? '';
          router.go('/?redirect=${Uri.encodeComponent('/devotions/$id')}');
          break;
        case "chat-query":
          final query = message.data['query'] ?? '';
          router.go('/?redirect=${Uri.encodeComponent('/chat?query=$query')}');
          break;
        default:
          break;
      }
    }, [router]);

    useEffect(() {
      debugPrint('Setting up FirebaseMessaging listeners');
      FirebaseMessaging.onMessage.listen(onMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(onMessageOpenedApp);
      return () {
        FirebaseMessaging.onMessage.drain();
        FirebaseMessaging.onMessageOpenedApp.drain();
      };
    }, [onMessage, onMessageOpenedApp]);

    return _EagerlyInitializedProviders(
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'RevelationsAI',
        theme: RAITheme.light,
        darkTheme: RAITheme.dark,
        themeMode: ref.watch(currentUserPreferencesProvider).value?.themeMode ??
            ThemeMode.system,
        routerConfig: router,
      ),
    );
  }
}

class _EagerlyInitializedProviders extends ConsumerWidget {
  final Widget child;

  const _EagerlyInitializedProviders({required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(currentChatIdProvider);
    ref.watch(currentDevotionIdProvider);
    return child;
  }
}
