import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:revelationsai/src/providers/advertisements/native_ad.dart';
import 'package:revelationsai/src/providers/user/current.dart';
import 'package:revelationsai/src/services/user.dart';
import 'package:revelationsai/src/utils/build_context_extensions.dart';

class NativeAdvertisement extends HookConsumerWidget {
  final TemplateType type;
  final double? width;
  final EdgeInsetsGeometry? padding;

  const NativeAdvertisement({
    super.key,
    required this.type,
    this.width,
    this.padding,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider).requireValue;
    final nativeAd = !UserService.hasPlus(currentUser) && !UserService.isAdmin(currentUser)
        ? ref.watch(nativeAdsProvider(context, type))
        : null;

    final width = this.width ?? context.width * 0.8;

    final advertisement = useMemoized(() {
      if (nativeAd == null) {
        return const SizedBox.shrink();
      }

      if (nativeAd.hasError == true) {
        return const SizedBox.shrink();
      }

      if (nativeAd.value == null) {
        return SizedBox(
          width: width,
          height: type == TemplateType.medium ? 360 : 120,
          child: Center(
            child: SpinKitSpinningLines(
              color: context.secondaryColor,
              size: width * 0.2,
            ),
          ),
        );
      }

      return Container(
        padding: padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Brought to you by",
              style: context.textTheme.bodySmall,
            ),
            SizedBox(
              width: width,
              height: type == TemplateType.medium ? 360 : 120,
              child: AdWidget(ad: nativeAd.value!),
            ),
          ],
        ),
      );
    }, [nativeAd]);

    return advertisement;
  }
}
