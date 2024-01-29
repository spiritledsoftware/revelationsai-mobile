import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:revelationsai/src/constants/llm.dart';
import 'package:revelationsai/src/constants/visual_density.dart';
import 'package:revelationsai/src/models/ai_response/reaction.dart';
import 'package:revelationsai/src/models/chat/message.dart';
import 'package:revelationsai/src/providers/ai_response/reaction.dart';
import 'package:revelationsai/src/providers/user/preferences.dart';
import 'package:revelationsai/src/utils/build_context_extensions.dart';
import 'package:revelationsai/src/utils/capitalization.dart';
import 'package:revelationsai/src/utils/markdown.dart';
import 'package:revelationsai/src/widgets/chat/markdown.dart';
import 'package:revelationsai/src/widgets/chat/reaction_comment_dialog.dart';
import 'package:revelationsai/src/widgets/chat/sources.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

class MessageActionsDialog extends HookConsumerWidget {
  final ChatMessage message;
  final ScreenshotController? screenshotController;

  const MessageActionsDialog({super.key, required this.message, this.screenshotController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hapticFeedback = ref.watch(currentUserPreferencesProvider).requireValue.hapticFeedback;

    final reactionsNotifier =
        message.role == Role.assistant ? ref.watch(aiResponseReactionsProvider(message.uuid).notifier) : null;
    final reactions =
        message.role == Role.assistant ? ref.watch(aiResponseReactionsProvider(message.uuid)).value : null;

    final isMounted = useIsMounted();
    final copied = useState(false);

    useEffect(() {
      if (message.role == Role.assistant) {
        ref.read(aiResponseReactionsProvider(message.uuid).notifier).refresh();
        ref.read(aiResponseReactionsProvider(message.uuid).notifier).refresh();
      }
      return () {};
    }, [message.uuid, message.role]);

    return Dialog(
      backgroundColor: context.colorScheme.background,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              top: 10,
              left: 10,
              right: 5,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: context.height * 0.4,
              ),
              child: Scrollbar(
                thumbVisibility: true,
                child: ChatMessageMarkdown(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 15,
                  ),
                  selectable: true,
                  data: message.content.trim(),
                ),
              ),
            ),
          ),
          Divider(
            color: context.colorScheme.onBackground.withOpacity(0.4),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 15,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () {
                        if (hapticFeedback) {
                          HapticFeedback.lightImpact();
                        }
                        Clipboard.setData(
                          ClipboardData(
                            text: markdownToText(message.content),
                          ),
                        ).then((value) {
                          if (isMounted()) {
                            if (hapticFeedback) {
                              HapticFeedback.lightImpact();
                            }
                            copied.value = true;
                          }
                        });
                        Future.delayed(const Duration(seconds: 3), () {
                          if (isMounted()) copied.value = false;
                        });
                      },
                      visualDensity: RAIVisualDensity.tightest,
                      iconSize: 16,
                      icon: AnimatedCrossFade(
                        duration: const Duration(milliseconds: 200),
                        crossFadeState: copied.value ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                        firstChild: const FaIcon(
                          FontAwesomeIcons.check,
                          color: Colors.green,
                        ),
                        secondChild: const FaIcon(
                          FontAwesomeIcons.copy,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () async {
                        if (screenshotController == null) {
                          return;
                        }
                        if (hapticFeedback) {
                          HapticFeedback.lightImpact();
                        }
                        final image = await screenshotController!.capture();
                        if (image == null) {
                          return;
                        }
                        await Share.shareXFiles(
                          [
                            XFile.fromData(
                              image,
                              mimeType: "image/png",
                              name: "screenshot.png",
                            ),
                          ],
                          subject: "Message from RevelationsAI",
                          text: "Check out this message from RevelationsAI!\n\nhttps://revelationsai.com",
                        );
                      },
                      visualDensity: RAIVisualDensity.tightest,
                      iconSize: 18,
                      icon: const Icon(CupertinoIcons.share_up),
                    ),
                    if (message.role == Role.assistant) ...[
                      IconButton(
                        onPressed: () {
                          if (hapticFeedback) {
                            HapticFeedback.lightImpact();
                          }
                          reactionsNotifier!.createReaction(
                            reactionType: AiResponseReactionType.LIKE,
                          );
                        },
                        visualDensity: RAIVisualDensity.tightest,
                        iconSize: 18,
                        icon: AnimatedCrossFade(
                          duration: const Duration(milliseconds: 200),
                          crossFadeState: reactions
                                      ?.where((element) => element.reaction == AiResponseReactionType.LIKE)
                                      .isNotEmpty ??
                                  false
                              ? CrossFadeState.showFirst
                              : CrossFadeState.showSecond,
                          firstChild: const Icon(
                            CupertinoIcons.hand_thumbsup_fill,
                            color: Colors.green,
                          ),
                          secondChild: const Icon(
                            CupertinoIcons.hand_thumbsup,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          if (hapticFeedback) {
                            HapticFeedback.lightImpact();
                          }
                          showDialog(
                            context: context,
                            builder: (context) {
                              return ResponseReactionCommentDialog(
                                aiResponseId: message.uuid,
                                reactionType: AiResponseReactionType.DISLIKE,
                              );
                            },
                          );
                        },
                        visualDensity: RAIVisualDensity.tightest,
                        iconSize: 18,
                        icon: AnimatedCrossFade(
                          duration: const Duration(milliseconds: 200),
                          crossFadeState: reactions
                                      ?.where((element) => element.reaction == AiResponseReactionType.DISLIKE)
                                      .isNotEmpty ??
                                  false
                              ? CrossFadeState.showFirst
                              : CrossFadeState.showSecond,
                          firstChild: const Icon(
                            CupertinoIcons.hand_thumbsdown_fill,
                            color: Colors.red,
                          ),
                          secondChild: const Icon(
                            CupertinoIcons.hand_thumbsdown,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Row(
                  children: [
                    if (message.modelId != null) ...[
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).pop();
                          context.push("/home/upgrade");
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: context.colorScheme.onBackground.withOpacity(0.4),
                            ),
                          ),
                          child: Text(
                            (modelIdMapping[message.modelId] ?? message.modelId!).toTitleCase(),
                            style: context.textTheme.bodySmall,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          DateFormat().addPattern("M/d/yy").format((message.createdAt ?? DateTime.now()).toLocal()),
                          style: context.textTheme.bodySmall,
                        ),
                        Text(
                          DateFormat()
                              .addPattern(DateFormat.HOUR_MINUTE)
                              .format((message.createdAt ?? DateTime.now()).toLocal()),
                          style: context.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (message.role == Role.assistant) ...[
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Sources",
                  style: context.textTheme.titleMedium,
                ),
                const SizedBox(height: 5),
                Sources(message: message),
              ],
            ),
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
