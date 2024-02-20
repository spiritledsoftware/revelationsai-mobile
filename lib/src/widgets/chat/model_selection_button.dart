import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:revelationsai/src/hooks/use_chat.dart';
import 'package:revelationsai/src/models/model_info.dart';
import 'package:revelationsai/src/providers/model_infos.dart';
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
    final modelInfos = ref.watch(modelInfosProvider).requireValue;

    return PopupMenuButton(
      position: PopupMenuPosition.under,
      offset: const Offset(-10, 0),
      itemBuilder: (context) {
        return [
          for (final modelInfo in modelInfos.entries) ...[
            PopupMenuItem(
              onTap: () {
                if (modelInfo.value.tier == ModelTier.plus &&
                    !UserService.hasPlus(currentUser) &&
                    !UserService.isAdmin(currentUser)) {
                  context.push("/home/upgrade");
                  return;
                }
                chatHook.modelId.value = modelInfo.key;
              },
              child: Text(
                modelInfo.value.name,
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
                    ? modelInfos.entries.firstWhere((element) => element.value.tier == ModelTier.plus).value.name
                    : modelInfos.entries.firstWhere((element) => element.value.tier == ModelTier.free).value.name
                : modelInfos[chatHook.modelId.value]?.name ?? chatHook.modelId.value!,
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
