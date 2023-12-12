import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:revelationsai/src/constants/colors.dart';
import 'package:revelationsai/src/providers/devotion/single.dart';
import 'package:revelationsai/src/providers/user/current.dart';
import 'package:revelationsai/src/providers/user/message/most_asked.dart';
import 'package:revelationsai/src/providers/user/preferences.dart';
import 'package:revelationsai/src/screens/account/settings_modal.dart';
import 'package:revelationsai/src/utils/build_context_extensions.dart';
import 'package:revelationsai/src/widgets/branding/logo.dart';
import 'package:revelationsai/src/widgets/colored_safe_area.dart';
import 'package:revelationsai/src/widgets/gradient_text.dart';
import 'package:revelationsai/src/widgets/refresh_indicator.dart';

class HomeScreen extends HookConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider.select((value) => value.requireValue));
    final hapticFeedbackEnabled =
        ref.watch(currentUserPreferencesProvider.select((value) => value.value?.hapticFeedback ?? true));

    final queryTextController = useTextEditingController();
    final queryTextFocusNode = useFocusNode();

    final latestDevotion = ref.watch(singleDevotionProvider(null));
    final mostAskedUserMessages = ref.watch(mostAskedUserMessagesProvider(5));

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
              title: const Logo(
                colorScheme: RAIColorScheme.light,
                width: 200,
              ),
              actions: [
                IconButton(
                  onPressed: () {
                    if (hapticFeedbackEnabled) {
                      HapticFeedback.mediumImpact();
                    }
                    showModalBottomSheet(
                      elevation: 20,
                      isScrollControlled: true,
                      context: context,
                      builder: (_) => const FractionallySizedBox(
                        heightFactor: 0.90,
                        widthFactor: 1,
                        child: SettingsModal(),
                      ),
                    );
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
                ref.refresh(singleDevotionProvider(null).future),
                ref.refresh(mostAskedUserMessagesProvider(5).future),
              ]);
            },
            child: ListView(
              children: [
                const SizedBox(height: 20),
                GradientText(
                  "Hello, ${currentUser.name ?? "friend"}",
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
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
                const SizedBox(height: 20),
                Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 10,
                  ),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: context.colorScheme.secondary.withOpacity(0.2),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GradientText(
                        "What's on your mind?",
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
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
                        style: context.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
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
                            left: 30,
                            right: 10,
                            top: 10,
                            bottom: 10,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: context.colorScheme.onBackground.withOpacity(0.8),
                            ),
                            borderRadius: BorderRadius.circular(50),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: context.colorScheme.onBackground.withOpacity(0.8),
                            ),
                            borderRadius: BorderRadius.circular(50),
                          ),
                          suffixIcon: IconButton(
                            visualDensity: VisualDensity.compact,
                            onPressed: () {
                              if (hapticFeedbackEnabled) HapticFeedback.lightImpact();
                              context.go("/chat?query=${queryTextController.text}");
                            },
                            icon: const Icon(Icons.arrow_upward),
                          ),
                        ),
                        onTapOutside: (event) {
                          queryTextFocusNode.unfocus();
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 10,
                  ),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: context.colorScheme.secondary.withOpacity(0.2),
                  ),
                  child: Column(
                    children: [
                      GradientText(
                        "Latest Devo",
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
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
                        style: context.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      latestDevotion.when(
                        data: (devo) => GestureDetector(
                          onTap: () {
                            context.go("/devotions/${devo.id}");
                          },
                          child: Text(
                            devo.bibleReading,
                          ),
                        ),
                        error: (error, stackTrace) => Center(
                          child: Text(
                            error.toString(),
                            style: context.textTheme.titleMedium,
                          ),
                        ),
                        loading: () => Center(
                          child: SpinKitSpinningLines(
                            color: context.colorScheme.primary,
                            size: 40,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 10,
                  ),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: context.colorScheme.secondary.withOpacity(0.2),
                  ),
                  child: Column(
                    children: [
                      GradientText(
                        "Most Asked Questions",
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
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
                        style: context.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      mostAskedUserMessages.when(
                        data: (messages) => ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final message = messages[index];
                            return ListTile(
                              onTap: () {
                                context.go("/chat?query=$message");
                              },
                              leading: Text(
                                "${(index + 1).toString()}.",
                                style: context.textTheme.titleMedium,
                              ),
                              title: Text(
                                message,
                                style: context.textTheme.bodyMedium,
                              ),
                              trailing: const Icon(
                                CupertinoIcons.arrow_right,
                                size: 15,
                              ),
                            );
                          },
                        ),
                        error: (error, stackTrace) => Center(
                          child: Text(
                            error.toString(),
                            style: context.textTheme.titleMedium,
                          ),
                        ),
                        loading: () => Center(
                          child: SpinKitSpinningLines(
                            color: context.colorScheme.secondary,
                            size: 40,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
