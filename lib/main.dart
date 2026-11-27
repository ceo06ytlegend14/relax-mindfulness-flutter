import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'dart:math' as math;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:relax_mindfulness/providers/app_state.dart';
import 'package:relax_mindfulness/providers/mixer_controller.dart';
import 'package:relax_mindfulness/theme/mixer_theme.dart';
import 'package:relax_mindfulness/theme/app_theme.dart';
import 'package:relax_mindfulness/screens/home_screen.dart';
import 'package:relax_mindfulness/screens/meditation_screen.dart';
import 'package:relax_mindfulness/screens/breathe_screen.dart';
import 'package:relax_mindfulness/screens/sounds_screen.dart';
import 'package:relax_mindfulness/screens/sleep_screen.dart';
import 'package:relax_mindfulness/screens/ai_studio_screen.dart';
import 'package:relax_mindfulness/components/glass_components.dart';
import 'package:relax_mindfulness/components/guided_player.dart';
import 'package:relax_mindfulness/components/sanctuary_icon.dart';
import 'package:relax_mindfulness/components/sanctuary_tab_bar.dart';

final FlutterLocalNotificationsPlugin localNotifications =
    FlutterLocalNotificationsPlugin();

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Keep Flutter/platform error reporting intact. Recoverable feature failures
  // are handled at their boundaries, not silently declared globally handled.

  // Make status bar transparent for edge-to-edge iOS design
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
    ),
  );

  // ── GPU & Image Cache tuning for maximum FPS ──
  PaintingBinding.instance.imageCache.maximumSizeBytes = 200 << 20; // 200 MB
  PaintingBinding.instance.imageCache.maximumSize = 200;

  final appState = AppState();

  // Render the root before native setup rather than blocking the first frame.
  // Cold-start timing/watchdog behavior still requires real-device measurement.
  runApp(
    ChangeNotifierProvider.value(value: appState, child: const SanctuaryApp()),
  );

  // Initialize native platform services safely in background post-first-frame
  _initNativeServices(appState);
}

Future<void> _initNativeServices(AppState appState) async {
  // 1. SharedPreferences & Audio engine state
  try {
    await appState.init();
  } catch (e) {
    debugPrint("AppState init error: $e");
  }

  // 2. Lock to portrait mode on mobile devices
  if (!kIsWeb) {
    try {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    } catch (e) {
      debugPrint("Orientation error: $e");
    }
  }

  // 3. Timezone & Local Notifications
  try {
    tz.initializeTimeZones();
    if (!kIsWeb) {
      const DarwinInitializationSettings initSettingsDarwin =
          DarwinInitializationSettings(
            requestSoundPermission: false,
            requestBadgePermission: false,
            requestAlertPermission: false,
          );
      const InitializationSettings initSettings = InitializationSettings(
        iOS: initSettingsDarwin,
      );
      await localNotifications.initialize(initSettings);
    }
  } catch (e) {
    debugPrint("Notifications init error: $e");
  }

  // 4. Store SDK setup uses platform-specific PUBLIC keys. No local premium
  // preference, automatic trial or successful payment callback grants access.
  await appState.initializePurchases();

  // 5. Deep Link Handling (Web)
  if (kIsWeb) {
    try {
      appState.parseAndApplyMixFromUri(Uri.base);
    } catch (e) {
      debugPrint("Deep link parsing error: $e");
    }
  }
}

// ─── Root App — CupertinoApp for full native iOS feel ─────────────────────────
class SanctuaryApp extends StatelessWidget {
  const SanctuaryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MixerController(context.read<AppState>()),
      child: CupertinoApp(
        title: 'Sanctuary – Relax & Meditate',
        localizationsDelegates: const [DefaultMaterialLocalizations.delegate],
        debugShowCheckedModeBanner: false,
        theme: buildCupertinoTheme(),
        builder: (context, child) {
          // Protect layout against RenderFlex yellow/black overflows on large accessibility fonts
          final mediaQuery = MediaQuery.of(context);
          final clampedScaler = mediaQuery.textScaler.clamp(
            minScaleFactor: 0.85,
            maxScaleFactor: 1.28,
          );
          return MediaQuery(
            data: mediaQuery.copyWith(textScaler: clampedScaler),
            child: child ?? const SizedBox.shrink(),
          );
        },
        // ── iOS Bouncing Scroll Physics globally ──
        scrollBehavior: const _IOSScrollBehavior(),
        home: const AppShell(),
      ),
    );
  }
}

// ── Global iOS Bouncing Scroll Behavior ──────────────────────────────────────
class _IOSScrollBehavior extends ScrollBehavior {
  const _IOSScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) => child; // No scrollbars — pure native iOS feel

  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.stylus,
    PointerDeviceKind.trackpad,
  };
}

// Only structural state belongs in the shell. Countdown/volume notifications
// are consumed by their own controls, not a rebuild of every tab and overlay.
typedef _ShellPresentation = ({
  AppTab tab,
  bool background,
  bool guidedExpanded,
  bool ambientExpanded,
  bool hasAmbientSession,
  bool hasAmbientRequest,
  bool hasGuidedSession,
  bool showMoodDialog,
});

// ─── AppShell — CupertinoTabScaffold with synced AppState ─────────────────────
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with WidgetsBindingObserver {
  late final CupertinoTabController _tabController;

  // Clean 4-tab intuitive structure (Home, Sounds mixer, Meditate, Sleep)
  static const _tabOrder = [
    AppTab.home,
    AppTab.sounds,
    AppTab.meditate,
    AppTab.sleep,
  ];

  int _appTabToIndex(AppTab tab) {
    switch (tab) {
      case AppTab.home:
        return 0;
      case AppTab.sounds:
        return 1;
      case AppTab.meditate:
      case AppTab.breathe:
        return 2;
      case AppTab.sleep:
      case AppTab.aiStudio:
        return 3;
    }
  }

  AppTab _indexToAppTab(int index) =>
      _tabOrder[index.clamp(0, _tabOrder.length - 1)];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabController = CupertinoTabController(initialIndex: 0);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycleState) {
    // Stop decorative work for screen lock, app switching and iOS inactive
    // overlays too. Audio ownership is outside the widget/ticker lifecycle.
    final app = context.read<AppState>();
    app.setBackgroundMode(lifecycleState != AppLifecycleState.resumed);
    if (lifecycleState == AppLifecycleState.resumed) {
      unawaited(app.refreshPurchaseStatus());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Selector<AppState, _ShellPresentation>(
      selector: (_, state) => (
        tab: state.tab,
        background: state.isBackgroundMode,
        guidedExpanded: state.isGuidedPlayerExpanded,
        ambientExpanded: state.isAmbientPlayerExpanded,
        hasAmbientSession: state.hasAmbientSession,
        hasAmbientRequest: state.hasAmbientPlaybackRequest,
        hasGuidedSession: state.hasGuidedSession,
        showMoodDialog: state.showMoodDialog,
      ),
      builder: (context, presentation, _) {
        final state = context.read<AppState>();
        // ── Sync CupertinoTabController → AppState ──
        final expectedIndex = _appTabToIndex(presentation.tab);
        if (_tabController.index != expectedIndex) {
          // Avoid setState loop — just set index directly
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _tabController.index != expectedIndex) {
              _tabController.index = expectedIndex;
            }
          });
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final width = math.min(constraints.maxWidth, MixerTheme.maxWidth);
            // CupertinoTabScaffold suppresses text scaling inside its bar. Carry
            // the intended label scale through explicitly, including nonlinear
            // platform text scaling, and reserve the larger capsule's height.
            final navLabelScale =
                MediaQuery.textScalerOf(context).scale(11) / 11;
            final navHeight = SanctuaryTabBar.extentForTextScale(navLabelScale);
            final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
            final theme = CupertinoTheme.of(context);
            return ColoredBox(
              color: MixerTheme.background,
              child: Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: width,
                  height: constraints.maxHeight,
                  child: CupertinoTheme(
                    data: theme.copyWith(
                      textTheme: theme.textTheme.copyWith(
                        tabLabelTextStyle: TextStyle(
                          fontFamily: MixerTheme.font,
                          fontSize: 11 * navLabelScale,
                          color: MixerTheme.muted,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                    child: TickerMode(
                      key: const ValueKey('app-motion'),
                      enabled: !presentation.background,
                      child: Stack(
                        children: [
                          // Page backgrounds are local solid colors. Decorative
                          // artwork belongs inside cards, not behind the tabs or
                          // pushed wellbeing tools. Do not request a wallpaper
                          // which an opaque page immediately hides.
                          // A floating capsule, with Cupertino tab stacks preserved.
                          TickerMode(
                            key: const ValueKey('tab-motion'),
                            enabled:
                                !presentation.guidedExpanded &&
                                !presentation.ambientExpanded &&
                                !presentation.showMoodDialog,
                            child: CupertinoTabScaffold(
                              backgroundColor: Colors.transparent,
                              controller: _tabController,
                              tabBar: SanctuaryTabBar(
                                labelScale: navLabelScale,
                                onTap: (index) {
                                  HapticFeedback.selectionClick();
                                  state.setTab(_indexToAppTab(index));
                                },
                                backgroundColor: MixerTheme.navigation,
                                border: null,
                                activeColor: MixerTheme.mintLight,
                                inactiveColor: MixerTheme.muted,
                                iconSize: 24,
                                height: navHeight,
                                currentIndex: _appTabToIndex(presentation.tab),
                                items: const [
                                  BottomNavigationBarItem(
                                    icon: SanctuaryIcon(SanctuarySymbol.home),
                                    activeIcon: SanctuaryIcon(
                                      SanctuarySymbol.home,
                                    ),
                                    label: 'Home',
                                  ),
                                  BottomNavigationBarItem(
                                    icon: SanctuaryIcon(SanctuarySymbol.sounds),
                                    activeIcon: SanctuaryIcon(
                                      SanctuarySymbol.sounds,
                                    ),
                                    label: 'Sounds',
                                  ),
                                  BottomNavigationBarItem(
                                    icon: SanctuaryIcon(
                                      SanctuarySymbol.meditate,
                                    ),
                                    activeIcon: SanctuaryIcon(
                                      SanctuarySymbol.meditate,
                                    ),
                                    label: 'Meditate',
                                  ),
                                  BottomNavigationBarItem(
                                    icon: SanctuaryIcon(SanctuarySymbol.sleep),
                                    activeIcon: SanctuaryIcon(
                                      SanctuarySymbol.sleep,
                                    ),
                                    label: 'Sleep',
                                  ),
                                ],
                              ),
                              tabBuilder: (context, index) {
                                final tab = _indexToAppTab(index);
                                return CupertinoTabView(
                                  builder: (ctx) => RepaintBoundary(
                                    child: _buildScreen(tab, ctx),
                                  ),
                                );
                              },
                            ),
                          ),

                          // ── 🎵 Floating Mini Player ───────────────────────────────────
                          if (!presentation.guidedExpanded &&
                              !presentation.ambientExpanded &&
                              (presentation.hasAmbientSession ||
                                  presentation.hasAmbientRequest ||
                                  presentation.hasGuidedSession))
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: navHeight + bottomInset + 8,
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                heightFactor: 1,
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 560,
                                  ),
                                  child: const SanctuaryMiniPlayer(),
                                ),
                              ),
                            ),

                          // ── 😊 Mood Check-In Dialog ───────────────────────────────────
                          if (presentation.showMoodDialog)
                            MoodCheckInDialog(
                              onMoodSelected: (rating) =>
                                  state.submitMood(rating),
                              onSkip: () => state.dismissMood(),
                            ),

                          // ── 🎧 Full-Screen Guided Player ──────────────────────────────
                          if (presentation.guidedExpanded)
                            const Positioned.fill(child: GuidedPlayerOverlay()),
                          if (presentation.ambientExpanded)
                            const Positioned.fill(
                              child: AmbientPlayerOverlay(),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildScreen(AppTab tab, BuildContext context) {
    switch (tab) {
      case AppTab.home:
        return const HomeScreen();
      case AppTab.meditate:
        return const MeditationScreen();
      case AppTab.breathe:
        return const BreatheScreen();
      case AppTab.sounds:
        return const SoundsScreen();
      case AppTab.sleep:
        return const SleepScreen();
      case AppTab.aiStudio:
        return const AiStudioScreen();
    }
  }
}
