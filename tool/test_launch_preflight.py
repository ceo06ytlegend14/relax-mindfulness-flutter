"""Offline fixtures only; no fabricated approval is ever written to real evidence."""
import copy
import json
from pathlib import Path
import subprocess
import sys
import tempfile
from types import SimpleNamespace
import unittest
from unittest.mock import patch

from launch_preflight import (
    GATES, REGISTER, ROOT, assess, bundle_files, candidate_fingerprint, digest,
    file_at, immutable_stream, inventory, load_register,
)


class LaunchPreflightTest(unittest.TestCase):
    def setUp(self):
        temp = tempfile.TemporaryDirectory()
        self.addCleanup(temp.cleanup)
        self.root = Path(temp.name).resolve()
        self.write('pubspec.yaml', '''name: evidence_fixture
flutter:
  assets:
    - assets/sounds/
    - assets/images/
  fonts:
    - family: Fixture
      fonts:
        - asset: assets/fonts/fixture.ttf
''')
        self.write('pubspec.lock', 'fixture lockfile')
        self.write('assets/sounds/local.mp3', 'fixture recording bytes, NOT real audio')
        self.write('assets/sounds/calm_guided.mp3', 'unreferenced bytes still shipped by directory')
        self.write('assets/images/cover.png', 'fixture artwork, NOT a real picture')
        self.write('assets/fonts/fixture.ttf', 'fixture font bytes')
        self.write('android/app/src/main/res/drawable/launch_background.xml', '<layer-list/>')
        self.write('ios/Runner/Assets.xcassets/Icon.appiconset/icon.png', 'fixture native icon')
        self.write('web/icons/icon.png', 'fixture web icon')
        self.write('lib/providers/app_state.dart', '''class AppState {
  static const soundStreamUrls = {
    'Local': 'https://raw.githubusercontent.com/example/project/main/local.mp3',
    'Remote': 'https://raw.githubusercontent.com/example/project/1111111111111111111111111111111111111111/remote.mp3',
  };
}
''')
        self.write('lib/models/bundled_recordings.dart', '''const bundledSoundAssets = <String, String>{
  'Local': 'assets/sounds/local.mp3',
};
''')
        self.write('docs/release/fixture-evidence.md', 'Fixture evidence, not an actual approval.')
        local, streams = inventory(self.root)
        self.register = {
            'schema_version': 1,
            'local_assets': [{**row, 'review': {'status': 'pending'}} for row in local.values()],
            'stream_bindings': [{**row, 'review': {'status': 'pending'}} for row in streams.values()],
            'gates': [{'id': name, 'review': {'status': 'pending'}} for name in GATES],
        }
        self.save()

    def write(self, name, text):
        path = self.root / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text)
        return path

    def save(self):
        self.write(REGISTER, json.dumps(self.register))

    def approve(self):
        def proof(status, subject):
            return {
                'status': status,
                'subject_sha256': subject,
                'reviewed_by': 'Fixture tester, not an actual release reviewer',
                'reviewed_on': '2026-11-19',
                'evidence_path': 'docs/release/fixture-evidence.md',
                'evidence_sha256': digest((self.root / 'docs/release/fixture-evidence.md').read_bytes()),
            }
        for row in self.register['local_assets']:
            row['review'] = proof('approved', row['sha256'])
        for row in self.register['stream_bindings']:
            row['review'] = proof('approved', digest(json.dumps({'name': row['name'], 'url': row['url']}, sort_keys=True).encode()))
        for row in self.register['gates']:
            row['review'] = proof('passed', candidate_fingerprint(self.root))
        self.save()

    def cli(self, *args):
        return subprocess.run([sys.executable, str(ROOT / 'tool/launch_preflight.py'), '--root', str(self.root), *args], capture_output=True, text=True)

    def test_real_inventory_matches_and_pending_reviews_are_not_clearance(self):
        report = assess()
        register = load_register()
        self.assertEqual(report['counts'], {'audio': 42, 'artwork': 68, 'font': 2, 'stream_bindings': 75, 'required_gates': 9})
        self.assertTrue(report['inventory_matches'])
        self.assertEqual(report['status'], 'BLOCKED' if report['blockers'] else 'EVIDENCE_RECORDED_FOR_OWNER_REVIEW')
        # Legitimate owner evidence may progress later without rewriting tests;
        # the gate must still account for every review that remains pending.
        for key, kind, subject_key in [('local_assets', 'asset', 'path'), ('stream_bindings', 'stream', 'name'), ('gates', 'gate', 'id')]:
            pending = {row[subject_key] for row in register[key] if row['review']['status'] == 'pending'}
            blocked = {row['subject'] for row in report['blockers'] if row['type'] == kind}
            self.assertLessEqual(pending, blocked)

    def test_pending_evidence_is_a_nonzero_default_result_and_does_not_edit_register(self):
        before = (self.root / REGISTER).read_bytes()
        result = self.cli('--json-output', 'build/launch-preflight.json')
        self.assertEqual(result.returncode, 1, result.stderr)
        self.assertIn('BLOCKED', result.stdout)
        self.assertEqual((self.root / REGISTER).read_bytes(), before)
        self.assertEqual(json.loads((self.root / 'build/launch-preflight.json').read_text())['status'], 'BLOCKED')

    def test_failed_new_check_replaces_stale_successful_json_report(self):
        self.approve()
        self.assertEqual(self.cli('--json-output', 'build/report.json').returncode, 0)
        self.write('assets/sounds/unreviewed.mp3', 'new fixture bytes')
        result = self.cli('--json-output', 'build/report.json')
        self.assertEqual(result.returncode, 2)
        report = json.loads((self.root / 'build/report.json').read_text())
        self.assertEqual(report['status'], 'INVALID_BLOCKED')
        self.assertFalse(report['inventory_matches'])

    def test_inventory_only_success_never_claims_release_approval(self):
        result = self.cli('--inventory-only')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('BLOCKED', result.stdout)
        self.assertIn('NOT a launch-readiness pass', result.stdout)

    def test_complete_fixture_evidence_is_only_recorded_for_owner_review(self):
        self.approve()
        report = assess(self.root)
        self.assertEqual(report['blockers'], [])
        self.assertEqual(report['status'], 'EVIDENCE_RECORDED_FOR_OWNER_REVIEW')
        self.assertIn('not legal clearance', report['boundary'])

    def test_asset_checksum_changes_invalidate_inventory(self):
        self.approve()
        self.write('assets/sounds/local.mp3', 'different recording')
        with self.assertRaisesRegex(ValueError, 'checksum/kind drift'):
            assess(self.root)

    def test_new_unlisted_bundled_media_fails(self):
        self.write('assets/sounds/unreviewed.mp3', 'new fixture bytes')
        with self.assertRaisesRegex(ValueError, 'local asset inventory drift'):
            assess(self.root)

    def test_unreferenced_audio_in_declared_directory_is_still_counted(self):
        self.assertIn('assets/sounds/calm_guided.mp3', inventory(self.root)[0])
        self.register['local_assets'] = [row for row in self.register['local_assets'] if not row['path'].endswith('calm_guided.mp3')]
        self.save()
        with self.assertRaisesRegex(ValueError, 'calm_guided.mp3'):
            assess(self.root)

    def test_native_and_web_artwork_are_not_hidden_by_flutter_only_inventory(self):
        paths = inventory(self.root)[0]
        self.assertIn('web/icons/icon.png', paths)
        self.assertIn('ios/Runner/Assets.xcassets/Icon.appiconset/icon.png', paths)
        self.assertIn('android/app/src/main/res/drawable/launch_background.xml', paths)
        self.write('android/app/src/main/res/mipmap-mdpi/ic_launcher.png', 'new fixture icon')
        with self.assertRaisesRegex(ValueError, 'local asset inventory drift'):
            assess(self.root)

    def test_directory_declarations_are_not_falsely_treated_as_recursive(self):
        self.write('assets/images/not-declared/cover.png', 'not bundled by parent directory')
        self.write('assets/images/2.0x/cover.png', 'resolution variant is bundled')
        paths = inventory(self.root)[0]
        self.assertNotIn('assets/images/not-declared/cover.png', paths)
        self.assertIn('assets/images/2.0x/cover.png', paths)

    def test_unsupported_pubspec_yaml_requires_parser_review(self):
        self.write('pubspec.yaml', 'flutter:\n  assets:\n    - path: assets/sounds/\n      flavors: [beta]\n')
        with self.assertRaisesRegex(ValueError, 'Unsupported pubspec asset declaration'):
            bundle_files(self.root)

    def test_deleting_bundled_source_cannot_preserve_old_approval(self):
        (self.root / 'assets/sounds/local.mp3').unlink()
        with self.assertRaisesRegex(ValueError, 'local asset inventory drift'):
            assess(self.root)

    def test_duplicate_inventory_entry_fails(self):
        self.register['local_assets'].append(copy.deepcopy(self.register['local_assets'][0]))
        self.save()
        with self.assertRaisesRegex(ValueError, 'Duplicate local asset'):
            assess(self.root)

    def test_missing_required_gate_cannot_be_omitted_to_make_green(self):
        self.approve()
        self.register['gates'].pop()
        self.save()
        with self.assertRaisesRegex(ValueError, 'required gate inventory drift'):
            assess(self.root)

    def test_changed_source_invalidates_prior_native_and_device_evidence(self):
        self.approve()
        path = self.root / 'lib/providers/app_state.dart'
        path.write_text(path.read_text() + '\n// changed runtime source\n')
        report = assess(self.root)
        self.assertEqual({row['subject'] for row in report['blockers']}, set(GATES))
        self.assertTrue(all('stale' in row['reason'] for row in report['blockers']))

    def test_historical_candidate_hash_is_not_current_evidence(self):
        self.approve()
        self.register['gates'][0]['review']['subject_sha256'] = '0' * 64
        self.save()
        self.assertEqual(len(assess(self.root)['blockers']), 1)

    def test_changed_or_empty_evidence_receipt_invalidates_approval(self):
        self.approve()
        self.write('docs/release/fixture-evidence.md', '')
        self.assertTrue(all('empty, changed' in row['reason'] for row in assess(self.root)['blockers']))

    def test_missing_human_reviewer_is_not_an_approval(self):
        self.approve()
        self.register['local_assets'][0]['review']['reviewed_by'] = ''
        self.save()
        self.assertIn('named human', assess(self.root)['blockers'][0]['reason'])

    def test_invalid_date_does_not_count_as_review(self):
        self.approve()
        self.register['gates'][0]['review']['reviewed_on'] = 'not tested yet'
        self.save()
        self.assertIn('ISO review date', assess(self.root)['blockers'][0]['reason'])

    def test_moving_stream_is_blocked_even_with_an_approval_record(self):
        self.approve()
        path = self.root / 'lib/providers/app_state.dart'
        text = path.read_text().replace('1111111111111111111111111111111111111111', 'main')
        path.write_text(text)
        self.register['stream_bindings'][0]['url'] = self.register['stream_bindings'][0]['url'].replace('1111111111111111111111111111111111111111', 'main')
        self.save()
        report = assess(self.root)
        self.assertTrue(any(row['type'] == 'stream' and 'Unpinned network content' in row['reason'] for row in report['blockers']))
        self.assertFalse(immutable_stream('https://actions.google.com/sounds/v1/weather/rain_on_roof.ogg'))

    def test_changed_stream_url_invalidates_inventory(self):
        path = self.root / 'lib/providers/app_state.dart'
        path.write_text(path.read_text().replace('/remote.mp3', '/changed.mp3'))
        with self.assertRaisesRegex(ValueError, 'Configured stream URL drift'):
            assess(self.root)

    def test_local_network_fallback_is_not_counted_as_an_effective_stream(self):
        self.assertEqual(set(inventory(self.root)[1]), {'Remote'})

    def test_unknown_review_status_fails_closed(self):
        self.register['local_assets'][0]['review']['status'] = 'looks-good'
        self.save()
        with self.assertRaisesRegex(ValueError, 'Unknown/malformed review status'):
            assess(self.root)

    def test_duplicate_json_keys_are_rejected(self):
        self.write(REGISTER, '{"schema_version": 1, "schema_version": 1}')
        with self.assertRaisesRegex(ValueError, 'Duplicate JSON'):
            load_register(self.root)

    def test_path_traversal_hidden_files_and_credentials_are_not_evidence(self):
        for name in ['../outside.md', '/etc/hosts', '.env', 'android/key.properties', 'keys/owner.jks', 'build/receipt.md']:
            with self.subTest(name=name), self.assertRaises(ValueError):
                file_at(self.root, name)

    def test_symlinked_receipts_are_rejected(self):
        original = self.root / 'docs/release/fixture-evidence.md'
        (self.root / 'docs/release/link.md').symlink_to(original)
        with self.assertRaisesRegex(ValueError, 'Symlink'):
            file_at(self.root, 'docs/release/link.md')

    def test_reports_cannot_overwrite_sources_or_evidence(self):
        before = (self.root / REGISTER).read_bytes()
        result = self.cli('--json-output', REGISTER)
        self.assertEqual(result.returncode, 2)
        self.assertEqual((self.root / REGISTER).read_bytes(), before)
        self.assertIn('never a source/evidence file', result.stderr)

    def test_git_ignored_sdk_paths_and_generated_files_do_not_change_candidate(self):
        # A mocked .git marker is not a repository/branch initialization.
        self.write('.git', 'fixture marker only')
        paths = ['lib/providers/app_state.dart', 'lib/models/bundled_recordings.dart', 'web/icons/icon.png']
        output = SimpleNamespace(returncode=0, stdout=('\0'.join(paths) + '\0').encode())
        with patch('launch_preflight.subprocess.run', return_value=output) as command:
            before = candidate_fingerprint(self.root)
            self.write('android/local.properties', 'sdk.dir=/fixture/machine-specific-path')
            self.write('ios/Flutter/Generated.xcconfig', 'FLUTTER_ROOT=/fixture/machine-specific-sdk')
            self.assertEqual(candidate_fingerprint(self.root), before)
            self.assertIn('--exclude-standard', command.call_args.args[0])

    def test_git_input_enumeration_failure_is_not_a_successful_candidate_check(self):
        self.write('.git', 'fixture marker only')
        with patch('launch_preflight.subprocess.run', return_value=SimpleNamespace(returncode=1, stdout=b'')):
            with self.assertRaisesRegex(ValueError, 'Cannot enumerate release source inputs'):
                candidate_fingerprint(self.root)

    def test_private_configuration_does_not_enter_fingerprints(self):
        before = candidate_fingerprint(self.root)
        self.write('android/key.properties', 'not a real credential; fixture only')
        self.write('android/.gradle/cache.properties', 'ignored fixture cache')
        self.assertEqual(candidate_fingerprint(self.root), before)


if __name__ == '__main__':
    unittest.main()
