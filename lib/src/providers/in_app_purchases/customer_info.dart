import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:revelationsai/src/providers/in_app_purchases/packages.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'customer_info.g.dart';

@riverpod
Future<CustomerInfo> customerInfo(CustomerInfoRef ref) async {
  return await Purchases.getCustomerInfo();
}

@riverpod
Future<List<Package>> activeSubscriptions(ActiveSubscriptionsRef ref) async {
  final customerInfo = await ref.watch(customerInfoProvider.future);
  final packages = await ref.watch(packagesProvider.future);
  final activeSubscriptions = customerInfo.activeSubscriptions;
  if (activeSubscriptions.isEmpty) {
    return [];
  }
  return packages.where((package) {
    return activeSubscriptions.contains(package.storeProduct.identifier);
  }).toList();
}
