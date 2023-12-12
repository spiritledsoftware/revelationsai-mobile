import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'packages.g.dart';

@riverpod
Future<List<Package>> packages(PackagesRef ref) async {
  return await Purchases.getOfferings().then((offerings) {
    debugPrint("Offering: ${offerings.current?.serverDescription}");
    return offerings.current?.availablePackages ?? [];
  });
}
