import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:relax_mindfulness/components/sanctuary_components.dart';
import 'package:relax_mindfulness/models/sanctuary_catalog.dart';
import 'package:relax_mindfulness/providers/app_state.dart';
import 'package:relax_mindfulness/providers/mixer_controller.dart';
import 'package:relax_mindfulness/theme/neumorphism_demo.dart';

class SleepScreen extends StatefulWidget {
  const SleepScreen({super.key});

  @override
  State<SleepScreen> createState() => _SleepScreenState();
}

class _SleepScreenState extends State<SleepScreen> {
  Duration _selectedDuration = const Duration(minutes: 30);
  bool _savedStoriesOnly = false;

  static const _quickTracks = [
    ('Ocean', CupertinoIcons.waveform, 'Ocean Waves'),
    ('Rain', CupertinoIcons.cloud_rain_fill, 'Soft Rain'),
    ('Wind', CupertinoIcons.wind, 'Soothing Breeze'),
    ('Thunder', CupertinoIcons.bolt_fill, 'Thunderstorm'),
    ('Nature', CupertinoIcons.leaf_arrow_circlepath, 'Mountain Stream'),
  ];

  Future<void> _showTimerPicker() async {
    final duration = await showCupertinoModalPopup<Duration>(
      context: context,
      builder: (context) =>
          _SleepTimerSheet(initialDuration: _selectedDuration),
    );
    if (!mounted || duration == null || duration.inMinutes <= 0) return;
    setState(() => _selectedDuration = duration);
    context.read<AppState>().startSleepTimer(duration.inMinutes);
  }

  void _playSoundscape(SleepSoundscape soundscape) {
    HapticFeedback.lightImpact();
    context.read<AppState>().startSleepTimer(soundscape.minutes);
    context.read<MixerController>().applyMix(
      soundscape.levels,
      name: soundscape.title,
    );
  }

  void _toggleQuickTrack(String name) {
    HapticFeedback.selectionClick();
    final app = context.read<AppState>();
    final levels = Map<String, double>.of(app.activeAmbientTracks);
    if (app.getTrackVolume(name) > 0) {
      levels.remove(name);
    } else {
      levels[name] = 0.6;
    }
    // Start only the actual quick selection, not an unrelated paused preset.
    context.read<MixerController>().applyMix(levels);
  }

  void _toggleLastMix() {
    final app = context.read<AppState>();
    final mixer = context.read<MixerController>();
    if (app.activeAmbientTracks.isNotEmpty) {
      mixer.togglePlayback();
    } else {
      final selected = Map<String, double>.of(mixer.levels)
        ..removeWhere((_, volume) => volume <= 0);
      mixer.applyMix(
        selected.isEmpty ? {'Soft Rain': 0.3} : selected,
        name: mixer.preset,
      );
    }
  }

  Future<void> _showLibrary({bool savedOnly = false}) async {
    final app = context.read<AppState>();
    final saved = app.presets.toList();
    final choice = await showCupertinoModalPopup<String>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(savedOnly ? 'Your soundscapes' : 'Wind Down Playlist'),
        message: Text(
          savedOnly
              ? saved.isEmpty
                    ? 'Save a mix in Sounds to keep your favorite nighttime rituals here.'
                    : 'Your saved mixes, ready for another quiet evening.'
              : 'Each soundscape starts an auto-fade timer for its listed duration.',
        ),
        actions: [
          if (savedOnly)
            for (var i = 0; i < saved.length; i++)
              CupertinoActionSheetAction(
                onPressed: () => Navigator.pop(context, 'saved-$i'),
                child: Text(saved[i].name),
              ),
          if (!savedOnly)
            for (final item in sleepSoundscapes)
              CupertinoActionSheetAction(
                onPressed: () => Navigator.pop(context, item.id),
                child: Text('${item.title} · ${item.minutes} min'),
              ),
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context, 'mixer'),
            child: const Text('Open sound mixer'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
    if (!mounted || choice == null) return;
    if (choice == 'mixer') {
      app.setTab(AppTab.sounds);
    } else if (choice.startsWith('saved-')) {
      final index = int.tryParse(choice.substring(6));
      if (index != null && index >= 0 && index < saved.length) {
        context.read<MixerController>().applyMix(
          saved[index].volumes,
          name: saved[index].name,
        );
      }
    } else {
      for (final item in sleepSoundscapes) {
        if (item.id == choice) _playSoundscape(item);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Consumer2<AppState, MixerController>(
    builder: (context, app, mixer, _) => LayoutBuilder(
      builder: (context, constraints) {
        final m = SanctuaryMetrics(constraints.maxWidth);
        final oceanPlaying =
            app.getTrackVolume('Ocean Waves') > 0 &&
            app.getTrackVolume('Soft Rain') > 0 &&
            app.activeAmbientTracks.keys.every(
              (name) => oceanSleepJourney.levels.containsKey(name),
            );
        final stories = sleepStories
            .where(
              (story) =>
                  !_savedStoriesOnly || app.isFavoriteSoundId(story.favoriteId),
            )
            .toList();
        return CupertinoPageScaffold(
          backgroundColor: SanctuaryPalette.navy,
          child: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SanctuaryBackdrop(
                  asset: 'assets/images/sleep/moonlit_ocean.webp',
                  color: SanctuaryPalette.navy,
                  height: m.space(410),
                ),
              ),
              SafeArea(
                bottom: false,
                child: CustomScrollView(
                  key: const PageStorageKey('sleep-scroll'),
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          m.space(29),
                          m.space(40),
                          m.space(29),
                          160,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sleep',
                              key: const ValueKey('sleep-title'),
                              style: m.sans(
                                48,
                                min: 29,
                                weight: FontWeight.w700,
                                height: 1.15,
                                tracking: -1.4,
                              ),
                            ),
                            SizedBox(height: m.space(24)),
                            Row(
                              children: [
                                Text(
                                  'Good Evening',
                                  style: m.sans(
                                    23,
                                    min: 13,
                                    color: SanctuaryPalette.mist,
                                    weight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(width: m.space(10)),
                                Icon(
                                  CupertinoIcons.moon_fill,
                                  size: m.font(24, min: 15),
                                  color: SanctuaryPalette.gold,
                                ),
                              ],
                            ),
                            SizedBox(height: m.space(4)),
                            Text(
                              'Sleep Sanctuary',
                              style: m.sans(
                                44,
                                min: 25,
                                weight: FontWeight.w700,
                                height: 1.15,
                                tracking: -1.3,
                              ),
                            ),
                            SizedBox(height: m.space(8)),
                            Text.rich(
                              TextSpan(
                                children: [
                                  const TextSpan(
                                    text:
                                        'Everything you need for a perfect night’s rest ',
                                  ),
                                  WidgetSpan(
                                    alignment: PlaceholderAlignment.middle,
                                    child: Icon(
                                      CupertinoIcons.heart,
                                      size: m.font(21, min: 12),
                                      color: SanctuaryPalette.mist,
                                    ),
                                  ),
                                ],
                              ),
                              style: m.sans(
                                22,
                                min: 12,
                                color: SanctuaryPalette.mist,
                              ),
                            ),
                            SizedBox(height: m.space(30)),
                            _TimerBar(
                              metrics: m,
                              app: app,
                              onSet: _showTimerPicker,
                            ),
                            SizedBox(height: m.space(27)),
                            _OceanJourney(
                              metrics: m,
                              playing: oceanPlaying,
                              onPressed: () => oceanPlaying
                                  ? mixer.togglePlayback()
                                  : _playSoundscape(oceanSleepJourney),
                            ),
                            SizedBox(height: m.space(18)),
                            SleepSectionHeading(
                              'Continue Listening',
                              metrics: m,
                              action: 'See All',
                              actionKey: const ValueKey('saved-soundscapes'),
                              onAction: () => _showLibrary(savedOnly: true),
                            ),
                            SizedBox(height: m.space(8)),
                            _ContinueListening(
                              metrics: m,
                              app: app,
                              mixer: mixer,
                              onPressed: _toggleLastMix,
                            ),
                            SizedBox(height: m.space(20)),
                            SleepSectionHeading(
                              'Wind Down Playlist',
                              metrics: m,
                              action: 'See All',
                              actionKey: const ValueKey('all-soundscapes'),
                              onAction: _showLibrary,
                            ),
                            SizedBox(height: m.space(10)),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  for (final soundscape in sleepSoundscapes)
                                    Padding(
                                      padding: EdgeInsets.only(
                                        right: m.space(20),
                                      ),
                                      child: _SoundscapeCard(
                                        soundscape: soundscape,
                                        metrics: m,
                                        onPressed: () =>
                                            _playSoundscape(soundscape),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            SizedBox(height: m.space(24)),
                            SleepSectionHeading(
                              'Sleep Sounds Mixer',
                              metrics: m,
                              action: 'Customize',
                              actionKey: const ValueKey('customize-sleep-mix'),
                              onAction: () => app.setTab(AppTab.sounds),
                            ),
                            SizedBox(height: m.space(8)),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: m.space(13),
                                vertical: m.space(17),
                              ),
                              decoration: sleepSurface(radius: m.space(28)),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  for (final track in _quickTracks)
                                    Expanded(
                                      child: _QuickTrack(
                                        label: track.$1,
                                        icon: track.$2,
                                        volume: app.getTrackVolume(track.$3),
                                        metrics: m,
                                        onPressed: () =>
                                            _toggleQuickTrack(track.$3),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            SizedBox(height: m.space(32)),
                            Text(
                              'Sleep Stories',
                              style: m.sans(
                                32,
                                min: 22,
                                weight: FontWeight.w700,
                                tracking: -0.8,
                              ),
                            ),
                            SizedBox(height: m.space(17)),
                            Row(
                              children: [
                                _StoryFilter(
                                  label: 'All',
                                  selected: !_savedStoriesOnly,
                                  metrics: m,
                                  onPressed: () =>
                                      setState(() => _savedStoriesOnly = false),
                                ),
                                SizedBox(width: m.space(10)),
                                _StoryFilter(
                                  label: 'My Stories',
                                  selected: _savedStoriesOnly,
                                  metrics: m,
                                  onPressed: () =>
                                      setState(() => _savedStoriesOnly = true),
                                ),
                              ],
                            ),
                            SizedBox(height: m.space(14)),
                            if (stories.isEmpty)
                              _EmptyStories(
                                metrics: m,
                                onBrowse: () =>
                                    setState(() => _savedStoriesOnly = false),
                              ),
                            for (final story in stories)
                              Padding(
                                padding: EdgeInsets.only(bottom: m.space(12)),
                                child: _StoryCard(
                                  story: story,
                                  metrics: m,
                                  saved: app.isFavoriteSoundId(
                                    story.favoriteId,
                                  ),
                                  playing:
                                      app.isGuidedPlaying &&
                                      app.currentGuidedTitle == story.title,
                                  onSave: () =>
                                      app.toggleFavorite(story.favoriteId),
                                  onPlay: () {
                                    if (app.isGuidedPlaying &&
                                        app.currentGuidedTitle == story.title) {
                                      app.pauseGuidedSession();
                                    } else {
                                      app.playGuidedSession(
                                        story.title,
                                        story.minutes,
                                      );
                                    }
                                  },
                                ),
                              ),
                            SizedBox(height: m.space(12)),
                            Text(
                              'Story sessions currently use the app’s calming audio. Individual story narration and downloads are not included.',
                              style: m.sans(
                                16,
                                min: 11,
                                color: SanctuaryPalette.mist,
                                height: 1.5,
                              ),
                            ),
                            SizedBox(height: m.space(28)),
                            CupertinoButton(
                              padding: EdgeInsets.zero,
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                Navigator.of(context).push(
                                  CupertinoPageRoute<void>(
                                    builder: (_) =>
                                        const NeumorphismDemoScreen(),
                                  ),
                                );
                              },
                              child: Container(
                                padding: EdgeInsets.all(m.space(20)),
                                decoration: sleepSurface(radius: m.space(22)),
                                child: Row(
                                  children: [
                                    Icon(
                                      CupertinoIcons.moon_stars,
                                      size: m.font(33, min: 25),
                                      color: SanctuaryPalette.lavender,
                                    ),
                                    SizedBox(width: m.space(16)),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Twilight Soft UI Controls',
                                            style: m.sans(
                                              22,
                                              min: 14,
                                              weight: FontWeight.w600,
                                            ),
                                          ),
                                          SizedBox(height: m.space(4)),
                                          Text(
                                            'Haptic dials, mood orb & living wallpaper',
                                            style: m.sans(
                                              17,
                                              min: 11,
                                              color: SanctuaryPalette.mist,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      CupertinoIcons.chevron_right,
                                      size: m.font(22, min: 15),
                                      color: SanctuaryPalette.lavender,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}

class _TimerBar extends StatelessWidget {
  const _TimerBar({
    required this.metrics,
    required this.app,
    required this.onSet,
  });
  final SanctuaryMetrics metrics;
  final AppState app;
  final VoidCallback onSet;

  @override
  Widget build(BuildContext context) {
    final m = metrics;
    final remaining = app.sleepTimerRemainingSec ?? 0;
    final time =
        '${(remaining ~/ 60).toString().padLeft(2, '0')}:${(remaining % 60).toString().padLeft(2, '0')}';
    return Container(
      key: const ValueKey('sleep-timer-bar'),
      constraints: BoxConstraints(minHeight: math.max(52.0, m.space(68))),
      padding: EdgeInsets.symmetric(horizontal: m.space(23)),
      decoration: sleepSurface(radius: 100, glow: true),
      child: Row(
        children: [
          Icon(
            CupertinoIcons.clock_fill,
            color: SanctuaryPalette.gold,
            size: m.font(28, min: 20),
          ),
          SizedBox(width: m.space(13)),
          Expanded(
            child: Text(
              app.isSleepTimerRunning
                  ? 'Auto-Fade Timer · $time'
                  : 'Set Sleep Auto-Fade Timer',
              style: m.sans(
                22,
                min: 12.5,
                weight: FontWeight.w600,
                tracking: -0.4,
              ),
            ),
          ),
          CupertinoButton(
            key: ValueKey(
              app.isSleepTimerRunning
                  ? 'cancel-sleep-timer'
                  : 'set-sleep-timer',
            ),
            padding: EdgeInsets.only(left: m.space(10)),
            minSize: 44,
            onPressed: app.isSleepTimerRunning ? app.cancelSleepTimer : onSet,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  app.isSleepTimerRunning ? 'Cancel' : 'Set',
                  style: m.sans(
                    22,
                    min: 13,
                    weight: FontWeight.w500,
                    color: app.isSleepTimerRunning
                        ? SanctuaryPalette.gold
                        : SanctuaryPalette.cream,
                  ),
                ),
                if (!app.isSleepTimerRunning) ...[
                  SizedBox(width: m.space(10)),
                  Icon(
                    CupertinoIcons.chevron_right,
                    size: m.font(24, min: 15),
                    color: SanctuaryPalette.cream,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OceanJourney extends StatelessWidget {
  const _OceanJourney({
    required this.metrics,
    required this.playing,
    required this.onPressed,
  });
  final SanctuaryMetrics metrics;
  final bool playing;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final m = metrics;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: sleepSurface(radius: m.space(32), glow: true),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: m.space(300)),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                oceanSleepJourney.artwork,
                fit: BoxFit.cover,
                excludeFromSemantics: true,
              ),
            ),
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xB5011632),
                      Color(0x30001535),
                      Color(0x08001832),
                    ],
                    stops: [0, 0.6, 1],
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                m.space(24),
                m.space(19),
                m.space(22),
                m.space(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: m.space(18),
                          vertical: m.space(7),
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0x55091B36),
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(
                            color: SanctuaryPalette.gold,
                            width: 1.3,
                          ),
                          boxShadow: const [
                            BoxShadow(color: Color(0x33F5C96D), blurRadius: 15),
                          ],
                        ),
                        child: Text(
                          'Tonight’s Journey',
                          style: m.sans(
                            19,
                            min: 11,
                            color: SanctuaryPalette.gold,
                            weight: FontWeight.w500,
                            height: 1.1,
                          ),
                        ),
                      ),
                      const Spacer(),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        minSize: 44,
                        onPressed: onPressed,
                        child: Container(
                          width: math.max(36.0, m.space(58)),
                          height: math.max(36.0, m.space(58)),
                          decoration: const BoxDecoration(
                            color: Color(0xA0031831),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            playing
                                ? CupertinoIcons.pause_fill
                                : CupertinoIcons.chevron_right,
                            size: m.font(29, min: 19),
                            color: Colors.white,
                            semanticLabel: playing
                                ? 'Pause Ocean Sleep'
                                : 'Start Ocean Sleep',
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: m.space(3)),
                  Text(
                    'Ocean Sleep',
                    style: m.sans(
                      44,
                      min: 27,
                      weight: FontWeight.w700,
                      height: 1.12,
                      tracking: -1,
                    ),
                  ),
                  SizedBox(height: m.space(3)),
                  Text(
                    'Deep Relaxation',
                    style: m.sans(25, min: 14, weight: FontWeight.w500),
                  ),
                  SizedBox(height: m.space(13)),
                  Row(
                    children: [
                      Icon(
                        CupertinoIcons.clock,
                        size: m.font(21, min: 13),
                        color: SanctuaryPalette.gold,
                      ),
                      SizedBox(width: m.space(8)),
                      Text('45 min', style: m.sans(19, min: 11.5)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: m.space(14)),
                        child: Text(
                          '|',
                          style: m.sans(20, color: SanctuaryPalette.mist),
                        ),
                      ),
                      Icon(
                        CupertinoIcons.music_note,
                        size: m.font(22, min: 14),
                        color: SanctuaryPalette.gold,
                      ),
                      SizedBox(width: m.space(7)),
                      Flexible(
                        child: Text(
                          'Ocean + Rain',
                          style: m.sans(19, min: 11.5),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: m.space(16)),
                  SanctuaryPillButton(
                    buttonKey: const ValueKey('begin-ocean-sleep'),
                    label: playing ? 'Pause Sleep' : 'Begin Sleep',
                    icon: playing
                        ? CupertinoIcons.pause_fill
                        : CupertinoIcons.play_fill,
                    metrics: m,
                    gold: true,
                    onPressed: onPressed,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContinueListening extends StatelessWidget {
  const _ContinueListening({
    required this.metrics,
    required this.app,
    required this.mixer,
    required this.onPressed,
  });
  final SanctuaryMetrics metrics;
  final AppState app;
  final MixerController mixer;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final m = metrics;
    final selected =
        mixer.levels.entries.where((entry) => entry.value > 0).toList()
          ..sort((a, b) => b.value.compareTo(a.value));
    final mainTrack = selected.isEmpty ? 'Soft Rain' : selected.first.key;
    final playing = app.activeAmbientTracks.isNotEmpty;
    final hasTimer =
        app.isSleepTimerRunning && (app.sleepTimerTotalSec ?? 0) > 0;
    final progress = hasTimer
        ? (1 - (app.sleepTimerRemainingSec ?? 0) / app.sleepTimerTotalSec!)
              .clamp(0.0, 1.0)
              .toDouble()
        : selected.isEmpty
        ? 0.3
        : selected.first.value;
    final title =
        mixer.preset ??
        (selected.length <= 1
            ? mainTrack
            : '$mainTrack + ${selected.length - 1} more');
    return Container(
      key: const ValueKey('continue-listening'),
      padding: EdgeInsets.all(m.space(12)),
      decoration: sleepSurface(radius: m.space(22)),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(m.space(16)),
            child: Image.asset(
              sleepArtworkForTrack(mainTrack),
              width: math.max(44.0, m.space(80)),
              height: math.max(52.0, m.space(80)),
              fit: BoxFit.cover,
              excludeFromSemantics: true,
            ),
          ),
          SizedBox(width: m.space(18)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: m.sans(
                    24,
                    min: 14,
                    weight: FontWeight.w600,
                    height: 1.2,
                    tracking: -0.4,
                  ),
                ),
                SizedBox(height: m.space(5)),
                Text(
                  hasTimer
                      ? '${((app.sleepTimerRemainingSec ?? 0) / 60).ceil()} min remaining'
                      : playing
                      ? 'Your nighttime soundscape'
                      : 'Your soundscape, ready when you are',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: m.sans(18, min: 11, color: SanctuaryPalette.mist),
                ),
                SizedBox(height: m.space(10)),
                Row(
                  children: [
                    Text(
                      hasTimer ? 'Auto-fade' : 'Level',
                      style: m.sans(13, min: 9, color: SanctuaryPalette.mist),
                    ),
                    SizedBox(width: m.space(8)),
                    Expanded(
                      child: Semantics(
                        label: hasTimer
                            ? 'Auto-fade timer elapsed'
                            : '$mainTrack volume',
                        value: '${(progress * 100).round()} percent',
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 4,
                            color: SanctuaryPalette.gold,
                            backgroundColor: const Color(0xFF3A4665),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: m.space(10)),
                    Text(
                      '${(progress * 100).round()}%',
                      style: m.sans(16, min: 10, weight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: m.space(16)),
          SanctuaryPillButton(
            buttonKey: const ValueKey('resume-sleep-mix'),
            label: playing
                ? 'Pause'
                : app.cachedVolumes.isNotEmpty
                ? 'Resume'
                : 'Play',
            metrics: m,
            quiet: true,
            onPressed: onPressed,
          ),
        ],
      ),
    );
  }
}

class _SoundscapeCard extends StatelessWidget {
  const _SoundscapeCard({
    required this.soundscape,
    required this.metrics,
    required this.onPressed,
  });
  final SleepSoundscape soundscape;
  final SanctuaryMetrics metrics;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final m = metrics;
    final size = math.max(86.0, m.space(152));
    return Semantics(
      label: '${soundscape.title}, ${soundscape.minutes} minutes',
      button: true,
      onTap: onPressed,
      excludeSemantics: true,
      child: CupertinoButton(
        key: ValueKey('soundscape-${soundscape.id}'),
        padding: EdgeInsets.zero,
        onPressed: onPressed,
        child: SizedBox(
          width: size,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: size,
                height: size,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(m.space(23)),
                  border: Border.all(
                    color: const Color(0xFF68839B).withOpacity(0.4),
                  ),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(soundscape.artwork, fit: BoxFit.cover),
                    Positioned(
                      right: m.space(10),
                      bottom: m.space(10),
                      child: Container(
                        padding: EdgeInsets.all(m.space(7)),
                        decoration: const BoxDecoration(
                          color: Color(0x99010E21),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          CupertinoIcons.chevron_right,
                          size: m.font(22, min: 15),
                          color: SanctuaryPalette.cream,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: m.space(9)),
              Text(
                soundscape.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: m.sans(
                  20,
                  min: 12,
                  weight: FontWeight.w600,
                  tracking: -0.3,
                ),
              ),
              SizedBox(height: m.space(2)),
              Text(
                '${soundscape.minutes} min',
                style: m.sans(18, min: 11, color: SanctuaryPalette.mist),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickTrack extends StatelessWidget {
  const _QuickTrack({
    required this.label,
    required this.icon,
    required this.volume,
    required this.metrics,
    required this.onPressed,
  });
  final String label;
  final IconData icon;
  final double volume;
  final SanctuaryMetrics metrics;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final m = metrics;
    final active = volume > 0;
    return Semantics(
      label: '$label sleep sound',
      toggled: active,
      button: true,
      onTap: onPressed,
      excludeSemantics: true,
      child: CupertinoButton(
        key: ValueKey('quick-$label'),
        padding: EdgeInsets.zero,
        minSize: 44,
        onPressed: onPressed,
        child: Column(
          children: [
            Container(
              width: math.max(44.0, m.space(72)),
              height: math.max(44.0, m.space(72)),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: active
                      ? const [Color(0xFF58607B), Color(0xFF303C5A)]
                      : const [Color(0xFF39435F), Color(0xFF242F4A)],
                ),
                border: Border.all(
                  color:
                      (active ? SanctuaryPalette.gold : SanctuaryPalette.mist)
                          .withOpacity(active ? 0.55 : 0.12),
                ),
                boxShadow: active
                    ? const [
                        BoxShadow(color: Color(0x33F5C96D), blurRadius: 16),
                      ]
                    : null,
              ),
              child: Icon(
                icon,
                size: m.font(37, min: 23),
                color: label == 'Thunder' || active
                    ? SanctuaryPalette.gold
                    : const Color(0xFFE1E5F4),
              ),
            ),
            SizedBox(height: m.space(9)),
            Text(
              label,
              maxLines: 1,
              style: m.sans(
                18,
                min: 11,
                weight: active ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            SizedBox(height: m.space(7)),
            Container(
              width: math.max(28.0, m.space(64)),
              height: 3,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: const Color(0xFF52607B),
                borderRadius: BorderRadius.circular(10),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: volume.clamp(0.0, 1.0).toDouble(),
                child: const ColoredBox(color: SanctuaryPalette.gold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StoryFilter extends StatelessWidget {
  const _StoryFilter({
    required this.label,
    required this.selected,
    required this.metrics,
    required this.onPressed,
  });
  final String label;
  final bool selected;
  final SanctuaryMetrics metrics;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    child: CupertinoButton(
      key: ValueKey('stories-$label'),
      minSize: 44,
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: metrics.space(27),
          vertical: metrics.space(11),
        ),
        decoration: BoxDecoration(
          color: selected
              ? SanctuaryPalette.lavender.withOpacity(0.22)
              : Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: selected
                ? SanctuaryPalette.lavender.withOpacity(0.7)
                : Colors.white.withOpacity(0.1),
          ),
        ),
        child: Text(
          label,
          style: metrics.sans(
            20,
            min: 12,
            color: selected ? Colors.white : SanctuaryPalette.mist,
            weight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    ),
  );
}

class _StoryCard extends StatelessWidget {
  const _StoryCard({
    required this.story,
    required this.metrics,
    required this.saved,
    required this.playing,
    required this.onSave,
    required this.onPlay,
  });
  final SleepStory story;
  final SanctuaryMetrics metrics;
  final bool saved, playing;
  final VoidCallback onSave, onPlay;

  @override
  Widget build(BuildContext context) {
    final m = metrics;
    return Container(
      key: ValueKey('story-${story.id}'),
      padding: EdgeInsets.all(m.space(14)),
      decoration: sleepSurface(radius: m.space(20)),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(m.space(13)),
            child: Image.asset(
              story.artwork,
              width: math.max(48.0, m.space(76)),
              height: math.max(56.0, m.space(76)),
              fit: BoxFit.cover,
              excludeFromSemantics: true,
            ),
          ),
          SizedBox(width: m.space(17)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  story.title,
                  style: m.sans(23, min: 14, weight: FontWeight.w600),
                ),
                SizedBox(height: m.space(5)),
                Text(
                  '${story.minutes} min · Calming audio',
                  style: m.sans(17, min: 11, color: SanctuaryPalette.mist),
                ),
              ],
            ),
          ),
          CupertinoButton(
            key: ValueKey('save-story-${story.id}'),
            padding: EdgeInsets.zero,
            minSize: 44,
            onPressed: onSave,
            child: Icon(
              saved ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
              size: m.font(26, min: 20),
              color: saved ? SanctuaryPalette.gold : SanctuaryPalette.mist,
              semanticLabel: '${saved ? 'Unsave' : 'Save'} ${story.title}',
            ),
          ),
          CupertinoButton(
            key: ValueKey('play-story-${story.id}'),
            padding: EdgeInsets.zero,
            minSize: 44,
            onPressed: onPlay,
            child: Icon(
              playing
                  ? CupertinoIcons.pause_circle
                  : CupertinoIcons.play_circle,
              size: m.font(37, min: 29),
              color: SanctuaryPalette.lavender,
              semanticLabel: '${playing ? 'Pause' : 'Play'} ${story.title}',
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyStories extends StatelessWidget {
  const _EmptyStories({required this.metrics, required this.onBrowse});
  final SanctuaryMetrics metrics;
  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: EdgeInsets.all(metrics.space(30)),
    decoration: sleepSurface(radius: metrics.space(24)),
    child: Column(
      children: [
        const Icon(
          CupertinoIcons.book,
          color: SanctuaryPalette.lavender,
          size: 32,
        ),
        SizedBox(height: metrics.space(14)),
        Text(
          'Your bedtime bookshelf',
          style: metrics.sans(25, min: 17, weight: FontWeight.w600),
        ),
        SizedBox(height: metrics.space(7)),
        Text(
          'Tap the heart on a story to keep it close.',
          style: metrics.sans(19, min: 12, color: SanctuaryPalette.mist),
          textAlign: TextAlign.center,
        ),
        CupertinoButton(
          onPressed: onBrowse,
          child: Text(
            'Browse all stories',
            style: metrics.sans(20, min: 13, color: SanctuaryPalette.gold),
          ),
        ),
      ],
    ),
  );
}

class _SleepTimerSheet extends StatefulWidget {
  const _SleepTimerSheet({required this.initialDuration});
  final Duration initialDuration;

  @override
  State<_SleepTimerSheet> createState() => _SleepTimerSheetState();
}

class _SleepTimerSheetState extends State<_SleepTimerSheet> {
  late Duration _duration = widget.initialDuration;

  @override
  Widget build(BuildContext context) => CupertinoTheme(
    data: const CupertinoThemeData(
      brightness: Brightness.dark,
      primaryColor: SanctuaryPalette.gold,
    ),
    child: Container(
      color: SanctuaryPalette.navySurface,
      height: 340 + MediaQuery.paddingOf(context).bottom,
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: SanctuaryPalette.mist),
                  ),
                ),
                const Text(
                  'Sleep Auto-Fade',
                  style: TextStyle(
                    fontFamily: 'MixerSans',
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.none,
                  ),
                ),
                CupertinoButton(
                  key: const ValueKey('confirm-sleep-timer'),
                  onPressed: _duration.inMinutes > 0
                      ? () => Navigator.pop(context, _duration)
                      : null,
                  child: const Text(
                    'Set',
                    style: TextStyle(color: SanctuaryPalette.gold),
                  ),
                ),
              ],
            ),
            Expanded(
              child: CupertinoTimerPicker(
                mode: CupertinoTimerPickerMode.hm,
                initialTimerDuration: widget.initialDuration,
                onTimerDurationChanged: (duration) =>
                    setState(() => _duration = duration),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 18),
              child: Text(
                'Ambient sounds fade during the final 30 seconds.\nAll audio stops when the timer ends.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'MixerSans',
                  fontSize: 13,
                  height: 1.4,
                  color: SanctuaryPalette.mist,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
