import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relax_mindfulness/components/sanctuary_components.dart';
import 'package:relax_mindfulness/components/sanctuary_icon.dart';
import 'package:relax_mindfulness/components/sanctuary_tab_bar.dart';
import 'package:relax_mindfulness/theme/mixer_theme.dart';

const _items = [
  BottomNavigationBarItem(
    icon: SanctuaryIcon(SanctuarySymbol.home),
    label: 'Home',
  ),
  BottomNavigationBarItem(
    icon: SanctuaryIcon(SanctuarySymbol.sounds),
    label: 'Sounds',
  ),
  BottomNavigationBarItem(
    icon: SanctuaryIcon(SanctuarySymbol.meditate),
    label: 'Meditate',
  ),
  BottomNavigationBarItem(
    icon: SanctuaryIcon(SanctuarySymbol.sleep),
    label: 'Sleep',
  ),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader(
      'MixerSans',
    )..addFont(rootBundle.load('assets/fonts/mixer/Roboto.ttf'))).load();
  });
  test('the shared page and surface colors are the approved Sleep palette', () {
    expect(MixerTheme.background, const Color(0xFF02132C));
    expect(MixerTheme.surface, const Color(0xFF122945));
    expect(MixerTheme.surfaceActive, const Color(0xFF193853));
    expect(MixerTheme.control, const Color(0xFF223F5C));
    expect(SanctuaryPalette.navy, MixerTheme.background);
    expect(SanctuaryPalette.navySurface, MixerTheme.surface);
    expect(SanctuaryPalette.navyActive, MixerTheme.surfaceActive);
    expect(SanctuaryPalette.navyControl, MixerTheme.control);
  });

  test(
    'copyWith preserves floating navigation when the scaffold connects its controller',
    () {
      var selected = -1;
      final original = SanctuaryTabBar(
        items: _items,
        labelScale: 1.6,
        height: SanctuaryTabBar.extentForTextScale(1.6),
      );
      final copied = original.copyWith(
        currentIndex: 2,
        onTap: (index) => selected = index,
      );
      expect(copied, isA<SanctuaryTabBar>());
      expect(copied.items, same(_items));
      expect(copied.currentIndex, 2);
      expect(copied.labelScale, 1.6);
      expect(copied.height, original.height);
      expect(copied.backgroundColor, MixerTheme.navigation);
      copied.onTap!(3);
      expect(selected, 3);
    },
  );

  for (final width in [320.0, 390.0, 823.0]) {
    for (final inset in [0.0, 34.0]) {
      testWidgets(
        'floating tabs fit $width pixels with $inset system inset and larger text',
        (tester) async {
          await tester.binding.setSurfaceSize(Size(width, 844));
          addTearDown(() async {
            await tester.pumpWidget(const SizedBox.shrink());
            await tester.binding.setSurfaceSize(null);
          });
          var selected = -1;
          const scale = 1.6;
          await tester.pumpWidget(
            CupertinoApp(
              home: Builder(
                builder: (context) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    padding: EdgeInsets.only(bottom: inset),
                    viewPadding: EdgeInsets.only(bottom: inset),
                    textScaler: const TextScaler.linear(scale),
                    disableAnimations: true,
                  ),
                  child: CupertinoTabScaffold(
                    tabBar: SanctuaryTabBar(
                      items: _items,
                      labelScale: scale,
                      height: SanctuaryTabBar.extentForTextScale(scale),
                      onTap: (index) => selected = index,
                    ),
                    tabBuilder: (context, index) =>
                        Center(child: Text('Destination $index')),
                  ),
                ),
              ),
            ),
          );
          await tester.pump();
          expect(find.byType(SanctuaryTabBar), findsOneWidget);
          final capsule = tester.getRect(
            find.byKey(const ValueKey('floating-tab-bar')),
          );
          expect(capsule.width, lessThanOrEqualTo(520));
          expect(capsule.left, greaterThanOrEqualTo(16));
          expect(capsule.right, lessThanOrEqualTo(width - 16));
          expect(capsule.bottom, closeTo(844 - inset - 12, 0.1));
          for (var index = 0; index < 4; index++) {
            final button = find.byKey(ValueKey('main-tab-$index'));
            expect(tester.getSize(button).width, greaterThanOrEqualTo(44));
            expect(tester.getSize(button).height, greaterThanOrEqualTo(44));
            expect(button.hitTestable(), findsOneWidget);
            await tester.tap(button);
            await tester.pump();
            expect(selected, index);
            expect(find.text('Destination $index'), findsOneWidget);
            expect(
              tester
                  .getRect(button)
                  .contains(
                    tester.getCenter(
                      find.byKey(const ValueKey('selected-tab-dot')),
                    ),
                  ),
              isTrue,
            );
            expect(tester.takeException(), isNull);
          }
          expect(
            find.descendant(
              of: find.byType(SanctuaryTabBar),
              matching: find.byType(Icon),
            ),
            findsNothing,
          );
        },
      );
    }
  }

  testWidgets(
    'accessible navigation uses an opaque capsule without changing tab semantics',
    (tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(context).copyWith(accessibleNavigation: true),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: SanctuaryTabBar(
                  items: _items,
                  currentIndex: 3,
                  onTap: (_) {},
                ),
              ),
            ),
          ),
        ),
      );
      final bar = tester.widget<Container>(
        find.byKey(const ValueKey('floating-tab-bar')),
      );
      expect((bar.decoration! as BoxDecoration).color, MixerTheme.surface);
      final blur = tester.widget<BackdropFilter>(
        find.descendant(
          of: find.byType(SanctuaryTabBar),
          matching: find.byType(BackdropFilter),
        ),
      );
      expect(blur.enabled, isFalse);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              widget.properties.label == 'Sleep' &&
              widget.properties.selected == true,
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
