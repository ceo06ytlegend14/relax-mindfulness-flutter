#!/usr/bin/env python3
"""Rebuild the small, attributed ambience pack; no paid API or opaque fallback.

Requires FFmpeg with libmp3lame. Fetches only pinned GitHub blobs using `gh`
when --download is explicitly supplied. Run from the repository root:
  python3 tool/prepare_ambient_pack.py --ffmpeg /path/to/ffmpeg --download

The manifest records the third-party audio licences, not Blanket's code licence.
Generated noises contain no samples and are offered under CC0-1.0 by this project.
"""
from __future__ import annotations

import argparse
import base64
import hashlib
import json
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / 'assets/sounds/ambient_pack.json'


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def command_for(record: dict, ffmpeg: str, source: Path | None, output: Path) -> list[str]:
    command = [ffmpeg, '-hide_banner', '-loglevel', 'error', '-y']
    if source is None:
        command += ['-f', 'lavfi', '-i',
                    f"anoisesrc=color={record['noise_color']}:sample_rate=44100:"
                    f"amplitude=0.12:duration=61:seed={record['seed']}"]
    else:
        command += ['-i', str(source)]
    # Last second overlaps the first, then rotate one second. At the boundary
    # the end of the overlap meets the next source sample, without a hard fade
    # to silence. MP3 codec/device loop seams still need a listening/device pass.
    filters = (
        '[0:a]atrim=0:61,aresample=44100,asetpts=PTS-STARTPTS,asplit=2[body][head];'
        '[head]atrim=0:1,asetpts=PTS-STARTPTS[intro];'
        '[body][intro]acrossfade=d=1:c1=tri:c2=tri,'
        'atrim=start=1,asetpts=PTS-STARTPTS,loudnorm=I=-24:TP=-6:LRA=11[out]'
    )
    command += ['-filter_complex', filters, '-map', '[out]', '-ar', '44100',
                '-ac', '1' if source is None else '2', '-c:a', 'libmp3lame',
                '-b:a', '96k', '-write_xing', '1', '-id3v2_version', '3',
                '-metadata', f"title={record['name']}",
                '-metadata', f"artist={record['creator']}",
                '-metadata', f"comment={record['license']} | {record['source_page']}",
                str(output)]
    return command


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--ffmpeg', default='ffmpeg')
    parser.add_argument('--source-dir', type=Path, default=ROOT / 'build/audio-research')
    parser.add_argument('--output-dir', type=Path, default=ROOT / 'build/rebuilt-ambient-pack')
    parser.add_argument('--download', action='store_true')
    parser.add_argument('--update-manifest', action='store_true', help='Record output hashes after a deliberate rebuild')
    args = parser.parse_args()
    replacing_assets = args.output_dir.resolve() == (ROOT / 'assets/sounds').resolve()
    if replacing_assets != args.update_manifest:
        parser.error('Replacing bundled assets requires both --output-dir assets/sounds and --update-manifest; otherwise use a scratch directory without --update-manifest')
    manifest = json.loads(MANIFEST.read_text())
    args.source_dir.mkdir(parents=True, exist_ok=True)
    args.output_dir.mkdir(parents=True, exist_ok=True)
    for record in manifest['sounds']:
        source = None
        if record['kind'] == 'field-recording':
            source = args.source_dir / record['source_file']
            if args.download:
                response = json.loads(subprocess.check_output([
                    'gh', 'api', f"repos/{manifest['mirror_repository']}/git/blobs/{record['blob_sha']}"
                ]))
                data = base64.b64decode(response['content'])
                blob = hashlib.sha1(f'blob {len(data)}\0'.encode() + data).hexdigest()
                if blob != record['blob_sha'] or sha256(data) != record['source_sha256']:
                    raise ValueError(f"Unrecognized source bytes: {record['name']}")
                source.write_bytes(data)
            if sha256(source.read_bytes()) != record['source_sha256']:
                raise ValueError(f"Source checksum mismatch: {record['name']}")
        output = args.output_dir / Path(record['asset']).name
        subprocess.run(command_for(record, args.ffmpeg, source, output), check=True)
        digest = sha256(output.read_bytes())
        if args.update_manifest:
            record['sha256'] = digest
            record['bytes'] = output.stat().st_size
        elif digest != record['sha256']:
            # Encoder builds may differ. Never silently replace a reviewed asset.
            raise ValueError(f"Output differs from the recorded encoder: {record['name']}; use a scratch output directory and review it")
        print(f"{record['name']}: {output.stat().st_size} bytes · {digest}")
    if args.update_manifest:
        MANIFEST.write_text(json.dumps(manifest, indent=2, ensure_ascii=False) + '\n')


if __name__ == '__main__':
    main()
