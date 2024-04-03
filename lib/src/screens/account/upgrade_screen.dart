import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:revelationsai/src/models/alert.dart';
import 'package:revelationsai/src/providers/in_app_purchases/customer_info.dart';
import 'package:revelationsai/src/providers/in_app_purchases/packages.dart';
import 'package:revelationsai/src/providers/user/current.dart';
import 'package:revelationsai/src/utils/build_context_extensions.dart';
import 'package:url_launcher/url_launcher_string.dart';

class UpgradeScreen extends HookConsumerWidget {
  const UpgradeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customerInfo = ref.watch(customerInfoProvider);
    final packages = ref.watch(packagesProvider);

    final alert = useState<Alert?>(null);

    final purchaseFuture = useState<Future?>(null);
    final purchaseSnapshot = useFuture(purchaseFuture.value);

    final handlePurchase = useCallback(([Package? package]) {
      if (package != null) {
        purchaseFuture.value =
            Purchases.purchasePackage(package).then((purchaserInfo) {
          debugPrint('Purchaser Info: $purchaserInfo');
          ref.read(currentUserProvider.notifier).refresh();
        }).catchError((e) {
          debugPrint('Encountered error on purchase: $e');
          final errorCode = PurchasesErrorHelper.getErrorCode(e);
          if (errorCode != PurchasesErrorCode.purchaseCancelledError) {
            throw e;
          }
        });
      } else {
        purchaseFuture.value =
            Purchases.restorePurchases().then((purchaserInfo) {
          debugPrint('Purchaser Info: $purchaserInfo');
          ref.read(currentUserProvider.notifier).refresh();
        }).catchError((e) {
          debugPrint('Encountered error on purchase: $e');
          final errorCode = PurchasesErrorHelper.getErrorCode(e);
          if (errorCode != PurchasesErrorCode.purchaseCancelledError) {
            throw e;
          }
        });
      }
    }, [ref]);

    useEffect(() {
      if (purchaseSnapshot.hasError &&
          purchaseSnapshot.connectionState != ConnectionState.waiting) {
        alert.value = Alert(
          type: AlertType.error,
          message: purchaseSnapshot.error.toString(),
        );
      }
      return () {};
    }, [
      purchaseSnapshot.hasError,
      purchaseSnapshot.connectionState,
      purchaseSnapshot.error,
    ]);

    useEffect(() {
      if (alert.value != null) {
        Future(() {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                alert.value!.message,
                style: TextStyle(color: context.colorScheme.onError),
              ),
              backgroundColor: alert.value!.type == AlertType.error
                  ? context.colorScheme.error
                  : context.colorScheme.secondary,
              duration: const Duration(seconds: 8),
            ),
          );
          if (context.mounted) alert.value = null;
        });
      }

      return () {};
    }, [alert.value]);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: context.colorScheme.onBackground,
        systemOverlayStyle: context.isDarkMode
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),
      body: customerInfo.hasValue && packages.hasValue
          ? Stack(
              children: [
                Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      context.brightness == Brightness.light
                          ? 'assets/logo/plus-logo-dark.png'
                          : 'assets/logo/plus-logo-light.png',
                      fit: BoxFit.cover,
                      width: context.width * 0.9,
                    ),
                    Container(
                      margin: const EdgeInsets.only(
                        top: 10,
                        bottom: 20,
                      ),
                      child: Column(
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
                                          launchUrlString(
                                              "https://www.anthropic.com/news/claude-3-family");
                                        },
                                        child: Text(
                                          'Claude-3 Opus',
                                          style: context.textTheme.titleMedium
                                              ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color:
                                                context.colorScheme.secondary,
                                          ),
                                        ),
                                      ),
                                      alignment: PlaceholderAlignment.middle,
                                    ),
                                    const TextSpan(text: " and "),
                                    WidgetSpan(
                                      child: GestureDetector(
                                        onTap: () {
                                          launchUrlString(
                                              "https://openai.com/gpt-4");
                                        },
                                        child: Text(
                                          'GPT-4 Turbo',
                                          style: context.textTheme.titleMedium
                                              ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color:
                                                context.colorScheme.secondary,
                                          ),
                                        ),
                                      ),
                                      alignment: PlaceholderAlignment.middle,
                                    ),
                                  ],
                                  style: context.textTheme.titleMedium,
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
                                      style: context.textTheme.titleMedium
                                          ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const TextSpan(
                                      text: " queries per day",
                                    ),
                                  ],
                                  style: context.textTheme.titleMedium,
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
                                      style: context.textTheme.titleMedium
                                          ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const TextSpan(
                                      text: " images per day",
                                    ),
                                  ],
                                  style: context.textTheme.titleMedium,
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
                                  style: context.textTheme.titleMedium,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (final package in packages.value!) ...[
                          GestureDetector(
                            onTap: () {
                              handlePurchase(package);
                            },
                            child: Container(
                              width: context.width * 0.3,
                              margin: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: context.colorScheme.primary,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: context.colorScheme.secondary,
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    package.storeProduct.priceString,
                                    style:
                                        context.textTheme.titleMedium?.copyWith(
                                      color: context.colorScheme.onPrimary,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 5,
                                      horizontal: 10,
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Container(
                                            height: 1,
                                            color: context.secondaryColor,
                                          ),
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          "per",
                                          style: context.textTheme.bodySmall
                                              ?.copyWith(
                                            color:
                                                context.colorScheme.onPrimary,
                                          ),
                                        ),
                                        const SizedBox(width: 5),
                                        Expanded(
                                          child: Container(
                                            height: 1,
                                            color: context.secondaryColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    (package.storeProduct.subscriptionPeriod ??
                                            'P1M')
                                        .replaceFirst("P", "")
                                        .split("")
                                        .join(" ")
                                        .replaceAll("1 ", "")
                                        .replaceAll("M", "Month")
                                        .replaceAll("Y", "Year")
                                        .replaceAll("W", "Week")
                                        .replaceAll("D", "Day"),
                                    style:
                                        context.textTheme.titleMedium?.copyWith(
                                      color: context.colorScheme.onPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        ]
                      ],
                    ),
                    Container(
                      margin: const EdgeInsets.only(
                        top: 30,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 25,
                      ),
                      child: Text(
                        "All subscriptions will be automatically renewed until cancelled. You can cancel at any time in the ${Platform.isAndroid ? "Play Store" : "App Store"} settings.",
                        textAlign: TextAlign.center,
                        style: context.textTheme.bodySmall,
                      ),
                    ),
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            if (customerInfo.value?.managementURL != null) ...[
                              GestureDetector(
                                onTap: () {
                                  launchUrlString(
                                      customerInfo.value!.managementURL!);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  child: Text(
                                    'Manage Subscriptions',
                                    style:
                                        context.textTheme.labelLarge?.copyWith(
                                      color: context.colorScheme.secondary,
                                    ),
                                  ),
                                ),
                              )
                            ],
                            GestureDetector(
                              onTap: () {
                                handlePurchase();
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                child: Text(
                                  'Restore Purchases',
                                  style: context.textTheme.labelLarge?.copyWith(
                                    color: context.colorScheme.secondary,
                                  ),
                                ),
                              ),
                            )
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                if (purchaseSnapshot.connectionState ==
                    ConnectionState.waiting) ...[
                  Positioned(
                    top: context.height * 0.05,
                    left: 0,
                    right: 0,
                    child: SpinKitSpinningLines(
                      color: context.colorScheme.secondary,
                      size: 40,
                    ),
                  ),
                ],
                if (alert.value != null) ...[
                  Positioned(
                    top: context.height * 0.05,
                    left: 0,
                    right: 0,
                    child: Container(
                      color: context.colorScheme.error,
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        alert.value!.message,
                        style: TextStyle(
                          color: context.colorScheme.onError,
                        ),
                        softWrap: true,
                        maxLines: 3,
                      ),
                    ),
                  ),
                ],
                if (purchaseSnapshot.connectionState == ConnectionState.done &&
                    purchaseSnapshot.hasData) ...[
                  Positioned(
                    top: context.height * 0.05,
                    left: 0,
                    right: 0,
                    child: Container(
                      color: context.primaryColor,
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'Purchase successful!',
                        style: TextStyle(
                          color: context.colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            )
          : customerInfo.hasError || packages.hasError
              ? const Center(
                  child: Text(
                    'An error occurred while loading the packages. Please try again later.',
                    textAlign: TextAlign.center,
                  ),
                )
              : Center(
                  child: SpinKitSpinningLines(
                    color: context.colorScheme.secondary,
                    size: 40,
                  ),
                ),
    );
  }
}
