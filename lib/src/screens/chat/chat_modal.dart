import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:revelationsai/src/models/chat.dart';
import 'package:revelationsai/src/providers/chat/current_id.dart';
import 'package:revelationsai/src/providers/chat/pages.dart';
import 'package:revelationsai/src/utils/build_context_extensions.dart';
import 'package:revelationsai/src/widgets/chat/create_dialog.dart';
import 'package:revelationsai/src/widgets/refresh_indicator.dart';

class ChatModal extends HookConsumerWidget {
  static const _pageSize = 9;

  final String? activeId;

  const ChatModal({
    super.key,
    this.activeId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchTextFocusNode = useFocusNode();
    final searchTextController = useTextEditingController();
    final searchText = useState('');

    final watchedChatsPages = ref.watch(chatsPagesProvider(
      pageSize: _pageSize,
      queryString: searchText.value,
    ));
    final chatsPagesNotifier = ref.watch(chatsPagesProvider(
      pageSize: _pageSize,
      queryString: searchText.value,
    ).notifier);

    final chatsPages = useState(watchedChatsPages.value ?? []);
    useEffect(() {
      chatsPages.value = watchedChatsPages.value ?? chatsPages.value;
      return () {};
    }, [watchedChatsPages.value]);

    useEffect(() {
      chatsPagesNotifier.refresh();
      return () {};
    }, []);

    useEffect(() {
      void closure() {
        searchText.value = searchTextController.text;
      }

      searchTextController.addListener(closure);
      return () {
        searchTextController.removeListener(closure);
      };
    }, [searchTextController]);

    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        color: context.colorScheme.background,
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
              color: context.primaryColor,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'All chats',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: context.colorScheme.onPrimary,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    children: [
                      IconButton(
                        color: context.colorScheme.onPrimary,
                        onPressed: () {
                          showDialog(
                            barrierDismissible: false,
                            context: context,
                            builder: (context) {
                              return const CreateDialog();
                            },
                          );
                        },
                        icon: const Icon(
                          CupertinoIcons.add,
                        ),
                      ),
                      IconButton(
                        color: context.colorScheme.onPrimary,
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        icon: const Icon(
                          Icons.close,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: TextField(
                      focusNode: searchTextFocusNode,
                      controller: searchTextController,
                      onTapOutside: (event) {
                        searchTextFocusNode.unfocus();
                      },
                      onSubmitted: (value) {
                        searchTextFocusNode.unfocus();
                      },
                      textInputAction: TextInputAction.search,
                      keyboardType: TextInputType.text,
                      decoration: InputDecoration(
                        hintText: 'Search',
                        filled: true,
                        fillColor: context.colorScheme.onBackground.withOpacity(0.1),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: context.colorScheme.onBackground.withOpacity(0.2),
                          ),
                        ),
                        prefixIcon: const Icon(
                          CupertinoIcons.search,
                          size: 18,
                        ),
                        suffixIcon: searchText.value.isNotEmpty
                            ? IconButton(
                                onPressed: () {
                                  searchTextController.clear();
                                },
                                icon: const Icon(
                                  CupertinoIcons.clear_circled_solid,
                                  size: 18,
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (chatsPagesNotifier.isLoadingInitial() && chatsPages.value.isEmpty) ...[
            Expanded(
              child: Center(
                child: SpinKitSpinningLines(
                  color: context.colorScheme.onBackground,
                  size: 32,
                ),
              ),
            )
          ] else ...[
            Expanded(
              child: RAIRefreshIndicator(
                onRefresh: () async {
                  await ref
                      .read(chatsPagesProvider(
                        pageSize: _pageSize,
                        queryString: searchText.value,
                      ).notifier)
                      .refresh();
                },
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: chatsPages.value.expand((element) => element).toList().length + 1,
                  itemBuilder: (listItemContext, index) {
                    if (index == chatsPages.value.expand((element) => element).toList().length) {
                      return chatsPagesNotifier.hasNextPage()
                          ? Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: ElevatedButton(
                                onPressed: () {
                                  if (chatsPagesNotifier.isLoadingNextPage()) {
                                    return;
                                  }
                                  chatsPagesNotifier.fetchNextPage();
                                },
                                child: chatsPagesNotifier.isLoadingNextPage()
                                    ? SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: SpinKitSpinningLines(
                                          color: context.secondaryColor,
                                          size: 20,
                                        ),
                                      )
                                    : const Text('Show More'),
                              ),
                            )
                          : const SizedBox();
                    }

                    final chatsFlat = chatsPages.value.expand((element) => element).toList();
                    final chat = chatsFlat[index];
                    return ChatListItem(
                      key: ValueKey(chat.id),
                      chat: chat,
                      searchQuery: searchText.value,
                      activeId: activeId,
                    );
                  },
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class ChatListItem extends HookConsumerWidget {
  final Chat chat;
  final String? searchQuery;
  final String? activeId;

  const ChatListItem({
    super.key,
    required this.chat,
    this.searchQuery,
    this.activeId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: ValueKey(chat.id),
      background: Container(
        color: context.colorScheme.error,
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Icon(
              Icons.delete,
              color: Colors.white,
            ),
            SizedBox(
              width: 20,
            ),
          ],
        ),
      ),
      direction: DismissDirection.endToStart,
      dismissThresholds: const {
        DismissDirection.endToStart: 0.5,
      },
      confirmDismiss: (direction) {
        return showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Delete Chat'),
              content: const Text('Are you sure you want to delete this chat?'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                  child: const Text('Delete'),
                ),
              ],
            );
          },
        );
      },
      onDismissed: (direction) {
        ref
            .read(chatsPagesProvider(
              pageSize: ChatModal._pageSize,
              queryString: searchQuery,
            ).notifier)
            .deleteChat(chat.id);
        if (activeId == chat.id) {
          ref.read(currentChatIdProvider.notifier).update(null);
          context.go('/chat/history');
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: activeId == chat.id ? context.secondaryColor.withOpacity(0.2) : Colors.transparent,
        ),
        child: ListTile(
          dense: true,
          visualDensity: VisualDensity.compact,
          title: Text(
            chat.name,
            softWrap: true,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            DateFormat.yMMMd().addPattern(DateFormat.HOUR_MINUTE).format(chat.updatedAt.toLocal()),
          ),
          trailing: activeId == chat.id
              ? Icon(
                  Icons.check,
                  color: context.secondaryColor,
                )
              : null,
          onTap: () {
            context.go(
              '/chat/${chat.id}',
            );
          },
        ),
      ),
    );
  }
}
