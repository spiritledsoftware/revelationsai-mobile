import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app_badger/flutter_app_badger.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:revelationsai/src/constants/visual_density.dart';
import 'package:revelationsai/src/models/devotion.dart';
import 'package:revelationsai/src/models/devotion/reaction.dart';
import 'package:revelationsai/src/models/source_document.dart';
import 'package:revelationsai/src/providers/devotion/current_id.dart';
import 'package:revelationsai/src/providers/devotion/image.dart';
import 'package:revelationsai/src/providers/devotion/pages.dart';
import 'package:revelationsai/src/providers/devotion/reaction.dart';
import 'package:revelationsai/src/providers/devotion/reaction_count.dart';
import 'package:revelationsai/src/providers/devotion/single.dart';
import 'package:revelationsai/src/providers/devotion/source_document.dart';
import 'package:revelationsai/src/utils/build_context_extensions.dart';
import 'package:revelationsai/src/utils/capitalization.dart';
import 'package:revelationsai/src/widgets/advertisement/native_ad.dart';
import 'package:revelationsai/src/widgets/colored_safe_area.dart';
import 'package:revelationsai/src/widgets/devotion/action_menu_button.dart';
import 'package:revelationsai/src/widgets/network_image.dart';
import 'package:revelationsai/src/widgets/refresh_indicator.dart';
import 'package:url_launcher/link.dart';

class DevotionScreen extends HookConsumerWidget {
  final String? devotionId;

  const DevotionScreen({
    super.key,
    this.devotionId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loading = useState(false);
    final devotion = useState<Devotion?>(null);
    final sourceDocs = useState<List<SourceDocument>>([]);
    final images = useState<List<DevotionImage>>([]);
    final reactionCounts = useState<Map<DevotionReactionType, int>>({});

    final advertisement = useRef(const NativeAdvertisement(
      padding: EdgeInsets.only(
        top: 20,
      ),
      type: TemplateType.medium,
    ));

    final fetchDevoData = useCallback((String? devoId) async {
      await Future.wait([
        ref.read(singleDevotionProvider(devoId).future),
        ref.read(devotionSourceDocumentsProvider(devoId).future),
        ref.read(devotionImagesProvider(devoId).future),
        ref.read(devotionReactionsProvider(devoId).future),
        ref.read(devotionReactionCountsProvider(devoId).future),
      ]).then((value) {
        final foundDevo = value[0] as Devotion;
        final foundSourceDocs = value[1] as List<SourceDocument>;
        final foundImages = value[2] as List<DevotionImage>;
        // final foundReactions = value[3] as List<DevotionReaction>;
        final foundReactionCounts = value[4] as Map<DevotionReactionType, int>;

        if (context.mounted) {
          devotion.value = foundDevo;
          sourceDocs.value = foundSourceDocs;
          images.value = foundImages;
          reactionCounts.value = foundReactionCounts;
        }
      });
    }, [ref, context.mounted]);

    final refreshDevoData = useCallback(() async {
      await Future.wait([
        ref.read(singleDevotionProvider(devotion.value?.id).notifier).refresh(),
        ref.read(devotionSourceDocumentsProvider(devotion.value?.id).notifier).refresh(),
        ref.read(devotionImagesProvider(devotion.value?.id).notifier).refresh(),
        ref.read(devotionReactionsProvider(devotion.value?.id).notifier).refresh(),
        ref.read(devotionReactionCountsProvider(devotion.value?.id).notifier).refresh(),
      ]).then((value) {
        final foundDevo = value[0] as Devotion;
        final foundSourceDocs = value[1] as List<SourceDocument>;
        final foundImages = value[2] as List<DevotionImage>;
        // final foundReactions = value[3] as List<DevotionReaction>;
        final foundReactionCounts = value[4] as Map<DevotionReactionType, int>;

        if (context.mounted) {
          devotion.value = foundDevo;
          sourceDocs.value = foundSourceDocs;
          images.value = foundImages;
          reactionCounts.value = foundReactionCounts;
        }
      });
    }, [ref, context.mounted]);

    useEffect(() {
      debugPrint("DevotionScreen: useEffect: devotionId: $devotionId");
      loading.value = true;
      fetchDevoData(devotionId).whenComplete(() async {
        if (context.mounted) {
          loading.value = false;
          await Future(() => refreshDevoData());
        }
      });
      return () {};
    }, [devotionId]);

    useEffect(() {
      final devo = devotion.value;
      if (devo != null) {
        Future(() {
          ref.read(currentDevotionIdProvider.notifier).updateId(devo.id);
        });
        ref.read(devotionsPagesProvider().future).then((value) {
          if (value.first.first.id == devo.id) {
            debugPrint("DevotionScreen: useEffect: User is viewing latest devo, resetting badge count");
            FlutterAppBadger.isAppBadgeSupported().then((value) {
              if (value) {
                FlutterAppBadger.updateBadgeCount(0);
              }
            });
          }
        });
      }
      return () {};
    }, [devotion.value]);

    return Scaffold(
      body: ColoredSafeArea(
        color: context.colorScheme.primary,
        overlayStyle: SystemUiOverlayStyle.light,
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                automaticallyImplyLeading: false,
                snap: true,
                floating: true,
                centerTitle: false,
                backgroundColor: context.colorScheme.primary,
                systemOverlayStyle: SystemUiOverlayStyle.light,
                title: loading.value || devotion.value == null
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text("Loading Devotion"),
                          const SizedBox(
                            width: 15,
                          ),
                          SpinKitSpinningLines(
                            color: context.appBarTheme.foregroundColor ?? context.colorScheme.onBackground,
                            size: 20,
                          )
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            devotion.value!.topic.toTitleCase(),
                          ),
                          Text(
                            DateFormat.yMd().format(devotion.value!.createdAt.toLocal()),
                            style: context.textTheme.labelLarge?.copyWith(
                              color: context.colorScheme.onPrimary,
                            ),
                          ),
                        ],
                      ),
                actions: [
                  DevotionActionMenuButton(
                    devotion: devotion,
                    reactionCounts: reactionCounts,
                  ),
                ],
              ),
            ];
          },
          body: loading.value || devotion.value == null
              ? Center(
                  child: SpinKitSpinningLines(
                    color: context.secondaryColor,
                    size: 40,
                  ),
                )
              : Container(
                  padding: const EdgeInsets.only(
                    left: 10,
                    right: 10,
                  ),
                  child: RAIRefreshIndicator(
                    onRefresh: () async {
                      await refreshDevoData();
                    },
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      scrollDirection: Axis.vertical,
                      shrinkWrap: true,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(
                            top: 20,
                          ),
                          alignment: Alignment.center,
                          child: SelectableText(
                            devotion.value!.bibleReading.split(" - ").first,
                            style: context.textTheme.titleLarge,
                          ),
                        ),
                        const SizedBox(
                          height: 5,
                        ),
                        SelectableText(
                          devotion.value!.bibleReading.split(" - ").last,
                        ),
                        Container(
                          margin: const EdgeInsets.only(top: 20),
                          alignment: Alignment.center,
                          child: SelectableText(
                            "Summary",
                            style: context.textTheme.titleLarge,
                          ),
                        ),
                        const SizedBox(
                          height: 5,
                        ),
                        SelectableText(
                          devotion.value!.summary,
                        ),
                        Container(
                          margin: const EdgeInsets.only(top: 20),
                          alignment: Alignment.center,
                          child: SelectableText(
                            "Reflection",
                            style: context.textTheme.titleLarge,
                          ),
                        ),
                        const SizedBox(
                          height: 5,
                        ),
                        SelectableText(
                          devotion.value!.reflection!,
                        ),
                        Container(
                          margin: const EdgeInsets.only(
                            top: 20,
                          ),
                          alignment: Alignment.center,
                          child: SelectableText(
                            "Prayer",
                            style: context.textTheme.titleLarge,
                          ),
                        ),
                        const SizedBox(
                          height: 5,
                        ),
                        SelectableText(
                          devotion.value!.prayer!,
                        ),
                        if (images.value.isNotEmpty) ...[
                          Container(
                            margin: const EdgeInsets.only(
                              top: 20,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              "Generated Image(s)",
                              style: context.textTheme.titleLarge,
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.only(
                              top: 10,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              images.value[0].caption ?? "No caption",
                              style: context.textTheme.bodySmall,
                            ),
                          ),
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 10,
                            runSpacing: 10,
                            children: images.value
                                .map(
                                  (e) => RAINetworkImage(
                                    imageUrl: e.url,
                                    fallbackText: "Image",
                                  ),
                                )
                                .toList(),
                          )
                        ],
                        advertisement.value,
                        if (devotion.value!.diveDeeperQueries.isNotEmpty) ...[
                          Container(
                            margin: const EdgeInsets.only(
                              top: 20,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              "Dive Deeper",
                              style: context.textTheme.titleLarge,
                            ),
                          ),
                          ...devotion.value!.diveDeeperQueries.map((query) {
                            return ListTile(
                              onTap: () {
                                context.go("/chat?query=${Uri.encodeQueryComponent(query)}");
                              },
                              leading: const Icon(
                                CupertinoIcons.chat_bubble_fill,
                                size: 18,
                              ),
                              title: Text(
                                query,
                                style: context.textTheme.bodyMedium,
                              ),
                              trailing: const Icon(
                                CupertinoIcons.chevron_right,
                                size: 18,
                              ),
                            );
                          })
                        ],
                        Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          child: ExpansionTile(
                            title: Text(
                              "Sources",
                              style: context.textTheme.titleLarge,
                            ),
                            children: [
                              ListView.builder(
                                shrinkWrap: true,
                                padding: EdgeInsets.zero,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: sourceDocs.value.length,
                                itemBuilder: (context, index) {
                                  final sourceDoc = sourceDocs.value[index];
                                  return Link(
                                    key: ValueKey(sourceDocs.value[index].id),
                                    uri: Uri.parse(
                                      sourceDocs.value[index].metadata['url'],
                                    ),
                                    target: LinkTarget.blank,
                                    builder: (context, followLink) => ListTile(
                                      dense: true,
                                      visualDensity: RAIVisualDensity.tightest,
                                      leading: Text(
                                        "${index + 1}.",
                                        style: context.textTheme.labelLarge,
                                      ),
                                      title: Text(
                                        sourceDoc.hasTitle ? sourceDoc.title! : sourceDoc.name,
                                        maxLines:
                                            sourceDoc.hasTitle && sourceDoc.hasAuthor ? 2 : 1, // leave room for author
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      subtitle: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          if (!sourceDoc.hasTitle && sourceDoc.isWebpage) ...[
                                            Text(
                                              Uri.parse(
                                                sourceDoc.url,
                                              ).pathSegments.lastWhere((element) => element.isNotEmpty),
                                              softWrap: false,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                          if (sourceDoc.hasTitle && sourceDoc.hasAuthor) ...[
                                            Text(
                                              sourceDoc.author!,
                                            ),
                                          ],
                                        ],
                                      ),
                                      trailing: const Icon(
                                        CupertinoIcons.chevron_right,
                                        size: 18,
                                      ),
                                      onTap: followLink,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
