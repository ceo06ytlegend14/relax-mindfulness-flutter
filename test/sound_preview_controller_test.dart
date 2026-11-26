import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:relax_mindfulness/models/bundled_recordings.dart';
import 'package:relax_mindfulness/services/sound_preview_controller.dart';

import 'support/fake_sound_preview_player.dart';

void main() {
  test(
    'opening a controller creates no player, loads nothing and never autoplays',
    () {
      var creations = 0;
      final controller = SoundPreviewController(
        playerFactory: () {
          creations++;
          return FakeSoundPreviewPlayer();
        },
      );
      expect(creations, 0);
      expect(controller.isPlaying, isFalse);
      expect(controller.isLoading, isFalse);
      expect(controller.name, isNull);
      controller.dispose();
    },
  );

  test(
    'explicit preview loads only the bundled clip at a quiet level',
    () async {
      final player = FakeSoundPreviewPlayer();
      final activity = <bool>[];
      final controller = SoundPreviewController(
        playerFactory: () => player,
        onPreviewActivity: activity.add,
      );
      addTearDown(controller.dispose);
      await controller.toggle(bundledRecordings[1]);
      expect(player.loads, ['assets/sounds/ocean_waves.mp3']);
      expect(player.volume, .08);
      expect(player.playCalls, 1);
      expect(controller.isPlaying, isTrue);
      expect(activity.last, isTrue);
      await controller.toggle(bundledRecordings[1]);
      expect(player.disposed, isTrue);
      expect(controller.isPlaying, isFalse);
      expect(activity.last, isFalse);
    },
  );

  test(
    'a different preview disposes the previous one rather than layering it',
    () async {
      final players = <FakeSoundPreviewPlayer>[];
      final controller = SoundPreviewController(
        playerFactory: () {
          final player = FakeSoundPreviewPlayer();
          players.add(player);
          return player;
        },
      );
      addTearDown(controller.dispose);
      await controller.toggle(bundledRecordings[0]);
      await controller.toggle(bundledRecordings[1]);
      expect(players[0].disposed, isTrue);
      expect(players[0].playing, isFalse);
      expect(players[1].playing, isTrue);
      expect(controller.name, 'Ocean Waves');
    },
  );

  test('late loading completion cannot revive a stopped preview', () async {
    final player = FakeSoundPreviewPlayer()..loadGate = Completer<void>();
    final controller = SoundPreviewController(playerFactory: () => player);
    addTearDown(controller.dispose);
    final loading = controller.toggle(bundledRecordings[0]);
    for (var i = 0; i < 6; i++) {
      await Future<void>.value();
    }
    expect(controller.isLoading, isTrue);
    await controller.stop();
    player.loadGate!.complete();
    await loading;
    expect(player.playCalls, 0);
    expect(player.disposed, isTrue);
    expect(controller.isPlaying, isFalse);
  });

  test(
    'disposal during loading blocks late play and late notifications',
    () async {
      final player = FakeSoundPreviewPlayer()..loadGate = Completer<void>();
      final controller = SoundPreviewController(playerFactory: () => player);
      var notifications = 0;
      controller.addListener(() => notifications++);
      final loading = controller.toggle(bundledRecordings[0]);
      for (var i = 0; i < 6; i++) {
        await Future<void>.value();
      }
      controller.dispose();
      final count = notifications;
      player.loadGate!.complete();
      await loading;
      expect(player.playCalls, 0);
      expect(notifications, count);
      expect(player.disposed, isTrue);
    },
  );

  for (final phase in ['load', 'play', 'create']) {
    test(
      '$phase failures report a safe error, restore gain and allow retry',
      () async {
        final player = FakeSoundPreviewPlayer()
          ..failLoad = phase == 'load'
          ..failPlay = phase == 'play';
        var factoryFails = phase == 'create';
        var retrying = false;
        final retryPlayer = FakeSoundPreviewPlayer();
        final activity = <bool>[];
        final controller = SoundPreviewController(
          playerFactory: () {
            if (factoryFails) throw StateError('private payload');
            return retrying ? retryPlayer : player;
          },
          onPreviewActivity: activity.add,
        );
        addTearDown(controller.dispose);
        await controller.toggle(bundledRecordings[0]);
        for (var i = 0; i < 8; i++) {
          await Future<void>.value();
        }
        expect(controller.isPlaying, isFalse);
        expect(controller.isLoading, isFalse);
        expect(
          controller.error,
          'Preview could not play. Your mix was not changed.',
        );
        expect(activity.last, isFalse);
        factoryFails = false;
        retrying = true;
        await controller.toggle(bundledRecordings[0]);
        expect(controller.error, isNull);
        expect(controller.isPlaying, isTrue);
        expect(retryPlayer.playCalls, 1);
        await controller.stop();
        expect(activity.last, isFalse);
      },
    );
  }

  testWidgets('the preview stops after eight seconds and restores gain', (
    tester,
  ) async {
    final player = FakeSoundPreviewPlayer();
    final activity = <bool>[];
    final controller = SoundPreviewController(
      playerFactory: () => player,
      onPreviewActivity: activity.add,
    );
    addTearDown(controller.dispose);
    await controller.toggle(bundledRecordings[0]);
    await tester.pump(const Duration(seconds: 7));
    expect(controller.isPlaying, isTrue);
    await tester.pump(const Duration(seconds: 1));
    expect(controller.isPlaying, isFalse);
    expect(player.disposed, isTrue);
    expect(activity.last, isFalse);
  });

  testWidgets('a stalled load times out safely without late autoplay', (
    tester,
  ) async {
    final player = FakeSoundPreviewPlayer()..loadGate = Completer<void>();
    final controller = SoundPreviewController(playerFactory: () => player);
    addTearDown(controller.dispose);
    final loading = controller.toggle(bundledRecordings[0]);
    await tester.pump();
    await tester.pump(const Duration(seconds: 10));
    expect(controller.error, isNotNull);
    expect(controller.isLoading, isFalse);
    player.loadGate!.complete();
    await loading;
    expect(player.playCalls, 0);
    expect(player.disposed, isTrue);
  });
}
