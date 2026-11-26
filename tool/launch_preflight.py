#!/usr/bin/env python3
"""Offline, read-only release evidence gate; never grants rights or publishes.

Default exit: 1 while evidence is pending, 2 for invalid/stale inventory, 0 only
when all recorded evidence matches. --inventory-only checks coverage/drift, NOT
readiness. There is deliberately no approve, upload, signing or network command.
"""
import argparse
from collections import Counter
from datetime import date
import hashlib
import json
from pathlib import Path
import re
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
REGISTER = 'docs/release/launch-review.json'
AUDIO = {'.mp3', '.wav', '.ogg', '.m4a', '.aac', '.flac', '.opus', '.aiff'}
ART = {'.png', '.jpg', '.jpeg', '.webp', '.gif', '.svg', '.ico', '.avif', '.pdf'}
FONTS = {'.ttf', '.otf', '.woff', '.woff2'}
GATES = {
    'fresh-native-quality': 'Current-candidate Flutter analysis/tests/web, Android and iOS release compilation; no historical run substitution.',
    'android-device-matrix': 'Signed Android install/upgrade, audio/background/lock/interruption/routes/timers, backup/reminders and TalkBack matrix.',
    'ios-device-matrix': 'Signed iOS install/upgrade, audio/background/lock/interruption/routes/timers, backup/reminders and VoiceOver matrix.',
    'ten-mix-human-listening': 'Human listening to every exact curated recipe, independent loop joins and gain/fade transitions; short cafe/breeze loops included.',
    'credential-incident': 'Owner confirms historical credential revocation/rotation and usage review; no secret values in evidence.',
    'identity-signing': 'Owner confirms existing Android/iOS identities, store/customer history, signing and upgrade continuity.',
    'privacy-support': 'Owner approves actual support/privacy/terms destinations, SDK/data inventory and store disclosures.',
    'sales-remain-off': 'Verify purchases disabled in the actual candidate; restoring existing entitlements remains separate. No new checkout approval.',
    'owner-beta-decision': 'Explicit owner authorization for the exact candidate, audience, distribution method and rollback; not a public-launch authorization.',
}
SKIP_PARTS = {'.git', '.dart_tool', '.gradle', '.symlinks', 'build', 'Pods', 'ephemeral', 'xcuserdata', '__pycache__'}
CODE = {'.dart', '.kt', '.java', '.kts', '.gradle', '.xml', '.plist', '.pbxproj', '.xcconfig', '.xcscheme', '.xcworkspacedata', '.json', '.properties', '.swift', '.m', '.h', '.html', '.js', '.css', '.entitlements', '.xcprivacy', '.storyboard', '.xib', '.sh', '.jar', '.rb'}


def digest(data):
    return hashlib.sha256(data).hexdigest()


def file_at(root, name):
    """Evidence and source paths must be repository-local files, never secrets."""
    if not isinstance(name, str) or not name or '\\' in name:
        raise ValueError('Expected a nonempty repository-relative file path')
    path = Path(name)
    if path.is_absolute() or '..' in path.parts:
        raise ValueError('File path must stay inside the repository')
    if any(part.startswith('.') or part in SKIP_PARTS for part in path.parts):
        raise ValueError('Evidence/source cannot use hidden, build or cache paths')
    if path.name == 'key.properties' or path.suffix.lower() in {'.jks', '.keystore', '.p12', '.p8', '.mobileprovision'}:
        raise ValueError('Credentials must never be release evidence')
    target = root / path
    if not target.resolve().is_relative_to(root.resolve()) or not target.is_file():
        raise ValueError(f'Missing or outside-repository file: {name}')
    if any(parent.is_symlink() for parent in [target, *target.parents] if parent != root.parent):
        raise ValueError(f'Symlink not accepted as evidence/source: {name}')
    return target


def bundle_files(root):
    """Read this project's simple pubspec asset/font declarations, fail closed.

    Flutter directory entries include direct files plus resolution variants, not
    arbitrary subdirectories. New YAML forms need an explicit parser review.
    """
    text = file_at(root, 'pubspec.yaml').read_text()
    match = re.search(r'^  assets:\s*\n((?:    [^\n]*\n|\s*\n)+)', text, re.M)
    if not match:
        raise ValueError('Unsupported or missing pubspec asset declarations')
    names = []
    for line in match[1].splitlines():
        if not line.strip() or line.lstrip().startswith('#'):
            continue
        entry = re.fullmatch(r'    - ([A-Za-z0-9_./-]+)', line)
        if not entry or '..' in Path(entry[1]).parts:
            raise ValueError('Unsupported pubspec asset declaration; review parser before release')
        name = entry[1]
        path = root / name
        if name.endswith('/'):
            if not path.is_dir() or path.is_symlink():
                raise ValueError(f'Missing/unsafe bundled directory: {name}')
            names.extend(str(p.relative_to(root)) for p in path.iterdir() if p.is_file())
            for variant in path.iterdir():
                if variant.is_dir() and re.fullmatch(r'[0-9]+(?:\.[0-9]+)?x', variant.name):
                    names.extend(str(p.relative_to(root)) for p in variant.iterdir() if p.is_file())
        else:
            names.append(name)
    font_lines = re.findall(r'^\s+- asset: ([^\n]+)$', text, re.M)
    if text.count('asset:') != len(font_lines):
        raise ValueError('Unsupported font asset declaration')
    names.extend(font_lines)
    for name in names:
        file_at(root, name)
    return sorted(set(names))


def string_map(root, file, declaration):
    text = file_at(root, file).read_text()
    match = re.search(declaration + r'\s*=\s*(?:<String, String>)?\{([\s\S]*?)\n\s*\};', text)
    if not match:
        raise ValueError(f'Cannot inspect source map in {file}')
    body = '\n'.join(line for line in match[1].splitlines() if not line.lstrip().startswith('//'))
    entries = re.findall(r"'([^']+)'\s*:\s*'([^']+)'\s*,?", body)
    remainder = re.sub(r"'([^']+)'\s*:\s*'([^']+)'\s*,?", '', body).strip()
    if remainder or not entries or len(dict(entries)) != len(entries):
        raise ValueError(f'Unsupported or duplicate source mapping in {file}')
    return dict(entries)


def inventory(root=ROOT):
    paths = set(bundle_files(root))
    for folder in ['android/app/src/main/res', 'ios/Runner/Assets.xcassets', 'web']:
        directory = root / folder
        if not directory.exists():
            continue
        for path in directory.rglob('*'):
            if path.is_file() and (path.suffix.lower() in ART or (
                path.suffix == '.xml' and path.parent.name.startswith('drawable')
            )):
                paths.add(str(path.relative_to(root)))
    local = {}
    for name in sorted(paths):
        suffix = Path(name).suffix.lower()
        kind = 'audio' if suffix in AUDIO else 'font' if suffix in FONTS else 'artwork' if suffix in ART or suffix == '.xml' else None
        if kind:
            local[name] = {'path': name, 'kind': kind, 'sha256': digest(file_at(root, name).read_bytes())}
    mappings = string_map(root, 'lib/providers/app_state.dart', r'soundStreamUrls')
    bundled = string_map(root, 'lib/models/bundled_recordings.dart', r'bundledSoundAssets')
    # Once local fallback is removed, these are the effective remote bindings.
    # Include legacy names outside the 77 cards: saved links may still name them.
    streams = {name: {'name': name, 'url': url} for name, url in sorted(mappings.items()) if name not in bundled}
    return local, streams


def candidate_fingerprint(root=ROOT):
    """Runtime source/configuration bytes; docs/reviews/build outputs excluded."""
    names = set(bundle_files(root))
    names.update(['pubspec.yaml', 'pubspec.lock'])
    folders = ['lib', 'android', 'ios', 'web']
    if (root / '.git').exists():
        # Respect Git's existing ignores: local SDK paths, generated Xcode files
        # and build caches must not make the same candidate machine-dependent.
        result = subprocess.run(['git', 'ls-files', '--cached', '--others', '--exclude-standard', '-z', '--', *folders], cwd=root, capture_output=True)
        if result.returncode != 0:
            raise ValueError('Cannot enumerate release source inputs with local git')
        paths = [root / name for name in result.stdout.decode().split('\0') if name]
    else:
        # Self-contained unit fixtures do not need to initialize another repo.
        paths = [path for folder in folders for path in (root / folder).rglob('*')]
    for path in paths:
        relative = path.relative_to(root)
        if any(part.startswith('.') or part in SKIP_PARTS for part in relative.parts):
            continue
        if path.name == 'key.properties' or not path.is_file():
            continue
        if path.suffix.lower() in CODE | AUDIO | ART | FONTS or path.name in {'Podfile', 'Podfile.lock', 'gradlew'}:
            names.add(str(relative))
    rows = [{'path': name, 'sha256': digest(file_at(root, name).read_bytes())} for name in sorted(names)]
    return digest(json.dumps(rows, sort_keys=True, separators=(',', ':')).encode())


def load_register(root=ROOT):
    def unique(pairs):
        result = {}
        for key, value in pairs:
            if key in result:
                raise ValueError('Duplicate JSON object key in release evidence')
            result[key] = value
        return result
    return json.loads(file_at(root, REGISTER).read_text(), object_pairs_hook=unique,
                      parse_constant=lambda _: (_ for _ in ()).throw(ValueError('Non-finite JSON value')))


def indexed(rows, key, label):
    if not isinstance(rows, list) or any(not isinstance(row, dict) or not isinstance(row.get(key), str) for row in rows):
        raise ValueError(f'Invalid {label} evidence list')
    result = {row[key]: row for row in rows}
    if len(result) != len(rows):
        raise ValueError(f'Duplicate {label} evidence entry')
    return result


def review_reason(root, review, subject, passed_status):
    if not isinstance(review, dict) or review.get('status') not in {'pending', passed_status}:
        raise ValueError('Unknown/malformed review status; only pending or explicit evidence is accepted')
    if review['status'] == 'pending':
        return 'Owner/tester evidence pending'
    if review.get('subject_sha256') != subject:
        return 'Evidence is stale or not bound to this exact subject/candidate'
    if not isinstance(review.get('reviewed_by'), str) or not review['reviewed_by'].strip():
        return 'A named human reviewer is required'
    try:
        date.fromisoformat(review.get('reviewed_on', ''))
    except (TypeError, ValueError):
        return 'An ISO review date is required'
    try:
        evidence = file_at(root, review.get('evidence_path'))
    except ValueError:
        return 'Missing safe repository-local evidence file'
    if not evidence.stat().st_size or review.get('evidence_sha256') != digest(evidence.read_bytes()):
        return 'Evidence file is empty, changed or missing its checksum'
    return None


def immutable_stream(url):
    # Current project streams are GitHub/raw/CDN or mutable Google sample URLs.
    # A duration inspection is not content enforcement. For another transport,
    # review this rule alongside the app before permitting an approval.
    return bool(re.fullmatch(r'https://(?:raw\.githubusercontent\.com/[^/]+/[^/]+/|cdn\.jsdelivr\.net/gh/[^/]+/[^/@]+@)[a-f0-9]{40}/[^\s?#]+', url))


def assess(root=ROOT, register=None):
    register = load_register(root) if register is None else register
    if not isinstance(register, dict) or register.get('schema_version') != 1:
        raise ValueError('Unsupported launch evidence schema')
    local, streams = inventory(root)
    recorded = indexed(register.get('local_assets'), 'path', 'local asset')
    remote = indexed(register.get('stream_bindings'), 'name', 'stream binding')
    gates = indexed(register.get('gates'), 'id', 'required gate')
    for label, actual, expected in [('local asset', recorded, local), ('stream binding', remote, streams), ('required gate', gates, GATES)]:
        if set(actual) != set(expected):
            raise ValueError(f'{label} inventory drift: missing={sorted(set(expected) - set(actual))}, extra={sorted(set(actual) - set(expected))}')
    candidate = candidate_fingerprint(root)
    blockers = []
    for name, expected in local.items():
        row = recorded[name]
        if any(row.get(key) != value for key, value in expected.items()):
            raise ValueError(f'Local asset checksum/kind drift: {name}')
        for evidence in row.get('provenance', []):
            file_at(root, evidence)
        reason = review_reason(root, row.get('review'), expected['sha256'], 'approved')
        if reason:
            blockers.append({'type': 'asset', 'subject': name, 'reason': reason})
    for name, expected in streams.items():
        row = remote[name]
        if row.get('url') != expected['url']:
            raise ValueError(f'Configured stream URL drift: {name}')
        reason = review_reason(root, row.get('review'), digest(json.dumps(expected, sort_keys=True).encode()), 'approved')
        if not immutable_stream(expected['url']):
            reason = 'Unpinned network content; pin/clear or remove the binding with owner approval before distribution'
        if reason:
            blockers.append({'type': 'stream', 'subject': name, 'reason': reason})
    for name in GATES:
        reason = review_reason(root, gates[name].get('review'), candidate, 'passed')
        if reason:
            blockers.append({'type': 'gate', 'subject': name, 'reason': reason})
    return {
        'status': 'BLOCKED' if blockers else 'EVIDENCE_RECORDED_FOR_OWNER_REVIEW',
        'inventory_matches': True,
        'candidate_sha256': candidate,
        'counts': {**dict(Counter(row['kind'] for row in local.values())), 'stream_bindings': len(streams), 'required_gates': len(GATES)},
        'blockers': blockers,
        'boundary': 'Offline evidence accounting only: not legal clearance, device execution, release permission, sales enablement or publication.',
    }


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root', type=Path, default=ROOT)
    parser.add_argument('--inventory-only', action='store_true', help='Check coverage/drift only; pending release evidence remains BLOCKED')
    parser.add_argument('--json-output', type=Path, help='Optional report file under ignored build/, never a source/evidence file')
    args = parser.parse_args(argv)
    output = None
    try:
        root = args.root.resolve()
        if args.json_output:
            requested = root / args.json_output
            if (not requested.resolve().is_relative_to(root / 'build')
                    or not requested.resolve().is_relative_to(root)
                    or requested.suffix != '.json'):
                raise ValueError('Report must be an ignored build/*.json file, never a source/evidence file')
            output = requested
        report = assess(root)
        if output:
            output.parent.mkdir(parents=True, exist_ok=True)
            output.write_text(json.dumps(report, indent=2) + '\n')
        print(f"Launch preflight: {report['status']}")
        print(f"Inventory matches: {json.dumps(report['counts'], sort_keys=True)}")
        print(f"Candidate runtime fingerprint: {report['candidate_sha256']}")
        counts = Counter(row['type'] for row in report['blockers'])
        print(f"Open evidence: {counts['asset']} local rights reviews, {counts['stream']} stream reviews/pins, {counts['gate']} release gates")
        for blocker in report['blockers']:
            if blocker['type'] == 'gate':
                print(f"  PENDING {blocker['subject']}: {GATES[blocker['subject']]}")
        print(report['boundary'])
        if args.inventory_only:
            print('Inventory-only success is NOT a launch-readiness pass.')
        return 0 if args.inventory_only or not report['blockers'] else 1
    except (ValueError, OSError, KeyError, TypeError) as error:
        print(f'Launch preflight INVALID/BLOCKED: {error}', file=sys.stderr)
        # Never leave a stale successful JSON report after a failed new check.
        if output:
            try:
                output.parent.mkdir(parents=True, exist_ok=True)
                output.write_text(json.dumps({'status': 'INVALID_BLOCKED', 'inventory_matches': False, 'error': str(error)}, indent=2) + '\n')
            except OSError:
                print('Could not write the failed-check report; the preflight still fails.', file=sys.stderr)
        return 2


if __name__ == '__main__':
    sys.exit(main())
