import 'package:revelationsai/src/models/devotion.dart';
import 'package:revelationsai/src/models/pagination.dart';
import 'package:revelationsai/src/providers/devotion/repositories.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'pages.g.dart';

@Riverpod(keepAlive: true)
class DevotionsPages extends _$DevotionsPages {
  static const int pageSize = 7;

  int _page = 1;
  bool _isLoadingInitial = true;
  final bool _isLoading = false;
  bool _isLoadingNextPage = false;

  @override
  FutureOr<List<List<Devotion>>> build() async {
    _loadingLogic();

    return await ref.devotions.getPageLocal(_getPaginationOptions()).then((value) {
      if (value.length < pageSize) {
        ref.devotions.getPageRemote(_getPaginationOptions()).then((value) {
          state = AsyncData(_insertPageIntoState(value, replace: true));
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

  List<List<Devotion>> _insertPageIntoState(List<Devotion> devotions, {bool replace = false}) {
    final previousState = state;
    if (previousState.hasValue) {
      if (replace) {
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
      futures.add(ref.devotions.getPageRemote(PaginatedEntitiesRequestOptions(
        page: i,
        limit: pageSize,
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

  bool isLoading() {
    return _isLoading;
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
