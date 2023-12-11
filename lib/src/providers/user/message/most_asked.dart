import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:revelationsai/src/constants/api.dart';
import 'package:revelationsai/src/utils/http_helpers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'most_asked.g.dart';

@Riverpod(keepAlive: true)
Future<List<String>> mostAskedUserMessages(MostAskedUserMessagesRef ref, int count) async {
  final response = await http.get(Uri.parse("${API.url}/user-messages/most-asked?count=$count"));
  if (!response.ok) {
    throw response.exception;
  }

  final data = jsonDecode(utf8.decode(response.bodyBytes));
  return List<String>.from(data);
}
