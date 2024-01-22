import 'dart:math';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:revelationsai/src/providers/advertisements/interstitial_ad.dart';
import 'package:revelationsai/src/providers/user/current.dart';
import 'package:revelationsai/src/services/user.dart';

Future<bool> showAdvertisementLogic(WidgetRef ref, {int? chanceNumerator}) async {
  try {
    final ad = await ref.read(interstitialAdsProvider.future);
    if (ad == null) {
      debugPrint("Ad is null, not showing ad");
      return false;
    }

    final currentUser = await ref.read(currentUserProvider.future);
    if (UserService.hasPlus(currentUser) || UserService.isAdmin(currentUser)) {
      debugPrint("User has plus, not showing ad");
      return false;
    }

    final randomInt = (Random().nextDouble() * 100).ceil();
    debugPrint("Random int for in ad logic: $randomInt");
    final showAd = randomInt % 1;
    debugPrint("Will show an ad if this equals 0: $showAd");
    if (showAd == 0) {
      await ad.show();
      return true;
    }
    return false;
  } catch (e) {
    debugPrint("Error in advertisement logic: $e");
    return false;
  }
}
