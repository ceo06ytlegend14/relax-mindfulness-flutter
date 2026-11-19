import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

/// Public SDK keys only. New purchases are opt-in and require real legal URLs.
/// Configuring a client does not configure products, receipts or store accounts.
class BillingConfiguration {
  const BillingConfiguration({
    required this.platform,
    this.isWeb = false,
    this.iosPublicKey = '',
    this.androidPublicKey = '',
    this.purchasesEnabled = false,
    this.privacyPolicyUrl = '',
    this.termsUrl = '',
    this.entitlementId = 'premium',
  });

  factory BillingConfiguration.fromEnvironment() => BillingConfiguration(
    platform: defaultTargetPlatform,
    isWeb: kIsWeb,
    iosPublicKey: const String.fromEnvironment('REVENUECAT_IOS_API_KEY'),
    androidPublicKey: const String.fromEnvironment(
      'REVENUECAT_ANDROID_API_KEY',
    ),
    purchasesEnabled: const bool.fromEnvironment('ENABLE_STORE_PURCHASES'),
    privacyPolicyUrl: const String.fromEnvironment('PRIVACY_POLICY_URL'),
    termsUrl: const String.fromEnvironment('TERMS_URL'),
    entitlementId: const String.fromEnvironment(
      'REVENUECAT_ENTITLEMENT_ID',
      defaultValue: 'premium',
    ),
  );

  final TargetPlatform platform;
  final bool isWeb;
  final String iosPublicKey;
  final String androidPublicKey;
  final bool purchasesEnabled;
  final String privacyPolicyUrl;
  final String termsUrl;
  final String entitlementId;

  bool get supportsStore =>
      !isWeb &&
      (platform == TargetPlatform.iOS || platform == TargetPlatform.android);

  String? get publicKey {
    if (!supportsStore || entitlementId.trim().isEmpty) return null;
    final key = platform == TargetPlatform.iOS
        ? iosPublicKey
        : androidPublicKey;
    final prefix = platform == TargetPlatform.iOS ? 'appl_' : 'goog_';
    if (!key.startsWith(prefix) ||
        key.length <= prefix.length ||
        key.toLowerCase().contains('your_'))
      return null;
    return key;
  }

  static Uri? legalUri(String value) {
    final uri = Uri.tryParse(value);
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.host == 'localhost' ||
        uri.host == '127.0.0.1' ||
        uri.host == '::1' ||
        uri.host == 'example.com' ||
        uri.host.endsWith('.example') ||
        uri.host.endsWith('.invalid'))
      return null;
    return uri;
  }

  Uri? get privacyUri => legalUri(privacyPolicyUrl);
  Uri? get termsUri => legalUri(termsUrl);
  bool get allowsNewPurchases =>
      purchasesEnabled &&
      publicKey != null &&
      privacyUri != null &&
      termsUri != null;
}

/// Small injectable boundary: presentation tests never call a store or charge.
abstract interface class BillingGateway {
  Future<void> configure(String publicKey);
  Future<CustomerInfo> customerInfo();
  Future<Offerings> offerings();
  Future<CustomerInfo> purchase(Package package);
  Future<CustomerInfo> restore();
  void addListener(void Function(CustomerInfo) listener);
  void removeListener(void Function(CustomerInfo) listener);
}

class RevenueCatBillingGateway implements BillingGateway {
  @override
  Future<void> configure(String publicKey) async {
    await Purchases.setLogLevel(LogLevel.warn);
    final configuration = PurchasesConfiguration(publicKey)
      ..entitlementVerificationMode = EntitlementVerificationMode.informational;
    await Purchases.configure(configuration);
  }

  @override
  Future<CustomerInfo> customerInfo() => Purchases.getCustomerInfo();
  @override
  Future<Offerings> offerings() => Purchases.getOfferings();
  @override
  Future<CustomerInfo> purchase(Package package) async =>
      (await Purchases.purchase(PurchaseParams.package(package))).customerInfo;
  @override
  Future<CustomerInfo> restore() => Purchases.restorePurchases();
  @override
  void addListener(void Function(CustomerInfo) listener) =>
      Purchases.addCustomerInfoUpdateListener(listener);
  @override
  void removeListener(void Function(CustomerInfo) listener) =>
      Purchases.removeCustomerInfoUpdateListener(listener);
}

enum BillingResult {
  active,
  noActiveEntitlement,
  cancelled,
  pending,
  unavailable,
  busy,
  failed,
}

/// Access comes only from the SDK's active entitlement, never a preference,
/// backup, successful payment callback alone, or a locally started trial.
/// Server-hosted paid services must independently authorize each request.
class SubscriptionController extends ChangeNotifier {
  SubscriptionController({
    BillingConfiguration? configuration,
    BillingGateway? gateway,
    DateTime Function()? now,
    this.requestTimeout = const Duration(seconds: 20),
  }) : configuration = configuration ?? BillingConfiguration.fromEnvironment(),
       _gateway = gateway ?? RevenueCatBillingGateway(),
       _now = now ?? DateTime.now;

  final BillingConfiguration configuration;
  final BillingGateway _gateway;
  final DateTime Function() _now;
  final Duration requestTimeout;
  CustomerInfo? _customer;
  List<Package> _plans = const [];
  Future<void>? _initializing;
  Future<void>? _refreshing;
  Timer? _expiryTimer;
  bool _configured = false;
  bool _loading = false;
  bool _busy = false;
  bool _disposed = false;
  bool _customerChecked = false;
  bool _checkoutNeedsReview = false;
  int _revision = 0;
  String? _notice;

  bool get isLoading => _loading;
  bool get isBusy => _busy;
  bool get isConfigured => _configured;
  bool get canRestore => _configured && !_loading && !_busy;
  bool get canPurchase =>
      canRestore &&
      configuration.allowsNewPurchases &&
      _customerChecked &&
      _plans.isNotEmpty &&
      !hasFullAccess &&
      !_accessIsUncertain &&
      !_checkoutNeedsReview;

  bool get _accessIsUncertain =>
      _customer?.entitlements.verification == VerificationResult.failed ||
      (_customer?.entitlements.active.containsKey(
            configuration.entitlementId,
          ) ??
          false);
  List<Package> get plans => _plans;
  String? get notice => _notice;

  EntitlementInfo? get _entitlement {
    final customer = _customer;
    if (customer == null ||
        customer.entitlements.verification == VerificationResult.failed)
      return null;
    return customer.entitlements.active[configuration.entitlementId];
  }

  DateTime? get expiration =>
      DateTime.tryParse(_entitlement?.expirationDate ?? '');
  bool get hasFullAccess {
    final entitlement = _entitlement;
    if (entitlement == null ||
        !entitlement.isActive ||
        entitlement.verification == VerificationResult.failed)
      return false;
    if (entitlement.expirationDate == null)
      return entitlement.periodType != PeriodType.trial;
    final end = expiration;
    return end != null && end.isAfter(_now());
  }

  bool get trialActive =>
      hasFullAccess && _entitlement?.periodType == PeriodType.trial;
  int get trialDaysLeft => trialActive && expiration != null
      ? (expiration!.difference(_now()).inMilliseconds /
                Duration.millisecondsPerDay)
            .ceil()
            .clamp(0, 366)
            .toInt()
      : 0;

  Uri? get managementUri {
    final uri = Uri.tryParse(_customer?.managementURL ?? '');
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.userInfo.isNotEmpty ||
        !const ['apps.apple.com', 'play.google.com'].contains(uri.host))
      return null;
    return uri;
  }

  String get availabilityMessage {
    if (!configuration.supportsStore)
      return 'Store purchases are available only in the iOS and Android apps.';
    if (configuration.publicKey == null)
      return 'Store connection is not configured in this build.';
    if (!configuration.allowsNewPurchases)
      return 'New purchases are not enabled in this build. You can still restore existing store access when connected.';
    if (_loading) return 'Checking the store…';
    if (!_configured || !_customerChecked)
      return 'Store access could not be checked. Try refreshing or restoring before making a purchase.';
    if (!hasFullAccess && (_accessIsUncertain || _checkoutNeedsReview))
      return 'Store access needs to be verified. Restore purchases or contact support; do not purchase again.';
    if (_plans.isEmpty)
      return 'No supported subscription plans are available from the store right now.';
    return 'Prices and billing periods below come from your device’s store. Any eligible offer is confirmed by the store before payment.';
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  void _accept(CustomerInfo customer) {
    if (_disposed) return;
    _customer = customer;
    _customerChecked = true;
    if (hasFullAccess && _checkoutNeedsReview) {
      _checkoutNeedsReview = false;
      _notice = null;
    }
    _scheduleExpiry();
    _notify();
  }

  void _updated(CustomerInfo customer) {
    ++_revision; // A late explicit refresh/purchase must not undo a newer update.
    _accept(customer);
  }

  void _scheduleExpiry() {
    _expiryTimer?.cancel();
    final end = expiration;
    if (_disposed || end == null || !end.isAfter(_now())) return;
    final remaining = end.difference(_now());
    // Avoid browser/native timer overflow on long subscriptions.
    final delay = remaining > const Duration(hours: 24)
        ? const Duration(hours: 24)
        : remaining;
    _expiryTimer = Timer(delay, () {
      _notify();
      _scheduleExpiry();
    });
  }

  Future<void> initialize() {
    if (_disposed) return Future<void>.value();
    if (_initializing != null) return _initializing!;
    if (_configured) return refresh();
    return _initializing ??= _initialize().whenComplete(
      () => _initializing = null,
    );
  }

  Future<void> _initialize() async {
    final key = configuration.publicKey;
    if (key == null) return;
    _loading = true;
    _notify();
    try {
      await _gateway.configure(key).timeout(requestTimeout);
      if (_disposed) return;
      _configured = true;
      _gateway.addListener(_updated);
      await _loadStoreState();
    } catch (_) {
      _notice =
          'The store could not be reached. No purchase was started. Try again later.';
    } finally {
      _loading = false;
      _notify();
    }
  }

  Future<void> refresh() {
    if (_disposed || _busy) return Future<void>.value();
    if (_initializing != null) return _initializing!;
    if (!_configured) return initialize();
    return _refreshing ??= _refresh().whenComplete(() => _refreshing = null);
  }

  Future<void> _refresh() async {
    _loading = true;
    _notify();
    try {
      await _loadStoreState();
    } finally {
      _loading = false;
      _notify();
    }
  }

  Future<void> _loadStoreState() async {
    final revision = _revision;
    _notice = null;
    try {
      final customer = await _gateway.customerInfo().timeout(requestTimeout);
      if (!_disposed && revision == _revision) _accept(customer);
    } catch (_) {
      if (_disposed) return;
      if (revision == _revision) {
        _customerChecked = false;
        _notice =
            'Access could not be refreshed. Known access is kept only until its recorded expiry. Try again or restore your purchase.';
      }
    }
    try {
      final offerings = await _gateway.offerings().timeout(requestTimeout);
      if (_disposed) return;
      _plans = List.unmodifiable(
        (offerings.current?.availablePackages ?? <Package>[]).where((package) {
          final product = package.storeProduct;
          final period = product.subscriptionPeriod;
          final supportedPeriod =
              (package.packageType == PackageType.monthly && period == 'P1M') ||
              (package.packageType == PackageType.annual &&
                  (period == 'P1Y' || period == 'P12M'));
          return supportedPeriod &&
              product.price.isFinite &&
              product.price > 0 &&
              product.priceString.trim().isNotEmpty &&
              product.currencyCode.trim().isNotEmpty;
        }),
      );
    } catch (_) {
      if (_disposed) return;
      _plans = const [];
      _notice ??=
          'Plans could not be loaded. No purchase was started. Try again later.';
    }
  }

  Future<BillingResult> purchase(Package package) async {
    if (_busy || _loading) return BillingResult.busy;
    if (!canPurchase || !_plans.any((plan) => identical(plan, package)))
      return BillingResult.unavailable;
    return _perform(() => _gateway.purchase(package), restoring: false);
  }

  Future<BillingResult> restore() async {
    if (_busy || _loading) return BillingResult.busy;
    if (!canRestore) return BillingResult.unavailable;
    return _perform(_gateway.restore, restoring: true);
  }

  Future<BillingResult> _perform(
    Future<CustomerInfo> Function() operation, {
    required bool restoring,
  }) async {
    _busy = true;
    _notice = null;
    final revision = _revision;
    _notify();
    try {
      // Do not impose a network timeout on interactive store checkout. It may
      // legitimately wait for user authentication or a parental approval flow.
      final customer = await operation();
      if (_disposed) return BillingResult.unavailable;
      if (revision == _revision) _accept(customer);
      if (hasFullAccess) {
        _notice = restoring
            ? 'Active store access restored.'
            : 'Store access is active.';
        return BillingResult.active;
      }
      // A checkout callback without access is not proof that no charge occurred.
      // Keep another checkout disabled for this session, even after an empty
      // cached refresh/restore. Only confirmed access resolves that uncertainty.
      if (!restoring) _checkoutNeedsReview = true;
      _notice = restoring
          ? 'No active premium entitlement was returned by the store.'
          : 'The store returned no active premium entitlement yet. Do not pay again; try Restore purchases or contact support.';
      return BillingResult.noActiveEntitlement;
    } on PlatformException catch (error) {
      if (_disposed) return BillingResult.unavailable;
      final code = PurchasesErrorHelper.getErrorCode(error);
      if (code == PurchasesErrorCode.purchaseCancelledError) {
        _notice = 'Purchase cancelled. No access was granted by this action.';
        return BillingResult.cancelled;
      }
      if (code == PurchasesErrorCode.paymentPendingError) {
        if (!restoring) _checkoutNeedsReview = true;
        _notice =
            'Payment is pending. Access will update only when the store reports an active entitlement.';
        return BillingResult.pending;
      }
      if (!restoring) _checkoutNeedsReview = true;
      _notice = restoring
          ? 'Purchases could not be restored. Check your store connection and try again.'
          : 'Purchase could not be completed. Check the store before trying again.';
      return BillingResult.failed;
    } catch (_) {
      if (_disposed) return BillingResult.unavailable;
      if (!restoring) _checkoutNeedsReview = true;
      _notice = restoring
          ? 'Purchases could not be restored. Try again later.'
          : 'Purchase could not be completed. Check the store before trying again.';
      return BillingResult.failed;
    } finally {
      _busy = false;
      _notify();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    ++_revision;
    _expiryTimer?.cancel();
    if (_configured) _gateway.removeListener(_updated);
    super.dispose();
  }
}
