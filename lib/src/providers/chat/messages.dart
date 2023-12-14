import 'package:flutter/foundation.dart';
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
    _persistenceLogic();

    if (chatId == null) {
      return [<ChatMessage>[]];
    }

    return await ref.chatMessages.getPageByChatId(chatId, _getPaginationOptions()).then((value) {
      if (value.length < pageSize) {
        ref.chatMessages.refreshPageByChatId(chatId, _getPaginationOptions()).then((value) {
          state = AsyncData(_insertPageIntoState(value));
        });
      }
      return _insertPageIntoState(value);
    });
  }

  PaginatedEntitiesRequestOptions _getPaginationOptions() {
    return PaginatedEntitiesRequestOptions(
      page: _page,
      limit: pageSize,
      orderBy: "createdAt",
      order: OrderType.desc,
    );
  }

  List<List<ChatMessage>> _insertPageIntoState(List<ChatMessage> messages) {
    final previousState = state;
    if (previousState.hasValue) {
      debugPrint("Inserting page $_page into state at index ${previousState.value!.length - _page}");
      if (previousState.value!.length >= _page) {
        debugPrint("Removing page index ${previousState.value!.length - _page}");
        previousState.value!.removeAt(previousState.value!.length - _page);
      }
      return previousState.value!
        ..insert(
          0,
          messages,
        );
    } else {
      return [
        messages,
      ];
    }
  }

  bool hasNextPage() {
    return (state.value?.firstOrNull?.length ?? 0) >= pageSize;
  }

  Future<List<ChatMessage>> fetchNextPage() async {
    try {
      _page++;
      ref.invalidateSelf();
      return await future.then((value) => value.last);
    } catch (e) {
      _page--;
      rethrow;
    }
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
    for (int i = _page; i >= 1; i--) {
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

  void _persistenceLogic() {
    ref.listenSelf((prev, next) async {
      if (next.hasValue && next.value != prev?.value) {
        await ref.chatMessages.deleteAllLocal();
        await ref.chatMessages.saveMany(next.value!.expand((element) => element).toList());
      }
    });
  }
}
