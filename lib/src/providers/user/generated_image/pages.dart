import 'package:flutter/material.dart';
import 'package:revelationsai/src/models/pagination.dart';
import 'package:revelationsai/src/models/user/generated_image.dart';
import 'package:revelationsai/src/providers/user/generated_image/repositories.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'pages.g.dart';

@Riverpod(keepAlive: true)
class UserGeneratedImagesPages extends _$UserGeneratedImagesPages {
  static const int pageSize = 15;

  int _page = 1;
  bool _isLoadingInitial = true;
  bool _isLoadingNextPage = false;

  @override
  FutureOr<List<List<UserGeneratedImage>>> build() async {
    _loadingLogic();
    _persistenceLogic();

    return await ref.userGeneratedImages.getPage(_getPaginationOptions()).then((value) {
      if (value.length < pageSize) {
        ref.userGeneratedImages.refreshPage(_getPaginationOptions()).then((value) {
          state = AsyncData(_insertPageIntoState(value));
        });
      }
      return _insertPageIntoState(value);
    });
  }

  List<List<UserGeneratedImage>> _insertPageIntoState(List<UserGeneratedImage> userGeneratedImages) {
    final previousState = state;
    if (previousState.hasValue) {
      if (previousState.value!.length >= _page) {
        previousState.value!.removeAt(_page - 1);
      }
      return previousState.value!
        ..insert(
          _page - 1,
          userGeneratedImages,
        );
    } else {
      return [
        userGeneratedImages,
      ];
    }
  }

  PaginatedEntitiesRequestOptions _getPaginationOptions() {
    return PaginatedEntitiesRequestOptions(
      page: _page,
      limit: pageSize,
    );
  }

  bool hasNextPage() {
    return (state.value?.last.length ?? 0) >= pageSize;
  }

  Future<void> fetchNextPage() async {
    _page++;
    ref.invalidateSelf();
    await future;
  }

  Future<void> reset() async {
    _page = 1;
    state = AsyncData([state.value?.first ?? []]);
    ref.invalidateSelf();
    await future;
  }

  Future<void> deleteImage(String userGeneratedImageId) async {
    final previousState = state;
    state = AsyncValue.data(state.value
            ?.map(
              (page) => page.where((userGeneratedImage) => userGeneratedImage.id != userGeneratedImageId).toList(),
            )
            .toList() ??
        []);
    return await ref.userGeneratedImages.deleteRemote(userGeneratedImageId).catchError((error) {
      debugPrint("Failed to delete userGeneratedImage: $error");
      state = previousState;
      throw error;
    });
  }

  Future<List<List<UserGeneratedImage>>> refresh() async {
    final futures = <Future<List<UserGeneratedImage>>>[];
    for (int i = 1; i <= _page; i++) {
      futures.add(ref.userGeneratedImages.refreshPage(
        PaginatedEntitiesRequestOptions(page: i, limit: pageSize),
      ));
    }
    return await Future.wait(futures).then((value) async {
      state = AsyncData(value);
      ref.userGeneratedImages.deleteAllLocal().then((_) {
        ref.userGeneratedImages.saveMany(value.expand((element) => element).toList());
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
        await ref.userGeneratedImages.deleteAllLocal();
        await ref.userGeneratedImages.saveMany(next.value!.expand((element) => element).toList());
      }
    });
  }
}
