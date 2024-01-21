import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:revelationsai/src/models/devotion.dart';
import 'package:revelationsai/src/providers/devotion/current_id.dart';
import 'package:revelationsai/src/providers/devotion/pages.dart';
import 'package:revelationsai/src/utils/build_context_extensions.dart';
import 'package:revelationsai/src/utils/capitalization.dart';
import 'package:revelationsai/src/widgets/refresh_indicator.dart';

class DevotionModal extends HookConsumerWidget {
  static const _pageSize = 7;

  const DevotionModal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchTextController = useTextEditingController();
    final searchTextFocusNode = useFocusNode();
    final searchText = useState('');

    final devotionsPages = ref.watch(devotionsPagesProvider(
      pageSize: _pageSize,
      queryString: searchText.value,
    ));
    final devotionsPagesNotifier = ref.watch(devotionsPagesProvider(
      pageSize: _pageSize,
      queryString: searchText.value,
    ).notifier);

    useEffect(() {
      devotionsPagesNotifier.refresh();
      return () {};
    }, []);

    useEffect(() {
      searchTextController.addListener(() {
        searchText.value = searchTextController.text;
      });
      return () {};
    }, [searchTextController]);

    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        color: context.colorScheme.background,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.only(
              top: 10,
              bottom: 10,
              left: 30,
            ),
            decoration: ShapeDecoration(
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              color: context.primaryColor,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'All Devotions',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: context.colorScheme.onPrimary,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  icon: Icon(
                    Icons.close,
                    color: context.colorScheme.onPrimary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: TextField(
                      focusNode: searchTextFocusNode,
                      controller: searchTextController,
                      onTapOutside: (event) {
                        searchTextFocusNode.unfocus();
                      },
                      onSubmitted: (value) {
                        searchTextFocusNode.unfocus();
                      },
                      textInputAction: TextInputAction.search,
                      keyboardType: TextInputType.text,
                      decoration: InputDecoration(
                        hintText: 'Search',
                        filled: true,
                        fillColor: context.colorScheme.onBackground.withOpacity(0.1),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: context.colorScheme.onBackground.withOpacity(0.2),
                          ),
                        ),
                        prefixIcon: const Icon(
                          CupertinoIcons.search,
                          size: 18,
                        ),
                        suffixIcon: searchText.value.isNotEmpty
                            ? IconButton(
                                onPressed: () {
                                  searchTextController.clear();
                                },
                                icon: const Icon(
                                  CupertinoIcons.clear_circled_solid,
                                  size: 18,
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (devotionsPagesNotifier.isLoadingInitial() || !devotionsPages.hasValue) ...[
            Expanded(
              child: Center(
                child: SpinKitSpinningLines(
                  color: context.colorScheme.onBackground,
                  size: 32,
                ),
              ),
            )
          ] else ...[
            Expanded(
              child: RAIRefreshIndicator(
                onRefresh: () async {
                  await ref
                      .read(devotionsPagesProvider(
                        pageSize: _pageSize,
                        queryString: searchText.value,
                      ).notifier)
                      .refresh();
                },
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: devotionsPages.requireValue.expand((element) => element).toList().length + 1,
                  itemBuilder: (listItemContext, index) {
                    final devotionsFlat = devotionsPages.requireValue.expand((element) => element).toList();
                    if (index == devotionsFlat.length) {
                      return devotionsPagesNotifier.hasNextPage()
                          ? Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: ElevatedButton(
                                onPressed: () {
                                  if (devotionsPagesNotifier.isLoadingNextPage()) {
                                    return;
                                  }
                                  devotionsPagesNotifier.fetchNextPage();
                                },
                                child: devotionsPagesNotifier.isLoadingNextPage()
                                    ? SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: SpinKitSpinningLines(
                                          color: context.secondaryColor,
                                          size: 20,
                                        ),
                                      )
                                    : const Text('Show More'),
                              ),
                            )
                          : const SizedBox();
                    }

                    final devotion = devotionsFlat[index];
                    return DevotionListItem(
                      key: ValueKey(devotion.id),
                      devotion: devotion,
                    );
                  },
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class DevotionListItem extends HookConsumerWidget {
  final Devotion devotion;

  const DevotionListItem({super.key, required this.devotion});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentDevotionId = ref.watch(currentDevotionIdProvider);

    return Container(
      key: ValueKey(devotion.id),
      color: currentDevotionId == devotion.id ? context.secondaryColor.withOpacity(0.2) : null,
      child: ListTile(
        dense: true,
        visualDensity: VisualDensity.compact,
        title: Text(
          devotion.topic.toCapitalized(),
        ),
        subtitle: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              devotion.bibleReading.split(" - ").first,
            ),
            Text(
              DateFormat.yMMMMd().format(devotion.createdAt.toLocal()),
            ),
          ],
        ),
        trailing: currentDevotionId == devotion.id
            ? Icon(
                Icons.check,
                color: context.secondaryColor,
              )
            : null,
        onTap: () {
          context.go(
            '/devotions/${devotion.id}',
          );
        },
      ),
    );
  }
}
