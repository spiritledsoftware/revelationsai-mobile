import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:revelationsai/src/constants/api.dart';
import 'package:revelationsai/src/models/model_info.dart';
import 'package:revelationsai/src/utils/http_helpers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'model_infos.g.dart';

@Riverpod(keepAlive: true)
FutureOr<Map<String, ModelInfo>> modelInfos(ModelInfosRef ref) async {
  final response = await http.get(Uri.parse("${API.url}/language-models"));

  if (!response.ok) {
    throw response.exception;
  }

  final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
  return data.map((key, value) => MapEntry(key, ModelInfo.fromJson(value)));
}
