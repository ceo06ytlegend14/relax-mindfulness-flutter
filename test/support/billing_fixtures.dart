import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:relax_mindfulness/services/subscription_controller.dart';

// Inert fixtures only. No real SDK key, network, store account or payment.
final billingNow = DateTime.utc(2026, 11, 19, 12);
const enabledBilling = BillingConfiguration(
  platform: TargetPlatform.iOS,
  iosPublicKey: 'appl_inert_unit_test_fixture',
  purchasesEnabled: true,
  privacyPolicyUrl: 'https://unit-store.sanctuary.app/privacy',
  termsUrl: 'https://unit-store.sanctuary.app/terms',
);

CustomerInfo billingCustomer({
  bool active = false,
  bool includeEntitlement = true,
  bool willRenew = true,
  PeriodType period = PeriodType.normal,
  String? expires = '2026-12-19T12:00:00Z',
  VerificationResult verification = VerificationResult.verified,
  VerificationResult envelopeVerification = VerificationResult.verified,
  String? managementUrl,
}) {
  final entitlement = EntitlementInfo(
    'premium',
    active,
    willRenew,
    '2026-11-19T12:00:00Z',
    '2026-11-19T12:00:00Z',
    'inert_product_monthly',
    true,
    periodType: period,
    expirationDate: expires,
    verification: verification,
  );
  return CustomerInfo(
    EntitlementInfos(
      includeEntitlement ? {'premium': entitlement} : {},
      includeEntitlement && active ? {'premium': entitlement} : {},
      verification: envelopeVerification,
    ),
    const {},
    const [],
    const [],
    const [],
    '2026-11-19T12:00:00Z',
    'inert-customer-fixture',
    const {},
    '2026-11-19T12:00:00Z',
    managementURL: managementUrl,
  );
}

Package billingPackage({
  String id = 'monthly',
  PackageType type = PackageType.monthly,
  double price = 4.25,
  String priceString = '€4.25',
  String? period = 'P1M',
  String currency = 'EUR',
}) => Package(
  id,
  type,
  StoreProduct(
    'inert_product_$id',
    'Store-configured test plan details.',
    'Test $id plan',
    price,
    priceString,
    currency,
    subscriptionPeriod: period,
    productCategory: ProductCategory.subscription,
  ),
  const PresentedOfferingContext('inert-offering', null, null),
);

Offerings billingOfferings(List<Package> packages) {
  final current = Offering(
    'inert-offering',
    'Inert test plans',
    const {},
    packages,
  );
  return Offerings({'inert-offering': current}, current: current);
}

class FakeBillingGateway implements BillingGateway {
  CustomerInfo customer = billingCustomer();
  CustomerInfo? purchasedCustomer;
  CustomerInfo? restoredCustomer;
  late Offerings available = billingOfferings([billingPackage()]);
  final configuredKeys = <String>[];
  final purchasedPackages = <Package>[];
  final listeners = <void Function(CustomerInfo)>{};
  int restoreCalls = 0;
  int customerCalls = 0;
  Object? purchaseError;
  Object? restoreError;
  Object? customerError;
  Object? offeringsError;
  Object? configureError;
  Completer<CustomerInfo>? customerGate;
  Completer<CustomerInfo>? purchaseGate;

  @override
  Future<void> configure(String publicKey) async {
    configuredKeys.add(publicKey);
    if (configureError != null) throw configureError!;
  }

  @override
  Future<CustomerInfo> customerInfo() async {
    customerCalls++;
    if (customerError != null) throw customerError!;
    final gate = customerGate;
    if (gate != null) return gate.future;
    return customer;
  }

  @override
  Future<Offerings> offerings() async {
    if (offeringsError != null) throw offeringsError!;
    return available;
  }

  @override
  Future<CustomerInfo> purchase(Package package) async {
    purchasedPackages.add(package);
    if (purchaseError != null) throw purchaseError!;
    final gate = purchaseGate;
    if (gate != null) return gate.future;
    return purchasedCustomer ?? customer;
  }

  @override
  Future<CustomerInfo> restore() async {
    restoreCalls++;
    if (restoreError != null) throw restoreError!;
    return restoredCustomer ?? customer;
  }

  void emit(CustomerInfo value) {
    customer = value;
    for (final listener in listeners.toList()) {
      listener(value);
    }
  }

  @override
  void addListener(void Function(CustomerInfo) listener) =>
      listeners.add(listener);
  @override
  void removeListener(void Function(CustomerInfo) listener) =>
      listeners.remove(listener);
}
