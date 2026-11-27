import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:relax_mindfulness/screens/premium_screen.dart';
import 'package:relax_mindfulness/services/subscription_controller.dart';

import 'support/billing_fixtures.dart';
import 'support/shared_background.dart';

Future<SubscriptionController> mountPremium(
  WidgetTester tester,
  FakeBillingGateway gateway, {
  BillingConfiguration configuration = enabledBilling,
  double width = 390,
  double scale = 1,
  Future<bool> Function(Uri)? openLink,
}) async {
  await tester.binding.setSurfaceSize(Size(width, 844));
  final billing = SubscriptionController(
    configuration: configuration,
    gateway: gateway,
    now: () => billingNow,
  );
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.binding.setSurfaceSize(null);
  });
  await tester.pumpWidget(
    // This fixture owns the controller. Disposal during tree teardown cancels
    // expiry timers before Flutter's end-of-test invariant verification.
    ChangeNotifierProvider<SubscriptionController>(
      create: (_) => billing,
      lazy: false,
      child: CupertinoApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: PremiumScreen(controller: billing, openExternalLink: openLink),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  expectSharedBackground(tester);
  return billing;
}

Future<void> tapPremium(WidgetTester tester, String key) async {
  await tester.pump();
  final target = find.byKey(ValueKey(key));
  await tester.ensureVisible(target);
  await tester.tap(target);
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  testWidgets(
    'unconfigured builds cannot start a purchase and do not invent prices or a free trial',
    (tester) async {
      final gateway = FakeBillingGateway();
      await mountPremium(
        tester,
        gateway,
        configuration: const BillingConfiguration(platform: TargetPlatform.iOS),
      );
      expect(
        tester
            .widget<CupertinoButton>(
              find.byKey(const ValueKey('purchase-store-plan')),
            )
            .onPressed,
        isNull,
      );
      expect(
        find.textContaining('Store connection is not configured'),
        findsOneWidget,
      );
      expect(find.textContaining('7-Day'), findsNothing);
      expect(find.textContaining(r'$6.99'), findsNothing);
      expect(gateway.configuredKeys, isEmpty);
      expect(gateway.purchasedPackages, isEmpty);
    },
  );

  testWidgets(
    'localized prices come from offerings and checkout requires an explicit selected plan',
    (tester) async {
      final gateway = FakeBillingGateway();
      final billing = await mountPremium(tester, gateway);
      expect(find.text('€4.25 / month'), findsOneWidget);
      expect(
        tester
            .widget<CupertinoButton>(
              find.byKey(const ValueKey('purchase-store-plan')),
            )
            .onPressed,
        isNull,
      );
      await tapPremium(tester, 'premium-plan-monthly');
      expect(gateway.purchasedPackages, isEmpty);
      gateway.purchasedCustomer = billingCustomer(active: true);
      await tapPremium(tester, 'purchase-store-plan');
      expect(gateway.purchasedPackages.single.identifier, 'monthly');
      expect(billing.hasFullAccess, isTrue);
      expect(
        find.byKey(const ValueKey('premium-active-status')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('purchase-store-plan')), findsNothing);
    },
  );

  testWidgets(
    'a purchase callback without access is not displayed as a trial or success',
    (tester) async {
      final gateway = FakeBillingGateway();
      await mountPremium(tester, gateway);
      await tapPremium(tester, 'premium-plan-monthly');
      await tapPremium(tester, 'purchase-store-plan');
      expect(find.byKey(const ValueKey('premium-active-status')), findsNothing);
      expect(find.textContaining('Do not pay again'), findsOneWidget);
      expect(find.text('Store trial active'), findsNothing);
      expect(
        tester
            .widget<CupertinoButton>(
              find.byKey(const ValueKey('purchase-store-plan')),
            )
            .onPressed,
        isNull,
      );
    },
  );

  testWidgets(
    'restore errors remain errors, not a false empty-purchase result',
    (tester) async {
      final gateway = FakeBillingGateway()
        ..restoreError = StateError('PRIVATE_TRANSACTION');
      await mountPremium(tester, gateway);
      await tapPremium(tester, 'restore-store-purchases');
      expect(find.textContaining('could not be restored'), findsOneWidget);
      expect(
        find.textContaining('No active premium entitlement'),
        findsNothing,
      );
      expect(find.textContaining('PRIVATE_TRANSACTION'), findsNothing);
      expect(gateway.restoreCalls, 1);
    },
  );

  testWidgets(
    'legal links open their configured HTTPS destination rather than doing nothing',
    (tester) async {
      final opened = <Uri>[];
      await mountPremium(
        tester,
        FakeBillingGateway(),
        openLink: (uri) async {
          opened.add(uri);
          return true;
        },
      );
      await tapPremium(tester, 'premium-privacy-link');
      await tapPremium(tester, 'premium-terms-link');
      expect(opened, [enabledBilling.privacyUri, enabledBilling.termsUri]);
    },
  );

  testWidgets('a failed legal-link launch is explained honestly', (
    tester,
  ) async {
    await mountPremium(
      tester,
      FakeBillingGateway(),
      openLink: (_) async => false,
    );
    await tapPremium(tester, 'premium-privacy-link');
    expect(
      find.textContaining('This link could not be opened'),
      findsOneWidget,
    );
  });

  testWidgets(
    'plans, restore and legal controls remain reachable at 320px with larger text',
    (tester) async {
      await mountPremium(tester, FakeBillingGateway(), width: 320, scale: 1.4);
      await tapPremium(tester, 'premium-plan-monthly');
      await tester.ensureVisible(
        find.byKey(const ValueKey('premium-terms-link')),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );
}
