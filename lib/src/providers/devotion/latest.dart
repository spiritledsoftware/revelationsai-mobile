import 'package:revelationsai/src/models/devotion.dart';
import 'package:revelationsai/src/providers/devotion/pages.dart';
import 'package:revelationsai/src/providers/devotion/repositories.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'latest.g.dart';

@riverpod
class LatestDevotion extends _$LatestDevotion {
  late String _id;

  @override
  FutureOr<Devotion> build() async {
    _id = await ref.watch(devotionsPagesProvider.selectAsync((data) => data.first.first.id));
    return await ref.devotions.get(_id);
  }

  Future<Devotion> refresh() async {
    final devotions = await ref.read(devotionsPagesProvider.notifier).refresh();
    final devotion = devotions.first.first;
    state = AsyncData(devotion);
    _id = devotion.id;
    return devotion;
  }
}
