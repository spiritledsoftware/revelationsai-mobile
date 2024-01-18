import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:revelationsai/src/constants/api.dart';
import 'package:revelationsai/src/models/data_source.dart';
import 'package:revelationsai/src/models/pagination.dart';
import 'package:revelationsai/src/models/search.dart';
import 'package:revelationsai/src/utils/http_helpers.dart';

class DataSourceService {
  static Future<PaginatedEntitiesResponseData<DataSource>> getDataSources({
    PaginatedEntitiesRequestOptions? options,
    required String session,
  }) async {
    options ??= PaginatedEntitiesRequestOptions.defaults();
    final response = await http.get(
      Uri.parse('${API.url}/data-sources?${options.searchQuery}'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $session',
      },
    );

    if (!response.ok) {
      throw response.exception;
    }

    final data = jsonDecode(utf8.decode(response.bodyBytes));

    return PaginatedEntitiesResponseData.fromJson(data, (json) {
      return DataSource.fromJson(json as Map<String, dynamic>);
    });
  }

  static Future<PaginatedEntitiesResponseData<DataSource>> searchForDataSources({
    PaginatedEntitiesRequestOptions? paginationOptions,
    Query? query,
    required String session,
  }) async {
    query ??= Query();
    paginationOptions ??= PaginatedEntitiesRequestOptions.defaults();
    http.Response res = await http.post(
      Uri.parse('${API.url}/data-sources/search?${paginationOptions.searchQuery}'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(query.toJson()),
    );

    if (!res.ok) {
      throw res.exception;
    }

    final data = jsonDecode(utf8.decode(res.bodyBytes));
    return PaginatedEntitiesResponseData.fromJson(data, (json) {
      return DataSource.fromJson(json as Map<String, dynamic>);
    });
  }

  static Future<DataSource> getDataSource(String id, {required String session}) async {
    final response = await http.get(
      Uri.parse('${API.url}/data-sources/$id'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $session',
      },
    );

    if (!response.ok) {
      throw response.exception;
    }

    final data = jsonDecode(utf8.decode(response.bodyBytes));

    return DataSource.fromJson(data);
  }
}
