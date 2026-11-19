import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:relax_mindfulness/providers/app_state.dart';
import 'package:relax_mindfulness/services/subscription_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/billing_fixtures.dart';
import 'support/inert_audio_player.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FakeBillingGateway gateway;
  late SubscriptionController controller;
  late DateTime now;

  setUp(() {
    now = billingNow;
    gateway = FakeBillingGateway();
    controller = SubscriptionController(
      configuration: enabledBilling,
      gateway: gateway,
      now: () => now,
    );
  });
  tearDown(() => controller.dispose());

  test(
    'missing/secret/wrong-platform keys and unsupported clients never configure a store',
    () async {
      for (final configuration in [
        const BillingConfiguration(platform: TargetPlatform.iOS),
        const BillingConfiguration(
          platform: TargetPlatform.iOS,
          iosPublicKey: 'sk_not_a_client_key',
        ),
        const BillingConfiguration(
          platform: TargetPlatform.android,
          androidPublicKey: 'appl_wrong_platform',
        ),
        const BillingConfiguration(
          platform: TargetPlatform.iOS,
          isWeb: true,
          iosPublicKey: 'appl_inert',
        ),
        const BillingConfiguration(
          platform: TargetPlatform.linux,
          iosPublicKey: 'appl_inert',
        ),
      ]) {
        final billing = SubscriptionController(
          configuration: configuration,
          gateway: gateway,
        );
        await billing.initialize();
        expect(billing.hasFullAccess, isFalse);
        expect(billing.canPurchase, isFalse);
        expect(billing.canRestore, isFalse);
        billing.dispose();
      }
      expect(gateway.configuredKeys, isEmpty);
    },
  );

  test(
    'platform keys and legal URLs are explicit and new purchases default off',
    () {
      const android = BillingConfiguration(
        platform: TargetPlatform.android,
        iosPublicKey: 'appl_inert',
        androidPublicKey: 'goog_inert',
      );
      expect(android.publicKey, 'goog_inert');
      expect(android.allowsNewPurchases, isFalse);
      for (final bad in [
        '',
        'http://legal.test/policy',
        'file:///policy',
        'https://localhost/policy',
        'https://example.com/privacy',
        'https://user:password@store.test/privacy',
      ]) {
        expect(BillingConfiguration.legalUri(bad), isNull);
      }
      expect(enabledBilling.allowsNewPurchases, isTrue);
    },
  );

  test(
    'initial access comes from the named active entitlement, not just a configured SDK',
    () async {
      await controller.initialize();
      expect(controller.isConfigured, isTrue);
      expect(controller.hasFullAccess, isFalse);
      expect(controller.trialActive, isFalse);
      expect(controller.canPurchase, isTrue);
      gateway.emit(billingCustomer(active: true));
      expect(controller.hasFullAccess, isTrue);
      expect(controller.canPurchase, isFalse);
      gateway.emit(billingCustomer(active: true, includeEntitlement: false));
      expect(controller.hasFullAccess, isFalse);
    },
  );

  test(
    'a successful payment callback without an entitlement grants nothing',
    () async {
      await controller.initialize();
      expect(
        await controller.purchase(controller.plans.single),
        BillingResult.noActiveEntitlement,
      );
      expect(gateway.purchasedPackages, hasLength(1));
      expect(controller.hasFullAccess, isFalse);
      expect(controller.trialActive, isFalse);
      expect(controller.notice, contains('Do not pay again'));
      expect(controller.canPurchase, isFalse);
      expect(
        await controller.purchase(controller.plans.single),
        BillingResult.unavailable,
      );
      expect(gateway.purchasedPackages, hasLength(1));
      await controller.refresh();
      expect(
        controller.canPurchase,
        isFalse,
      ); // A cached empty fetch is not proof of failed payment.
    },
  );

  test(
    'purchase reconciles the returned active entitlement immediately',
    () async {
      await controller.initialize();
      gateway.purchasedCustomer = billingCustomer(active: true);
      expect(
        await controller.purchase(controller.plans.single),
        BillingResult.active,
      );
      expect(controller.hasFullAccess, isTrue);
      expect(controller.canPurchase, isFalse);
    },
  );

  for (final entry in {
    PurchasesErrorCode.purchaseCancelledError: BillingResult.cancelled,
    PurchasesErrorCode.paymentPendingError: BillingResult.pending,
  }.entries) {
    test(
      '${entry.key.name} never grants access or leaks SDK details',
      () async {
        await controller.initialize();
        gateway.purchaseError = PlatformException(
          code: entry.key.index.toString(),
          message: 'PRIVATE_STORE_DETAILS',
        );
        expect(await controller.purchase(controller.plans.single), entry.value);
        expect(controller.hasFullAccess, isFalse);
        expect(controller.notice, isNot(contains('PRIVATE_STORE_DETAILS')));
        expect(controller.isBusy, isFalse);
        expect(controller.canPurchase, entry.value == BillingResult.cancelled);
        gateway.emit(billingCustomer(active: true));
        expect(controller.hasFullAccess, isTrue);
        gateway.emit(billingCustomer(active: false));
        expect(controller.canPurchase, isTrue);
      },
    );
  }

  test(
    'an uncertain checkout failure blocks another charge attempt while restore stays available',
    () async {
      await controller.initialize();
      gateway.purchaseError = StateError('PRIVATE_CHECKOUT_DETAILS');
      expect(
        await controller.purchase(controller.plans.single),
        BillingResult.failed,
      );
      expect(controller.canPurchase, isFalse);
      expect(controller.canRestore, isTrue);
      expect(controller.notice, isNot(contains('PRIVATE_CHECKOUT_DETAILS')));
      await controller.restore();
      expect(controller.canPurchase, isFalse);
      expect(
        await controller.purchase(controller.plans.single),
        BillingResult.unavailable,
      );
      expect(gateway.purchasedPackages, hasLength(1));
    },
  );

  test(
    'restore can both grant and revoke access; errors are not reported as an empty purchase history',
    () async {
      await controller.initialize();
      gateway.restoredCustomer = billingCustomer(active: true);
      expect(await controller.restore(), BillingResult.active);
      gateway.restoredCustomer = billingCustomer();
      expect(await controller.restore(), BillingResult.noActiveEntitlement);
      expect(controller.hasFullAccess, isFalse);
      gateway.restoreError = StateError('PRIVATE_STORE_DETAILS');
      expect(await controller.restore(), BillingResult.failed);
      expect(controller.notice, contains('could not be restored'));
      expect(controller.notice, isNot(contains('PRIVATE_STORE_DETAILS')));
      expect(controller.notice, isNot(contains('No active')));
    },
  );

  test(
    'refund/expiry updates revoke access and a cancelled renewal retains its paid period',
    () async {
      gateway.customer = billingCustomer(active: true, willRenew: false);
      await controller.initialize();
      expect(controller.hasFullAccess, isTrue);
      gateway.emit(billingCustomer(active: false));
      expect(controller.hasFullAccess, isFalse);
      gateway.emit(
        billingCustomer(active: true, expires: '2026-11-19T12:01:00Z'),
      );
      expect(controller.hasFullAccess, isTrue);
      now = now.add(const Duration(minutes: 1));
      expect(controller.hasFullAccess, isFalse);
      expect(controller.trialDaysLeft, 0);
    },
  );

  test(
    'trial dates come from the entitlement and invalid/expired data cannot invent a trial',
    () async {
      await controller.initialize();
      gateway.emit(
        billingCustomer(
          active: true,
          period: PeriodType.trial,
          expires: '2026-11-21T13:00:00Z',
        ),
      );
      expect(controller.trialActive, isTrue);
      expect(controller.trialDaysLeft, 3);
      for (final expires in [null, 'invalid', '2026-11-18T12:00:00Z']) {
        gateway.emit(
          billingCustomer(
            active: true,
            period: PeriodType.trial,
            expires: expires,
          ),
        );
        expect(controller.hasFullAccess, isFalse);
        expect(controller.trialActive, isFalse);
      }
      gateway.emit(billingCustomer(active: true, expires: null));
      expect(
        controller.hasFullAccess,
        isTrue,
      ); // SDK-reported lifetime, not a local trial.
    },
  );

  test('failed SDK entitlement verification is rejected', () async {
    await controller.initialize();
    gateway.emit(
      billingCustomer(active: true, verification: VerificationResult.failed),
    );
    expect(controller.hasFullAccess, isFalse);
    gateway.emit(
      billingCustomer(
        active: true,
        envelopeVerification: VerificationResult.failed,
      ),
    );
    expect(controller.hasFullAccess, isFalse);
  });

  test(
    'only currently offered monthly/yearly plans with real localized metadata can be purchased',
    () async {
      gateway.available = billingOfferings([
        billingPackage(),
        billingPackage(
          id: 'annual',
          type: PackageType.annual,
          period: 'P1Y',
          priceString: '¥5,000',
        ),
        billingPackage(id: 'mislabeled', period: 'P1W'),
        billingPackage(id: 'unpriced', price: double.nan),
        billingPackage(id: 'blank', priceString: ''),
        billingPackage(id: 'custom', type: PackageType.custom),
      ]);
      await controller.initialize();
      expect(controller.plans.map((plan) => plan.identifier), [
        'monthly',
        'annual',
      ]);
      expect(controller.plans.last.storeProduct.priceString, '¥5,000');
      expect(
        await controller.purchase(billingPackage()),
        BillingResult.unavailable,
      ); // Forged/stale object.
      expect(gateway.purchasedPackages, isEmpty);
      expect(() => controller.plans.clear(), throwsUnsupportedError);
    },
  );

  test(
    'new purchases can be disabled while existing customers can still restore',
    () async {
      final billing = SubscriptionController(
        configuration: const BillingConfiguration(
          platform: TargetPlatform.iOS,
          iosPublicKey: 'appl_inert',
        ),
        gateway: gateway,
        now: () => now,
      );
      addTearDown(billing.dispose);
      await billing.initialize();
      expect(billing.canPurchase, isFalse);
      expect(
        await billing.purchase(billing.plans.single),
        BillingResult.unavailable,
      );
      gateway.restoredCustomer = billingCustomer(active: true);
      expect(await billing.restore(), BillingResult.active);
      expect(gateway.purchasedPackages, isEmpty);
    },
  );

  test(
    'a stale purchase response cannot undo a newer revocation update',
    () async {
      await controller.initialize();
      final gate = Completer<CustomerInfo>();
      gateway.purchaseGate = gate;
      final buying = controller.purchase(controller.plans.single);
      expect(controller.isBusy, isTrue);
      expect(
        await controller.purchase(controller.plans.single),
        BillingResult.busy,
      );
      expect(await controller.restore(), BillingResult.busy);
      gateway.emit(billingCustomer(active: false));
      gate.complete(billingCustomer(active: true));
      expect(await buying, BillingResult.noActiveEntitlement);
      expect(controller.hasFullAccess, isFalse);
      expect(gateway.purchasedPackages, hasLength(1));
    },
  );

  test(
    'refreshes coalesce and a late stale fetch cannot restore revoked access',
    () async {
      await controller.initialize();
      final gate = Completer<CustomerInfo>();
      gateway.customerGate = gate;
      final refreshing = controller.refresh();
      final coalesced = controller.refresh();
      expect(gateway.customerCalls, 2); // Initial fetch and one shared refresh.
      gateway.emit(billingCustomer(active: false));
      gate.complete(billingCustomer(active: true));
      await Future.wait([refreshing, coalesced]);
      expect(controller.hasFullAccess, isFalse);
    },
  );

  test(
    'network failure retains only known unexpired access and blocks new checkout',
    () async {
      gateway.customer = billingCustomer(active: true);
      await controller.initialize();
      gateway.customerError = StateError('network unavailable');
      await controller.refresh();
      expect(controller.hasFullAccess, isTrue);
      expect(controller.canPurchase, isFalse);
      now = DateTime.utc(2027);
      expect(controller.hasFullAccess, isFalse);
      gateway.offeringsError = StateError('network unavailable');
      await controller.refresh();
      expect(controller.plans, isEmpty);
    },
  );

  test('only known store HTTPS management links are offered', () async {
    await controller.initialize();
    gateway.emit(
      billingCustomer(
        active: true,
        managementUrl: 'https://apps.apple.com/account/subscriptions',
      ),
    );
    expect(controller.managementUri?.host, 'apps.apple.com');
    gateway.emit(
      billingCustomer(active: true, managementUrl: 'https://phishing.invalid/'),
    );
    expect(controller.managementUri, isNull);
  });

  test(
    'legacy local premium/trial preferences do not grant access after reinstall/hydration',
    () async {
      SharedPreferences.setMockInitialValues({
        'is_premium': true,
        'trial_active': true,
        'trial_start': billingNow.toIso8601String(),
      });
      final preferences = await SharedPreferences.getInstance();
      final app = AppState(
        guidedPlayer: InertAudioPlayer(),
        preferences: preferences,
      );
      addTearDown(app.dispose);
      await app.init();
      expect(app.isPremium, isFalse);
      expect(app.trialActive, isFalse);
      expect(app.hasFullAccess, isFalse);
    },
  );
}
