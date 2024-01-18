import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:revelationsai/src/constants/colors.dart';
import 'package:revelationsai/src/constants/website.dart';
import 'package:revelationsai/src/models/user.dart';
import 'package:revelationsai/src/models/user/request.dart';
import 'package:revelationsai/src/providers/in_app_purchases/customer_info.dart';
import 'package:revelationsai/src/providers/user/current.dart';
import 'package:revelationsai/src/providers/user/preferences.dart';
import 'package:revelationsai/src/utils/build_context_extensions.dart';
import 'package:revelationsai/src/widgets/account/user_avatar.dart';
import 'package:revelationsai/src/widgets/branding/circular_logo.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';

class SettingsModal extends HookConsumerWidget {
  const SettingsModal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: context.theme.canvasColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.only(
              top: 10,
              bottom: 10,
              left: 30,
            ),
            decoration: ShapeDecoration(
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              color: RAIColors.primary,
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Settings',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(
                    Icons.close,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(
                bottom: 20,
              ),
              children: [
                ListTile(
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  title: Text(
                    "App",
                    style: context.textTheme.titleMedium,
                  ),
                ),
                ListTile(
                  leading: const CircularLogo(
                    radius: 12,
                    noShadow: true,
                  ),
                  title: const Text('About RevelationsAI'),
                  onTap: () {
                    context.push("/home/about");
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: const Text('Privacy Policy'),
                  onTap: () async {
                    await launchUrlString(
                      '${Website.url}/privacy-policy',
                      mode: LaunchMode.inAppWebView,
                      webViewConfiguration: const WebViewConfiguration(
                        enableJavaScript: true,
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.article_outlined),
                  title: const Text('Terms of Use'),
                  onTap: () async {
                    await launchUrlString(
                      Platform.isIOS
                          ? 'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/'
                          : 'https://play.google.com/about/play-terms/',
                      mode: LaunchMode.inAppWebView,
                      webViewConfiguration: const WebViewConfiguration(
                        enableJavaScript: true,
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const FaIcon(FontAwesomeIcons.headset),
                  title: const Text('Support'),
                  onTap: () async {
                    await launchUrl(
                      Uri.parse(
                          'mailto:support@revelationsai.com?subject=${Uri.encodeComponent('RevelationsAI Support Request')}'),
                      mode: LaunchMode.externalApplication,
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  title: Text(
                    "Account",
                    style: context.textTheme.titleMedium,
                  ),
                ),
                ListTile(
                  leading: const UserAvatar(
                    radius: 16,
                    noShadow: true,
                  ),
                  title: const Text('Manage Account'),
                  trailing: Text(ref.watch(currentUserProvider).requireValue.name ??
                      ref.watch(currentUserProvider).requireValue.email),
                  onTap: () {
                    context.push("/home/account");
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.payment),
                  title: const Text('Current Plan'),
                  trailing: ref.watch(activeSubscriptionsProvider).when(
                        data: (value) {
                          if (value.isEmpty) {
                            return const Text('Late to Sunday Service');
                          }
                          return Text(value.first.storeProduct.title);
                        },
                        loading: () => SizedBox(
                          width: 20,
                          height: 20,
                          child: SpinKitSpinningLines(
                            color: context.colorScheme.secondary,
                            size: 20,
                          ),
                        ),
                        error: (error, stack) => Text(
                          'Error',
                          style: TextStyle(color: context.colorScheme.error),
                        ),
                      ),
                  onTap: () {
                    context.push("/home/upgrade");
                  },
                ),
                const Divider(),
                ListTile(
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  title: Text(
                    "Preferences",
                    style: context.textTheme.titleMedium,
                  ),
                ),
                ListTile(
                  leading: context.isLightMode
                      ? const Icon(Icons.light_mode_outlined)
                      : const Icon(Icons.dark_mode_outlined),
                  title: const Text('Theme Mode'),
                  trailing: DropdownButton(
                    value: ref.watch(currentUserPreferencesProvider).requireValue.themeMode,
                    onChanged: (value) {
                      ref.read(currentUserPreferencesProvider.notifier).updatePrefs(
                            ref
                                .read(currentUserPreferencesProvider)
                                .requireValue
                                .copyWith(themeMode: value as ThemeMode),
                          );
                    },
                    items: const <DropdownMenuItem>[
                      DropdownMenuItem(
                        value: ThemeMode.system,
                        child: Text('System'),
                      ),
                      DropdownMenuItem(
                        value: ThemeMode.light,
                        child: Text('Light'),
                      ),
                      DropdownMenuItem(
                        value: ThemeMode.dark,
                        child: Text('Dark'),
                      ),
                    ],
                  ),
                ),
                ListTile(
                  leading: const FaIcon(FontAwesomeIcons.bookBible),
                  title: const Text('Bible Translation'),
                  trailing: DropdownButton(
                    value: ref.watch(currentUserProvider).requireValue.translation,
                    onChanged: (value) async {
                      await ref.read(currentUserProvider.notifier).updateUser(
                            UpdateUserRequest(translation: value as Translation),
                          );
                    },
                    items: Translation.values.map((translation) {
                      return DropdownMenuItem(
                        value: translation,
                        child: Text(translation.toString().split('.').last),
                      );
                    }).toList(),
                  ),
                ),
                SwitchListTile.adaptive(
                  title: const Row(
                    children: [
                      Icon(CupertinoIcons.waveform),
                      SizedBox(width: 10),
                      Text('Haptic Feedback'),
                    ],
                  ),
                  value: ref.watch(currentUserPreferencesProvider).requireValue.hapticFeedback,
                  onChanged: (value) {
                    ref.read(currentUserPreferencesProvider.notifier).updatePrefs(
                          ref.read(currentUserPreferencesProvider).requireValue.copyWith(hapticFeedback: value),
                        );
                  },
                ),
                SwitchListTile.adaptive(
                  title: const Row(
                    children: [
                      Icon(CupertinoIcons.chat_bubble_2_fill),
                      SizedBox(width: 10),
                      Text('Chat Suggestions'),
                    ],
                  ),
                  value: ref.watch(currentUserPreferencesProvider).requireValue.chatSuggestions,
                  onChanged: (value) {
                    ref.read(currentUserPreferencesProvider.notifier).updatePrefs(
                          ref.read(currentUserPreferencesProvider).requireValue.copyWith(chatSuggestions: value),
                        );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
