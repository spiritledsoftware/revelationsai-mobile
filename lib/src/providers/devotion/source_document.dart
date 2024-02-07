import 'package:revelationsai/src/models/source_document.dart';
import 'package:revelationsai/src/providers/devotion/latest.dart';
import 'package:revelationsai/src/providers/devotion/repositories.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'source_document.g.dart';

@riverpod
class DevotionSourceDocuments extends _$DevotionSourceDocuments {
  @override
  FutureOr<List<SourceDocument>> build(String? id) async {
    id ??= await ref.watch(latestDevotionProvider.future).then((devotion) => devotion.id);
    return ref.devotionSourceDocuments.getByDevotionId(id!);
  }

  Future<List<SourceDocument>> refresh() async {
    id ??= await ref.read(latestDevotionProvider.notifier).refresh().then((devotion) => devotion.id);
    final sourceDocs = await ref.devotionSourceDocuments.refreshByDevotionId(id!);
    state = AsyncData(sourceDocs);
    return sourceDocs;
  }
}
