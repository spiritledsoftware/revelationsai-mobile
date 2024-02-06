import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:revelationsai/src/screens/about_screen.dart';
import 'package:revelationsai/src/screens/account/account_screen.dart';
import 'package:revelationsai/src/screens/account/settings_modal.dart';
import 'package:revelationsai/src/screens/account/upgrade_screen.dart';
import 'package:revelationsai/src/screens/all_sources_screen.dart';
import 'package:revelationsai/src/screens/auth_screen.dart';
import 'package:revelationsai/src/screens/chat/chat_modal.dart';
import 'package:revelationsai/src/screens/chat/chat_screen.dart';
import 'package:revelationsai/src/screens/devotion/devotion_modal.dart';
import 'package:revelationsai/src/screens/devotion/devotion_screen.dart';
import 'package:revelationsai/src/screens/home_screen.dart';
import 'package:revelationsai/src/screens/images/all_images_screen.dart';
import 'package:revelationsai/src/screens/images/image_screen.dart';
import 'package:revelationsai/src/screens/splash_screen.dart';
import 'package:revelationsai/src/widgets/modal_page.dart';
import 'package:revelationsai/src/widgets/tabs_scaffold.dart';

List<RouteBase> getRoutes({
  required GlobalKey<NavigatorState> rootNavigatorKey,
  required GlobalKey<NavigatorState> shellHomeNavigatorKey,
  required GlobalKey<NavigatorState> shellChatNavigatorKey,
  required GlobalKey<NavigatorState> shellImagesNavigatorKey,
  required GlobalKey<NavigatorState> shellDevotionsNavigatorKey,
}) {
  return [
    GoRoute(
      path: "/",
      pageBuilder: (context, state) {
        return const NoTransitionPage(
          child: SplashScreen(),
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
          pageBuilder: (context, state) {
            return NoTransitionPage(
              child: AuthScreen(
                initType: AuthType.signIn,
                resetPassword: state.uri.queryParameters['resetPassword'] == 'true',
              ),
            );
          },
        ),
        GoRoute(
          path: "sign-up",
          pageBuilder: (context, state) {
            return const NoTransitionPage(
              child: AuthScreen(
                initType: AuthType.signUp,
              ),
            );
          },
        ),
        GoRoute(
          path: "forgot-password",
          pageBuilder: (context, state) {
            return NoTransitionPage(
              child: AuthScreen(
                initType: AuthType.forgotPassword,
                resetToken: state.uri.queryParameters['token'],
              ),
            );
          },
        ),
      ],
    ),
    StatefulShellRoute.indexedStack(
      pageBuilder: (context, state, navigationShell) {
        return NoTransitionPage(child: TabsScaffold(navShell: navigationShell));
      },
      branches: [
        StatefulShellBranch(
          navigatorKey: shellHomeNavigatorKey,
          routes: [
            GoRoute(
              path: "/home",
              pageBuilder: (context, state) {
                return const NoTransitionPage(child: HomeScreen());
              },
              routes: [
                GoRoute(
                  path: "settings",
                  pageBuilder: (context, state) {
                    return ModalPage(
                      builder: (_) {
                        return const FractionallySizedBox(
                          widthFactor: 1.0,
                          heightFactor: 0.90,
                          child: SettingsModal(),
                        );
                      },
                    );
                  },
                ),
                GoRoute(
                  path: "account",
                  builder: (context, state) {
                    return const AccountScreen();
                  },
                ),
                GoRoute(
                  path: "upgrade",
                  builder: (context, state) {
                    return const UpgradeScreen();
                  },
                ),
                GoRoute(
                  path: "about",
                  builder: (context, state) {
                    return const AboutScreen();
                  },
                ),
                GoRoute(
                  path: "sources",
                  builder: (context, state) {
                    return const SourcesScreen();
                  },
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: shellChatNavigatorKey,
          routes: [
            GoRoute(
              path: "/chat",
              pageBuilder: (context, state) {
                return NoTransitionPage(
                  child: ChatScreen(
                    initQuery: state.uri.queryParameters['query'],
                  ),
                );
              },
              routes: [
                GoRoute(
                  path: "history",
                  pageBuilder: (context, state) {
                    return ModalPage(
                      builder: (_) {
                        return FractionallySizedBox(
                          widthFactor: 1.0,
                          heightFactor: 0.90,
                          child: ChatModal(
                            activeId: state.uri.queryParameters['activeId'],
                          ),
                        );
                      },
                    );
                  },
                ),
                GoRoute(
                  path: ":id",
                  builder: (context, state) {
                    return ChatScreen(
                      initChatId: state.pathParameters['id'],
                      initQuery: state.uri.queryParameters['query'],
                    );
                  },
                  routes: [
                    GoRoute(
                      path: "history",
                      pageBuilder: (context, state) {
                        return ModalPage(
                          builder: (_) {
                            return FractionallySizedBox(
                              widthFactor: 1.0,
                              heightFactor: 0.90,
                              child: ChatModal(
                                activeId: state.uri.queryParameters['activeId'] ?? state.pathParameters['id'],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: shellImagesNavigatorKey,
          routes: [
            GoRoute(
              path: "/images",
              pageBuilder: (context, state) {
                return const NoTransitionPage(child: AllImagesScreen());
              },
              routes: [
                GoRoute(
                  path: ":id",
                  builder: (context, state) {
                    return ImageScreen(
                      id: state.pathParameters['id']!,
                    );
                  },
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: shellDevotionsNavigatorKey,
          routes: [
            GoRoute(
              path: "/devotions",
              pageBuilder: (context, state) {
                return const NoTransitionPage(child: DevotionScreen());
              },
              routes: [
                GoRoute(
                  path: "history",
                  pageBuilder: (context, state) {
                    return ModalPage(
                      builder: (_) {
                        return FractionallySizedBox(
                          widthFactor: 1.0,
                          heightFactor: 0.90,
                          child: DevotionModal(
                            activeId: state.uri.queryParameters['activeId'],
                          ),
                        );
                      },
                    );
                  },
                ),
                GoRoute(
                  path: ":id",
                  builder: (context, state) {
                    return DevotionScreen(
                      devotionId: state.pathParameters['id']!,
                    );
                  },
                  routes: [
                    GoRoute(
                      path: "history",
                      pageBuilder: (context, state) {
                        return ModalPage(
                          builder: (_) {
                            return FractionallySizedBox(
                              widthFactor: 1.0,
                              heightFactor: 0.90,
                              child: DevotionModal(
                                activeId: state.uri.queryParameters['activeId'] ?? state.pathParameters['id'],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    )
  ];
}
