import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:revelationsai/src/constants/website.dart';
import 'package:revelationsai/src/models/alert.dart';
import 'package:revelationsai/src/providers/user/current.dart';
import 'package:revelationsai/src/utils/build_context_extensions.dart';
import 'package:revelationsai/src/widgets/branding/logo.dart';

class AuthScreen extends HookConsumerWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingLogin = useState<Future<void>?>(null);
    final snapshot = useFuture(pendingLogin.value);
    final alert = useState<Alert?>(null);

    final isLoading = !snapshot.hasData && !snapshot.hasError && snapshot.connectionState == ConnectionState.waiting;

    final handleLogin = useCallback(() async {
      const url = "${Website.authUrl}/sign-in?mobile=true";
      final authResult = await FlutterWebAuth2.authenticate(
        url: url,
        callbackUrlScheme: "revelationsai",
      );
      final token = Uri.parse(authResult).queryParameters['token'];
      if (token == null) {
        alert.value = Alert(
          message: "Login failed. Please try again.",
          type: AlertType.error,
        );
        return;
      }
      pendingLogin.value = ref.read(currentUserProvider.notifier).loginWithToken(token).catchError((error) {
        alert.value = Alert(
          message: error.toString(),
          type: AlertType.error,
        );
      });
      await pendingLogin.value;
    }, [ref]);

    useEffect(
      () {
        if (snapshot.hasError) {
          alert.value = Alert(
            message: snapshot.error.toString(),
            type: AlertType.error,
          );
        }
        return () {};
      },
      [
        snapshot,
        snapshot.hasError,
        snapshot.error,
      ],
    );

    useEffect(
      () {
        if (alert.value != null) {
          Future.delayed(
            const Duration(seconds: 8),
            () => alert.value = null,
          );
        }
        return () {};
      },
      [alert.value],
    );

    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Expanded(
            child: Center(
              child: Logo(
                width: 300,
              ),
            ),
          ),
          Card(
            elevation: 5,
            margin: EdgeInsets.zero,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(25),
                topRight: Radius.circular(25),
              ),
            ),
            child: SingleChildScrollView(
              child: SafeArea(
                child: Container(
                  width: context.width,
                  padding: const EdgeInsets.only(
                    left: 20,
                    right: 20,
                    bottom: 30,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      alert.value != null
                          ? Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                color: alert.value!.type == AlertType.error ? Colors.red : Colors.green,
                              ),
                              child: Text(
                                alert.value!.message,
                                style: TextStyle(
                                  color: context.colorScheme.onError,
                                ),
                              ),
                            )
                          : (isLoading)
                              ? Container(
                                  height: 32,
                                  width: 32,
                                  padding: const EdgeInsets.all(10),
                                  child: SpinKitSpinningLines(
                                    color: context.secondaryColor,
                                    size: 32,
                                  ),
                                )
                              : const SizedBox(),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () async => await handleLogin(),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.all(15),
                                  backgroundColor: context.secondaryColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.login,
                                      color: context.colorScheme.onSecondary,
                                      size: 30,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      "Login",
                                      style: context.textTheme.titleLarge?.copyWith(
                                        color: context.colorScheme.onSecondary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
