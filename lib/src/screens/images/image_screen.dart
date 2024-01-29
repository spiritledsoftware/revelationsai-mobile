import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:intl/intl.dart';
import 'package:popover/popover.dart';
import 'package:revelationsai/src/constants/visual_density.dart';
import 'package:revelationsai/src/providers/user/generated_image/pages.dart';
import 'package:revelationsai/src/providers/user/generated_image/single.dart';
import 'package:revelationsai/src/utils/build_context_extensions.dart';
import 'package:revelationsai/src/widgets/network_image.dart';
import 'package:revelationsai/src/widgets/refresh_indicator.dart';
import 'package:share_plus/share_plus.dart';

class ImageScreen extends HookConsumerWidget {
  final String id;

  const ImageScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imageNotifier = ref.watch(singleUserGeneratedImageProvider(id).notifier);
    final image = ref.watch(singleUserGeneratedImageProvider(id));

    final isMounted = useIsMounted();
    final showImageActions = useState(false);
    final loadingDownload = useState(false);
    final downloaded = useState(false);

    useEffect(() {
      imageNotifier.refresh();
      return () {};
    }, []);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          image.hasValue
              ? DateFormat()
                  .addPattern("M/d/yy")
                  .addPattern(
                    DateFormat.HOUR_MINUTE,
                  )
                  .format(
                    image.value!.createdAt.toLocal(),
                  )
              : "Image",
        ),
        actions: [
          IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text(
                      "Delete image",
                    ),
                    content: const Text(
                      "Are you sure you want to delete this image?",
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text(
                          "Cancel",
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          ref.read(userGeneratedImagesPagesProvider.notifier).deleteImage(id);
                          context.go("/images");
                        },
                        child: const Text(
                          "Delete",
                        ),
                      ),
                    ],
                  );
                },
              );
            },
            icon: Icon(
              CupertinoIcons.trash,
              color: context.colorScheme.error,
            ),
          )
        ],
      ),
      body: RAIRefreshIndicator(
        onRefresh: () async {
          await imageNotifier.refresh();
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            image.when(
              loading: () => SpinKitSpinningLines(
                color: context.secondaryColor,
              ),
              error: (err, stack) => Center(
                child: Text(
                  err.toString(),
                  style: TextStyle(
                    color: context.colorScheme.error,
                  ),
                ),
              ),
              data: (image) {
                return Column(
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (isMounted()) showImageActions.value = !showImageActions.value;
                      },
                      child: Stack(
                        children: [
                          RAINetworkImage(
                            imageUrl: image!.url,
                            fallbackText: image.id,
                          ),
                          Positioned.fill(
                            child: AnimatedOpacity(
                              opacity: showImageActions.value ? 0.5 : 0,
                              duration: const Duration(milliseconds: 200),
                              child: Container(
                                color: Colors.black,
                              ),
                            ),
                          ),
                          Positioned.fill(
                            child: AnimatedScale(
                              scale: showImageActions.value ? 1 : 0,
                              duration: const Duration(milliseconds: 200),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    onPressed: () async {
                                      if (loadingDownload.value || downloaded.value) {
                                        return;
                                      }
                                      if (isMounted()) {
                                        loadingDownload.value = true;
                                      }
                                      final res = await http.get(Uri.parse(image.url!));
                                      await ImageGallerySaver.saveImage(
                                        res.bodyBytes,
                                        name: image.id,
                                        quality: 100,
                                      );
                                      if (isMounted()) {
                                        downloaded.value = true;
                                        loadingDownload.value = false;
                                      }
                                      Future.delayed(const Duration(seconds: 5), () {
                                        if (isMounted()) {
                                          downloaded.value = false;
                                        }
                                      });
                                    },
                                    iconSize: 40,
                                    icon: loadingDownload.value
                                        ? const SizedBox(
                                            height: 30,
                                            width: 30,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                            ),
                                          )
                                        : Icon(
                                            downloaded.value ? Icons.check : CupertinoIcons.square_arrow_down,
                                            color: downloaded.value ? Colors.green : Colors.white,
                                          ),
                                  ),
                                  IconButton(
                                    onPressed: () async {
                                      final response = await http.get(Uri.parse(image.url!));
                                      final tempFile = XFile.fromData(
                                        response.bodyBytes,
                                        name: image.id,
                                        mimeType: 'image/png',
                                      );
                                      await Share.shareXFiles(
                                        [tempFile],
                                        subject: "RevelationsAI Image: ${image.userPrompt}",
                                      );
                                    },
                                    iconSize: 40,
                                    icon: const Icon(
                                      CupertinoIcons.share_up,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.width * 0.05,
                        vertical: 15,
                      ),
                      child: Column(
                        children: [
                          Text(
                            image.userPrompt,
                            style: context.textTheme.headlineMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 15),
                          if (image.prompt != null) ...[
                            Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Generated Prompt",
                                      style: context.textTheme.titleLarge,
                                      textAlign: TextAlign.center,
                                    ),
                                    const PromptInfoButton(),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  image.prompt!.replaceAll("${image.userPrompt}, ", ""),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class PromptInfoButton extends StatelessWidget {
  const PromptInfoButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      visualDensity: RAIVisualDensity.tightest,
      onPressed: () {
        showPopover(
          direction: PopoverDirection.bottom,
          width: 250,
          backgroundColor: (context.brightness == Brightness.dark ? context.colorScheme.primary : Colors.grey.shade200)
              .withOpacity(0.98),
          barrierColor: Colors.transparent,
          arrowHeight: 0,
          arrowWidth: 0,
          contentDxOffset: -125,
          transitionDuration: const Duration(milliseconds: 75),
          shadow: [
            BoxShadow(
              color: context.colorScheme.shadow.withOpacity(0.5),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
          context: context,
          bodyBuilder: (context) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                "This is the prompt that is generated by AI to help make your image more accurate. It is then fed into a stable diffusion model.",
                style: context.textTheme.bodyMedium,
              ),
            );
          },
        );
      },
      icon: const Icon(
        CupertinoIcons.question_circle,
        size: 15,
      ),
    );
  }
}
