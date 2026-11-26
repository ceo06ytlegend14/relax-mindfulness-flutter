#!/usr/bin/env python3
"""Check the twelve new assets, per-file provenance and (optionally) decoding.

  python3 tool/verify_ambient_pack.py
  python3 tool/verify_ambient_pack.py --ffmpeg /path/to/ffmpeg --report build/audio-qc.json

This verifies technical properties, not subjective listening quality, legal
indemnity, real-device playback, or the licences of the older app audio.
"""
from __future__ import annotations

import argparse
from array import array
import hashlib
import json
import math
from pathlib import Path
import re
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]


def verify(root: Path = ROOT, ffmpeg: str | None = None) -> list[dict]:
    manifest = json.loads((root / 'assets/sounds/ambient_pack.json').read_text())
    sounds = manifest['sounds']
    if len(sounds) != 12 or len({sound['name'] for sound in sounds}) != 12:
        raise ValueError('Expected twelve individually named additions')
    if len({sound['asset'] for sound in sounds}) != 12:
        raise ValueError('Aliases cannot be counted as distinct assets')
    if len({sound['sha256'] for sound in sounds}) != 12:
        raise ValueError('Duplicate audio is not a new source')
    kinds = [sound['kind'] for sound in sounds]
    if kinds.count('field-recording') != 7 or kinds.count('generated-noise') != 5:
        raise ValueError('Expected seven recordings and five generated noises')
    recordings = [sound for sound in sounds if sound['kind'] == 'field-recording']
    for field in ('source_sha256', 'blob_sha', 'source_page'):
        if len({sound[field] for sound in recordings}) != 7:
            raise ValueError('Re-encoding one recording does not create distinct sources')
    if not re.fullmatch(r'[0-9a-f]{40}', manifest['mirror_commit']):
        raise ValueError('Source repository must be pinned')
    if not (root / manifest['evidence']).is_file():
        raise ValueError('Missing original-page licence evidence')
    reports = []
    for sound in sounds:
        path = root / sound['asset']
        if path.parent != root / 'assets/sounds' or path.suffix != '.mp3':
            raise ValueError('Unexpected output location')
        data = path.read_bytes()
        if len(data) != sound['bytes'] or hashlib.sha256(data).hexdigest() != sound['sha256']:
            raise ValueError(f"Asset checksum/size mismatch: {sound['name']}")
        if sound['license'] not in {'CC0-1.0', 'LicenseRef-Public-Domain-SoundBible'}:
            raise ValueError('Recording requires a separate licence review')
        if not sound['creator'] or not sound['source_page']:
            raise ValueError('Missing recording-specific attribution')
        if sound['kind'] == 'field-recording':
            if not re.fullmatch(r'[0-9a-f]{40}', sound['blob_sha']):
                raise ValueError('Missing original source identity')
            if not re.fullmatch(r'[0-9a-f]{64}', sound['source_sha256']):
                raise ValueError('Missing original source checksum')
            if not sound['source_page'].startswith(('https://freesound.org/people/', 'https://soundbible.com/')):
                raise ValueError('Unrecognized original recording page')
        report = {'name': sound['name'], 'bytes': len(data), 'sha256': sound['sha256']}
        if ffmpeg:
            # Decode the entire file, not just a header or a short preview.
            decoded = subprocess.check_output([
                ffmpeg, '-v', 'error', '-xerror', '-i', str(path), '-f', 'f32le',
                '-acodec', 'pcm_f32le', '-ac', '1', '-ar', '22050', '-'
            ])
            samples = array('f')
            samples.frombytes(decoded)
            if sys.byteorder != 'little':
                samples.byteswap()
            seconds = len(samples) / 22050
            if not 8 <= seconds <= 60.2:
                raise ValueError(f"Unexpected duration: {sound['name']}: {seconds}")
            if not all(math.isfinite(value) for value in samples):
                raise ValueError('Non-finite audio samples')
            peak = max(map(abs, samples))
            rms = math.sqrt(sum(value * value for value in samples) / len(samples))
            if not 0.001 < rms < 0.25 or peak > 0.9:
                raise ValueError(f"Silence or excessive level: {sound['name']}: rms={rms}, peak={peak}")
            report.update(seconds=round(seconds, 3), rms_dbfs=round(20 * math.log10(rms), 2), peak_dbfs=round(20 * math.log10(peak), 2))
        reports.append(report)
    return reports


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--ffmpeg')
    parser.add_argument('--report', type=Path)
    args = parser.parse_args()
    reports = verify(ffmpeg=args.ffmpeg)
    if args.report:
        args.report.parent.mkdir(parents=True, exist_ok=True)
        args.report.write_text(json.dumps(reports, indent=2) + '\n')
    print(json.dumps(reports, indent=2))
    print('Verified twelve distinct additions; legacy audio is outside this check.')


if __name__ == '__main__':
    main()
