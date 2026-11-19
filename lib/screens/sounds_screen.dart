import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:relax_mindfulness/components/mixer_waveform.dart';
import 'package:relax_mindfulness/models/mixer_catalog.dart';
import 'package:relax_mindfulness/providers/app_state.dart';
import 'package:relax_mindfulness/providers/mixer_controller.dart';
import 'package:relax_mindfulness/screens/wellbeing_screen.dart';
import 'package:relax_mindfulness/theme/mixer_theme.dart';

/// The dedicated reference-inspired mixer. Home has its own daily dashboard.
class SoundsScreen extends StatelessWidget {
  const SoundsScreen({super.key});

  Future<void> _notice(BuildContext context, String title, String message) =>
      showCupertinoDialog<void>(
        context: context,
        builder: (dialogContext) => CupertinoAlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Done'),
            ),
          ],
        ),
      );

  Future<void> _saveMix(BuildContext context, MixerController mixer) async {
    if (mixer.selectedCount == 0) {
      await _notice(
        context,
        'Choose a sound first',
        'Turn on a sound to create your mix.',
      );
      return;
    }
    final name = await showCupertinoDialog<String>(
      context: context,
      builder: (_) => const _MixNameDialog(
        title: 'Save your soundscape',
        action: 'Save mix',
        placeholder: 'e.g. Rainy study night',
      ),
    );
    if (name != null && context.mounted && mixer.saveMix(name)) {
      await _notice(
        context,
        'Soundscape saved',
        'Find “$name” in Saved mixes.',
      );
    }
  }

  Future<void> _shareMix(BuildContext context, MixerController mixer) async {
    final uri = mixer.shareUri(base: kIsWeb ? Uri.base : null);
    try {
      await Clipboard.setData(ClipboardData(text: uri.toString()));
      if (context.mounted) {
        await _notice(
          context,
          'Mix link copied',
          'Share your soundscape with someone who could use a little calm.',
        );
      }
    } catch (_) {
      if (context.mounted) {
        await _notice(context, 'Your mix link', uri.toString());
      }
    }
  }

  Future<void> _renamePreset(
    BuildContext context,
    AppState state,
    String originalName,
  ) async {
    final name = await showCupertinoDialog<String>(
      context: context,
      builder: (_) => _MixNameDialog(
        title: 'Rename recommended mix',
        action: 'Save name',
        initialValue: state.getPresetDisplayName(originalName),
      ),
    );
    if (name != null && context.mounted) {
      state.renameCuratedPreset(originalName, name);
    }
  }

  void _savedMixes(
    BuildContext context,
    AppState state,
    MixerController mixer,
  ) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (sheetContext) => CupertinoActionSheet(
        title: const Text('Your saved soundscapes'),
        actions: [
          for (final preset in state.presets)
            CupertinoActionSheetAction(
              onPressed: () {
                mixer.applyMix(preset.volumes, name: preset.name);
                Navigator.pop(sheetContext);
              },
              child: Text(preset.name),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(sheetContext),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Consumer2<AppState, MixerController>(
    builder: (context, state, mixer, _) => LayoutBuilder(
      builder: (context, constraints) {
        final metrics = MixerMetrics(
          math.min(constraints.maxWidth, MixerTheme.maxWidth),
        );
        final s = metrics.scale;
        final tracks = mixer.category == 'favorites'
            ? allMixerTracks
                  .where((track) => state.isFavorite(track.name))
                  .toList()
            : mixerCategories
                  .firstWhere((category) => category.id == mixer.category)
                  .tracks;
        return CupertinoPageScaffold(
          backgroundColor: MixerTheme.background,
          child: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: ExcludeSemantics(
                  child: Image.asset(
                    'assets/images/mixer/moonlit_forest.webp',
                    fit: BoxFit.fitWidth,
                    filterQuality: FilterQuality.medium,
                  ),
                ),
              ),
              SafeArea(
                bottom: false,
                child: CustomScrollView(
                  key: const PageStorageKey('ambient-mixer-scroll'),
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  slivers: [
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(29 * s, 36 * s, 29 * s, 0),
                      sliver: SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sounds',
                              key: const ValueKey('mixer-title'),
                              style: metrics.text(
                                53,
                                weight: FontWeight.w700,
                                height: 1.2,
                                tracking: -1.5 * s,
                              ),
                            ),
                            SizedBox(height: 8 * s),
                            Row(
                              children: [
                                Text(
                                  'AMBIENT SOUND MIXER',
                                  style: metrics.text(
                                    17,
                                    color: const Color(0xFF80E5D2),
                                    weight: FontWeight.w600,
                                    tracking: 2.8 * s,
                                  ),
                                ),
                                SizedBox(width: 14 * s),
                                Container(
                                  width: 60 * s,
                                  height: 1,
                                  color: MixerTheme.mint.withOpacity(0.5),
                                ),
                              ],
                            ),
                            SizedBox(height: 8 * s),
                            Text(
                              'Build Your Environment',
                              style: metrics.text(
                                44,
                                weight: FontWeight.w700,
                                height: 1.15,
                                tracking: -0.7 * s,
                              ),
                            ),
                            SizedBox(height: 8 * s),
                            Text(
                              'Layer natural sounds & healing frequencies for work, study, or sleep',
                              style: metrics.text(
                                22,
                                color: const Color(0xFFB9D0D5),
                              ),
                            ),
                            SizedBox(height: 24 * s),
                            _masterControls(context, state, mixer, metrics),
                            SizedBox(
                              height: 44 * s,
                              width: double.infinity,
                              child: MixerWaveform(
                                playing:
                                    mixer.isPlaying && !state.isBackgroundMode,
                              ),
                            ),
                            MixerSectionHeading(
                              'CURATED ONE-TAP MIXES',
                              metrics: metrics,
                            ),
                            SizedBox(height: 12 * s),
                          ],
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.symmetric(
                          horizontal: 20 * s,
                          vertical: 1 * s,
                        ),
                        child: Row(
                          children: [
                            for (final entry in AppState.curatedPresets.entries)
                              Padding(
                                padding: EdgeInsets.only(right: 12 * s),
                                child: _MixChip(
                                  label: state.getPresetDisplayName(entry.key),
                                  selected: mixer.preset == entry.key,
                                  onLongPress: () =>
                                      _renamePreset(context, state, entry.key),
                                  metrics: metrics,
                                  onPressed: () {
                                    HapticFeedback.selectionClick();
                                    mixer.applyMix(
                                      entry.value,
                                      name: entry.key,
                                    );
                                  },
                                ),
                              ),
                            if (state.presets.isNotEmpty)
                              _MixChip(
                                label:
                                    '♧ Saved mixes (${state.presets.length})',
                                metrics: metrics,
                                onPressed: () =>
                                    _savedMixes(context, state, mixer),
                              ),
                          ],
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        29 * s,
                        18 * s,
                        29 * s,
                        14 * s,
                      ),
                      sliver: SliverToBoxAdapter(
                        child: MixerSectionHeading(
                          'SOUND CATEGORY TRAY',
                          metrics: metrics,
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: SingleChildScrollView(
                        key: const ValueKey('mixer-categories'),
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.symmetric(
                          horizontal: 29 * s,
                          vertical: 1 * s,
                        ),
                        child: Row(
                          children: [
                            _CategoryChip(
                              id: 'favorites',
                              emoji: '❤️',
                              label: 'Favorites',
                              count: state.favoriteSounds.length,
                              mixer: mixer,
                              metrics: metrics,
                            ),
                            for (final category in mixerCategories)
                              _CategoryChip(
                                id: category.id,
                                emoji: category.emoji,
                                label: category.label,
                                count: category.tracks.length,
                                mixer: mixer,
                                metrics: metrics,
                              ),
                          ],
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(29 * s, 18 * s, 29 * s, 0),
                      sliver: tracks.isEmpty
                          ? SliverToBoxAdapter(
                              child: _emptyFavorites(mixer, metrics),
                            )
                          : SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) => Padding(
                                  padding: EdgeInsets.only(bottom: 16 * s),
                                  child: _TrackCard(
                                    key: ValueKey(
                                      'track-${tracks[index].name}',
                                    ),
                                    track: tracks[index],
                                    state: state,
                                    mixer: mixer,
                                    metrics: metrics,
                                  ),
                                ),
                                childCount: tracks.length,
                              ),
                            ),
                    ),
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        29 * s,
                        12,
                        29 * s,
                        MediaQuery.paddingOf(context).bottom +
                            (state.hasGuidedSession ? 126 : 32),
                      ),
                      sliver: SliverToBoxAdapter(
                        child: Column(
                          children: [
                            Text(
                              'Touch and hold a sound to add or remove a favorite.',
                              textAlign: TextAlign.center,
                              style: metrics.text(18, color: MixerTheme.muted),
                            ),
                            const SizedBox(height: 12),
                            CupertinoButton(
                              onPressed: () => Navigator.of(context).push(
                                CupertinoPageRoute<void>(
                                  builder: (_) => const WellbeingScreen(),
                                ),
                              ),
                              child: const Text(
                                'Your wellbeing dashboard  →',
                                style: TextStyle(color: MixerTheme.mint),
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

  Widget _masterControls(
    BuildContext context,
    AppState state,
    MixerController mixer,
    MixerMetrics metrics,
  ) {
    final s = metrics.scale;
    return MixerSurface(
      metrics: metrics,
      padding: EdgeInsets.symmetric(horizontal: 24 * s, vertical: 22 * s),
      child: Row(
        children: [
          Semantics(
            button: true,
            label: mixer.isPlaying ? 'Pause sound mixer' : 'Play sound mixer',
            child: CupertinoButton(
              key: const ValueKey('mixer-play'),
              padding: EdgeInsets.zero,
              minSize: 0,
              onPressed: () {
                HapticFeedback.lightImpact();
                mixer.togglePlayback();
              },
              child: SizedBox(
                width: math.max(44.0, 70 * s),
                height: math.max(44.0, 70 * s),
                child: Center(
                  child: Container(
                    width: 70 * s,
                    height: 70 * s,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: MixerTheme.mint,
                        width: 2.5 * s,
                      ),
                      gradient: const RadialGradient(
                        colors: [Color(0xFF0D645F), Color(0xFF02373D)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: MixerTheme.mint.withOpacity(0.4),
                          blurRadius: 20 * s,
                        ),
                      ],
                    ),
                    child: Icon(
                      mixer.isPlaying
                          ? CupertinoIcons.pause_fill
                          : CupertinoIcons.play_fill,
                      color: MixerTheme.mintLight,
                      size: 34 * s,
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: 24 * s),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mixer.isPlaying ? 'Soundscape Active' : 'Mixer Paused',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: metrics.text(
                    26,
                    weight: FontWeight.w600,
                    tracking: -0.6 * s,
                  ),
                ),
                SizedBox(height: 3 * s),
                Text(
                  mixer.isPlaying
                      ? '${mixer.selectedCount} active layers'
                      : 'Tap play to start audio',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: metrics.text(20, color: MixerTheme.muted),
                ),
              ],
            ),
          ),
          _roundButton(
            'Shuffle mix',
            'mixer-shuffle',
            CupertinoIcons.shuffle,
            metrics,
            mixer.shuffle,
          ),
          SizedBox(width: 8 * s),
          _roundButton(
            'Share mix',
            'mixer-share',
            CupertinoIcons.share,
            metrics,
            () => _shareMix(context, mixer),
          ),
          SizedBox(width: 14 * s),
          Semantics(
            button: true,
            label: 'Save sound mix',
            child: CupertinoButton(
              key: const ValueKey('mixer-save'),
              minSize: 0,
              padding: EdgeInsets.zero,
              onPressed: () => _saveMix(context, mixer),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 22 * s,
                  vertical: 13 * s,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFACFFE6),
                      Color(0xFF45EACB),
                      Color(0xFF23D7BC),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(34 * s),
                  border: Border.all(
                    color: MixerTheme.mintLight.withOpacity(0.7),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: MixerTheme.mint.withOpacity(0.5),
                      blurRadius: 23 * s,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      CupertinoIcons.bookmark,
                      color: const Color(0xFF00554F),
                      size: 24 * s,
                    ),
                    SizedBox(width: 8 * s),
                    Text(
                      'Save',
                      style: metrics.text(
                        22,
                        color: const Color(0xFF004D48),
                        weight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _roundButton(
    String label,
    String key,
    IconData icon,
    MixerMetrics metrics,
    VoidCallback onPressed,
  ) {
    final s = metrics.scale;
    return Semantics(
      button: true,
      label: label,
      child: CupertinoButton(
        key: ValueKey(key),
        minSize: 0,
        padding: EdgeInsets.zero,
        onPressed: onPressed,
        child: SizedBox(
          width: math.max(32.0, 48 * s),
          height: math.max(44.0, 48 * s),
          child: Center(
            child: Container(
              width: 48 * s,
              height: 48 * s,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: MixerTheme.mint.withOpacity(0.11),
              ),
              child: Icon(icon, color: MixerTheme.muted, size: 21 * s),
            ),
          ),
        ),
      ),
    );
  }

  Widget _emptyFavorites(MixerController mixer, MixerMetrics metrics) =>
      MixerSurface(
        metrics: metrics,
        padding: const EdgeInsets.all(30),
        child: Column(
          children: [
            const Icon(CupertinoIcons.heart, color: MixerTheme.mint, size: 32),
            const SizedBox(height: 12),
            Text(
              'Your quiet favorites live here',
              textAlign: TextAlign.center,
              style: metrics.text(28, weight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Touch and hold any sound card to save it to Favorites.',
              textAlign: TextAlign.center,
              style: metrics.text(21, color: MixerTheme.muted),
            ),
            CupertinoButton(
              onPressed: () => mixer.selectCategory('rain'),
              child: const Text('Explore rain sounds'),
            ),
          ],
        ),
      );
}

/// Own the controller for the entire route transition, including dismissal.
class _MixNameDialog extends StatefulWidget {
  const _MixNameDialog({
    required this.title,
    required this.action,
    this.initialValue = '',
    this.placeholder = 'Name your soundscape',
  });
  final String title, action, initialValue, placeholder;

  @override
  State<_MixNameDialog> createState() => _MixNameDialogState();
}

class _MixNameDialogState extends State<_MixNameDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  void _submit() {
    final name = _controller.text.trim();
    if (name.isNotEmpty) Navigator.pop(context, name);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CupertinoAlertDialog(
    title: Text(widget.title),
    content: Padding(
      padding: const EdgeInsets.only(top: 16),
      child: CupertinoTextField(
        key: const ValueKey('mix-name'),
        controller: _controller,
        autofocus: true,
        maxLength: 60,
        placeholder: widget.placeholder,
        style: const TextStyle(color: MixerTheme.text),
        onChanged: (_) => setState(() {}),
        onSubmitted: (_) => _submit(),
      ),
    ),
    actions: [
      CupertinoDialogAction(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      CupertinoDialogAction(
        isDefaultAction: true,
        onPressed: _controller.text.trim().isEmpty ? null : _submit,
        child: Text(widget.action),
      ),
    ],
  );
}

class _MixChip extends StatelessWidget {
  const _MixChip({
    required this.label,
    required this.metrics,
    required this.onPressed,
    this.selected = false,
    this.onLongPress,
  });
  final String label;
  final MixerMetrics metrics;
  final VoidCallback onPressed;
  final bool selected;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final s = metrics.scale;
    return GestureDetector(
      onLongPress: onLongPress,
      child: Semantics(
        selected: selected,
        child: CupertinoButton(
          minSize: 0,
          padding: EdgeInsets.zero,
          onPressed: onPressed,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 14 * s, vertical: 12 * s),
            decoration: BoxDecoration(
              color: selected
                  ? const Color(0xFF0A4145)
                  : const Color(0xD0001821),
              borderRadius: BorderRadius.circular(30 * s),
              border: Border.all(
                color: selected
                    ? MixerTheme.mint.withOpacity(0.6)
                    : MixerTheme.border.withOpacity(0.2),
              ),
            ),
            child: Text(
              label,
              style: metrics.text(19, weight: FontWeight.w500),
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.id,
    required this.emoji,
    required this.label,
    required this.count,
    required this.mixer,
    required this.metrics,
  });
  final String id, emoji, label;
  final int count;
  final MixerController mixer;
  final MixerMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final selected = mixer.category == id;
    final s = metrics.scale;
    return Padding(
      padding: EdgeInsets.only(right: 10 * s),
      child: Semantics(
        selected: selected,
        button: true,
        label: '$label, $count sounds',
        child: CupertinoButton(
          key: ValueKey('category-$id'),
          minSize: 0,
          padding: EdgeInsets.zero,
          onPressed: () {
            HapticFeedback.selectionClick();
            mixer.selectCategory(id);
          },
          child: Container(
            width: 184 * s,
            padding: EdgeInsets.symmetric(vertical: 12 * s),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(17 * s),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: selected
                    ? const [Color(0xFF6CECCF), Color(0xFF25C9B2)]
                    : const [Color(0xFF07363F), Color(0xFF02242E)],
              ),
              border: Border.all(
                color: selected
                    ? MixerTheme.mintLight.withOpacity(0.6)
                    : MixerTheme.border.withOpacity(0.4),
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: MixerTheme.mint.withOpacity(0.35),
                        blurRadius: 18 * s,
                      ),
                    ]
                  : null,
            ),
            child: Text(
              '$emoji $label ($count)',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: metrics.text(
                21,
                color: selected ? const Color(0xFF00544D) : MixerTheme.text,
                weight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TrackCard extends StatelessWidget {
  const _TrackCard({
    required this.track,
    required this.state,
    required this.mixer,
    required this.metrics,
    super.key,
  });
  final MixerTrack track;
  final AppState state;
  final MixerController mixer;
  final MixerMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final s = metrics.scale;
    final volume = mixer.volume(track.name);
    final selected = volume > 0;
    final thumbWidth = math.max(40.0, 104 * s);
    final thumbHeight = math.max(40.0, (selected ? 100 : 88) * s);
    final verticalPadding = selected ? 14.0 : 12.0;
    return Semantics(
      container: true,
      label: '${track.name}, ${track.description}',
      hint: state.isFavorite(track.name)
          ? 'Touch and hold to remove from Favorites'
          : 'Touch and hold to add to Favorites',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => mixer.toggleTrack(track.name),
        onLongPress: () {
          HapticFeedback.lightImpact();
          state.toggleFavoriteSound(track.name);
        },
        child: _MotionAwareTrackSize(
          child: MixerSurface(
            metrics: metrics,
            active: selected,
            padding: EdgeInsets.symmetric(
              horizontal: 14 * s,
              vertical: verticalPadding * s,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16 * s),
                      child: Container(
                        width: thumbWidth,
                        height: thumbHeight,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              track.color.withOpacity(0.6),
                              const Color(0xFF073039),
                            ],
                          ),
                        ),
                        child: track.artwork != null
                            ? Image.asset(
                                track.artwork!,
                                fit: BoxFit.cover,
                                excludeFromSemantics: true,
                              )
                            : Center(
                                child: Text(
                                  track.emoji,
                                  style: TextStyle(fontSize: 38 * s),
                                ),
                              ),
                      ),
                    ),
                    SizedBox(width: 24 * s),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            track.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: metrics.text(
                              selected ? 30 : 28,
                              weight: FontWeight.w600,
                              tracking: -0.7 * s,
                            ),
                          ),
                          SizedBox(height: 3 * s),
                          Text(
                            track.description,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: metrics.text(20, color: MixerTheme.muted),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 12 * s),
                    Container(
                      width: math.max(38.0, 96 * s),
                      padding: EdgeInsets.symmetric(vertical: 10 * s),
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFF00514F)
                            : const Color(0xFF12333E),
                        borderRadius: BorderRadius.circular(28 * s),
                      ),
                      child: Text(
                        '${(volume * 100).round()}%',
                        textAlign: TextAlign.center,
                        style: metrics.text(
                          24,
                          color: selected
                              ? const Color(0xFF74F9DA)
                              : MixerTheme.muted,
                          weight: selected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ),
                    SizedBox(width: 24 * s),
                    Semantics(
                      label: 'Enable ${track.name}',
                      child: SizedBox(
                        width: math.max(38.0, 80 * s),
                        height: math.max(40.0, 48 * s),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(40),
                            boxShadow: selected
                                ? [
                                    BoxShadow(
                                      color: MixerTheme.mint.withOpacity(0.35),
                                      blurRadius: 20 * s,
                                    ),
                                  ]
                                : null,
                          ),
                          child: FittedBox(
                            fit: BoxFit.contain,
                            child: CupertinoSwitch(
                              key: ValueKey('toggle-${track.name}'),
                              value: selected,
                              activeColor: MixerTheme.mint,
                              trackColor: const Color(0xFF3B5660),
                              thumbColor: Colors.white,
                              onChanged: (_) => mixer.toggleTrack(track.name),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (selected)
                  Padding(
                    padding: EdgeInsets.only(
                      left: thumbWidth + 24 * s,
                      top: 1 * s,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          CupertinoIcons.volume_down,
                          color: const Color(0xFF3FADAA),
                          size: 26 * s,
                        ),
                        SizedBox(width: 14 * s),
                        Expanded(
                          child: SizedBox(
                            height: math.max(32.0, 34 * s),
                            child: Material(
                              type: MaterialType.transparency,
                              child: SliderTheme(
                                data: SliderThemeData(
                                  trackHeight: 6 * s,
                                  activeTrackColor: MixerTheme.mint,
                                  inactiveTrackColor: const Color(0xFF20404A),
                                  thumbColor: Colors.white,
                                  overlayColor: MixerTheme.mint.withOpacity(
                                    0.15,
                                  ),
                                  thumbShape: RoundSliderThumbShape(
                                    enabledThumbRadius: math.max(8.0, 18 * s),
                                    elevation: 0,
                                  ),
                                  overlayShape: RoundSliderOverlayShape(
                                    overlayRadius: math.max(16.0, 24 * s),
                                  ),
                                  trackShape: const _FullWidthSliderTrack(),
                                ),
                                child: Slider(
                                  key: ValueKey('volume-${track.name}'),
                                  value: volume,
                                  semanticFormatterCallback: (value) =>
                                      '${track.name} volume ${(value * 100).round()} percent',
                                  onChanged: (value) =>
                                      mixer.setVolume(track.name, value),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 14 * s),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Reduced motion removes size animation rather than running AnimatedSize at
/// zero duration, which can synchronously dirty itself during layout.
class _MotionAwareTrackSize extends StatelessWidget {
  const _MotionAwareTrackSize({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context))
      return child;
    return AnimatedSize(
      duration: const Duration(milliseconds: 180),
      alignment: Alignment.topCenter,
      child: child,
    );
  }
}

class _FullWidthSliderTrack extends RoundedRectSliderTrackShape {
  const _FullWidthSliderTrack();

  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final height = sliderTheme.trackHeight ?? 2;
    return Rect.fromLTWH(
      offset.dx,
      offset.dy + (parentBox.size.height - height) / 2,
      parentBox.size.width,
      height,
    );
  }
}
