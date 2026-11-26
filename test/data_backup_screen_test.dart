import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:relax_mindfulness/providers/app_state.dart';
import 'package:relax_mindfulness/screens/data_backup_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/inert_audio_player.dart';
import 'support/user_backup_fixture.dart' show validBackup;

Future<AppState> mountBackup(
  WidgetTester tester, {
  bool storageReady = true,
  double width = 390,
  double textScale = 1,
}) async {
  await tester.binding.setSurfaceSize(Size(width, 844));
  SharedPreferences.setMockInitialValues({});
  final preferences = storageReady
      ? await SharedPreferences.getInstance()
      : null;
  final app = AppState(
    guidedPlayer: InertAudioPlayer(),
    preferences: preferences,
  );
  app.toggleFavorite('existing-favorite');
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    app.dispose();
    await tester.binding.setSurfaceSize(null);
  });
  await tester.pumpWidget(
    ChangeNotifierProvider<AppState>.value(
      value: app,
      child: CupertinoApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: const DataBackupScreen(),
      ),
    ),
  );
  return app;
}

Future<void> tapBackup(WidgetTester tester, String key) async {
  final target = find.byKey(ValueKey(key));
  await tester.ensureVisible(target);
  await tester.tap(target);
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('copy reports success only after clipboard writing succeeds', (
    tester,
  ) async {
    await mountBackup(tester);
    String? copied;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData')
            copied = call.arguments['text'] as String;
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );
    await tapBackup(tester, 'copy-profile-backup');
    expect(jsonDecode(copied!)['favorites'], ['existing-favorite']);
    expect(find.textContaining('Backup copied.'), findsOneWidget);
  });

  testWidgets('clipboard failure does not claim a backup was saved', (
    tester,
  ) async {
    final app = await mountBackup(tester);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData')
            throw PlatformException(code: 'denied');
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );
    await tapBackup(tester, 'copy-profile-backup');
    expect(find.textContaining('Clipboard access failed.'), findsOneWidget);
    expect(app.favorites, ['existing-favorite']);
  });

  testWidgets(
    'review and cancel do not replace data; explicit confirmation does',
    (tester) async {
      final app = await mountBackup(tester);
      await tester.enterText(
        find.byKey(const ValueKey('backup-json-input')),
        jsonEncode(validBackup()),
      );
      expect(find.byKey(const ValueKey('apply-profile-backup')), findsNothing);
      await tapBackup(tester, 'review-profile-backup');
      expect(find.text('Saved mixes: 1 entry'), findsOneWidget);
      expect(app.favorites, ['existing-favorite']);
      await tapBackup(tester, 'apply-profile-backup');
      expect(find.text('Replace saved data?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(app.favorites, ['existing-favorite']);
      await tapBackup(tester, 'apply-profile-backup');
      await tester.tap(find.byKey(const ValueKey('confirm-data-restore')));
      await tester.pump(const Duration(milliseconds: 400));
      expect(app.favorites, contains('story-starry-night'));
      expect(
        find.textContaining('Profile restored on this device.'),
        findsOneWidget,
      );
    },
  );

  testWidgets('editing a reviewed source requires a fresh review', (
    tester,
  ) async {
    await mountBackup(tester);
    final input = find.byKey(const ValueKey('backup-json-input'));
    await tester.enterText(input, jsonEncode(validBackup()));
    await tapBackup(tester, 'review-profile-backup');
    expect(find.byKey(const ValueKey('apply-profile-backup')), findsOneWidget);
    await tester.enterText(input, '{"favorites":[]}');
    await tester.pump();
    expect(find.byKey(const ValueKey('apply-profile-backup')), findsNothing);
  });

  testWidgets('invalid JSON is explained without echoing personal input', (
    tester,
  ) async {
    final app = await mountBackup(tester);
    await tester.enterText(
      find.byKey(const ValueKey('backup-json-input')),
      'PRIVATE_PERSONAL_TITLE not JSON',
    );
    await tapBackup(tester, 'review-profile-backup');
    final notice = tester
        .widget<Text>(find.byKey(const ValueKey('backup-result')))
        .data!;
    expect(notice, contains('existing data has not changed'));
    expect(notice, isNot(contains('PRIVATE_PERSONAL_TITLE')));
    expect(app.favorites, ['existing-favorite']);
    expect(find.byKey(const ValueKey('apply-profile-backup')), findsNothing);
  });

  testWidgets('storage preparation disables both export and restore review', (
    tester,
  ) async {
    await mountBackup(tester, storageReady: false);
    for (final key in ['copy-profile-backup', 'review-profile-backup']) {
      expect(
        tester.widget<CupertinoButton>(find.byKey(ValueKey(key))).onPressed,
        isNull,
      );
    }
    expect(find.text('Preparing device storage…'), findsOneWidget);
  });

  for (final scale in [1.0, 1.3]) {
    testWidgets('backup remains scrollable at 320px and text scale $scale', (
      tester,
    ) async {
      await mountBackup(tester, width: 320, textScale: scale);
      await tester.ensureVisible(
        find.byKey(const ValueKey('review-profile-backup')),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  }
}
