#!/usr/bin/env python3
"""Build named ambient arrangements from existing bundled recordings, not narration.

Default output is ignored build/. Replacing shipped files requires BOTH
--output-dir assets/sounds and --update-manifest. No downloads or new grants.
Use --verify to check input/output hashes and distinct decoded audio identity;
use --write-catalogs to regenerate the Dart/browser routing metadata.
"""
from __future__ import annotations

import argparse
import array
import hashlib
import json
import math
from pathlib import Path
import re
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / 'assets/sounds/session_soundscapes.json'
DART = ROOT / 'lib/models/session_soundscapes.dart'
PREVIEW = ROOT / 'design/preview/session-audio.js'


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def recipe_digest(session: dict, manifest: dict) -> str:
    recipe = {key: session[key] for key in ('id', 'title', 'asset', 'layers')}
    recipe['processing'] = manifest['processing']
    recipe['inputs'] = {layer['recording']: manifest['recordings'][layer['recording']]['sha256']
                        for layer in session['layers']}
    return hashlib.sha256(json.dumps(recipe, sort_keys=True, ensure_ascii=False).encode()).hexdigest()


def validate(manifest: dict, root: Path = ROOT, outputs: bool = False) -> None:
    if manifest['schema_version'] != 1 or manifest['loop_seconds'] != 30:
        raise ValueError('Unsupported session soundscape format')
    ids, titles, pairs, hashes = set(), set(), set(), set()
    for name, recording in manifest['recordings'].items():
        asset = recording['asset']
        if not re.fullmatch(r'assets/sounds/[a-z_]+\.mp3', asset) or '/session_' in asset:
            raise ValueError(f'Not an original bundled source: {name}')
        if digest(root / asset) != recording['sha256']:
            raise ValueError(f'Input hash mismatch: {name}')
        evidence = (root / recording['evidence'].split('#', 1)[0]).resolve()
        if not recording['credit'] or not evidence.is_relative_to(root.resolve()) or not evidence.is_file():
            raise ValueError(f'Missing source credit/evidence: {name}')
        if recording['rights_status'] not in {
            'legacy-provenance-unresolved', 'source-page-evidence-not-release-clearance',
        }:
            raise ValueError('Arrangement rendering cannot grant source rights')
    for session in manifest['sessions']:
        sid, title = session['id'], session['title']
        if not re.fullmatch(r'[a-z]+(?:-[a-z]+)*', sid) or sid in ids or title in titles:
            raise ValueError('Invalid or duplicate session identity')
        ids.add(sid)
        titles.add(title)
        asset = f"assets/sounds/session_{sid.replace('-', '_')}.mp3"
        if session['asset'] != asset:
            raise ValueError('Session output cannot replace a library recording')
        layers = session['layers']
        if (len(layers) != 2 or any(layer['recording'] not in manifest['recordings'] for layer in layers)
                or not all(.2 <= layer['weight'] <= .8 for layer in layers)):
            raise ValueError('Each arrangement needs two contributing, bounded layers')
        if not math.isclose(sum(layer['weight'] for layer in layers), 1):
            raise ValueError('Arrangement weights must total one')
        pair = tuple(sorted(manifest['recordings'][layer['recording']]['sha256'] for layer in layers))
        if pair[0] == pair[1] or pair in pairs:
            raise ValueError('Repeated source pair is not a new soundscape')
        pairs.add(pair)
        if outputs:
            if session['recipe_sha256'] != recipe_digest(session, manifest):
                raise ValueError('Render recipe changed: rebuild audio before publishing metadata')
            path = root / asset
            if path.stat().st_size != session['bytes'] or digest(path) != session['sha256']:
                raise ValueError(f'Output hash/size mismatch: {title}')
            if session['pcm_sha256'] in hashes:
                raise ValueError('Two arrangements decode to identical audio')
            hashes.add(session['pcm_sha256'])
    if any(alias in titles or target not in titles for alias, target in manifest['aliases'].items()):
        raise ValueError('Unknown or shadowing alias target')
    used = {layer['recording'] for session in manifest['sessions'] for layer in session['layers']}
    if used != manifest['recordings'].keys():
        raise ValueError('Source evidence must match exactly the ingredients used')


def mix_command(ffmpeg: str, session: dict, sources: list[Path], output: Path) -> list[str]:
    command = [ffmpeg, '-hide_banner', '-loglevel', 'error', '-y']
    for source in sources:
        command += ['-i', str(source)]
    a, b = (layer['weight'] for layer in session['layers'])
    filters = (
        f'[0:a]volume={a}[a];[1:a]volume={b}[b];'
        '[a][b]amix=inputs=2:normalize=0:duration=shortest,asplit=2[body][head];'
        '[head]atrim=0:1,asetpts=PTS-STARTPTS[intro];'
        '[body][intro]acrossfade=d=1:c1=tri:c2=tri,atrim=start=1,'
        'asetpts=PTS-STARTPTS,loudnorm=I=-24:TP=-6:LRA=7[out]'
    )
    return command + ['-filter_complex', filters, '-map', '[out]', '-ar', '44100',
                      '-ac', '2', '-c:a', 'libmp3lame', '-b:a', '96k',
                      '-write_xing', '1', '-id3v2_version', '3',
                      '-metadata', f"title={session['title']} — ambient arrangement",
                      '-metadata', 'artist=Sanctuary arrangement; original sources in session_soundscapes.json',
                      '-metadata', 'comment=Ambient loop, no narration; source rights remain subject to recorded review', str(output)]


def decode_mono(ffmpeg: str, path: Path) -> bytes:
    return subprocess.check_output([ffmpeg, '-nostdin', '-v', 'error', '-i', str(path),
                                    '-f', 's16le', '-ac', '1', '-ar', '8000', '-'])


def inspect_audio(ffmpeg: str, path: Path) -> dict:
    pcm = decode_mono(ffmpeg, path)
    samples = array.array('h', pcm)
    if not samples:
        raise ValueError(f'No decoded audio: {path}')
    peak = max(abs(value) for value in samples) / 32768
    rms = math.sqrt(sum(value * value for value in samples) / len(samples)) / 32768
    seconds = len(samples) / 8000
    if not 29.9 <= seconds <= 30.1 or not .001 < rms < .2 or not .01 < peak < .8:
        raise ValueError(f'Unexpected decoded duration/level: {path}: {seconds}, {rms}, {peak}')
    # Measure the final encoded file at its full stereo bandwidth, independently
    # of the render target and the low-rate PCM identity/level check above.
    result = subprocess.run([ffmpeg, '-nostdin', '-hide_banner', '-nostats', '-i', str(path),
                             '-af', 'loudnorm=I=-24:TP=-6:LRA=7:print_format=json',
                             '-f', 'null', '-'], capture_output=True, text=True, check=True)
    measurements = re.findall(r'\{\s*"input_i"[\s\S]*?\}', result.stderr)
    loudness = json.loads(measurements[-1])
    integrated, true_peak = float(loudness['input_i']), float(loudness['input_tp'])
    if not -36 <= integrated <= -18 or not -60 <= true_peak <= -3:
        raise ValueError(f'Encoded loudness/headroom outside guardrails: {path}')
    return {'pcm_sha256': hashlib.sha256(pcm).hexdigest(), 'decoded_seconds': seconds,
            'rms_8khz_mono': round(rms, 6), 'peak_8khz_mono': round(peak, 6),
            'integrated_lufs': integrated, 'true_peak_dbtp': true_peak}


def correlation(a: list | array.array, b: list | array.array) -> float:
    """Phase-aligned regression check; not a test of perceptual uniqueness."""
    n = min(len(a), len(b))
    if not n:
        raise ValueError('Empty comparison signal')
    a, b = a[:n], b[:n]
    ma, mb = sum(a) / n, sum(b) / n
    aa = sum(x * x for x in a) - n * ma * ma
    bb = sum(x * x for x in b) - n * mb * mb
    if aa <= 0 or bb <= 0:
        raise ValueError('Silent/constant comparison signal')
    return (sum(x * y for x, y in zip(a, b)) - n * ma * mb) / math.sqrt(aa * bb)


def compare_arrangements(ffmpeg: str, files: list[tuple[str, Path]]) -> dict:
    # Sampling every eighth decoded sample is deliberately just a cheap identity
    # regression. It does not establish spectrum, seam quality or human audibility.
    signals = [(title, array.array('h', decode_mono(ffmpeg, path))[::8]) for title, path in files]
    comparisons = []
    for index, (title, signal) in enumerate(signals):
        for other, previous in signals[:index]:
            comparisons.append({'titles': [other, title], 'correlation': round(abs(correlation(signal, previous)), 6)})
    maximum = max(comparisons, key=lambda item: item['correlation'])
    if maximum['correlation'] >= .97:
        raise ValueError(f'Arrangements are too similar for this regression guard: {maximum}')
    return {'method': 'absolute zero-lag correlation; 8 kHz mono PCM sampled every eighth sample',
            'pair_count': len(comparisons), 'maximum': maximum,
            'limitation': 'Not a listening test, perceptual-distance measure or seamless-loop guarantee.'}


def write_catalogs(manifest: dict) -> None:
    # Pure routing/label data: UI never infers a source from a cover or a title.
    header = '// Generated by tool/prepare_session_soundscapes.py --write-catalogs.\n'
    dart = header + '''/// Named mixes of existing library recordings, not original narrated sessions.
class SessionSoundscape {
  const SessionSoundscape(this.id, this.title, this.sources);
  final String id, title;
  final List<String> sources;
  String get assetPath =>
      'assets/sounds/session_${id.replaceAll('-', '_')}.mp3';
  String get sourceLabel => sources.join(' + ');
}

const sessionSoundscapes = <SessionSoundscape>[
'''
    preview = {}
    for session in manifest['sessions']:
        names = [layer['recording'] for layer in session['layers']]
        # JSON quoting also works for Dart; escape interpolation explicitly.
        literal = lambda value: json.dumps(value, ensure_ascii=False).replace('$', r'\$')
        dart += (f"  SessionSoundscape({literal(session['id'])}, {literal(session['title'])}, [\n"
                 + ''.join(f'    {literal(name)},\n' for name in names) + '  ]),\n')
        preview[session['title']] = {'id': session['id'], 'assetPath': session['asset'],
                                     'sources': names, 'sourceLabel': ' + '.join(names)}
    dart += '];\n\nconst _sessionAudioAliases = <String, String>{\n'
    dart += ''.join(f'  {json.dumps(key)}: {json.dumps(value)},\n' for key, value in manifest['aliases'].items())
    dart += '''};

SessionSoundscape? sessionSoundscapeForTitle(String? title) {
  final resolved = _sessionAudioAliases[title] ?? title;
  for (final soundscape in sessionSoundscapes) {
    if (soundscape.title == resolved) return soundscape;
  }
  return null;
}

String sessionSourceLabel(String? title) =>
    sessionSoundscapeForTitle(title)?.sourceLabel ?? 'Audio unavailable';
'''
    DART.write_text(dart)
    PREVIEW.write_text(header + "'use strict';\nconst SESSION_SOUNDSCAPES = "
                       + json.dumps(preview, ensure_ascii=False, indent=2)
                       + ';\nconst SESSION_AUDIO_ALIASES = ' + json.dumps(manifest['aliases'], indent=2)
                       + ''';
function sessionSoundscapeForTitle(title) {
  const resolved = Object.hasOwn(SESSION_AUDIO_ALIASES, title) ? SESSION_AUDIO_ALIASES[title] : title;
  return Object.hasOwn(SESSION_SOUNDSCAPES, resolved) ? SESSION_SOUNDSCAPES[resolved] : null;
}
function sessionSourceLabel(title) { return sessionSoundscapeForTitle(title)?.sourceLabel || 'Audio unavailable'; }
''')


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--ffmpeg', default='ffmpeg')
    parser.add_argument('--output-dir', type=Path, default=ROOT / 'build/rebuilt-session-soundscapes')
    parser.add_argument('--update-manifest', action='store_true')
    parser.add_argument('--verify', action='store_true')
    parser.add_argument('--report', type=Path, help='Ignored build/ path for a --verify measurement report')
    parser.add_argument('--write-catalogs', action='store_true')
    args = parser.parse_args()
    if args.report and not args.verify:
        parser.error('--report requires --verify')
    if args.report and not args.report.resolve().is_relative_to((ROOT / 'build').resolve()):
        parser.error('--report must stay inside ignored build/ storage')
    if args.update_manifest and (args.verify or args.write_catalogs):
        parser.error('--update-manifest is only for an explicit bundled rebuild')
    manifest = json.loads(MANIFEST.read_text())
    validate(manifest, outputs=args.verify or args.write_catalogs)
    if args.verify:
        report = {'recordings': []}
        for session in manifest['sessions']:
            metrics = inspect_audio(args.ffmpeg, ROOT / session['asset'])
            if metrics['pcm_sha256'] != session['pcm_sha256']:
                raise ValueError('Decoded audio differs from the manifest')
            report['recordings'].append({'id': session['id'], **metrics})
        report['comparison'] = compare_arrangements(args.ffmpeg, [
            (session['title'], ROOT / session['asset']) for session in manifest['sessions']
        ])
        if args.report:
            args.report.parent.mkdir(parents=True, exist_ok=True)
            args.report.write_text(json.dumps(report, indent=2) + '\n')
        print(f"{len(manifest['sessions'])} arrangements fully decoded and hash-verified; "
              f"loudness/headroom and {report['comparison']['pair_count']} pair comparisons passed.")
    elif not args.write_catalogs:
        replacing = args.output_dir.resolve() == (ROOT / 'assets/sounds').resolve()
        if replacing != args.update_manifest:
            parser.error('Bundled replacement requires --output-dir assets/sounds AND --update-manifest')
        (ROOT / 'build').mkdir(exist_ok=True)
        with tempfile.TemporaryDirectory(prefix='session-render-', dir=ROOT / 'build') as scratch:
            scratch = Path(scratch)
            normalized = {}
            for index, (name, recording) in enumerate(manifest['recordings'].items()):
                output = scratch / f'source-{index}.wav'
                subprocess.run([args.ffmpeg, '-v', 'error', '-y', '-stream_loop', '-1',
                                '-i', str(ROOT / recording['asset']), '-af',
                                'atrim=0:31,asetpts=PTS-STARTPTS,loudnorm=I=-26:TP=-8:LRA=7',
                                '-ar', '44100', '-ac', '2', '-c:a', 'pcm_s16le', str(output)], check=True)
                normalized[name] = output
            for session in manifest['sessions']:
                output = scratch / Path(session['asset']).name
                subprocess.run(mix_command(args.ffmpeg, session, [normalized[layer['recording']] for layer in session['layers']], output), check=True)
                metrics = inspect_audio(args.ffmpeg, output)
                sha, size = digest(output), output.stat().st_size
                if args.update_manifest:
                    session.update(metrics, sha256=sha, bytes=size,
                                   recipe_sha256=recipe_digest(session, manifest))
                elif sha != session['sha256']:
                    raise ValueError('Output differs from pinned renderer; no bundled files were replaced')
                print(f"{session['title']}: {size} bytes · {metrics['pcm_sha256'][:12]}", flush=True)
            compare_arrangements(args.ffmpeg, [
                (session['title'], scratch / Path(session['asset']).name) for session in manifest['sessions']
            ])
            args.output_dir.mkdir(parents=True, exist_ok=True)
            for session in manifest['sessions']:
                shutil.copyfile(scratch / Path(session['asset']).name, args.output_dir / Path(session['asset']).name)
        if args.update_manifest:
            manifest['encoder'] = subprocess.check_output([args.ffmpeg, '-version'], text=True).splitlines()[0]
            MANIFEST.write_text(json.dumps(manifest, indent=2, ensure_ascii=False) + '\n')
            write_catalogs(manifest)
    if args.write_catalogs:
        write_catalogs(manifest)


if __name__ == '__main__':
    main()
