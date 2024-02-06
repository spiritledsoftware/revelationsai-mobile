import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:revelationsai/src/constants/colors.dart';
import 'package:revelationsai/src/providers/devotion/latest.dart';
import 'package:revelationsai/src/providers/user/current.dart';
import 'package:revelationsai/src/providers/user/message/most_asked.dart';
import 'package:revelationsai/src/providers/user/preferences.dart';
import 'package:revelationsai/src/services/user.dart';
import 'package:revelationsai/src/utils/build_context_extensions.dart';
import 'package:revelationsai/src/utils/capitalization.dart';
import 'package:revelationsai/src/widgets/advertisement/native_ad.dart';
import 'package:revelationsai/src/widgets/branding/logo.dart';
import 'package:revelationsai/src/widgets/colored_safe_area.dart';
import 'package:revelationsai/src/widgets/gradient_text.dart';
import 'package:revelationsai/src/widgets/refresh_indicator.dart';
import 'package:url_launcher/url_launcher_string.dart';

const greetings = {
  "Peace be with you",
  "Shalom",
  "Hello",
  "God bless you",
  "Welcome",
  "Grace and peace",
  "Grace to you",
  "Greetings",
  "The Lord be with you",
  "Joy in Lord to you",
  "Pax Domini",
};

class HomeScreen extends HookConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider.select((value) => value.requireValue));
    final hapticFeedbackEnabled =
        ref.watch(currentUserPreferencesProvider.select((value) => value.value?.hapticFeedback ?? true));

    final greeting = useRef(greetings.elementAt(
      DateTime.now().millisecondsSinceEpoch % greetings.length,
    ));

    final queryTextController = useTextEditingController();
    final queryTextFocusNode = useFocusNode();
    final queryText = useState("");

    final latestDevotion = ref.watch(latestDevotionProvider);
    final mostAskedUserMessages = ref.watch(mostAskedUserMessagesProvider(5));

    final advertisement = useRef(const NativeAdvertisement(type: TemplateType.medium));

    useEffect(() {
      Future.wait([
        ref.read(latestDevotionProvider.notifier).refresh(),
        ref.refresh(mostAskedUserMessagesProvider(5).future),
      ]);
      return () {};
    }, []);

    useEffect(() {
      void closure() {
        queryText.value = queryTextController.text;
      }

      queryTextController.addListener(closure);
      return () {
        queryTextController.removeListener(closure);
      };
    }, [queryTextController]);

    return Scaffold(
      body: ColoredSafeArea(
        color: context.colorScheme.primary,
        overlayStyle: SystemUiOverlayStyle.light,
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverAppBar(
              automaticallyImplyLeading: false,
              snap: true,
              floating: true,
              centerTitle: false,
              backgroundColor: context.colorScheme.primary,
              systemOverlayStyle: SystemUiOverlayStyle.light,
              title: UserService.hasPlus(currentUser) || UserService.isAdmin(currentUser)
                  ? Image.asset(
                      "assets/logo/plus-logo-light.png",
                      width: 200,
                    )
                  : const Logo(
                      colorScheme: RAIColorScheme.light,
                      width: 200,
                    ),
              actions: [
                IconButton(
                  onPressed: () {
                    if (hapticFeedbackEnabled) {
                      HapticFeedback.lightImpact();
                    }
                    context.go("/home/settings");
                  },
                  icon: const Icon(
                    Icons.settings,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ],
          body: RAIRefreshIndicator(
            onRefresh: () {
              return Future.wait([
                ref.read(latestDevotionProvider.notifier).refresh(),
                ref.refresh(mostAskedUserMessagesProvider(5).future),
              ]);
            },
            child: ListView(
              children: [
                const SizedBox(height: 20),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.width * 0.1,
                  ),
                  child: GradientText(
                    "${greeting.value},\n${currentUser.name ?? "friend"}",
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        if (context.brightness == Brightness.dark) ...[
                          Colors.white,
                          context.secondaryColor,
                        ],
                        if (context.brightness == Brightness.light) ...[
                          context.primaryColor,
                          context.secondaryColor,
                        ],
                      ],
                    ),
                    style: context.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                if (!UserService.hasPlus(currentUser) && !UserService.isAdmin(currentUser)) ...[
                  GestureDetector(
                    onTap: () {
                      if (hapticFeedbackEnabled) {
                        HapticFeedback.lightImpact();
                      }
                      context.go("/home/upgrade");
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: context.primaryColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: context.secondaryColor,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: context.colorScheme.shadow.withOpacity(0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            "assets/logo/plus-logo-light.png",
                            width: context.width * 0.8,
                          ),
                          Column(
                            children: [
                              Text.rich(
                                TextSpan(
                                  children: [
                                    WidgetSpan(
                                      child: Icon(
                                        Icons.add,
                                        size: 20,
                                        color: context.secondaryColor,
                                      ),
                                      alignment: PlaceholderAlignment.middle,
                                    ),
                                    TextSpan(
                                      children: [
                                        const TextSpan(text: "Unlock "),
                                        WidgetSpan(
                                          child: GestureDetector(
                                            onTap: () {
                                              launchUrlString("https://www.anthropic.com/news/claude-2-1");
                                            },
                                            child: Text(
                                              'Anthropic Claude v2.1',
                                              style: context.textTheme.titleMedium?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: context.secondaryColor,
                                              ),
                                            ),
                                          ),
                                          alignment: PlaceholderAlignment.middle,
                                        ),
                                      ],
                                      style: context.textTheme.titleMedium?.copyWith(
                                        color: context.colorScheme.onPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text.rich(
                                TextSpan(
                                  children: [
                                    WidgetSpan(
                                      child: Icon(
                                        Icons.add,
                                        size: 20,
                                        color: context.secondaryColor,
                                      ),
                                      alignment: PlaceholderAlignment.middle,
                                    ),
                                    TextSpan(
                                      children: [
                                        TextSpan(
                                          text: "Unlimited",
                                          style: context.textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: context.colorScheme.onPrimary,
                                          ),
                                        ),
                                        const TextSpan(
                                          text: " queries per day",
                                        ),
                                      ],
                                      style: context.textTheme.titleMedium?.copyWith(
                                        color: context.colorScheme.onPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text.rich(
                                TextSpan(
                                  children: [
                                    WidgetSpan(
                                      child: Icon(
                                        Icons.add,
                                        size: 20,
                                        color: context.secondaryColor,
                                      ),
                                      alignment: PlaceholderAlignment.middle,
                                    ),
                                    TextSpan(
                                      children: [
                                        TextSpan(
                                          text: "Unlimited",
                                          style: context.textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: context.colorScheme.onPrimary,
                                          ),
                                        ),
                                        const TextSpan(
                                          text: " images per day",
                                        ),
                                      ],
                                      style: context.textTheme.titleMedium?.copyWith(
                                        color: context.colorScheme.onPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text.rich(
                                TextSpan(
                                  children: [
                                    WidgetSpan(
                                      child: Icon(
                                        Icons.add,
                                        size: 20,
                                        color: context.secondaryColor,
                                      ),
                                      alignment: PlaceholderAlignment.middle,
                                    ),
                                    TextSpan(
                                      text: 'Ad-free experience',
                                      style: context.textTheme.titleMedium?.copyWith(
                                        color: context.colorScheme.onPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                advertisement.value,
                HomeScreenCard(
                  title: "Ask a Question",
                  child: TextField(
                    controller: queryTextController,
                    focusNode: queryTextFocusNode,
                    minLines: 1,
                    maxLines: 3,
                    keyboardType: TextInputType.multiline,
                    textCapitalization: TextCapitalization.sentences,
                    autocorrect: true,
                    decoration: InputDecoration(
                      hintText: "Type a message",
                      contentPadding: const EdgeInsets.only(
                        left: 20,
                        right: 0,
                        top: 10,
                        bottom: 10,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: context.colorScheme.onBackground.withOpacity(0.8),
                        ),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: context.colorScheme.onBackground.withOpacity(0.8),
                        ),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      suffixIcon: queryText.value.isNotEmpty
                          ? IconButton(
                              visualDensity: VisualDensity.compact,
                              onPressed: () {
                                if (hapticFeedbackEnabled) {
                                  HapticFeedback.lightImpact();
                                }
                                context.go("/chat?query=${Uri.encodeQueryComponent(queryTextController.text)}");
                              },
                              icon: const FaIcon(
                                FontAwesomeIcons.arrowUp,
                                size: 18,
                              ),
                            )
                          : null,
                    ),
                    onTapOutside: (event) {
                      queryTextFocusNode.unfocus();
                    },
                  ),
                ),
                HomeScreenCard(
                  title: "Latest Devo",
                  child: latestDevotion.when(
                    data: (devo) => GestureDetector(
                      onTap: () {
                        if (hapticFeedbackEnabled) {
                          HapticFeedback.lightImpact();
                        }
                        context.go("/devotions/${devo.id}");
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${devo.topic.toTitleCase()} - ${DateFormat.yMd().format(devo.createdAt.toLocal())}',
                            style: context.textTheme.titleMedium?.copyWith(
                              color: context.colorScheme.onPrimary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            devo.bibleReading,
                            maxLines: 6,
                            overflow: TextOverflow.ellipsis,
                            style: context.textTheme.bodyMedium?.copyWith(
                              color: context.colorScheme.onPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    error: (error, stackTrace) => Center(
                      child: Text(
                        error.toString(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: context.colorScheme.onPrimary,
                        ),
                      ),
                    ),
                    loading: () => Center(
                      child: SpinKitSpinningLines(
                        color: context.colorScheme.onPrimary,
                        size: 40,
                      ),
                    ),
                  ),
                ),
                HomeScreenCard(
                  title: "Dive Deeper",
                  child: latestDevotion.when(
                    data: (devo) => GestureDetector(
                      onTap: () {
                        if (hapticFeedbackEnabled) {
                          HapticFeedback.lightImpact();
                        }
                        context.go("/devotions/${devo.id}");
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: devo.diveDeeperQueries.isNotEmpty
                            ? devo.diveDeeperQueries
                                .map(
                                  (query) => ListTile(
                                    onTap: () {
                                      if (hapticFeedbackEnabled) {
                                        HapticFeedback.lightImpact();
                                      }
                                      context.go("/chat?query=${Uri.encodeQueryComponent(query)}");
                                    },
                                    leading: Icon(
                                      CupertinoIcons.chat_bubble_fill,
                                      size: 18,
                                      color: context.colorScheme.onPrimary,
                                    ),
                                    title: Text(
                                      query,
                                      style: context.textTheme.bodySmall?.copyWith(
                                        color: context.colorScheme.onPrimary,
                                      ),
                                    ),
                                    trailing: Icon(
                                      CupertinoIcons.chevron_right,
                                      size: 18,
                                      color: context.colorScheme.onPrimary,
                                    ),
                                  ),
                                )
                                .toList()
                            : [
                                ListTile(
                                  title: Text(
                                    "No dive deeper queries found for this devotion",
                                    style: context.textTheme.bodySmall?.copyWith(
                                      color: context.colorScheme.onPrimary,
                                    ),
                                  ),
                                ),
                              ],
                      ),
                    ),
                    error: (error, stackTrace) => Center(
                      child: Text(
                        error.toString(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: context.colorScheme.onPrimary,
                        ),
                      ),
                    ),
                    loading: () => Center(
                      child: SpinKitSpinningLines(
                        color: context.colorScheme.onPrimary,
                        size: 40,
                      ),
                    ),
                  ),
                ),
                HomeScreenCard(
                  title: "Most Asked Questions",
                  child: mostAskedUserMessages.when(
                    data: (messages) => ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        return ListTile(
                          onTap: () {
                            context.go("/chat?query=${Uri.encodeQueryComponent(message)}");
                          },
                          leading: Text(
                            "#${(index + 1).toString()}",
                            style: context.textTheme.labelLarge?.copyWith(
                              color: context.colorScheme.onPrimary,
                            ),
                          ),
                          title: Text(
                            message,
                            style: context.textTheme.bodyMedium?.copyWith(
                              color: context.colorScheme.onPrimary,
                            ),
                          ),
                          trailing: Icon(
                            CupertinoIcons.chevron_right,
                            size: 18,
                            color: context.colorScheme.onPrimary,
                          ),
                        );
                      },
                    ),
                    error: (error, stackTrace) => Center(
                      child: Text(
                        error.toString(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: context.colorScheme.onPrimary,
                        ),
                      ),
                    ),
                    loading: () => Center(
                      child: SpinKitSpinningLines(
                        color: context.colorScheme.onPrimary,
                        size: 40,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HomeScreenCard extends StatelessWidget {
  final String title;
  final Widget child;

  const HomeScreenCard({
    super.key,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 10,
      ),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: context.colorScheme.primary,
        boxShadow: [
          BoxShadow(
            color: context.colorScheme.shadow.withOpacity(0.4),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          GradientText(
            title,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white,
                context.secondaryColor,
              ],
            ),
            style: context.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
