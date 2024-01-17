import 'package:revelationsai/src/models/devotion.dart';
import 'package:revelationsai/src/models/pagination.dart';
import 'package:revelationsai/src/providers/devotion/repositories.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'pages.g.dart';

@Riverpod()
class DevotionsPages extends _$DevotionsPages {
  int _page = 1;
  bool _isLoadingInitial = true;
  bool _isLoadingNextPage = false;

  @override
  FutureOr<List<List<Devotion>>> build({
    int pageSize = 6,
    String? queryString,
  }) async {
    _loadingLogic();
    _persistenceLogic();

    return await ref.devotions.getPage(_getPaginationOptions(), queryString).then((value) {
      if (value.length < pageSize) {
        ref.devotions.refreshPage(_getPaginationOptions(), queryString).then((value) {
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
    );
  }

  List<List<Devotion>> _insertPageIntoState(List<Devotion> devotions) {
    final previousState = state;
    if (previousState.hasValue) {
      if (previousState.value!.length >= _page) {
        previousState.value!.removeAt(_page - 1);
      }
      return previousState.value!
        ..insert(
          _page - 1,
          devotions,
        );
    } else {
      return [
        devotions,
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

  Future<List<List<Devotion>>> refresh() async {
    final futures = <Future<List<Devotion>>>[];
    for (int i = 1; i <= _page; i++) {
      futures.add(
        ref.devotions.refreshPage(
          PaginatedEntitiesRequestOptions(
            page: i,
            limit: pageSize,
          ),
          queryString,
        ),
      );
    }
    return await Future.wait(futures).then((value) async {
      state = AsyncData(value);
      ref.devotions.deleteAllLocal().then((_) {
        ref.devotions.saveMany(value.expand((element) => element).toList());
      });
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
        await ref.devotions.deleteAllLocal();
        await ref.devotions.saveMany(next.value!.expand((element) => element).toList());
      }
    });
  }
}
