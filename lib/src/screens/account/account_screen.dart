import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:revelationsai/src/constants/visual_density.dart';
import 'package:revelationsai/src/providers/user/current.dart';
import 'package:revelationsai/src/providers/user/preferences.dart';
import 'package:revelationsai/src/utils/build_context_extensions.dart';
import 'package:revelationsai/src/widgets/account/change_password_dialog.dart';
import 'package:revelationsai/src/widgets/account/delete_account_dialog.dart';
import 'package:revelationsai/src/widgets/account/edit_email_dialog.dart';
import 'package:revelationsai/src/widgets/account/rename_dialog.dart';
import 'package:revelationsai/src/widgets/account/user_avatar.dart';

class AccountScreen extends HookConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider).requireValue;
    final currentUserPrefs = ref.watch(currentUserPreferencesProvider).requireValue;

    final hapticFeedbackEnabled = currentUserPrefs.hapticFeedback;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: context.isDarkMode ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        floatingActionButtonLocation: FloatingActionButtonLocation.miniStartTop,
        floatingActionButton: FloatingActionButton.small(
          onPressed: () {
            if (hapticFeedbackEnabled) {
              HapticFeedback.mediumImpact();
            }
            context.go("/home");
          },
          child: const Icon(Icons.arrow_back),
        ),
        body: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  UserAvatar(
                    radius: 50,
                    badgeBuilder: (context) {
                      return IconButton(
                        visualDensity: RAIVisualDensity.tightest,
                        onPressed: () async {
                          if (ImagePicker().supportsImageSource(
                            ImageSource.gallery,
                          )) {
                            final image = await ImagePicker().pickImage(
                              source: ImageSource.gallery,
                            );

                            if (image != null) {
                              final croppedImage = await ImageCropper().cropImage(
                                  sourcePath: image.path,
                                  maxHeight: 512,
                                  maxWidth: 512,
                                  cropStyle: CropStyle.circle,
                                  aspectRatioPresets: [
                                    CropAspectRatioPreset.square,
                                  ],
                                  uiSettings: [
                                    IOSUiSettings(
                                      title: 'Crop Image',
                                    ),
                                    AndroidUiSettings(
                                      toolbarTitle: 'Crop Image',
                                    )
                                  ]);

                              if (croppedImage != null) {
                                ref.read(currentUserProvider.notifier).updateUserImage(croppedImage);
                              }
                            }
                          }
                        },
                        icon: Icon(
                          Icons.edit,
                          color: context.colorScheme.onSecondary,
                        ),
                        iconSize: 15,
                        color: context.secondaryColor,
                      );
                    },
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.width * 0.1,
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text.rich(
                                TextSpan(
                                  text: "Name:",
                                  children: [
                                    const WidgetSpan(
                                      child: SizedBox(
                                        width: 10,
                                      ),
                                    ),
                                    TextSpan(
                                      text: currentUser.name ?? currentUser.email,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                softWrap: false,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                showDialog(
                                  barrierDismissible: false,
                                  context: context,
                                  builder: (context) {
                                    return const RenameDialog();
                                  },
                                );
                              },
                              icon: const Icon(Icons.edit),
                            )
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text.rich(
                                TextSpan(
                                  text: "Email:",
                                  children: [
                                    const WidgetSpan(
                                      child: SizedBox(
                                        width: 10,
                                      ),
                                    ),
                                    TextSpan(
                                      text: currentUser.email,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                softWrap: false,
                                overflow: TextOverflow.fade,
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                showDialog(
                                  barrierDismissible: false,
                                  context: context,
                                  builder: (context) {
                                    return const EditEmailDialog();
                                  },
                                );
                              },
                              icon: const Icon(Icons.edit),
                            )
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text.rich(
                                TextSpan(
                                  text: "Password:",
                                  children: [
                                    const WidgetSpan(
                                      child: SizedBox(
                                        width: 10,
                                      ),
                                    ),
                                    for (int i = 0; i < 12; i++) ...[
                                      const WidgetSpan(
                                        alignment: PlaceholderAlignment.middle,
                                        child: Icon(Icons.circle, size: 7),
                                      ),
                                      const WidgetSpan(
                                        child: SizedBox(
                                          width: 2,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                softWrap: false,
                                overflow: TextOverflow.fade,
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                showDialog(
                                  barrierDismissible: false,
                                  context: context,
                                  builder: (context) {
                                    return const ChangePasswordDialog();
                                  },
                                );
                              },
                              icon: const Icon(Icons.edit),
                            )
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 30,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Queries:',
                                style: context.textTheme.titleMedium,
                              ),
                              const SizedBox(
                                width: 10,
                              ),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: currentUser.remainingQueries <= 3
                                      ? context.colorScheme.error.withOpacity(0.5)
                                      : context.primaryColor,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    currentUser.remainingQueries > 100
                                        ? Icon(
                                            CupertinoIcons.infinite,
                                            color: context.colorScheme.onPrimary,
                                            size: 18,
                                          )
                                        : Text(
                                            currentUser.remainingQueries.toString(),
                                            style: context.textTheme.labelLarge?.copyWith(
                                              color: currentUser.remainingQueries <= 3
                                                  ? context.colorScheme.onError
                                                  : context.colorScheme.onPrimary,
                                            ),
                                          ),
                                    SizedBox(
                                      height: 15,
                                      child: VerticalDivider(
                                        color: currentUser.remainingQueries <= 3
                                            ? context.colorScheme.onError
                                            : context.colorScheme.onPrimary,
                                      ),
                                    ),
                                    currentUser.remainingQueries > 100
                                        ? Icon(
                                            CupertinoIcons.infinite,
                                            color: context.colorScheme.onPrimary,
                                            size: 18,
                                          )
                                        : Text(
                                            currentUser.maxQueries.toString(),
                                            style: context.textTheme.labelLarge?.copyWith(
                                              color: currentUser.remainingQueries <= 3
                                                  ? context.colorScheme.onError
                                                  : context.colorScheme.onPrimary,
                                            ),
                                          ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Images:',
                                style: context.textTheme.titleMedium,
                              ),
                              const SizedBox(
                                width: 10,
                              ),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: currentUser.remainingGeneratedImages <= 3
                                      ? context.colorScheme.error.withOpacity(0.5)
                                      : context.primaryColor,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    currentUser.remainingGeneratedImages > 100
                                        ? Icon(
                                            CupertinoIcons.infinite,
                                            color: context.colorScheme.onPrimary,
                                            size: 18,
                                          )
                                        : Text(
                                            currentUser.remainingGeneratedImages.toString(),
                                            style: context.textTheme.labelLarge?.copyWith(
                                              color: currentUser.remainingGeneratedImages <= 3
                                                  ? context.colorScheme.onError
                                                  : context.colorScheme.onPrimary,
                                            ),
                                          ),
                                    SizedBox(
                                      height: 15,
                                      child: VerticalDivider(
                                        color: currentUser.remainingGeneratedImages <= 3
                                            ? context.colorScheme.onError
                                            : context.colorScheme.onPrimary,
                                      ),
                                    ),
                                    currentUser.remainingGeneratedImages > 100
                                        ? Icon(
                                            CupertinoIcons.infinite,
                                            color: context.colorScheme.onPrimary,
                                            size: 18,
                                          )
                                        : Text(
                                            currentUser.maxGeneratedImages.toString(),
                                            style: context.textTheme.labelLarge?.copyWith(
                                              color: currentUser.remainingGeneratedImages <= 3
                                                  ? context.colorScheme.onError
                                                  : context.colorScheme.onPrimary,
                                            ),
                                          ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(
                        width: 30,
                      ),
                      TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            vertical: 15,
                            horizontal: 40,
                          ),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(
                              Radius.circular(10),
                            ),
                          ),
                        ),
                        onPressed: () {
                          context.go("/upgrade");
                        },
                        child: const Text("Upgrade"),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 40,
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: 15,
                        horizontal: 40,
                      ),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(
                          Radius.circular(10),
                        ),
                      ),
                    ),
                    onPressed: () async {
                      await ref.read(currentUserProvider.notifier).logout().then((value) => context.go("/auth"));
                    },
                    child: SizedBox(
                      width: context.width * 0.5,
                      child: const Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.logout),
                          SizedBox(
                            width: 10,
                          ),
                          Text('Logout'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade300.withOpacity(0.3),
                      padding: const EdgeInsets.symmetric(
                        vertical: 15,
                        horizontal: 40,
                      ),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(
                          Radius.circular(10),
                        ),
                      ),
                    ),
                    onPressed: () async {
                      // display confirmation dialog
                      await showDialog(
                        barrierDismissible: false,
                        context: context,
                        builder: (context) {
                          return const DeleteAccountDialog();
                        },
                      );
                    },
                    child: SizedBox(
                      width: context.width * 0.5,
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            CupertinoIcons.trash,
                            color: Colors.red.shade500,
                          ),
                          const SizedBox(
                            width: 10,
                          ),
                          Text(
                            'Delete Account',
                            textAlign: TextAlign.center,
                            style: context.textTheme.titleMedium?.copyWith(
                              color: Colors.red.shade500,
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
    );
  }
}
