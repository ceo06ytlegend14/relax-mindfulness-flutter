import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relax_mindfulness/screens/ai_studio_screen.dart';

Future<void> mountReflection(
  WidgetTester tester, {
  double width = 390,
  double scale = 1,
}) async {
  await tester.binding.setSurfaceSize(Size(width, 844));
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.binding.setSurfaceSize(null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });
  await tester.pumpWidget(
    CupertinoApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: const AiStudioScreen(),
    ),
  );
}

Future<void> tapReflection(WidgetTester tester, String key) async {
  // Render controller-driven enabled/disabled changes before hit testing.
  await tester.pump();
  final target = find.byKey(ValueKey(key));
  await tester.ensureVisible(target);
  await tester.tap(target);
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  testWidgets(
    'local writing is explicit and empty prompts cannot create a draft',
    (tester) async {
      await mountReflection(tester);
      expect(find.text('Reflection studio'), findsOneWidget);
      expect(
        find.textContaining('This is not AI or music generation.'),
        findsOneWidget,
      );
      expect(
        tester
            .widget<CupertinoButton>(
              find.byKey(const ValueKey('create-reflection')),
            )
            .onPressed,
        isNull,
      );
      expect(find.byKey(const ValueKey('reflection-output')), findsNothing);
      expect(find.text('Save & Close'), findsNothing);
    },
  );

  testWidgets(
    'creating a template uses the actual prompt and editing clears stale output',
    (tester) async {
      await mountReflection(tester);
      final input = find.byKey(const ValueKey('reflection-prompt'));
      await tester.enterText(input, '  A small kind step  ');
      await tapReflection(tester, 'create-reflection');
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('reflection-output')))
            .data,
        startsWith('A quiet reflection: A small kind step\n'),
      );
      await tester.enterText(input, 'A different intention');
      await tester.pump();
      expect(find.byKey(const ValueKey('reflection-output')), findsNothing);
    },
  );

  testWidgets(
    'copy confirms only after the clipboard operation and never claims saving',
    (tester) async {
      await mountReflection(tester);
      final clipboard = Completer<void>();
      String? copied;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
            if (call.method == 'Clipboard.setData') {
              copied = call.arguments['text'] as String;
              await clipboard.future;
            }
            return null;
          });
      await tester.enterText(
        find.byKey(const ValueKey('reflection-prompt')),
        'Making room for rest',
      );
      await tapReflection(tester, 'create-reflection');
      await tapReflection(tester, 'copy-reflection');
      expect(find.byKey(const ValueKey('reflection-notice')), findsNothing);
      expect(copied, contains('Making room for rest'));
      clipboard.complete();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.textContaining('Text copied.'), findsOneWidget);
      await tapReflection(tester, 'clear-reflection');
      expect(find.byKey(const ValueKey('reflection-output')), findsNothing);
      expect(find.byKey(const ValueKey('reflection-notice')), findsNothing);
    },
  );

  testWidgets('clipboard denial is a private failure, not a fake save', (
    tester,
  ) async {
    await mountReflection(tester);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData')
            throw PlatformException(code: 'denied', message: 'PRIVATE_PROMPT');
          return null;
        });
    await tester.enterText(
      find.byKey(const ValueKey('reflection-prompt')),
      'A quiet pause',
    );
    await tapReflection(tester, 'create-reflection');
    await tapReflection(tester, 'copy-reflection');
    expect(
      find.text('Clipboard access failed. Nothing was saved.'),
      findsOneWidget,
    );
    expect(find.textContaining('PRIVATE_PROMPT'), findsNothing);
  });

  testWidgets(
    'the local template stays scrollable with larger text on a narrow phone',
    (tester) async {
      await mountReflection(tester, width: 320, scale: 1.4);
      await tester.enterText(
        find.byKey(const ValueKey('reflection-prompt')),
        'A quiet moment',
      );
      await tapReflection(tester, 'create-reflection');
      await tester.ensureVisible(find.byKey(const ValueKey('copy-reflection')));
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );
}
