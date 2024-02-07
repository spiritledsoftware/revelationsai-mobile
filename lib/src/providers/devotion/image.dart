import 'package:revelationsai/src/models/devotion/image.dart';
import 'package:revelationsai/src/providers/devotion/pages.dart';
import 'package:revelationsai/src/providers/devotion/repositories.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'image.g.dart';

@riverpod
class DevotionImages extends _$DevotionImages {

	String? _id;

  @override
  FutureOr<List<DevotionImage>> build(String? devotionId) async {
    _id = devotionId ?? await ref.watch(devotionsPagesProvider().selectAsync((data) => data.first.first.id));
    return await ref.devotionImages.getByDevotionId(_id!);
  }

  Future<List<DevotionImage>> refresh() async {
		_id = devotionId ?? await ref.watch(devotionsPagesProvider().selectAsync((data) => data.first.first.id));
    final images = await ref.devotionImages.refreshByDevotionId(_id!);
    state = AsyncData(images);
    return images;
  }
}
