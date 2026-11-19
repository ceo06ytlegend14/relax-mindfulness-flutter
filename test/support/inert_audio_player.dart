import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';

/// A profile/settings test never creates a native player or starts media.
class InertAudioPlayer extends Fake implements AudioPlayer {
  @override
  Stream<PlayerState> get playerStateStream => const Stream.empty();
  @override
  Stream<PlaybackEvent> get playbackEventStream => const Stream.empty();
  @override
  Future<void> dispose() async {}
}
