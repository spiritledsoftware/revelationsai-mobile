import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:revelationsai/src/screens/about_screen.dart';
import 'package:revelationsai/src/screens/account/account_screen.dart';
import 'package:revelationsai/src/screens/account/upgrade_screen.dart';
import 'package:revelationsai/src/screens/auth_screen.dart';
import 'package:revelationsai/src/screens/chat/chat_screen.dart';
import 'package:revelationsai/src/screens/devotion/devotion_screen.dart';
import 'package:revelationsai/src/screens/images/all_images_screen.dart';
import 'package:revelationsai/src/screens/images/image_screen.dart';
import 'package:revelationsai/src/screens/sources_screen.dart';
import 'package:revelationsai/src/screens/splash_screen.dart';
import 'package:revelationsai/src/widgets/tabs_scaffold.dart';

CustomTransitionPage buildPageWithDefaultTransition<T>({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        alwaysIncludeSemantics: true,
        opacity: animation,
        child: child,
      );
    },
  );
}

List<RouteBase> routes = [
  GoRoute(
    path: "/",
    builder: (context, state) {
      return SplashScreen(
        redirectPath: state.uri.queryParameters["redirect"],
      );
    },
  ),
  GoRoute(
    path: "/about",
    builder: (context, state) {
      return const AboutScreen();
    },
    pageBuilder: (context, state) {
      return buildPageWithDefaultTransition(
        context: context,
        state: state,
        child: const AboutScreen(),
      );
    },
  ),
  GoRoute(
    path: "/sources",
    builder: (context, state) {
      return const SourcesScreen();
    },
    pageBuilder: (context, state) {
      return buildPageWithDefaultTransition(
        context: context,
        state: state,
        child: const SourcesScreen(),
      );
    },
  ),
  GoRoute(
    path: "/upgrade",
    builder: (context, state) {
      return const TabsScaffold(child: UpgradeScreen());
    },
    pageBuilder: (context, state) {
      return buildPageWithDefaultTransition(
        context: context,
        state: state,
        child: const TabsScaffold(child: UpgradeScreen()),
      );
    },
  ),
  GoRoute(
    path: "/auth",
    redirect: (context, state) {
      if (state.uri.path == "/auth") {
        return "/auth/sign-in";
      }
      return null;
    },
    routes: [
      GoRoute(
        path: "sign-in",
        builder: (context, state) {
          return AuthScreen(
            initType: AuthType.signIn,
            resetPassword: state.uri.queryParameters['resetPassword'] == 'true',
          );
        },
        pageBuilder: (context, state) {
          return buildPageWithDefaultTransition(
            context: context,
            state: state,
            child: AuthScreen(
              initType: AuthType.signIn,
              resetPassword: state.uri.queryParameters['resetPassword'] == 'true',
            ),
          );
        },
      ),
      GoRoute(
        path: "sign-up",
        builder: (context, state) {
          return const AuthScreen(
            initType: AuthType.signUp,
          );
        },
        pageBuilder: (context, state) {
          return buildPageWithDefaultTransition(
            context: context,
            state: state,
            child: const AuthScreen(
              initType: AuthType.signUp,
            ),
          );
        },
      ),
      GoRoute(
        path: "forgot-password",
        builder: (context, state) {
          return AuthScreen(
            initType: AuthType.forgotPassword,
            resetToken: state.uri.queryParameters['token'],
          );
        },
        pageBuilder: (context, state) {
          return buildPageWithDefaultTransition(
            context: context,
            state: state,
            child: AuthScreen(
              initType: AuthType.forgotPassword,
              resetToken: state.uri.queryParameters['token'],
            ),
          );
        },
      ),
    ],
  ),
  ShellRoute(
    navigatorKey: GlobalKey<NavigatorState>(),
    builder: (context, state, child) {
      return TabsScaffold(child: child);
    },
    pageBuilder: (context, state, child) {
      return buildPageWithDefaultTransition(
        context: context,
        state: state,
        child: TabsScaffold(child: child),
      );
    },
    routes: [
      GoRoute(
        path: "/chat",
        builder: (context, state) {
          return ChatScreen(
            initQuery: state.uri.queryParameters['query'],
          );
        },
        pageBuilder: (context, state) {
          return buildPageWithDefaultTransition(
            context: context,
            state: state,
            child: ChatScreen(
              initQuery: state.uri.queryParameters['query'],
            ),
          );
        },
        routes: [
          GoRoute(
            path: ":id",
            builder: (context, state) {
              return ChatScreen(
                initChatId: state.pathParameters['id'],
              );
            },
            pageBuilder: (context, state) {
              return buildPageWithDefaultTransition(
                context: context,
                state: state,
                child: ChatScreen(
                  initChatId: state.pathParameters['id'],
                ),
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: "/images",
        builder: (context, state) {
          return const AllImagesScreen();
        },
        pageBuilder: (context, state) {
          return buildPageWithDefaultTransition(
            context: context,
            state: state,
            child: const AllImagesScreen(),
          );
        },
        routes: [
          GoRoute(
            path: ":id",
            builder: (context, state) {
              return ImageScreen(
                id: state.pathParameters['id']!,
              );
            },
            pageBuilder: (context, state) {
              return buildPageWithDefaultTransition(
                context: context,
                state: state,
                child: ImageScreen(
                  id: state.pathParameters['id']!,
                ),
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: "/devotions",
        builder: (context, state) {
          return const DevotionScreen();
        },
        pageBuilder: (context, state) {
          return buildPageWithDefaultTransition(
            context: context,
            state: state,
            child: const DevotionScreen(),
          );
        },
        routes: [
          GoRoute(
            path: ":id",
            builder: (context, state) {
              return DevotionScreen(
                devotionId: state.pathParameters['id'],
              );
            },
            pageBuilder: (context, state) {
              return buildPageWithDefaultTransition(
                context: context,
                state: state,
                child: DevotionScreen(
                  devotionId: state.pathParameters['id'],
                ),
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: "/account",
        builder: (context, state) {
          return const AccountScreen();
        },
        pageBuilder: (context, state) {
          return buildPageWithDefaultTransition(
            context: context,
            state: state,
            child: const AccountScreen(),
          );
        },
        routes: const [
          // TODO: More account stuff
        ],
      )
    ],
  )
];
