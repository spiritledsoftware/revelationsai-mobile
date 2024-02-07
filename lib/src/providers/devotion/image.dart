import 'package:revelationsai/src/models/devotion/image.dart';
import 'package:revelationsai/src/providers/devotion/latest.dart';
import 'package:revelationsai/src/providers/devotion/repositories.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'image.g.dart';

@riverpod
class DevotionImages extends _$DevotionImages {
  @override
  FutureOr<List<DevotionImage>> build(String? id) async {
    id ??= await ref.watch(latestDevotionProvider.future).then((devotion) => devotion.id);
    return await ref.devotionImages.getByDevotionId(id!);
  }

  Future<List<DevotionImage>> refresh() async {
    id ??= await ref.read(latestDevotionProvider.notifier).refresh().then((devotion) => devotion.id);
    final images = await ref.devotionImages.refreshByDevotionId(id!);
    state = AsyncData(images);
    return images;
  }
}
