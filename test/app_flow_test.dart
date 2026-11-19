import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
// ignore: depend_on_referenced_packages
import 'package:just_audio_platform_interface/just_audio_platform_interface.dart';
import 'package:relax_mindfulness/main.dart';
import 'package:relax_mindfulness/providers/app_state.dart';
import 'package:relax_mindfulness/screens/onboarding_screen.dart';

class MockAudioPlayer extends Fake implements AudioPlayerPlatform {
  final String _id;
  final _eventController = StreamController<PlaybackEventMessage>.broadcast();

  MockAudioPlayer(this._id) {
    _eventController.add(
      PlaybackEventMessage(
        processingState: ProcessingStateMessage.ready,
        updateTime: DateTime.now(),
        updatePosition: Duration.zero,
        bufferedPosition: Duration.zero,
        duration: const Duration(seconds: 120),
        icyMetadata: null,
        currentIndex: 0,
        androidAudioSessionId: null,
      ),
    );
  }

  @override
  String get id => _id;

  @override
  Stream<PlayerDataMessage> get playerDataMessageStream => const Stream.empty();

  @override
  Stream<PlaybackEventMessage> get playbackEventMessageStream => _eventController.stream;

  @override
  Future<LoadResponse> load(LoadRequest request) async {
    _eventController.add(
      PlaybackEventMessage(
        processingState: ProcessingStateMessage.ready,
        updateTime: DateTime.now(),
        updatePosition: Duration.zero,
        bufferedPosition: Duration.zero,
        duration: const Duration(seconds: 120),
        icyMetadata: null,
        currentIndex: 0,
        androidAudioSessionId: null,
      ),
    );
    return LoadResponse(duration: const Duration(seconds: 120));
  }

  @override
  Future<PlayResponse> play(PlayRequest request) async => PlayResponse();

  @override
  Future<PauseResponse> pause(PauseRequest request) async => PauseResponse();

  @override
  Future<SetVolumeResponse> setVolume(SetVolumeRequest request) async => SetVolumeResponse();

  @override
  Future<SetSpeedResponse> setSpeed(SetSpeedRequest request) async => SetSpeedResponse();

  @override
  Future<SetLoopModeResponse> setLoopMode(SetLoopModeRequest request) async => SetLoopModeResponse();

  @override
  Future<SetShuffleModeResponse> setShuffleMode(SetShuffleModeRequest request) async => SetShuffleModeResponse();

  @override
  Future<SetAutomaticallyWaitsToMinimizeStallingResponse> setAutomaticallyWaitsToMinimizeStalling(SetAutomaticallyWaitsToMinimizeStallingRequest request) async => SetAutomaticallyWaitsToMinimizeStallingResponse();
}

class MockJustAudio extends JustAudioPlatform {
  @override
  Future<AudioPlayerPlatform> init(InitRequest request) async => MockAudioPlayer(request.id);

  @override
  Future<DisposePlayerResponse> disposePlayer(DisposePlayerRequest request) async => DisposePlayerResponse();

  @override
  Future<DisposeAllPlayersResponse> disposeAllPlayers(DisposeAllPlayersRequest request) async => DisposeAllPlayersResponse();
}

class _MockHttpHeaders extends Fake implements HttpHeaders {
  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}
}

class _MockHttpClientResponse extends Fake implements HttpClientResponse {
  static final _pngBytes = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=',
  );

  @override
  int get statusCode => 200;

  @override
  int get contentLength => _pngBytes.length;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.value(_pngBytes).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}

class _MockHttpClientRequest extends Fake implements HttpClientRequest {
  @override
  final HttpHeaders headers = _MockHttpHeaders();

  @override
  Future<HttpClientResponse> close() async => _MockHttpClientResponse();
}

class _MockHttpClient extends Fake implements HttpClient {
  @override
  bool autoUncompress = true;

  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _MockHttpClientRequest();
}

class _MockHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => _MockHttpClient();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = _MockHttpOverrides();
  JustAudioPlatform.instance = MockJustAudio();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('com.ryanheise.audio_session'),
      (MethodCall methodCall) async => true,
    );
    SharedPreferences.setMockInitialValues({
      'onboarding_done': true,
      'streak': 3,
      'theme_mode': 'midnightNavy',
    });
  });

  testWidgets('Test 1: App initializes and renders HomeScreen with Serenly navigation', (WidgetTester tester) async {
    final appState = AppState();
    await appState.init();

    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>.value(
        value: appState,
        child: const SanctuaryApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    // Verify Tab scaffold & items
    expect(find.byType(CupertinoTabBar), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Sounds'), findsOneWidget);
    expect(find.text('Meditate'), findsOneWidget);
    expect(find.text('Sleep'), findsOneWidget);
  });

  testWidgets('Test 2: Tab switching between screens works smoothly', (WidgetTester tester) async {
    final appState = AppState();
    await appState.init();

    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>.value(
        value: appState,
        child: const SanctuaryApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    // Switch to Discover
    appState.setTab(AppTab.meditate);
    await tester.pump(const Duration(milliseconds: 300));
    expect(appState.tab, AppTab.meditate);

    // Switch to Breathe
    appState.setTab(AppTab.breathe);
    await tester.pump(const Duration(milliseconds: 300));
    expect(appState.tab, AppTab.breathe);

    // Switch to Sounds
    appState.setTab(AppTab.sounds);
    await tester.pump(const Duration(milliseconds: 300));
    expect(appState.tab, AppTab.sounds);
  });

  testWidgets('Test 3: Sound mixer & volume state calculations', (WidgetTester tester) async {
    final appState = AppState();
    await appState.init();

    // Verify initial audio state
    expect(appState.isAnyAudioPlaying, false);
    expect(appState.getTrackVolume('Soft Rain'), 0.0);

    // Stop all audio cleanly resets playback state
    await appState.stopAllAudio();
    expect(appState.isAnyAudioPlaying, false);
  });

  testWidgets('Test 4: Sleep auto-fade timer start and cancel', (WidgetTester tester) async {
    final appState = AppState();
    await appState.init();

    appState.startSleepTimer(15);
    expect(appState.isSleepTimerRunning, true);
    expect(appState.sleepTimerRemainingSec, 15 * 60);

    appState.cancelSleepTimer();
    expect(appState.isSleepTimerRunning, false);
    expect(appState.sleepTimerRemainingSec, null);
  });

  testWidgets('Test 5: Onboarding screen and Skip button works as expected', (WidgetTester tester) async {
    final appState = AppState();
    await appState.init();

    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>.value(
        value: appState,
        child: const CupertinoApp(
          home: Material(child: OnboardingScreen()),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.text('Relax & Mindfulness'), findsOneWidget);
    expect(find.text('Continue →'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);

    // Tap Skip to complete onboarding
    await tester.tap(find.text('Skip'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(appState.onboardingDone, true);
  });
}
