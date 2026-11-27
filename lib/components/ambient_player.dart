part of 'guided_player.dart';

/// Expanded view of the *existing* mixer, sharing the guided player's visual
/// components. It owns no AudioPlayer, timer, audio position or recipe copy.
class AmbientPlayerOverlay extends StatefulWidget {
  const AmbientPlayerOverlay({super.key});

  @override
  State<AmbientPlayerOverlay> createState() => _AmbientPlayerOverlayState();
}

class _AmbientPlayerOverlayState extends State<AmbientPlayerOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breath = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  );
  bool _pulsing = false;

  @override
  void initState() {
    super.initState();
    setPwaPlayerExpanded(true, owner: this);
  }

  @override
  void dispose() {
    setPwaPlayerExpanded(false, owner: this);
    _breath.dispose();
    super.dispose();
  }

  Future<void> _chooseTimer(AppState app) => showCupertinoModalPopup<void>(
    context: context,
    builder: (sheetContext) => CupertinoActionSheet(
      title: const Text('Sleep auto-fade'),
      message: const Text(
        'Sound fades during the final 30 seconds. The timer keeps running while the player is minimized or paused.',
      ),
      actions: [
        for (final minutes in const [15, 30, 45, 60, 90])
          CupertinoActionSheetAction(
            onPressed: () {
              app.startSleepTimer(minutes);
              Navigator.of(sheetContext).pop();
            },
            child: Text('$minutes minutes'),
          ),
        if (app.isSleepTimerRunning)
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              app.cancelSleepTimer();
              Navigator.of(sheetContext).pop();
            },
            child: const Text('Cancel auto-fade timer'),
          ),
      ],
      cancelButton: CupertinoActionSheetAction(
        onPressed: () => Navigator.of(sheetContext).pop(),
        child: const Text('Done'),
      ),
    ),
  );

  Future<void> _saveMix(MixerController mixer) => showCupertinoDialog<void>(
    context: context,
    builder: (_) => _AmbientSaveMixDialog(mixer: mixer),
  );

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final mixer = context.watch<MixerController>();
    final layers = mixer.levels.entries
        .where((entry) => entry.value > 0)
        .toList();
    if (layers.isEmpty) return const SizedBox.shrink();
    final main =
        (layers.toList()..sort((a, b) => b.value.compareTo(a.value))).first.key;
    final title =
        mixer.preset ??
        (layers.length == 1 ? main : '$main + ${layers.length - 1} more');
    final artwork = layers.any((entry) => entry.key == 'Ocean Waves')
        ? oceanSleepJourney.artwork
        : _ambientArtwork(main);
    final animate =
        mixer.isPlaying &&
        !app.isBackgroundMode &&
        TickerMode.of(context) &&
        !MediaQuery.of(context).disableAnimations &&
        !MediaQuery.of(context).accessibleNavigation;
    if (_pulsing != animate) {
      _pulsing = animate;
      if (animate)
        _breath.repeat(reverse: true);
      else
        _breath.stop();
    }
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) app.minimizeAmbientPlayer();
      },
      child: BlockSemantics(
        child: Semantics(
          label: 'Soundscape player',
          explicitChildNodes: true,
          scopesRoute: true,
          namesRoute: true,
          child: FocusScope(
            autofocus: true,
            child: Material(
              key: const ValueKey('ambient-player'),
              color: MixerTheme.background,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const Positioned.fill(
                    child: SanctuaryBackground(child: SizedBox.expand()),
                  ),
                  SafeArea(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final s = (constraints.maxWidth / 430)
                            .clamp(.85, 1.35)
                            .toDouble();
                        final cover = math.min(
                          176.0,
                          math.min(
                            constraints.maxWidth * .38,
                            math.max(112.0, constraints.maxHeight * .20),
                          ),
                        );
                        return SingleChildScrollView(
                          key: const ValueKey('ambient-player-scroll'),
                          padding: EdgeInsets.all(18 * s),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: _PlayerGlass(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 10,
                                          ),
                                          child: Text(
                                            'AMBIENT MIX',
                                            style: _type(
                                              11,
                                              weight: FontWeight.w600,
                                              tracking: 1.1,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  _CircleControl(
                                    buttonKey: const ValueKey(
                                      'minimize-ambient-player',
                                    ),
                                    label: 'Minimize soundscape player',
                                    symbol: SanctuarySymbol.chevronDown,
                                    size: 44,
                                    onPressed: app.minimizeAmbientPlayer,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              AnimatedBuilder(
                                key: const ValueKey(
                                  'ambient-artwork-animation',
                                ),
                                animation: _breath,
                                builder: (context, _) => _BreathingArtwork(
                                  size: cover,
                                  scale: s,
                                  pulse: animate ? _breath.value : .35,
                                  artwork: artwork,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                title,
                                key: const ValueKey('ambient-player-title'),
                                textAlign: TextAlign.center,
                                style: _type(
                                  25 * s,
                                  weight: FontWeight.w600,
                                  height: 1.16,
                                ),
                              ),
                              const SizedBox(height: 9),
                              Semantics(
                                liveRegion: true,
                                child: Text(
                                  mixer.playbackStatusLabel,
                                  key: const ValueKey(
                                    'ambient-playback-status',
                                  ),
                                  textAlign: TextAlign.center,
                                  style: _type(13, color: _mint, height: 1.4),
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                'Continuous loops · No narration',
                                textAlign: TextAlign.center,
                                style: _type(12, color: _mist),
                              ),
                              const SizedBox(height: 18),
                              Semantics(
                                label: mixer.transportLabel,
                                button: true,
                                child: CupertinoButton(
                                  key: const ValueKey('ambient-play-pause'),
                                  padding: EdgeInsets.zero,
                                  onPressed: () =>
                                      mixer.togglePlayback(expandPlayer: false),
                                  child: Container(
                                    width: 70,
                                    height: 70,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: MixerTheme.primary,
                                    ),
                                    child: SanctuaryIcon(
                                      mixer.isPreparing && !mixer.isPlaying
                                          ? SanctuarySymbol.close
                                          : mixer.isPlaying
                                          ? SanctuarySymbol.pause
                                          : SanctuarySymbol.play,
                                      size: 32,
                                      color: MixerTheme.onPrimary,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                alignment: WrapAlignment.center,
                                spacing: 10,
                                runSpacing: 10,
                                children: [
                                  _PlayerOption(
                                    label: app.isSleepTimerRunning
                                        ? 'Auto-fade · ${_clock(app.sleepTimerRemainingSec!)}'
                                        : 'Set auto-fade',
                                    symbol: SanctuarySymbol.clock,
                                    scale: 1,
                                    buttonKey: const ValueKey(
                                      'ambient-sleep-timer',
                                    ),
                                    onPressed: () => _chooseTimer(app),
                                  ),
                                  _PlayerOption(
                                    label: 'Add sounds',
                                    symbol: SanctuarySymbol.sliders,
                                    scale: 1,
                                    buttonKey: const ValueKey(
                                      'ambient-edit-mix',
                                    ),
                                    onPressed: () {
                                      app.minimizeAmbientPlayer();
                                      app.setTab(AppTab.sounds);
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 22),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'YOUR SOUNDS · ${layers.length} selected',
                                  style: _type(11, color: _mist, tracking: 1.4),
                                ),
                              ),
                              const SizedBox(height: 12),
                              for (final layer in layers)
                                Padding(
                                  key: ValueKey('ambient-layer-${layer.key}'),
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _AmbientLayer(
                                    name: layer.key,
                                    volume: layer.value,
                                    app: app,
                                    mixer: mixer,
                                  ),
                                ),
                              Text(
                                'Individual volumes, not parts of 100%. Overall output is gain-limited.',
                                style: _type(11, color: _mist, height: 1.5),
                              ),
                              const SizedBox(height: 18),
                              Wrap(
                                alignment: WrapAlignment.center,
                                spacing: 10,
                                runSpacing: 10,
                                children: [
                                  _PlayerOption(
                                    label: 'Save a separate mix',
                                    symbol: SanctuarySymbol.book,
                                    scale: 1,
                                    buttonKey: const ValueKey(
                                      'ambient-save-mix',
                                    ),
                                    onPressed: () => _saveMix(mixer),
                                  ),
                                  _PlayerOption(
                                    label: 'Stop soundscape',
                                    symbol: SanctuarySymbol.close,
                                    scale: 1,
                                    buttonKey: const ValueKey('ambient-stop'),
                                    onPressed: app.stopAllAudio,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _ambientArtwork(String name) {
  for (final track in allMixerTracks) {
    if (track.name == name) return track.coverAsset;
  }
  return sleepArtworkForTrack(name);
}

class _AmbientLayer extends StatelessWidget {
  const _AmbientLayer({
    required this.name,
    required this.volume,
    required this.app,
    required this.mixer,
  });
  final String name;
  final double volume;
  final AppState app;
  final MixerController mixer;

  @override
  Widget build(BuildContext context) {
    final status = app.ambientTrackStatus(name);
    final error = app.ambientTrackError(name);
    final hasSource = AppState.hasAmbientSource(name);
    final label = !hasSource
        ? 'No recording configured'
        : error != null
        ? 'Unavailable · Retry this layer'
        : switch (status) {
            AmbientPlaybackStatus.playing => 'Playing',
            AmbientPlaybackStatus.loading => 'Preparing audio…',
            AmbientPlaybackStatus.buffering => 'Buffering…',
            _ => 'Paused',
          };
    return _PlayerGlass(
      radius: 20,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 8, 3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    _ambientArtwork(name),
                    width: 38,
                    height: 42,
                    fit: BoxFit.cover,
                    excludeFromSemantics: true,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: _type(14, weight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      Text(
                        label,
                        key: ValueKey('ambient-layer-status-$name'),
                        style: _type(
                          11,
                          color: error != null
                              ? const Color(0xFFFFDCAB)
                              : status == AmbientPlaybackStatus.playing
                              ? _mint
                              : _mist,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${(volume * 100).round()}%',
                  key: ValueKey('ambient-layer-volume-$name'),
                  style: _type(15, color: _mint),
                ),
                _CircleControl(
                  buttonKey: ValueKey('ambient-remove-$name'),
                  label: 'Remove $name from mix',
                  symbol: SanctuarySymbol.close,
                  size: 40,
                  onPressed: () =>
                      mixer.setVolume(name, 0, preservePaused: true),
                ),
              ],
            ),
            Semantics(
              label: '$name volume',
              value: '${(volume * 100).round()} percent',
              child: SizedBox(
                height: 44,
                child: CupertinoSlider(
                  key: ValueKey('ambient-volume-$name'),
                  value: volume,
                  divisions: 100,
                  activeColor: MixerTheme.primary,
                  thumbColor: _pearl,
                  onChanged: hasSource
                      ? (value) =>
                            mixer.setVolume(name, value, preservePaused: true)
                      : null,
                ),
              ),
            ),
            if (error != null && hasSource)
              CupertinoButton(
                key: ValueKey('ambient-retry-$name'),
                minSize: 44,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                onPressed: () => mixer.retryTrack(name),
                child: Text(
                  'Retry layer',
                  style: _type(13, color: const Color(0xFFFFDCAB)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AmbientSaveMixDialog extends StatefulWidget {
  const _AmbientSaveMixDialog({required this.mixer});
  final MixerController mixer;

  @override
  State<_AmbientSaveMixDialog> createState() => _AmbientSaveMixDialogState();
}

class _AmbientSaveMixDialogState extends State<_AmbientSaveMixDialog> {
  final _name = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CupertinoAlertDialog(
    title: const Text('Save a separate mix'),
    content: Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Semantics(
        label: 'Mix name',
        child: CupertinoTextField(
          controller: _name,
          autofocus: true,
          maxLength: 60,
          placeholder: 'e.g. Evening forest',
          onChanged: (_) => setState(() {}),
        ),
      ),
    ),
    actions: [
      CupertinoDialogAction(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancel'),
      ),
      CupertinoDialogAction(
        isDefaultAction: true,
        onPressed: _name.text.trim().isEmpty
            ? null
            : () {
                if (widget.mixer.saveMix(_name.text))
                  Navigator.of(context).pop();
              },
        child: const Text('Save mix'),
      ),
    ],
  );
}
