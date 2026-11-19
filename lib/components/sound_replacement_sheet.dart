import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:relax_mindfulness/components/mixer_artwork.dart';
import 'package:relax_mindfulness/components/sanctuary_icon.dart';
import 'package:relax_mindfulness/models/bundled_recordings.dart';
import 'package:relax_mindfulness/models/mixer_catalog.dart';
import 'package:relax_mindfulness/providers/mixer_controller.dart';
import 'package:relax_mindfulness/services/sound_preview_controller.dart';
import 'package:relax_mindfulness/services/pwa_player_visibility.dart';

/// Replaces one layer with an existing sound, not several purported recordings
/// of that sound. No file import or newly licensed audio pack is implied.
class SoundReplacementSheet extends StatefulWidget {
  const SoundReplacementSheet({
    required this.track,
    required this.mixer,
    required this.onPreviewActivity,
    this.previewPlayerFactory,
    super.key,
  });
  final MixerTrack track;
  final MixerController mixer;
  final void Function(bool) onPreviewActivity;
  final SoundPreviewPlayer Function()? previewPlayerFactory;

  @override
  State<SoundReplacementSheet> createState() => _SoundReplacementSheetState();
}

class _SoundReplacementSheetState extends State<SoundReplacementSheet>
    with WidgetsBindingObserver {
  late final SoundPreviewController _preview;
  String? _selected;
  String? _notice;
  bool _applying = false;

  @override
  void initState() {
    super.initState();
    setPwaSoundChooserOpen(true);
    WidgetsBinding.instance.addObserver(this);
    _preview = SoundPreviewController(
      playerFactory: widget.previewPlayerFactory,
      onPreviewActivity: widget.onPreviewActivity,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) unawaited(_preview.stop());
  }

  @override
  void dispose() {
    setPwaSoundChooserOpen(false);
    WidgetsBinding.instance.removeObserver(this);
    _preview.dispose();
    super.dispose();
  }

  bool _available(String name) =>
      name != widget.track.name &&
      widget.mixer.replacementConflict(widget.track.name, name) == null;

  Future<void> _use() async {
    final name = _selected;
    if (name == null || !_available(name) || _applying) return;
    setState(() => _applying = true);
    await _preview.stop();
    if (!mounted) return;
    if (widget.mixer.replaceTrack(widget.track.name, name)) {
      Navigator.pop(context);
    } else {
      setState(() {
        _applying = false;
        _notice =
            'That recording is already in your mix. Choose another sound.';
      });
    }
  }

  Widget _recording(BundledRecording recording) {
    final track = allMixerTracks.firstWhere(
      (track) => track.name == recording.name,
    );
    final available = _available(recording.name);
    final current = recording.name == widget.track.name;
    final conflict = widget.mixer.replacementConflict(
      widget.track.name,
      recording.name,
    );
    final selected = _selected == recording.name;
    final previewing =
        _preview.name == recording.name &&
        (_preview.isPlaying || _preview.isLoading);
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 6),
      child: Semantics(
        selected: selected,
        child: Container(
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF124841) : const Color(0xFF0C3039),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? const Color(0xFF73E4CD)
                  : const Color(0xFF24505A),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: CupertinoButton(
                  key: ValueKey('select-replacement-${recording.name}'),
                  padding: const EdgeInsets.all(12),
                  onPressed: !available || _applying
                      ? null
                      : () => setState(() {
                          _selected = recording.name;
                          _notice = null;
                        }),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: SizedBox.square(
                          dimension: 48,
                          child: MixerArtwork(track: track),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              recording.name,
                              style: TextStyle(
                                color: available
                                    ? const Color(0xFFEBF8F4)
                                    : const Color(0xFFB0C3C3),
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              current
                                  ? 'Current sound'
                                  : conflict != null
                                  ? 'Already in mix: $conflict'
                                  : recording.description,
                              style: const TextStyle(
                                color: Color(0xFFA1BFC4),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (selected)
                        const Padding(
                          padding: EdgeInsets.only(left: 6),
                          child: SanctuaryIcon(
                            SanctuarySymbol.check,
                            size: 20,
                            color: Color(0xFF77E8D0),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Semantics(
                label:
                    '${previewing ? 'Stop preview' : 'Preview'} ${recording.name}',
                button: true,
                child: CupertinoButton(
                  key: ValueKey('preview-${recording.name}'),
                  padding: const EdgeInsets.all(12),
                  onPressed: _applying
                      ? null
                      : () {
                          unawaited(_preview.toggle(recording));
                        },
                  child: _preview.isLoading && previewing
                      ? const SizedBox.square(
                          dimension: 22,
                          child: CupertinoActivityIndicator(),
                        )
                      : SanctuaryIcon(
                          previewing
                              ? SanctuarySymbol.pause
                              : SanctuarySymbol.play,
                          size: 22,
                          color: const Color(0xFF77E8D0),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: Listenable.merge([_preview, widget.mixer]),
    builder: (context, _) => CupertinoPopupSurface(
      child: ColoredBox(
        color: const Color(0xFF06232D),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: math.min(680, MediaQuery.sizeOf(context).height * 0.85),
            child: Semantics(
              scopesRoute: true,
              namesRoute: true,
              label: 'Replace sound',
              explicitChildNodes: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 14, 10, 0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Replace ${widget.track.name}',
                                    style: const TextStyle(
                                      color: Color(0xFFF0FAF7),
                                      fontSize: 22,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Semantics(
                                  label: 'Close sound chooser',
                                  button: true,
                                  child: CupertinoButton(
                                    key: const ValueKey(
                                      'close-sound-replacement',
                                    ),
                                    onPressed: () => Navigator.pop(context),
                                    padding: const EdgeInsets.all(12),
                                    child: const SanctuaryIcon(
                                      SanctuarySymbol.close,
                                      size: 22,
                                      color: Color(0xFFAECCC9),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
                            child: Text(
                              'Choose from six bundled sounds. Preview up to 8 seconds; a playing mix becomes quieter underneath. Nothing changes until you tap Use sound.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFFAAC6CA),
                                height: 1.4,
                              ),
                            ),
                          ),
                          if (widget.mixer.volume(widget.track.name) <= 0)
                            const Padding(
                              padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
                              child: Text(
                                'This layer is off. Its replacement will be selected at 30%. A paused mix stays paused.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFFAAC6CA),
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ...bundledRecordings.map(_recording),
                          if (_preview.error != null || _notice != null)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                              child: Semantics(
                                liveRegion: true,
                                child: Text(
                                  _notice ?? _preview.error!,
                                  key: const ValueKey('replacement-notice'),
                                  style: const TextStyle(
                                    color: Color(0xFFFFC9A0),
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
                    child: CupertinoButton.filled(
                      key: const ValueKey('use-replacement-sound'),
                      onPressed:
                          _selected != null &&
                              _available(_selected!) &&
                              !_applying
                          ? _use
                          : null,
                      child: const Text('Use sound'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
