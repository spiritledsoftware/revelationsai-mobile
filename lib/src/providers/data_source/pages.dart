import 'package:revelationsai/src/models/data_source.dart';
import 'package:revelationsai/src/models/pagination.dart';
import 'package:revelationsai/src/providers/data_source/repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'pages.g.dart';

@riverpod
class DataSourcesPages extends _$DataSourcesPages {
  int _page = 1;
  bool _isLoadingInitial = true;
  bool _isLoadingNextPage = false;

  @override
  FutureOr<List<List<DataSource>>> build({
    int pageSize = 10,
  }) async {
    _loadingLogic();

    return await ref.dataSources.getPage(PaginatedEntitiesRequestOptions(page: _page, limit: pageSize)).then((value) {
      return _insertPageIntoState(value);
    });
  }

  List<List<DataSource>> _insertPageIntoState(List<DataSource> dataSources) {
    final previousState = state;
    if (previousState.hasValue) {
      if (previousState.value!.length >= _page) {
        previousState.value!.removeAt(_page - 1);
      }
      return previousState.value!
        ..insert(
          _page - 1,
          dataSources,
        );
    } else {
      return [
        dataSources,
      ];
    }
  }

  bool hasNextPage() {
    return (state.value?.last.length ?? 0) >= pageSize;
  }

  Future<void> fetchNextPage() async {
    try {
      _page++;
      ref.invalidateSelf();
      await future;
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

  Future<List<List<DataSource>>> refresh() async {
    final futures = <Future<List<DataSource>>>[];
    for (int i = 1; i <= _page; i++) {
      futures.add(ref.dataSources.getPage(
        PaginatedEntitiesRequestOptions(page: i, limit: pageSize),
      ));
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
