#!/usr/bin/env python3
"""Prepare loop joins for six existing development recordings, without downloads.

Original inputs remain untouched. These edits are NOT new recordings or rights
clearance. Requires FFmpeg with libmp3lame to render or inspect audio. Examples:
  python3 tool/prepare_placeholder_loops.py --verify
  python3 tool/prepare_placeholder_loops.py --ffmpeg /path/to/ffmpeg
  python3 tool/prepare_placeholder_loops.py --ffmpeg /path/to/ffmpeg \
      --output-dir assets/sounds --update-manifest

Scratch output defaults to ignored build/. --verify without --ffmpeg checks only
hashes, provenance status and routing metadata, not decoded audio or listening.
"""
from __future__ import annotations

import argparse
from array import array
import copy
import hashlib
import json
import math
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / 'assets/sounds/placeholder_loops.json'
SOURCES = {
    'Soft Rain': 'soft_rain',
    'Ocean Waves': 'ocean_waves',
    'Forest Birds': 'forest_birds',
    'Campfire': 'campfire',
    'Bamboo Chimes': 'wind_chimes',
    'Temple Bowl': 'tibetan_bowls',
}
RIGHTS_STATUS = 'legacy-provenance-unresolved'
SAMPLE_RATE = 44100


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def recipe_digest(record: dict, manifest: dict) -> str:
    fields = ('name', 'source_asset', 'source_sha256', 'asset', 'overlap_seconds')
    recipe = {key: record[key] for key in fields}
    recipe['processing'] = manifest['processing']
    return hashlib.sha256(json.dumps(recipe, sort_keys=True).encode()).hexdigest()


def validate(manifest: dict, root: Path = ROOT, outputs: bool = False) -> None:
    if (manifest['schema_version'] != 1 or manifest['additional_recordings'] != 0
            or manifest['rights_status'] != RIGHTS_STATUS):
        raise ValueError('Loop editing cannot add recordings or grant source rights')
    evidence = root / manifest['evidence']
    if not evidence.resolve().is_relative_to(root.resolve()) or not evidence.is_file():
        raise ValueError('Missing development-audio evidence')
    records = manifest['loops']
    if len(records) != len(SOURCES) or {row['name'] for row in records} != SOURCES.keys():
        raise ValueError('Expected the six existing legacy sources, not aliases or new takes')
    for row in records:
        stem = SOURCES[row['name']]
        if row['source_asset'] != f'assets/sounds/{stem}.mp3':
            raise ValueError('Unexpected original source path')
        if row['asset'] != f'assets/sounds/loop_{stem}.mp3':
            raise ValueError('Loop output must be separate from its original source')
        if (row['rights_status'] != RIGHTS_STATUS
                or not re.fullmatch(r'[a-f0-9]{64}', row['source_sha256'])):
            raise ValueError('A derivative cannot clear unresolved source rights')
        if (not isinstance(row['overlap_seconds'], (int, float))
                or isinstance(row['overlap_seconds'], bool)
                or not 2 <= row['overlap_seconds'] <= 6):
            raise ValueError('Expected a bounded 2–6 second overlap')
        if digest(root / row['source_asset']) != row['source_sha256']:
            raise ValueError(f"Original input hash mismatch: {row['name']}")
        if outputs:
            path = root / row['asset']
            if (path.stat().st_size != row['bytes'] or digest(path) != row['sha256']):
                raise ValueError(f"Loop output hash/size mismatch: {row['name']}")
            if row['recipe_sha256'] != recipe_digest(row, manifest):
                raise ValueError('Loop recipe changed: rebuild before changing routing')
            if (not math.isfinite(row['loop_seconds']) or row['loop_seconds'] <= 0
                    or not math.isclose(row['input_seconds'] - row['overlap_seconds'],
                                        row['loop_seconds'], abs_tol=.05)):
                raise ValueError('Loop duration must reflect the actual overlap, not an extension')


def overlap_command(ffmpeg: str, source: Path, output: Path, seconds: float) -> list[str]:
    # Overlap the tail with the head using equal-power curves, then rotate past
    # the consumed head. The wrap now meets adjacent original samples instead of
    # jumping from an unrelated ending to an intro. There is NO fade to silence.
    # Independent decoder inputs are intentional: FFmpeg 7's asplit + short
    # atrim branch can end the shared stream early and emit an empty edit.
    filters = (
        '[0:a]aresample=44100,asetpts=PTS-STARTPTS[body];'
        f'[1:a]aresample=44100,atrim=duration={seconds},asetpts=PTS-STARTPTS[intro];'
        f'[body][intro]acrossfade=d={seconds}:c1=qsin:c2=qsin,'
        f'atrim=start={seconds},asetpts=PTS-STARTPTS[out]'
    )
    return [ffmpeg, '-nostdin', '-v', 'error', '-y', '-i', str(source), '-i', str(source),
            '-filter_complex', filters, '-map', '[out]', '-ar', str(SAMPLE_RATE),
            '-ac', '2', '-c:a', 'pcm_f32le', str(output)]


def levels(ffmpeg: str, path: Path) -> dict:
    # Measurement only: loudnorm's filtered output is discarded. Never apply a
    # time-varying normalizer after preparing a join: it can unmatch its ends.
    result = subprocess.run([
        ffmpeg, '-nostdin', '-hide_banner', '-nostats', '-i', str(path),
        '-af', 'loudnorm=I=-24:TP=-6:LRA=11:print_format=json', '-f', 'null', '-',
    ], capture_output=True, text=True, check=True)
    matches = re.findall(r'\{\s*"input_i"[\s\S]*?\}', result.stderr)
    if not matches:
        raise ValueError('FFmpeg did not return a loudness measurement')
    measured = json.loads(matches[-1])
    values = {name: float(measured[field]) for name, field in [
        ('integrated_lufs', 'input_i'), ('true_peak_dbtp', 'input_tp'),
    ]}
    if not all(math.isfinite(value) for value in values.values()):
        raise ValueError('Silent or non-finite source audio')
    return values


def inspect_audio(ffmpeg: str, path: Path) -> dict:
    decoded = subprocess.check_output([
        ffmpeg, '-nostdin', '-v', 'error', '-xerror', '-i', str(path),
        '-f', 'f32le', '-acodec', 'pcm_f32le', '-ac', '2', '-ar', str(SAMPLE_RATE), '-',
    ])
    samples = array('f')
    samples.frombytes(decoded)
    if sys.byteorder != 'little':
        samples.byteswap()
    if len(samples) < SAMPLE_RATE * 4 or len(samples) % 2:
        raise ValueError('Empty, short or incomplete stereo recording')
    if not all(math.isfinite(value) for value in samples):
        raise ValueError('Non-finite decoded samples')
    peak = max(map(abs, samples))
    rms = math.sqrt(sum(value * value for value in samples) / len(samples))
    if not .0001 < rms < .5 or peak >= 1:
        raise ValueError('Silent or clipped decoded audio')
    channels = []
    for channel in range(2):
        data = samples[channel::2]
        steps = math.sqrt(sum((data[i] - data[i - 1]) ** 2
                              for i in range(1, len(data))) / (len(data) - 1))
        jump = abs(data[0] - data[-1])
        channels.append({'boundary_jump': round(jump, 8),
                         'jump_over_rms_step': round(jump / steps, 5) if steps else 0})
    return {'seconds': round(len(samples) / (2 * SAMPLE_RATE), 6),
            'sample_peak_dbfs': round(20 * math.log10(peak), 3),
            'rms_dbfs': round(20 * math.log10(rms), 3),
            'channels': channels, **levels(ffmpeg, path)}


def encode_command(ffmpeg: str, source: Path, output: Path, row: dict,
                   gain_db: float) -> list[str]:
    # A single constant attenuation preserves the edited join. Headroom absorbs
    # equal-power overlap/codec overshoot; saved mixer percentages are untouched.
    return [ffmpeg, '-nostdin', '-v', 'error', '-y', '-i', str(source),
            '-af', f'volume={gain_db:.6f}dB', '-ar', str(SAMPLE_RATE), '-ac', '2',
            '-c:a', 'libmp3lame', '-b:a', '128k', '-write_xing', '1',
            '-id3v2_version', '3', '-metadata', f"title={row['name']} — development loop edit",
            '-metadata', 'comment=Existing legacy recording; rights unresolved; NOT a new take or release clearance',
            str(output)]


def render(manifest: dict, ffmpeg: str, output_dir: Path, root: Path = ROOT) -> dict:
    """Stage and check every render before copying any output. No input writes."""
    validate(manifest, root)
    result = copy.deepcopy(manifest)
    result['encoder'] = subprocess.check_output([ffmpeg, '-version'], text=True).splitlines()[0]
    (root / 'build').mkdir(exist_ok=True)
    with tempfile.TemporaryDirectory(prefix='placeholder-loops-', dir=root / 'build') as directory:
        scratch = Path(directory)
        for index, row in enumerate(result['loops']):
            source = root / row['source_asset']
            original = inspect_audio(ffmpeg, source)
            if original['seconds'] < 3 * row['overlap_seconds']:
                raise ValueError('Overlap would consume too much of the source')
            wave = scratch / f'edit-{index}.wav'
            subprocess.run(overlap_command(ffmpeg, source, wave, row['overlap_seconds']), check=True)
            gain_db = min(0.0, -6.0 - levels(ffmpeg, wave)['true_peak_dbtp'])
            output = scratch / Path(row['asset']).name
            for attempt in range(3):
                subprocess.run(encode_command(ffmpeg, wave, output, row, gain_db), check=True)
                measured = inspect_audio(ffmpeg, output)
                if measured['true_peak_dbtp'] <= -5.5:
                    break
                gain_db -= measured['true_peak_dbtp'] + 6.0
            else:
                raise ValueError('Encoded headroom check failed')
            expected = original['seconds'] - row['overlap_seconds']
            if not math.isclose(measured['seconds'], expected, abs_tol=.05):
                raise ValueError('Rendered loop has an unexpected decoded duration')
            row.update(input_seconds=original['seconds'], loop_seconds=measured.pop('seconds'),
                       gain_db=round(gain_db, 6), sha256=digest(output), bytes=output.stat().st_size,
                       recipe_sha256=recipe_digest(row, result), measurements=measured)
            print(f"{row['name']}: {row['input_seconds']}s → {row['loop_seconds']}s; "
                  f"{row['overlap_seconds']}s overlap; {row['gain_db']} dB static gain", flush=True)
        output_dir.mkdir(parents=True, exist_ok=True)
        for row in result['loops']:
            shutil.copyfile(scratch / Path(row['asset']).name, output_dir / Path(row['asset']).name)
    return result


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--ffmpeg', help='FFmpeg executable; required to render or fully inspect')
    parser.add_argument('--output-dir', type=Path, default=ROOT / 'build/rebuilt-placeholder-loops')
    parser.add_argument('--update-manifest', action='store_true')
    parser.add_argument('--verify', action='store_true')
    parser.add_argument('--report', type=Path, help='Optional ignored build/*.json technical report')
    args = parser.parse_args()
    bundled = args.output_dir.resolve() == (ROOT / 'assets/sounds').resolve()
    if args.update_manifest and args.verify:
        parser.error('--verify cannot update a manifest')
    if not args.verify and bundled != args.update_manifest:
        parser.error('Bundled outputs require both --output-dir assets/sounds and --update-manifest')
    if not args.verify and not args.ffmpeg:
        parser.error('--ffmpeg is required to render')
    if args.report and (args.report.suffix != '.json' or not args.report.resolve().is_relative_to((ROOT / 'build').resolve())):
        parser.error('--report must be an ignored build/*.json file')
    manifest = json.loads(MANIFEST.read_text())
    if args.verify:
        validate(manifest, outputs=True)
        report = {'scope': 'Development derivatives only; not new takes, rights clearance or human/device listening.', 'loops': []}
        if args.ffmpeg:
            for row in manifest['loops']:
                measured = inspect_audio(args.ffmpeg, ROOT / row['asset'])
                if not math.isclose(measured['seconds'], row['loop_seconds'], abs_tol=.05) or measured['true_peak_dbtp'] > -5.5:
                    raise ValueError('Decoded duration/headroom drift')
                report['loops'].append({'name': row['name'], **measured})
        print('Six loop edits verified; six original inputs unchanged; zero additional recordings.')
    else:
        result = render(manifest, args.ffmpeg, args.output_dir)
        if args.update_manifest:
            MANIFEST.write_text(json.dumps(result, indent=2, ensure_ascii=False) + '\n')
        report = result
    if args.report:
        args.report.parent.mkdir(parents=True, exist_ok=True)
        args.report.write_text(json.dumps(report, indent=2, ensure_ascii=False) + '\n')


if __name__ == '__main__':
    main()
