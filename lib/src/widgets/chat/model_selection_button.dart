import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:revelationsai/src/constants/llm.dart';
import 'package:revelationsai/src/hooks/use_chat.dart';
import 'package:revelationsai/src/providers/user/current.dart';
import 'package:revelationsai/src/services/user.dart';
import 'package:revelationsai/src/utils/build_context_extensions.dart';

class ModelSelectionButton extends HookConsumerWidget {
  final UseChatReturnObject chatHook;

  const ModelSelectionButton({
    super.key,
    required this.chatHook,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider).requireValue;

    return PopupMenuButton(
      position: PopupMenuPosition.under,
      offset: const Offset(-10, 0),
      itemBuilder: (context) {
        return [
          for (final modelId in modelIdMapping.keys) ...[
            PopupMenuItem(
              onTap: () {
                if (modelId == claudeV2 && !UserService.hasPlus(currentUser) && !UserService.isAdmin(currentUser)) {
                  context.go("/home/upgrade");
                  return;
                }
                chatHook.modelId.value = modelId;
              },
              child: Text(
                modelIdMapping[modelId]!,
                style: context.textTheme.labelSmall?.copyWith(
                  color: context.colorScheme.onBackground,
                ),
              ),
            ),
          ],
        ];
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text(
            chatHook.modelId.value == null
                ? UserService.hasPlus(currentUser) || UserService.isAdmin(currentUser)
                    ? modelIdMapping[claudeV2]!
                    : modelIdMapping[claudeV1]!
                : modelIdMapping[chatHook.modelId.value!] ?? chatHook.modelId.value!,
            style: context.textTheme.labelSmall?.copyWith(
              color: context.colorScheme.onPrimary.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          Icon(
            Icons.arrow_drop_down,
            size: 18,
            color: context.colorScheme.onPrimary.withOpacity(0.5),
          ),
        ],
      ),
    );
  }
}
