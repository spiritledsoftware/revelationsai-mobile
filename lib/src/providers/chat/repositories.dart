import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:revelationsai/src/models/chat.dart';
import 'package:revelationsai/src/models/chat/message.dart';
import 'package:revelationsai/src/models/pagination.dart';
import 'package:revelationsai/src/models/search.dart' as search;
import 'package:revelationsai/src/providers/isar.dart';
import 'package:revelationsai/src/providers/user/current.dart';
import 'package:revelationsai/src/services/chat.dart';
import 'package:revelationsai/src/utils/isar.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'repositories.g.dart';

@Riverpod(keepAlive: true)
Future<ChatRepository> chatRepository(ChatRepositoryRef ref) async {
  final isar = await ref.watch(isarInstanceProvider.future);
  final session = await ref.watch(currentUserProvider.selectAsync((data) => data.session));
  return ChatRepository(isar, session);
}

class ChatRepository {
  final Isar _isar;
  final String _session;

  ChatRepository(this._isar, this._session);

  Future<bool> _hasLocal(String id) async {
    final chat = await _isar.chats.get(fastHash(id));
    return chat != null;
  }

  Future<Chat?> getChat(String id) async {
    if (await _hasLocal(id)) {
      return await _getLocal(id);
    }
    return await _fetch(id);
  }

  Future<Chat> refresh(String id) async {
    return await _fetch(id);
  }

  Future<Chat?> _getLocal(String id) async {
    return await _isar.chats.get(fastHash(id));
  }

  Future<Chat> _fetch(String id) async {
    return await ChatService.getChat(id: id, session: _session).then((value) async {
      await save(value);
      return value;
    });
  }

  Future<Chat> create(CreateChatRequest request) async {
    return await ChatService.createChat(request: request, session: _session).then((value) async {
      await save(value);
      return value;
    });
  }

  Future<Chat> update(String id, UpdateChatRequest request) async {
    return await ChatService.updateChat(id: id, request: request, session: _session).then((value) async {
      await save(value);
      return value;
    });
  }

  Future<List<int>> saveMany(List<Chat> chats) async {
    return await _isar.writeTxn(() => _isar.chats.putAll(chats));
  }

  Future<int> save(Chat chat) async {
    return await _isar.writeTxn(() => _isar.chats.put(chat));
  }

  Future<void> deleteRemote(String id) async {
    return await ChatService.deleteChat(id: id, session: _session).then((value) async {
      if (await _hasLocal(id)) {
        await deleteLocal(id);
      }
      return value;
    });
  }

  Future<void> deleteLocal(String id) async {
    await _isar.writeTxn(() => _isar.chats.delete(fastHash(id)));
  }

  Future<void> deleteManyLocal(List<String> ids) async {
    await _isar.writeTxn(() => _isar.chats.deleteAll(ids.map((e) => fastHash(e)).toList()));
  }

  Future<void> deleteAllLocal() async {
    await _isar.writeTxn(() async => _isar.chats
        .deleteAll(await _isar.chats.where().findAll().then((value) => value.map((e) => e.isarId).toList())));
  }

  Future<List<Chat>> getAllLocal() async {
    return await _isar.chats.where().findAll();
  }

  QueryBuilder<Chat, Chat, QAfterSortBy> _queryBuilderForPageOptions(
    PaginatedEntitiesRequestOptions options,
    String? queryString,
  ) {
    final chats = _isar.chats;
    if (queryString != null && queryString.isNotEmpty) {
      final filter = chats.filter().nameContains(queryString, caseSensitive: false);
      switch (options.orderBy) {
        case "name":
          if (options.order == OrderType.desc) {
            return filter.sortByNameDesc();
          }
          return filter.sortByName();
        case "createdAt":
          if (options.order == OrderType.desc) {
            return filter.sortByCreatedAtDesc();
          }
          return filter.sortByCreatedAt();
        case "updatedAt":
          if (options.order == OrderType.desc) {
            return filter.sortByUpdatedAtDesc();
          }
          return filter.sortByUpdatedAt();
        default:
          throw Exception("You cannot order by this field: ${options.orderBy}");
      }
    } else {
      final where = chats.where();
      switch (options.orderBy) {
        case "name":
          if (options.order == OrderType.desc) {
            return where.sortByNameDesc();
          }
          return where.sortByName();
        case "createdAt":
          if (options.order == OrderType.desc) {
            return where.sortByCreatedAtDesc();
          }
          return where.sortByCreatedAt();
        case "updatedAt":
          if (options.order == OrderType.desc) {
            return where.sortByUpdatedAtDesc();
          }
          return where.sortByUpdatedAt();
        default:
          throw Exception("You cannot order by this field: ${options.orderBy}");
      }
    }
  }

  Future<List<Chat>> getPage(
    PaginatedEntitiesRequestOptions options,
    String? queryString,
  ) async {
    final local = await _getPageLocal(options, queryString);
    if (local.isEmpty) {
      return await _getPageRemote(options, queryString);
    }
    return local;
  }

  Future<List<Chat>> refreshPage(
    PaginatedEntitiesRequestOptions options,
    String? queryString,
  ) async {
    return await _getPageRemote(
      options,
      queryString,
    );
  }

  Future<List<Chat>> _getPageLocal(
    PaginatedEntitiesRequestOptions options,
    String? queryString,
  ) async {
    return await _queryBuilderForPageOptions(
      options,
      queryString,
    ).offset((options.page - 1) * options.limit).limit(options.limit).findAll();
  }

  Future<List<Chat>> _getPageRemote(
    PaginatedEntitiesRequestOptions options,
    String? queryString,
  ) async {
    search.Query? query;
    if (queryString != null && queryString.isNotEmpty) {
      query = search.Query(
        iLike: search.ColumnPlaceHolder(
          column: "name",
          placeholder: "%$queryString%",
        ),
      );
    }
    return await ChatService.searchForChats(session: _session, query: query, paginationOptions: options)
        .then((value) async {
      await deleteManyLocal(await _getPageLocal(
        options,
        queryString,
      ).then((value) => value.map((e) => e.id).toList()));
      await saveMany(value.entities);
      return value.entities;
    });
  }
}

@Riverpod(keepAlive: true)
Future<ChatMessagesRepository> chatMessagesRepository(ChatMessagesRepositoryRef ref) async {
  final isar = await ref.watch(isarInstanceProvider.future);
  final session = await ref.watch(currentUserProvider.selectAsync((data) => data.session));
  return ChatMessagesRepository(isar, session);
}

class ChatMessagesRepository {
  final Isar _isar;
  final String _session;

  ChatMessagesRepository(
    Isar isar,
    String session,
  )   : _isar = isar,
        _session = session;

  Future<List<ChatMessage>> getAllLocal() async {
    return await _isar.chatMessages.where().findAll();
  }

  Future<List<ChatMessage>> getPageByChatId(
    String chatId,
    PaginatedEntitiesRequestOptions options,
  ) async {
    final local = await _getPageByChatIdLocal(chatId, options);
    if (local.isEmpty) {
      return await _getPageByChatIdRemote(chatId, options);
    }
    return local;
  }

  Future<List<ChatMessage>> refreshPageByChatId(
    String chatId,
    PaginatedEntitiesRequestOptions options,
  ) async {
    return await _getPageByChatIdRemote(chatId, options);
  }

  Future<List<ChatMessage>> _getPageByChatIdLocal(
    String chatId,
    PaginatedEntitiesRequestOptions options,
  ) async {
    return await _isar.chatMessages
        .where()
        .chatIdEqualTo(chatId)
        .sortByCreatedAtDesc()
        .thenByRoleDesc()
        .offset((options.page - 1) * options.limit)
        .limit(options.limit)
        .findAll()
        .then((value) => value.reversed.toList());
  }

  Future<List<ChatMessage>> _getPageByChatIdRemote(
    String chatId,
    PaginatedEntitiesRequestOptions options,
  ) async {
    return await ChatService.getChatMessages(
      session: _session,
      chatId: chatId,
      paginationOptions: options,
    ).then((value) => value.entities).then((value) => value.reversed.toList()).then((value) async {
      await deleteManyLocal(
          await _getPageByChatIdLocal(chatId, options).then((value) => value.map((e) => e.id).toList()));
      await saveMany(value.map((e) {
        return e.copyWith(
          chatId: chatId,
        );
      }).toList());
      return value;
    });
  }

  Future<bool> _hasLocalForChatId(String chatId) async {
    final messages = await _isar.chatMessages.where().chatIdEqualTo(chatId).findAll();
    return messages.isNotEmpty;
  }

  Future<List<ChatMessage>> getByChatId(String chatId) async {
    if (await _hasLocalForChatId(chatId)) {
      return await _getLocalByChatId(chatId);
    }

    return await _fetchByChatId(chatId);
  }

  Future<List<ChatMessage>> _getLocalByChatId(String chatId) async {
    return await _isar.chatMessages.where().chatIdEqualTo(chatId).sortByCreatedAt().thenByRole().findAll();
  }

  Future<List<ChatMessage>> _fetchByChatId(String chatId) async {
    return await ChatService.getChatMessages(
      session: _session,
      chatId: chatId,
    ).then((value) => value.entities).then((value) async {
      await deleteLocalByChatId(chatId);
      value = value.map((e) => e.copyWith(chatId: chatId)).toList();
      await saveMany(value);
      return value;
    });
  }

  Future<List<ChatMessage>> refreshByChatId(String chatId) async {
    return await _fetchByChatId(chatId);
  }

  Future<int> save(ChatMessage message) async {
    return await _isar.writeTxn(() => _isar.chatMessages.put(message));
  }

  Future<List<int>> saveMany(List<ChatMessage> messages) async {
    return await _isar.writeTxn(() async {
      return await _isar.chatMessages.putAll(messages);
    });
  }

  Future<void> deleteLocalByChatId(String chatId) async {
    if (await _hasLocalForChatId(chatId)) {
      await _isar.writeTxn(() async {
        final messages = await _isar.chatMessages.where().chatIdEqualTo(chatId).findAll();
        await _isar.chatMessages.deleteAll(messages.map((e) => e.isarId).toList());
      });
    }
  }

  Future<void> deleteManyLocal(List<String> messageIds) async {
    await _isar.writeTxn(() async {
      await _isar.chatMessages.deleteAll(messageIds.map((id) => fastHash(id)).toList());
    });
  }

  Future<void> deleteAllLocal() async {
    await _isar.writeTxn(() async =>
        _isar.chatMessages.deleteAll(await getAllLocal().then((value) => value.map((e) => e.isarId).toList())));
  }

  Future<void> deleteAllLocalByChatId(String chatId) async {
    await _isar.writeTxn(() async => _isar.chatMessages
        .deleteAll(await _getLocalByChatId(chatId).then((value) => value.map((e) => e.isarId).toList())));
  }
}

extension ChatRepositoryRefX on Ref {
  ChatRepository get chats => watch(chatRepositoryProvider).requireValue;
  ChatMessagesRepository get chatMessages => watch(chatMessagesRepositoryProvider).requireValue;
}

extension ChatRepositoryWidgetRefX on WidgetRef {
  ChatRepository get chats => watch(chatRepositoryProvider).requireValue;
  ChatMessagesRepository get chatMessages => watch(chatMessagesRepositoryProvider).requireValue;
}
