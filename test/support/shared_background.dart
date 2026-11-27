import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relax_mindfulness/components/sanctuary_components.dart';
import 'package:relax_mindfulness/theme/mixer_theme.dart';

/// Scope player assertions to the overlay, not the covered tab underneath it.
Finder expectSharedBackground(WidgetTester tester, {Finder? within}) {
  final background = within == null
      ? find.byType(SanctuaryBackground)
      : find.descendant(of: within, matching: find.byType(SanctuaryBackground));
  expect(background, findsOneWidget);
  final sky = find.descendant(
    of: background,
    matching: find.byType(SanctuaryBackdrop),
  );
  final backdrop = tester.widget<SanctuaryBackdrop>(sky);
  expect(backdrop.asset, 'assets/images/sleep/night_sky.webp');
  expect(backdrop.color, MixerTheme.background);
  expect(backdrop.darkenLeft, isFalse);
  final image = tester.widget<Image>(
    find.descendant(of: sky, matching: find.byType(Image)),
  );
  expect(image.image, const AssetImage('assets/images/sleep/night_sky.webp'));
  expect(image.fit, BoxFit.cover);
  expect(image.alignment, Alignment.topCenter);
  expect(image.excludeFromSemantics, isTrue);
  expect(
    find.ancestor(of: sky, matching: find.byType(IgnorePointer)),
    findsWidgets,
  );
  expect(
    tester.renderObject<RenderRepaintBoundary>(
      find.ancestor(of: sky, matching: find.byType(RepaintBoundary)).first,
    ),
    isA<RenderRepaintBoundary>(),
  );
  return sky;
}
