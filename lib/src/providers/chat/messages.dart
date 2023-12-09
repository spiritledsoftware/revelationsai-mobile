import 'package:revelationsai/src/models/chat/message.dart';
import 'package:revelationsai/src/models/pagination.dart';
import 'package:revelationsai/src/providers/chat/repositories.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'messages.g.dart';

@Riverpod(keepAlive: true)
class ChatMessages extends _$ChatMessages {
  static const int pageSize = 20;

  int _page = 1;
  bool _isLoadingInitial = true;
  bool _isLoadingNextPage = false;

  @override
  FutureOr<List<List<ChatMessage>>> build(String? chatId) async {
    _loadingLogic();

    if (chatId == null) {
      return [<ChatMessage>[]];
    }

    return await ref.chatMessages
        .getPageByChatId(chatId, PaginatedEntitiesRequestOptions(page: _page, limit: pageSize))
        .then((value) {
      if (state.hasValue) {
        // replace pages previous content with new content
        return [
          ...state.value!.sublist(0, _page - 1),
          value,
          if (state.value!.length > _page + 1) ...state.value!.sublist(_page + 1, state.value!.length),
        ];
      } else {
        return [
          value,
        ];
      }
    });
  }

  bool hasNextPage() {
    return (state.value?.last.length ?? 0) >= pageSize;
  }

  Future<List<ChatMessage>> fetchNextPage() async {
    _page++;
    ref.invalidateSelf();
    return await future.then((value) => value.last);
  }

  Future<void> reset() async {
    _page = 1;
    state = AsyncData([state.value?.first ?? []]);
    ref.invalidateSelf();
    await future;
  }

  Future<List<List<ChatMessage>>> refresh() async {
    if (chatId == null) {
      final messages = [<ChatMessage>[]];
      state = AsyncData(messages);
      return messages;
    }
    final futures = <Future<List<ChatMessage>>>[];
    for (int i = 1; i <= _page; i++) {
      futures.add(
        ref.chatMessages.refreshPageByChatId(
          chatId!,
          PaginatedEntitiesRequestOptions(
            page: i,
            limit: pageSize,
          ),
        ),
      );
    }
    return await Future.wait(futures).then((value) async {
      state = AsyncData(value);
      return value;
    });
  }

  bool isLoadingInitial() {
    return _isLoadingInitial;
  }

  bool isLoadingNextPage() {
    return _isLoadingNextPage;
  }

  void _loadingLogic() {
    ref.listenSelf((_, __) {
      if (!state.isLoading) {
        _isLoadingInitial = false;
        _isLoadingNextPage = false;
      } else if (state.isLoading && _page == 1 && (!state.hasValue || state.value!.isEmpty)) {
        _isLoadingInitial = true;
      } else if (state.isLoading && _page > 1) {
        _isLoadingNextPage = true;
      } else {
        _isLoadingInitial = false;
        _isLoadingNextPage = false;
      }
    });
  }
}
