import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:relax_mindfulness/theme/mixer_theme.dart';

/// Floating, iPhone-inspired navigation while retaining CupertinoTabScaffold's
/// independent navigators, selected index and normal tab semantics.
///
/// copyWith must preserve this type: CupertinoTabScaffold copies its bar to
/// connect the actual controller. The bottom lift is separate from the device's
/// home-indicator inset; no fake system home indicator is painted by the app.
class SanctuaryTabBar extends CupertinoTabBar {
  const SanctuaryTabBar({
    super.key,
    required super.items,
    super.currentIndex = 0,
    super.onTap,
    super.backgroundColor = MixerTheme.navigation,
    super.activeColor = MixerTheme.mintLight,
    super.inactiveColor = MixerTheme.muted,
    super.iconSize = 24,
    super.height = 84,
    super.border = null,
    this.labelScale = 1,
  });

  static const lift = 12.0;
  static const maxWidth = 520.0;

  // The scaffold wraps tab bars in MediaQuery.withNoTextScaling. The shell
  // supplies the label's original platform scale once, before that boundary.
  final double labelScale;

  static double extentForTextScale(double scale) =>
      84.0 + math.max(0.0, scale - 1) * 40.0;

  // Content may draw behind the floating gaps even when reduced-transparency
  // accessibility preferences make the capsule itself opaque.
  @override
  bool opaque(BuildContext context) => false;

  @override
  SanctuaryTabBar copyWith({
    Key? key,
    List<BottomNavigationBarItem>? items,
    Color? backgroundColor,
    Color? activeColor,
    Color? inactiveColor,
    double? iconSize,
    double? height,
    Border? border,
    int? currentIndex,
    ValueChanged<int>? onTap,
  }) => SanctuaryTabBar(
    key: key ?? this.key,
    items: items ?? this.items,
    backgroundColor: backgroundColor ?? this.backgroundColor,
    activeColor: activeColor ?? this.activeColor,
    inactiveColor: inactiveColor ?? this.inactiveColor,
    iconSize: iconSize ?? this.iconSize,
    height: height ?? this.height,
    border: border ?? this.border,
    currentIndex: currentIndex ?? this.currentIndex,
    onTap: onTap ?? this.onTap,
    labelScale: labelScale,
  );

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final reduceEffects = media.accessibleNavigation || media.highContrast;
    final fill = CupertinoDynamicColor.resolve(
      reduceEffects
          ? MixerTheme.surface
          : backgroundColor ?? MixerTheme.navigation,
      context,
    );
    final active = CupertinoDynamicColor.resolve(
      activeColor ?? CupertinoTheme.of(context).primaryColor,
      context,
    );
    final inactive = CupertinoDynamicColor.resolve(inactiveColor, context);
    final radius = BorderRadius.circular(40);
    final localizations = CupertinoLocalizations.of(context);
    return SizedBox(
      height: height + media.viewPadding.bottom,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          lift + media.viewPadding.bottom,
        ),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: maxWidth),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: radius,
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x30000000),
                    blurRadius: 28,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: radius,
                child: BackdropFilter(
                  enabled: !reduceEffects,
                  filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                  child: Container(
                    key: const ValueKey('floating-tab-bar'),
                    height: height - lift,
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: fill,
                      borderRadius: radius,
                      border:
                          border ?? Border.all(color: const Color(0x18D4E4FA)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var index = 0; index < items.length; index++) ...[
                          if (index > 0) const SizedBox(width: 4),
                          Expanded(
                            child: Semantics(
                              label: items[index].label,
                              hint: localizations.tabSemanticsLabel(
                                tabIndex: index + 1,
                                tabCount: items.length,
                              ),
                              button: true,
                              enabled: onTap != null,
                              selected: index == currentIndex,
                              excludeSemantics: true,
                              onTap: onTap == null ? null : () => onTap!(index),
                              child: CupertinoButton(
                                key: ValueKey('main-tab-$index'),
                                padding: EdgeInsets.zero,
                                minSize: 44,
                                borderRadius: BorderRadius.circular(32),
                                focusColor: MixerTheme.mintLight,
                                onPressed: onTap == null
                                    ? null
                                    : () => onTap!(index),
                                child: SizedBox.expand(
                                  child: AnimatedContainer(
                                    duration: media.disableAnimations
                                        ? Duration.zero
                                        : const Duration(milliseconds: 180),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(32),
                                      color: index == currentIndex
                                          ? MixerTheme.navigationSelected
                                          : const Color(0x00000000),
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        IconTheme(
                                          data: IconThemeData(
                                            size: iconSize,
                                            color: index == currentIndex
                                                ? active
                                                : inactive,
                                          ),
                                          child: index == currentIndex
                                              ? items[index].activeIcon
                                              : items[index].icon,
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            if (index == currentIndex) ...[
                                              Container(
                                                key: const ValueKey(
                                                  'selected-tab-dot',
                                                ),
                                                width: 3,
                                                height: 3,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: active,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                            ],
                                            Flexible(
                                              child: Text(
                                                items[index].label ?? '',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  fontFamily: MixerTheme.font,
                                                  fontSize: 11 * labelScale,
                                                  height: 1.2,
                                                  fontWeight:
                                                      index == currentIndex
                                                      ? FontWeight.w700
                                                      : FontWeight.w500,
                                                  color: index == currentIndex
                                                      ? active
                                                      : inactive,
                                                  decoration:
                                                      TextDecoration.none,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
