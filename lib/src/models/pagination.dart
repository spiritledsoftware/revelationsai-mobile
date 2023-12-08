import 'package:freezed_annotation/freezed_annotation.dart';

part 'pagination.freezed.dart';
part 'pagination.g.dart';

enum OrderType {
  asc,
  desc,
}

@freezed
class PaginatedEntitiesRequestOptions with _$PaginatedEntitiesRequestOptions {
  const PaginatedEntitiesRequestOptions._();

  factory PaginatedEntitiesRequestOptions({
    required int page,
    required int limit,
    @Default("createdAt") String orderBy,
    @Default(OrderType.desc) OrderType order,
  }) = _PaginatedEntitiesRequestOptions;

  factory PaginatedEntitiesRequestOptions.defaults() => PaginatedEntitiesRequestOptions(
        page: 1,
        limit: 25,
        orderBy: 'createdAt',
        order: OrderType.desc,
      );

  String get searchQuery {
    return <String>[
      'page=$page',
      'limit=$limit',
      'orderBy=$orderBy',
      'order=${order.toString().split('.').last}',
    ].join('&');
  }

  factory PaginatedEntitiesRequestOptions.fromJson(Map<String, dynamic> json) =>
      _$PaginatedEntitiesRequestOptionsFromJson(json);
}

@Freezed(genericArgumentFactories: true)
class PaginatedEntitiesResponse<T> with _$PaginatedEntitiesResponse<T> {
  const PaginatedEntitiesResponse._();

  factory PaginatedEntitiesResponse.data({
    required int page,
    required int perPage,
    required List<T> entities,
  }) = PaginatedEntitiesResponseData;

  factory PaginatedEntitiesResponse.error({
    required String error,
  }) = PaginatedEntitiesResponseError;

  factory PaginatedEntitiesResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) =>
      _$PaginatedEntitiesResponseFromJson(json, fromJsonT);
}
