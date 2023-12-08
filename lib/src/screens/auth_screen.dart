import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:revelationsai/src/constants/api.dart';
import 'package:revelationsai/src/models/alert.dart';
import 'package:revelationsai/src/providers/user/current.dart';
import 'package:revelationsai/src/utils/build_context_extensions.dart';
import 'package:revelationsai/src/widgets/branding/logo.dart';

enum AuthType {
  signIn,
  signUp,
  forgotPassword,
}

class AuthScreen extends HookConsumerWidget {
  final AuthType initType;
  final bool? resetPassword;
  final String? resetToken;

  const AuthScreen({
    super.key,
    this.resetPassword,
    required this.initType,
    this.resetToken,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final type = useState(initType);

    final formKey = useRef(GlobalKey<FormState>());

    final TextEditingController emailTextController = useTextEditingController();
    final emailFocusNode = useFocusNode();

    final TextEditingController passwordTextController = useTextEditingController();
    final passwordFocusNode = useFocusNode();

    final TextEditingController confirmPasswordTextController = useTextEditingController();
    final confirmPasswordFocusNode = useFocusNode();

    final pendingFuture = useState<Future<void>?>(null);
    final snapshot = useFuture(pendingFuture.value);
    final alert = useState<Alert?>(null);

    final showPassword = useState(false);
    final showConfirmPassword = useState(false);

    final isLoading = !snapshot.hasData && !snapshot.hasError && snapshot.connectionState == ConnectionState.waiting;

    final handleSignUp = useCallback(
      () async {
        if (formKey.value.currentState?.validate() ?? false) {
          pendingFuture.value = ref
              .read(currentUserProvider.notifier)
              .register(emailTextController.value.text, passwordTextController.value.text)
              .then((value) {
            alert.value = Alert(
              message: "Check your email for a verification link.",
              type: AlertType.success,
            );
          }).catchError((error) {
            alert.value = Alert(
              message: error.toString(),
              type: AlertType.error,
            );
          });
          await pendingFuture.value;
        }
      },
      [
        ref,
        formKey.value,
        emailTextController.value.text,
        passwordTextController.value.text,
      ],
    );

    final handleSignIn = useCallback(() async {
      pendingFuture.value = ref
          .read(currentUserProvider.notifier)
          .login(emailTextController.value.text, passwordTextController.value.text)
          .catchError((error) {
        alert.value = Alert(
          message: error.toString(),
          type: AlertType.error,
        );
      });
      await pendingFuture.value;
    }, [ref, formKey.value, emailTextController.value.text, passwordTextController.value.text]);

    final handleResetPassword = useCallback(
      () async {
        if (resetToken == null) {
          if (emailTextController.text.isEmpty) {
            alert.value = Alert(
              message: "Email is required",
              type: AlertType.error,
            );
            return;
          }
          pendingFuture.value = ref
              .read(currentUserProvider.notifier)
              .forgotPassword(
                emailTextController.text,
              )
              .then((value) {
            alert.value = Alert(
              message: "Password reset email sent",
              type: AlertType.success,
            );
          }).catchError((error) {
            alert.value = Alert(
              message: error.toString(),
              type: AlertType.error,
            );
          });
          await pendingFuture.value;
        } else {
          if (passwordTextController.text != confirmPasswordTextController.text) {
            alert.value = Alert(
              message: "Passwords do not match",
              type: AlertType.error,
            );
            return;
          }

          pendingFuture.value = ref
              .read(currentUserProvider.notifier)
              .resetPassword(
                resetToken!,
                passwordTextController.text,
              )
              .then((value) {
            alert.value = Alert(
              message: "Password reset successful. Please login with your new password.",
              type: AlertType.success,
            );
            type.value = AuthType.signIn;
          }).catchError((error) {
            alert.value = Alert(
              message: error.toString(),
              type: AlertType.error,
            );
          });
          await pendingFuture.value;
        }
      },
      [
        resetToken,
        emailTextController.text,
        passwordTextController.text,
        confirmPasswordTextController.text,
      ],
    );

    final handleSocialSignIn = useCallback((String provider) async {
      final authResult = await FlutterWebAuth2.authenticate(
        url: "${API.url}/auth/$provider-mobile/authorize",
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

      pendingFuture.value = ref.read(currentUserProvider.notifier).loginWithToken(token).catchError((error) {
        alert.value = Alert(
          message: error.toString(),
          type: AlertType.error,
        );
      });
      await pendingFuture.value;
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

    useEffect(() {
      if (resetPassword == true) {
        alert.value = Alert(
          message: "Password reset successful. Please login with your new password.",
          type: AlertType.success,
        );
      }
      return () {};
    }, [resetPassword]);

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
      body: Stack(
        children: [
          SafeArea(
            child: SizedBox(
              height: context.height * 0.3,
              width: context.width,
              child: const Center(
                child: Logo(
                  width: 300,
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (alert.value != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      margin: const EdgeInsets.only(bottom: 30),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        color: alert.value!.type == AlertType.error ? Colors.red : Colors.green,
                      ),
                      child: Text(
                        alert.value!.message,
                        style: TextStyle(
                          color: context.colorScheme.onError,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    )
                  ] else if (isLoading) ...[
                    Container(
                      height: 40,
                      width: 40,
                      margin: const EdgeInsets.only(bottom: 30),
                      child: SpinKitSpinningLines(
                        color: context.secondaryColor,
                        size: 40,
                      ),
                    ),
                  ],
                  Container(
                    padding: const EdgeInsets.only(
                      top: 40,
                      left: 20,
                      right: 20,
                      bottom: 10,
                    ),
                    decoration: BoxDecoration(
                      color: context.brightness == Brightness.light
                          ? context.colorScheme.background
                          : context.colorScheme.surface,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(25),
                        topRight: Radius.circular(25),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: context.colorScheme.shadow.withOpacity(0.1),
                          blurRadius: 5,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      top: false,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (type.value == AuthType.forgotPassword && resetToken == null) ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 30,
                              ),
                              child: Text(
                                "Enter your email address and we'll send you a link to reset your password.",
                                textAlign: TextAlign.center,
                                style: context.textTheme.bodyMedium?.copyWith(
                                  color: context.brightness == Brightness.light
                                      ? context.primaryColor.withOpacity(0.6)
                                      : context.secondaryColor,
                                ),
                              ),
                            ),
                            const SizedBox(
                              height: 20,
                            ),
                          ],
                          if (type.value != AuthType.forgotPassword) ...[
                            if (Platform.isIOS) ...[
                              Flex(
                                direction: Axis.horizontal,
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(5),
                                        ),
                                        padding: const EdgeInsets.only(
                                          top: 15,
                                          bottom: 15,
                                        ),
                                      ),
                                      onPressed: () async {
                                        handleSocialSignIn("apple");
                                      },
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          FaIcon(
                                            FontAwesomeIcons.apple,
                                          ),
                                          SizedBox(
                                            width: 10,
                                          ),
                                          Text(
                                            "Continue with Apple",
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(
                                height: 10,
                              ),
                            ],
                            Flex(
                              direction: Axis.horizontal,
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      padding: const EdgeInsets.only(
                                        top: 15,
                                        bottom: 15,
                                      ),
                                    ),
                                    onPressed: () async {
                                      handleSocialSignIn("google");
                                    },
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        FaIcon(
                                          FontAwesomeIcons.google,
                                        ),
                                        SizedBox(
                                          width: 10,
                                        ),
                                        Text(
                                          "Continue with Google",
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(
                              height: 10,
                            ),
                            Flex(
                              mainAxisAlignment: MainAxisAlignment.center,
                              direction: Axis.horizontal,
                              children: [
                                Expanded(
                                  child: Container(
                                    height: 1,
                                    color: context.colorScheme.onBackground.withOpacity(0.5),
                                  ),
                                ),
                                const SizedBox(
                                  width: 10,
                                ),
                                const Text(
                                  "OR",
                                ),
                                const SizedBox(
                                  width: 10,
                                ),
                                Expanded(
                                  child: Container(
                                    height: 1,
                                    color: context.colorScheme.onBackground.withOpacity(0.5),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(
                              height: 10,
                            ),
                          ],
                          Form(
                            key: formKey.value,
                            child: AutofillGroup(
                              child: Column(
                                children: [
                                  if (type.value != AuthType.forgotPassword || resetToken == null) ...[
                                    TextFormField(
                                      autofillHints: const [
                                        AutofillHints.email,
                                      ],
                                      autocorrect: false,
                                      keyboardType: TextInputType.emailAddress,
                                      controller: emailTextController,
                                      focusNode: emailFocusNode,
                                      decoration: const InputDecoration(
                                        hintText: "Email",
                                      ),
                                      onTapOutside: (event) {
                                        emailFocusNode.unfocus();
                                      },
                                      onFieldSubmitted: (value) {
                                        emailFocusNode.unfocus();
                                        passwordFocusNode.requestFocus();
                                      },
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return "Email is required";
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(
                                      height: 10,
                                    ),
                                  ],
                                  if (type.value != AuthType.forgotPassword || resetToken != null) ...[
                                    TextFormField(
                                      autofillHints: [
                                        type.value == AuthType.signUp
                                            ? AutofillHints.newPassword
                                            : AutofillHints.password,
                                      ],
                                      autocorrect: false,
                                      obscureText: !showPassword.value,
                                      keyboardType: TextInputType.visiblePassword,
                                      controller: passwordTextController,
                                      focusNode: passwordFocusNode,
                                      onFieldSubmitted: (value) {
                                        if (type.value == AuthType.signUp) {
                                          confirmPasswordFocusNode.requestFocus();
                                        } else {
                                          passwordFocusNode.unfocus();
                                        }
                                      },
                                      onTapOutside: (event) {
                                        passwordFocusNode.unfocus();
                                      },
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return "Password is required";
                                        }
                                        return null;
                                      },
                                      decoration: InputDecoration(
                                        hintText: "Password",
                                        suffixIcon: IconButton(
                                          onPressed: () {
                                            showPassword.value = !showPassword.value;
                                          },
                                          icon: FaIcon(
                                            showPassword.value ? FontAwesomeIcons.eye : FontAwesomeIcons.eyeSlash,
                                            size: 18,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(
                                      height: 10,
                                    ),
                                  ],
                                  if (type.value == AuthType.signUp ||
                                      (type.value == AuthType.forgotPassword && resetToken != null)) ...[
                                    TextFormField(
                                      autofillHints: const [
                                        AutofillHints.newPassword,
                                      ],
                                      autocorrect: false,
                                      obscureText: !showConfirmPassword.value,
                                      keyboardType: TextInputType.visiblePassword,
                                      controller: confirmPasswordTextController,
                                      focusNode: confirmPasswordFocusNode,
                                      onFieldSubmitted: (value) {
                                        confirmPasswordFocusNode.unfocus();
                                      },
                                      onTapOutside: (event) {
                                        confirmPasswordFocusNode.unfocus();
                                      },
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return "Confirm Password is required";
                                        }
                                        return null;
                                      },
                                      decoration: InputDecoration(
                                        hintText: "Confirm Password",
                                        suffixIcon: IconButton(
                                          onPressed: () {
                                            showConfirmPassword.value = !showConfirmPassword.value;
                                          },
                                          icon: FaIcon(
                                            showConfirmPassword.value
                                                ? FontAwesomeIcons.eye
                                                : FontAwesomeIcons.eyeSlash,
                                            size: 18,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(
                                      height: 10,
                                    ),
                                  ],
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(5),
                                            ),
                                            padding: const EdgeInsets.only(
                                              top: 15,
                                              bottom: 15,
                                            ),
                                          ),
                                          onPressed: () async {
                                            emailFocusNode.unfocus();
                                            passwordFocusNode.unfocus();
                                            confirmPasswordFocusNode.unfocus();
                                            if (formKey.value.currentState?.validate() ?? false) {
                                              if (type.value == AuthType.signUp) {
                                                await handleSignUp();
                                              } else if (type.value == AuthType.forgotPassword) {
                                                await handleResetPassword();
                                              } else {
                                                await handleSignIn();
                                              }
                                            }
                                          },
                                          child: Text(
                                            type.value == AuthType.forgotPassword ? "Submit" : "Continue with Email",
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  if (type.value == AuthType.signIn) {
                                    type.value = AuthType.signUp;
                                  } else {
                                    type.value = AuthType.signIn;
                                  }
                                },
                                child: Text(
                                  type.value == AuthType.signUp
                                      ? "Already have an account?"
                                      : type.value == AuthType.signIn
                                          ? "Don't have an account?"
                                          : "Know your password?",
                                  style: context.textTheme.bodySmall?.copyWith(
                                    color: context.brightness == Brightness.light
                                        ? context.primaryColor.withOpacity(0.6)
                                        : context.secondaryColor,
                                  ),
                                ),
                              ),
                              if (type.value == AuthType.signIn) ...[
                                GestureDetector(
                                  onTap: () {
                                    type.value = AuthType.forgotPassword;
                                  },
                                  child: Text(
                                    "Forgot password?",
                                    style: context.textTheme.bodySmall?.copyWith(
                                      color: context.brightness == Brightness.light
                                          ? context.primaryColor.withOpacity(0.6)
                                          : context.secondaryColor,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
