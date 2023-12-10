import 'package:flutter/material.dart';
import 'package:revelationsai/src/models/chat.dart';
import 'package:revelationsai/src/models/pagination.dart';
import 'package:revelationsai/src/providers/chat/repositories.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'pages.g.dart';

@Riverpod(keepAlive: true)
class ChatsPages extends _$ChatsPages {
  static const int pageSize = 7;

  int _page = 1;
  bool _isLoadingInitial = true;
  bool _isLoadingNextPage = false;

  @override
  FutureOr<List<List<Chat>>> build() async {
    _loadingLogic();

    return await ref.chats.getPageLocal(_getPaginationOptions()).then((value) {
      if (value.length < pageSize) {
        ref.chats.getPageRemote(_getPaginationOptions()).then((value) {
          state = AsyncData(_insertPageIntoState(value, replace: true));
        });
      }
      return _insertPageIntoState(value);
    });
  }

  List<List<Chat>> _insertPageIntoState(List<Chat> chats, {bool replace = false}) {
    final previousState = state;
    if (previousState.hasValue) {
      if (replace) {
        previousState.value!.removeAt(_page - 1);
      }
      return previousState.value!
        ..insert(
          _page - 1,
          chats,
        );
    } else {
      return [
        chats,
      ];
    }
  }

  PaginatedEntitiesRequestOptions _getPaginationOptions() {
    return PaginatedEntitiesRequestOptions(
      page: _page,
      limit: pageSize,
      orderBy: "updatedAt",
      order: OrderType.desc,
    );
  }

  bool hasNextPage() {
    return (state.value?.last.length ?? 0) >= pageSize;
  }

  Future<void> fetchNextPage() async {
    try {
      _page++;
      ref.invalidateSelf();
      await future;
    } catch (error) {
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

  Future<void> deleteChat(String chatId) async {
    final previousState = state;
    state = AsyncValue.data(state.value
            ?.map(
              (page) => page.where((chat) => chat.id != chatId).toList(),
            )
            .toList() ??
        []);
    return await ref.chats.deleteRemote(chatId).catchError((error) {
      debugPrint("Failed to delete chat: $error");
      state = previousState;
      throw error;
    });
  }

  Future<List<List<Chat>>> refresh() async {
    final futures = <Future<List<Chat>>>[];
    for (int i = 1; i <= _page; i++) {
      futures.add(ref.chats.getPageRemote(PaginatedEntitiesRequestOptions(
        page: i,
        limit: pageSize,
        orderBy: "updatedAt",
        order: OrderType.desc,
      )));
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
