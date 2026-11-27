import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:relax_mindfulness/components/sanctuary_components.dart';
import 'package:relax_mindfulness/providers/app_state.dart';
import 'package:relax_mindfulness/services/subscription_controller.dart';
import 'package:relax_mindfulness/theme/mixer_theme.dart';
import 'package:url_launcher/url_launcher.dart';

/// Uses real store offerings and SDK entitlements. New sales are disabled by
/// default; there is no local trial, hardcoded price, or no-op legal button.
class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key, this.controller, this.openExternalLink});

  final SubscriptionController? controller;
  final Future<bool> Function(Uri)? openExternalLink;

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  late final SubscriptionController _billing;
  String? _selectedId;
  String? _linkNotice;

  @override
  void initState() {
    super.initState();
    _billing = widget.controller ?? context.read<AppState>().subscriptions;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_billing.initialize());
    });
  }

  Package? get _selected {
    for (final package in _billing.plans) {
      if (package.identifier == _selectedId) return package;
    }
    return null;
  }

  Future<void> _openLink(Uri uri) async {
    if (_linkNotice != null) setState(() => _linkNotice = null);
    try {
      final opened =
          await (widget.openExternalLink?.call(uri) ??
              launchUrl(uri, mode: LaunchMode.externalApplication));
      if (opened) return;
    } catch (_) {
      // Do not leak SDK/platform details or pretend that a link opened.
    }
    if (mounted)
      setState(
        () => _linkNotice =
            'This link could not be opened. Please try again on your device.',
      );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _billing,
      builder: (context, _) {
        final selected = _selected;
        final active = _billing.hasFullAccess;
        final waiting = _billing.isBusy || _billing.isLoading;
        return SanctuaryPageScaffold(
          navigationBar: const CupertinoNavigationBar(
            middle: Text('Sanctuary Premium'),
            backgroundColor: MixerTheme.background,
            border: null,
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    active
                        ? (_billing.trialActive
                              ? 'Store trial active'
                              : 'Premium access active')
                        : 'Your store subscription',
                    style: const TextStyle(
                      color: CupertinoColors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Access is based on your store account, not a local switch. '
                    'The core app remains available when subscriptions are unavailable.',
                    style: TextStyle(color: Color(0xFFBCD0DC), height: 1.5),
                  ),
                  const SizedBox(height: 20),
                  if (active) ...[
                    Text(
                      _billing.trialActive
                          ? '${_billing.trialDaysLeft} day(s) until the store trial’s recorded expiry.'
                          : 'The store SDK reports an active premium entitlement.',
                      key: const ValueKey('premium-active-status'),
                      style: const TextStyle(
                        color: Color(0xFF9CF0DA),
                        height: 1.5,
                      ),
                    ),
                    if (_billing.expiration != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Recorded expiry: ${_billing.expiration!.toLocal().toString().split('.').first}',
                        style: const TextStyle(
                          color: Color(0xFFBCD0DC),
                          fontSize: 13,
                        ),
                      ),
                    ],
                    if (_billing.managementUri != null)
                      CupertinoButton.filled(
                        key: const ValueKey('manage-store-subscription'),
                        onPressed: () => _openLink(_billing.managementUri!),
                        child: const Text('Manage subscription'),
                      ),
                  ] else ...[
                    Text(
                      _billing.availabilityMessage,
                      key: const ValueKey('premium-availability'),
                      style: const TextStyle(
                        color: Color(0xFFBCD0DC),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 18),
                    for (final package in _billing.plans)
                      _planTile(
                        package,
                        selected: package.identifier == _selectedId,
                      ),
                    if (_billing.plans.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      const Text(
                        'Select a plan. The full amount shown is billed for its stated period; no trial or discount is guaranteed.',
                        style: TextStyle(
                          color: Color(0xFFBCD0DC),
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    CupertinoButton.filled(
                      key: const ValueKey('purchase-store-plan'),
                      onPressed: selected != null && _billing.canPurchase
                          ? () async {
                              await _billing.purchase(selected);
                            }
                          : null,
                      child: const Text('Continue with store'),
                    ),
                  ],
                  if (waiting) ...[
                    const SizedBox(height: 18),
                    const CupertinoActivityIndicator(),
                    const SizedBox(height: 8),
                    const Text(
                      'Waiting for the store…',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFFBCD0DC)),
                    ),
                  ],
                  if (_billing.notice != null) ...[
                    const SizedBox(height: 18),
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        _billing.notice!,
                        key: const ValueKey('store-purchase-notice'),
                        style: const TextStyle(
                          color: Color(0xFF9CF0DA),
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 22),
                  CupertinoButton(
                    key: const ValueKey('restore-store-purchases'),
                    onPressed: _billing.canRestore
                        ? () async {
                            await _billing.restore();
                          }
                        : null,
                    child: const Text('Restore purchases'),
                  ),
                  CupertinoButton(
                    key: const ValueKey('refresh-store-access'),
                    onPressed: waiting
                        ? null
                        : () => unawaited(_billing.refresh()),
                    child: const Text('Check store connection'),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 14,
                    children: [
                      if (_billing.configuration.privacyUri != null)
                        CupertinoButton(
                          key: const ValueKey('premium-privacy-link'),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 8,
                          ),
                          onPressed: () =>
                              _openLink(_billing.configuration.privacyUri!),
                          child: const Text('Privacy policy'),
                        ),
                      if (_billing.configuration.termsUri != null)
                        CupertinoButton(
                          key: const ValueKey('premium-terms-link'),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 8,
                          ),
                          onPressed: () =>
                              _openLink(_billing.configuration.termsUri!),
                          child: const Text('Terms'),
                        ),
                    ],
                  ),
                  if (_linkNotice != null)
                    Text(
                      _linkNotice!,
                      style: const TextStyle(
                        color: Color(0xFFFFCA9B),
                        height: 1.5,
                      ),
                    ),
                  const SizedBox(height: 14),
                  const Text(
                    'Subscriptions renew automatically unless cancelled through your store. '
                    'The displayed price and billing period apply to the selected plan. '
                    'Your store confirms any eligible introductory offer and payment terms before you authorize payment. '
                    'Manage or cancel in App Store or Google Play subscription settings.',
                    style: TextStyle(
                      color: Color(0xFF9BB4C4),
                      fontSize: 12,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _planTile(Package package, {required bool selected}) {
    final product = package.storeProduct;
    final annual = package.packageType == PackageType.annual;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Semantics(
        selected: selected,
        child: CupertinoButton(
          key: ValueKey('premium-plan-${package.identifier}'),
          padding: EdgeInsets.zero,
          onPressed: _billing.isBusy || _billing.isLoading
              ? null
              : () => setState(() => _selectedId = package.identifier),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: selected ? MixerTheme.surfaceActive : MixerTheme.surface,
              borderRadius: BorderRadius.circular(18),
              // A selected-plan outline conveys state, not decorative chrome.
              border: selected
                  ? Border.all(color: MixerTheme.primary, width: 2)
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  annual ? 'Yearly' : 'Monthly',
                  style: const TextStyle(
                    color: CupertinoColors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  product.title,
                  style: const TextStyle(
                    color: Color(0xFFE3F1F5),
                    fontSize: 15,
                  ),
                ),
                if (product.description.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    product.description,
                    style: const TextStyle(
                      color: Color(0xFFBCD0DC),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Text(
                  '${product.priceString} / ${annual ? 'year' : 'month'}',
                  key: ValueKey('store-price-${package.identifier}'),
                  style: const TextStyle(
                    color: Color(0xFF9CF0DA),
                    fontSize: 23,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  annual ? 'Billed annually' : 'Billed monthly',
                  style: const TextStyle(
                    color: Color(0xFFBCD0DC),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
