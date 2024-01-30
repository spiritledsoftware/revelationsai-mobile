import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:revelationsai/src/constants/admob.dart';
import 'package:revelationsai/src/utils/build_context_extensions.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'native_ad.g.dart';

@Riverpod(keepAlive: true)
class NativeAds extends _$NativeAds {
  final _adUnitId = Platform.isIOS
      ? kDebugMode
          ? AdMob.testIosNativeAdUnitId
          : AdMob.iosNativeAdUnitId
      : kDebugMode
          ? AdMob.testAndroidNativeAdUnitId
          : AdMob.androidNativeAdUnitId;

  @override
  FutureOr<NativeAd?> build(BuildContext context, TemplateType type) async {
    _loadAd();
    return state.valueOrNull;
  }

  void _loadAd() async {
    state = const AsyncValue.loading();
    NativeAd(
      adUnitId: _adUnitId,
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          debugPrint('$NativeAd loaded.');
          state = AsyncValue.data(ad as NativeAd);
        },
        onAdFailedToLoad: (ad, error) {
          // Dispose the ad here to free resources.
          debugPrint('$NativeAd failed to load: $error');
          ad.dispose();
        },
      ),
      request: const AdRequest(),
      // Styling
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: type,
        mainBackgroundColor: context.colorScheme.background,
        cornerRadius: 10.0,
        callToActionTextStyle: NativeTemplateTextStyle(
          textColor: context.colorScheme.onPrimary,
          backgroundColor: context.colorScheme.primary,
          style: NativeTemplateFontStyle.monospace,
          size: context.textTheme.labelLarge!.fontSize,
        ),
        primaryTextStyle: NativeTemplateTextStyle(
          textColor: context.colorScheme.onBackground,
          backgroundColor: context.colorScheme.background,
          style: NativeTemplateFontStyle.italic,
          size: context.textTheme.labelMedium!.fontSize,
        ),
        secondaryTextStyle: NativeTemplateTextStyle(
          textColor: context.colorScheme.onBackground,
          backgroundColor: context.colorScheme.background,
          style: NativeTemplateFontStyle.bold,
          size: context.textTheme.labelSmall!.fontSize,
        ),
        tertiaryTextStyle: NativeTemplateTextStyle(
          textColor: context.colorScheme.onBackground,
          backgroundColor: context.colorScheme.background,
          style: NativeTemplateFontStyle.normal,
          size: context.textTheme.labelSmall!.fontSize,
        ),
      ),
    ).load();
  }
}
