import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'dart:io' show Platform;
import 'dart:math' as math;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:purchases_flutter/purchases_flutter.dart';
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

import 'dart:ui' show PlatformDispatcher;

final FlutterLocalNotificationsPlugin localNotifications =
    FlutterLocalNotificationsPlugin();

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Global Error Boundaries to eliminate unhandled crash states
  FlutterError.onError = (FlutterErrorDetails details) {
    debugPrint('Global FlutterError caught: ${details.exceptionAsString()}');
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Global Async Error caught: $error');
    return true; // Handled safely without freezing or crashing the app
  };

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

  // 🚀 CRITICAL FOR IOS: Launch root UI IMMEDIATELY so the native window renders within 50ms.
  // This completely eliminates iOS SpringBoard 0x8badf00d watchdog boot termination in TestFlight.
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

  // 4. RevenueCat (In-App Purchases)
  const revenueCatKey = String.fromEnvironment(
    'REVENUECAT_API_KEY',
    defaultValue: '',
  );
  if (!kIsWeb &&
      (Platform.isIOS || Platform.isMacOS) &&
      revenueCatKey.isNotEmpty &&
      !revenueCatKey.contains('your_revenuecat_key')) {
    try {
      await Purchases.setLogLevel(LogLevel.debug);
      await Purchases.configure(PurchasesConfiguration(revenueCatKey));
    } catch (e) {
      debugPrint("RevenueCat init error: $e");
    }
  }

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
    // Thermal & battery optimization: pause high-power UI animations on screen sleep
    if (lifecycleState == AppLifecycleState.paused ||
        lifecycleState == AppLifecycleState.hidden) {
      context.read<AppState>().setBackgroundMode(true);
    } else if (lifecycleState == AppLifecycleState.resumed) {
      context.read<AppState>().setBackgroundMode(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        // ── Sync CupertinoTabController → AppState ──
        final expectedIndex = _appTabToIndex(state.tab);
        if (_tabController.index != expectedIndex) {
          // Avoid setState loop — just set index directly
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _tabController.index != expectedIndex) {
              _tabController.index = expectedIndex;
            }
          });
        }

        final hasInlinePlayback =
            state.tab == AppTab.home || state.tab == AppTab.sounds;
        return LayoutBuilder(
          builder: (context, constraints) {
            final width = math.min(constraints.maxWidth, MixerTheme.maxWidth);
            final metrics = MixerMetrics(width);
            final s = metrics.scale;
            final navHeight = math.max(68.0, 132 * s);
            final bottomInset = MediaQuery.paddingOf(context).bottom;
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
                          fontSize: math.max(12.0, 24 * s),
                          color: MixerTheme.muted,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Other tabs retain the user's existing wallpaper preference.
                        if (!hasInlinePlayback &&
                            state.wallpaper.imageUrl.isNotEmpty)
                          Positioned.fill(
                            child: Image.network(
                              state.wallpaper.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const SizedBox.shrink(),
                            ),
                          ),
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  state.wallpaper.baseColor.withOpacity(0.78),
                                  state.wallpaper.baseColor.withOpacity(0.94),
                                  state.wallpaper.baseColor,
                                ],
                              ),
                            ),
                          ),
                        ),

                        // ── 🍎 Authentic Apple iOS Inspired Footer Tab Bar ──────────────
                        CupertinoTabScaffold(
                          backgroundColor: Colors.transparent,
                          controller: _tabController,
                          tabBar: CupertinoTabBar(
                            onTap: (index) {
                              HapticFeedback.selectionClick();
                              state.setTab(_indexToAppTab(index));
                            },
                            backgroundColor: const Color(0xF0001D26),
                            border: const Border(
                              top: BorderSide(
                                color: Color(0xFF21565E),
                                width: 1,
                              ),
                            ),
                            activeColor: MixerTheme.mint,
                            inactiveColor: const Color(0xFF7E9AA5),
                            iconSize: math.max(24.0, 46 * s),
                            height: navHeight,
                            currentIndex: _appTabToIndex(state.tab),
                            items: const [
                              BottomNavigationBarItem(
                                icon: SanctuaryIcon(SanctuarySymbol.home),
                                activeIcon: SanctuaryIcon(
                                  SanctuarySymbol.home,
                                  glow: true,
                                ),
                                label: 'Home',
                              ),
                              BottomNavigationBarItem(
                                icon: SanctuaryIcon(SanctuarySymbol.sounds),
                                activeIcon: SanctuaryIcon(
                                  SanctuarySymbol.sounds,
                                  glow: true,
                                ),
                                label: 'Sounds',
                              ),
                              BottomNavigationBarItem(
                                icon: SanctuaryIcon(SanctuarySymbol.meditate),
                                activeIcon: SanctuaryIcon(
                                  SanctuarySymbol.meditate,
                                  glow: true,
                                ),
                                label: 'Meditate',
                              ),
                              BottomNavigationBarItem(
                                icon: SanctuaryIcon(SanctuarySymbol.sleep),
                                activeIcon: SanctuaryIcon(
                                  SanctuarySymbol.sleep,
                                  glow: true,
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

                        // ── 🎵 Floating Mini Player ───────────────────────────────────
                        if ((state.isAnyAudioPlaying && !hasInlinePlayback) ||
                            (state.hasGuidedSession &&
                                state.activeAmbientTracks.isEmpty))
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: navHeight + bottomInset + 8,
                            child: const SanctuaryMiniPlayer(),
                          ),

                        // Mint indicator follows the real selected tab, not a decorative label.
                        Positioned(
                          bottom: bottomInset + 3,
                          left: width * expectedIndex / 4 + width * 0.065,
                          width: width * 0.12,
                          child: IgnorePointer(
                            child: Container(
                              height: math.max(2.0, 3 * s),
                              decoration: BoxDecoration(
                                color: MixerTheme.mint,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: MixerTheme.mint.withOpacity(0.8),
                                    blurRadius: 16,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // ── 😊 Mood Check-In Dialog ───────────────────────────────────
                        if (state.showMoodDialog)
                          MoodCheckInDialog(
                            onMoodSelected: (rating) =>
                                state.submitMood(rating),
                            onSkip: () => state.dismissMood(),
                          ),

                        // ── 🎧 Full-Screen Guided Player ──────────────────────────────
                        if (state.isGuidedPlayerExpanded)
                          const Positioned.fill(child: GuidedPlayerOverlay()),
                      ],
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
