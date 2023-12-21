import 'dart:convert';

import 'package:http/http.dart';
import 'package:revelationsai/src/models/chat/message.dart';
import 'package:revelationsai/src/models/pagination.dart';
import 'package:revelationsai/src/utils/http_helpers.dart';

import '../constants/api.dart';
import '../models/chat.dart';

class ChatService {
  static Future<PaginatedEntitiesResponseData<Chat>> getChats({
    PaginatedEntitiesRequestOptions? paginationOptions,
    required String session,
  }) async {
    paginationOptions ??= PaginatedEntitiesRequestOptions.defaults();
    Response res = await get(
      Uri.parse('${API.url}/chats?${paginationOptions.searchQuery}'),
      headers: <String, String>{
        'Authorization': 'Bearer $session',
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    if (!res.ok) {
      throw res.exception;
    }

    final data = jsonDecode(utf8.decode(res.bodyBytes));
    return PaginatedEntitiesResponseData.fromJson(data, (json) {
      return Chat.fromJson(json as Map<String, dynamic>);
    });
  }

  static Future<Chat> getChat({
    required String id,
    required String session,
  }) async {
    Response res = await get(
      Uri.parse('${API.url}/chats/$id'),
      headers: <String, String>{
        'Authorization': 'Bearer $session',
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    if (!res.ok) {
      throw res.exception;
    }

    final data = jsonDecode(utf8.decode(res.bodyBytes));
    return Chat.fromJson(data);
  }

  static Future<Chat> createChat({
    required String session,
    required CreateChatRequest request,
  }) async {
    Response res = await post(
      Uri.parse('${API.url}/chats'),
      headers: <String, String>{
        'Authorization': 'Bearer $session',
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(request.toJson()),
    );

    if (!res.ok) {
      throw res.exception;
    }

    final data = jsonDecode(utf8.decode(res.bodyBytes));
    return Chat.fromJson(data);
  }

  static Future<Chat> updateChat({
    required String session,
    required String id,
    required UpdateChatRequest request,
  }) async {
    Response res = await put(
      Uri.parse('${API.url}/chats/$id'),
      headers: <String, String>{
        'Authorization': 'Bearer $session',
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(request.toJson()),
    );

    if (!res.ok) {
      throw res.exception;
    }

    final data = jsonDecode(utf8.decode(res.bodyBytes));
    return Chat.fromJson(data);
  }

  static Future<void> deleteChat({
    required String session,
    required String id,
  }) async {
    Response res = await delete(
      Uri.parse('${API.url}/chats/$id'),
      headers: <String, String>{
        'Authorization': 'Bearer $session',
      },
    );

    if (!res.ok) {
      throw res.exception;
    }
  }

  static Future<PaginatedEntitiesResponseData<ChatMessage>> getChatMessages({
    required String session,
    required String chatId,
    PaginatedEntitiesRequestOptions? paginationOptions,
  }) async {
    paginationOptions ??= PaginatedEntitiesRequestOptions(page: 1, limit: 10);
    Response res = await get(
      Uri.parse('${API.url}/chats/$chatId/messages?${paginationOptions.searchQuery}'),
      headers: <String, String>{
        'Authorization': 'Bearer $session',
      },
    );

    if (!res.ok) {
      throw res.exception;
    }

    final data = jsonDecode(utf8.decode(res.bodyBytes));
    return PaginatedEntitiesResponseData.fromJson(data, (json) {
      return ChatMessage.fromJson(json as Map<String, dynamic>);
    });
  }
}
