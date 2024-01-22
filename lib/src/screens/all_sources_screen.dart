import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:revelationsai/src/providers/data_source/pages.dart';
import 'package:revelationsai/src/utils/build_context_extensions.dart';
import 'package:revelationsai/src/widgets/colored_safe_area.dart';
import 'package:revelationsai/src/widgets/refresh_indicator.dart';
import 'package:url_launcher/url_launcher_string.dart';

class SourcesScreen extends HookConsumerWidget {
  static const pageSize = 8;

  const SourcesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchTextFocusNode = useFocusNode();
    final searchTextController = useTextEditingController();
    final searchText = useState('');

    final watchedDataSources = ref.watch(dataSourcesPagesProvider(
      queryString: searchText.value,
      pageSize: pageSize,
    ));
    final dataSourcesNotifier = ref.watch(dataSourcesPagesProvider(
      queryString: searchText.value,
      pageSize: pageSize,
    ).notifier);

    final dataSources = useState(watchedDataSources.value ?? []);
    useEffect(() {
      dataSources.value = watchedDataSources.value ?? dataSources.value;
      return () {};
    }, [watchedDataSources.value]);

    useEffect(() {
      void closure() {
        searchText.value = searchTextController.text;
      }

      searchTextController.addListener(closure);
      return () {
        searchTextController.removeListener(closure);
      };
    }, [searchTextController]);

    return Scaffold(
      body: ColoredSafeArea(
        bottom: false,
        color: context.colorScheme.primary,
        overlayStyle: SystemUiOverlayStyle.light,
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                automaticallyImplyLeading: true,
                snap: true,
                floating: true,
                centerTitle: false,
                backgroundColor: context.colorScheme.primary,
                systemOverlayStyle: SystemUiOverlayStyle.light,
                title: const Text("All Sources"),
              ),
            ];
          },
          body: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
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
              Expanded(
                child: dataSourcesNotifier.isLoadingInitial() && dataSources.value.isEmpty
                    ? SpinKitSpinningLines(
                        color: context.secondaryColor,
                        size: 40,
                      )
                    : RAIRefreshIndicator(
                        onRefresh: () async {
                          await dataSourcesNotifier.refresh();
                        },
                        child: ListView.builder(
                          itemCount: dataSources.value.expand((element) => element).length + 1,
                          itemBuilder: (context, index) {
                            final sources = dataSources.value.expand((element) => element).toList();
                            if (index == sources.length) {
                              return dataSourcesNotifier.hasNextPage()
                                  ? Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      child: ElevatedButton(
                                        onPressed: () {
                                          if (dataSourcesNotifier.isLoadingNextPage()) {
                                            return;
                                          }
                                          dataSourcesNotifier.fetchNextPage();
                                        },
                                        child: dataSourcesNotifier.isLoadingNextPage()
                                            ? SizedBox(
                                                height: 20,
                                                width: 20,
                                                child: SpinKitSpinningLines(
                                                  color: context.secondaryColor,
                                                  size: 20,
                                                ),
                                              )
                                            : const Text('Load more'),
                                      ),
                                    )
                                  : const SizedBox();
                            }

                            final dataSource = sources[index];
                            return ListTile(
                              onTap: () async {
                                await launchUrlString(
                                  dataSource.url,
                                  mode: LaunchMode.externalApplication,
                                );
                              },
                              title: Text(dataSource.title ?? dataSource.name),
                              subtitle: Text(dataSource.author ?? Uri.parse(dataSource.url).origin),
                              trailing: const FaIcon(
                                FontAwesomeIcons.arrowUpRightFromSquare,
                                size: 18,
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
