import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:revelationsai/src/hooks/use_chat.dart';
import 'package:revelationsai/src/models/chat.dart';
import 'package:revelationsai/src/utils/build_context_extensions.dart';
import 'package:revelationsai/src/widgets/chat/action_menu_button.dart';
import 'package:revelationsai/src/widgets/chat/model_selection_button.dart';
import 'package:revelationsai/src/widgets/colored_safe_area.dart';

class ChatAppBar extends HookConsumerWidget implements PreferredSizeWidget {
  final ValueNotifier<bool> showToolbar;
  final ValueNotifier<Chat?> chat;
  final UseChatReturnObject chatHook;
  final ValueNotifier<bool> isRefreshingChat;
  final Future<void> Function() refreshChatData;

  const ChatAppBar({
    super.key,
    required this.showToolbar,
    required this.chat,
    required this.chatHook,
    required this.isRefreshingChat,
    required this.refreshChatData,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ColoredSafeArea(
      color: context.colorScheme.primary,
      overlayStyle: SystemUiOverlayStyle.light,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: showToolbar.value ? preferredSize.height : 0,
        child: AppBar(
          automaticallyImplyLeading: false,
          centerTitle: false,
          title: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                chat.value?.name ?? "New Chat",
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.titleMedium?.copyWith(
                  color: context.colorScheme.onPrimary,
                ),
              ),
              ModelSelectionButton(chatHook: chatHook),
            ],
          ),
          actions: [
            ChatActionMenuButton(
              chatHook: chatHook,
              chat: chat,
              isRefreshingChat: isRefreshingChat,
              refreshChatData: refreshChatData,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(60);
}
