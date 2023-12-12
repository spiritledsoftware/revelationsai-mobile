import 'dart:io';

import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:revelationsai/src/constants/store.dart';
import 'package:revelationsai/src/providers/user/current.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'purchases_config.g.dart';

@riverpod
class PurchasesConfig extends _$PurchasesConfig {
  @override
  FutureOr<void> build() async {
    final currentUser = ref.watch(currentUserProvider).requireValue;

    final isConfigured = await Purchases.isConfigured;
    if (!isConfigured) {
      debugPrint('Initializing Purchases...');
      PurchasesConfiguration configuration;
      if (Platform.isAndroid) {
        configuration = PurchasesConfiguration(RAIStore.playStoreApiKey);
      } else if (Platform.isIOS) {
        configuration = PurchasesConfiguration(RAIStore.appStoreApiKey);
      } else {
        throw UnsupportedError("Unsupported platform");
      }
      configuration.appUserID = currentUser.id;
      Purchases.configure(configuration);
    } else {
      debugPrint('Logging in Purchases...');
      Purchases.logIn(currentUser.id);
    }
  }
}
