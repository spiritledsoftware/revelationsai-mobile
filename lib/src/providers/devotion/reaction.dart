import 'package:revelationsai/src/models/devotion/reaction.dart';
import 'package:revelationsai/src/providers/devotion/latest.dart';
import 'package:revelationsai/src/providers/devotion/reaction_count.dart';
import 'package:revelationsai/src/providers/devotion/repositories.dart';
import 'package:revelationsai/src/providers/user/current.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

part 'reaction.g.dart';

@riverpod
class DevotionReactions extends _$DevotionReactions {
  @override
  FutureOr<List<DevotionReaction>> build(String? id) async {
    id ??= await ref.watch(latestDevotionProvider.future).then((devotion) => devotion.id);
    return await ref.devotionReactions.getByDevotionId(id!);
  }

  Future<void> createReaction({
    required DevotionReactionType reactionType,
    String? comment,
  }) async {
    if (id == null) {
      throw Exception('Devotion ID is not set');
    }

    final previousState = state;

    final reaction = DevotionReaction(
      id: const Uuid().v4(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      devotionId: id!,
      userId: ref.read(currentUserProvider).requireValue.id,
      reaction: reactionType,
    );

    state = AsyncData([
      if (state.hasValue) ...state.requireValue,
      reaction,
    ]);

    return await ref.devotionReactions.createForDevotionId(id!, reactionType, comment: comment).then(
      (value) {
        refresh();
        ref.read(devotionReactionCountsProvider(id).notifier).increment(reactionType);
      },
    ).catchError(
      (error) {
        state = previousState;
        throw error;
      },
    );
  }

  Future<List<DevotionReaction>> refresh() async {
    id ??= await ref.read(latestDevotionProvider.notifier).refresh().then((devotion) => devotion.id);
    final reactions = await ref.devotionReactions.refreshByDevotionId(id!);
    state = AsyncData(reactions);
    return reactions;
  }
}
