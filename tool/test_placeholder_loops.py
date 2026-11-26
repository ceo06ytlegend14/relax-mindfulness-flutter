"""Offline safety/identity checks; encoded-audio measurements are a separate CLI."""
import copy
import hashlib
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

from prepare_placeholder_loops import (
    MANIFEST, ROOT, RIGHTS_STATUS, SOURCES, encode_command, levels,
    overlap_command, recipe_digest, render, validate,
)


class PlaceholderLoopsTest(unittest.TestCase):
    def setUp(self):
        self.manifest = json.loads(MANIFEST.read_text())
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        (self.root / 'assets/sounds').mkdir(parents=True)
        evidence = self.root / self.manifest['evidence']
        evidence.parent.mkdir(parents=True)
        evidence.write_text('Fixture context; NOT permission or a real recording')
        for row in self.manifest['loops']:
            for field in ['source_asset', 'asset']:
                data = f"Independent fixture: {row['name']} / {field}".encode()
                (self.root / row[field]).write_bytes(data)
                row['source_sha256' if field == 'source_asset' else 'sha256'] = hashlib.sha256(data).hexdigest()
                if field == 'asset':
                    row['bytes'] = len(data)
            row['recipe_sha256'] = recipe_digest(row, self.manifest)

    def test_real_six_inputs_and_outputs_have_exact_hashes_and_zero_new_recordings(self):
        validate(json.loads(MANIFEST.read_text()), outputs=True)
        self.assertEqual(len(self.manifest['loops']), 6)
        self.assertEqual(self.manifest['additional_recordings'], 0)
        self.assertEqual(len({row['source_sha256'] for row in self.manifest['loops']}), 6)

    def test_independent_fixture_is_valid(self):
        validate(self.manifest, self.root, outputs=True)

    def test_original_modification_does_not_inherit_stale_derivative_provenance(self):
        (self.root / self.manifest['loops'][0]['source_asset']).write_bytes(b'Another source')
        with self.assertRaisesRegex(ValueError, 'Original input hash mismatch'):
            validate(self.manifest, self.root)

    def test_modified_output_fails_instead_of_silently_falling_back(self):
        (self.root / self.manifest['loops'][0]['asset']).write_bytes(b'Unreviewed edit')
        with self.assertRaisesRegex(ValueError, 'output hash/size mismatch'):
            validate(self.manifest, self.root, outputs=True)

    def test_output_can_never_overwrite_its_original(self):
        row = self.manifest['loops'][0]
        row['asset'] = row['source_asset']
        with self.assertRaisesRegex(ValueError, 'separate from its original'):
            validate(self.manifest, self.root)

    def test_source_path_is_pinned_to_the_existing_recording(self):
        self.manifest['loops'][0]['source_asset'] = 'assets/sounds/calm_guided.mp3'
        with self.assertRaisesRegex(ValueError, 'Unexpected original source'):
            validate(self.manifest, self.root)

    def test_an_alias_cannot_be_counted_as_a_seventh_recording(self):
        row = copy.deepcopy(self.manifest['loops'][0])
        row['name'] = 'Forest Birds #2'
        self.manifest['loops'].append(row)
        with self.assertRaisesRegex(ValueError, 'six existing legacy sources'):
            validate(self.manifest, self.root)

    def test_loop_edits_cannot_increment_the_recording_count(self):
        self.manifest['additional_recordings'] = 6
        with self.assertRaisesRegex(ValueError, 'cannot add recordings'):
            validate(self.manifest, self.root)

    def test_neither_manifest_nor_derivative_can_upgrade_rights(self):
        for target in [self.manifest, self.manifest['loops'][0]]:
            with self.subTest(target='manifest' if target is self.manifest else 'derivative'):
                before = target['rights_status']
                target['rights_status'] = 'release-cleared'
                with self.assertRaisesRegex(ValueError, 'rights'):
                    validate(self.manifest, self.root)
                target['rights_status'] = before
        self.assertEqual(self.manifest['rights_status'], RIGHTS_STATUS)

    def test_overlap_limits_reject_invalid_and_excessive_values(self):
        for value in [0, -1, 1.99, 6.01, float('nan'), float('inf'), '4', True]:
            with self.subTest(value=value):
                self.manifest['loops'][0]['overlap_seconds'] = value
                with self.assertRaisesRegex(ValueError, 'bounded'):
                    validate(self.manifest, self.root)

    def test_changed_overlap_or_processing_needs_a_real_rebuild(self):
        self.manifest['loops'][0]['overlap_seconds'] = 4
        with self.assertRaisesRegex(ValueError, 'recipe changed'):
            validate(self.manifest, self.root, outputs=True)
        self.manifest['loops'][0]['overlap_seconds'] = 3
        self.manifest['processing'] += ' unrendered change'
        with self.assertRaisesRegex(ValueError, 'recipe changed'):
            validate(self.manifest, self.root, outputs=True)

    def test_extending_the_recorded_duration_cannot_fake_longer_material(self):
        self.manifest['loops'][0]['loop_seconds'] = 300
        with self.assertRaisesRegex(ValueError, 'actual overlap'):
            validate(self.manifest, self.root, outputs=True)

    def test_missing_context_is_not_a_grant(self):
        (self.root / self.manifest['evidence']).unlink()
        with self.assertRaisesRegex(ValueError, 'Missing development'):
            validate(self.manifest, self.root)

    def test_independent_input_graph_avoids_ffmpeg7_asplit_early_eof(self):
        command = overlap_command('ffmpeg', Path('source.mp3'), Path('edit.wav'), 4)
        self.assertEqual(command.count('-i'), 2)
        self.assertEqual(command.count('source.mp3'), 2)
        filters = command[command.index('-filter_complex') + 1]
        self.assertIn('acrossfade=d=4:c1=qsin:c2=qsin', filters)
        self.assertIn('atrim=start=4', filters)
        self.assertNotIn('asplit', filters)
        self.assertNotIn('afade', filters)
        self.assertNotIn('loudnorm', filters)

    def test_encoder_preserves_headroom_with_one_static_gain_and_gapless_metadata(self):
        command = encode_command('ffmpeg', Path('edit.wav'), Path('loop.mp3'), self.manifest['loops'][0], -2.5)
        self.assertEqual(command[command.index('-af') + 1], 'volume=-2.500000dB')
        self.assertEqual(command[command.index('-write_xing') + 1], '1')
        self.assertNotIn('loudnorm', ' '.join(command))
        self.assertIn('rights unresolved', ' '.join(command))

    def test_silent_measurement_is_rejected_before_an_empty_loop_can_be_copied(self):
        response = subprocess.CompletedProcess([], 0, stderr='{"input_i":"-inf","input_tp":"-inf"}')
        with patch('prepare_placeholder_loops.subprocess.run', return_value=response):
            with self.assertRaisesRegex(ValueError, 'Silent or non-finite'):
                levels('ffmpeg', Path('empty.wav'))

    def test_failed_render_does_not_copy_any_outputs_or_touch_originals(self):
        snapshots = {row['source_asset']: (self.root / row['source_asset']).read_bytes()
                     for row in self.manifest['loops']}
        destination = self.root / 'scratch-output'
        with patch('prepare_placeholder_loops.subprocess.check_output', return_value='Fixture encoder\n'):
            with patch('prepare_placeholder_loops.inspect_audio', side_effect=ValueError('Decoder failed')):
                with self.assertRaisesRegex(ValueError, 'Decoder failed'):
                    render(self.manifest, 'ffmpeg', destination, self.root)
        self.assertFalse(destination.exists())
        for name, data in snapshots.items():
            self.assertEqual((self.root / name).read_bytes(), data)

    def test_cli_refuses_accidental_bundled_writes_and_reports_over_source_paths(self):
        before = MANIFEST.read_bytes()
        for arguments in [
            ['--output-dir', str(ROOT / 'assets/sounds')],
            ['--output-dir', str(self.root / 'scratch'), '--update-manifest'],
            ['--verify', '--update-manifest'],
            ['--verify', '--report', str(ROOT / 'assets/sounds/placeholder_loops.json')],
            ['--verify', '--report', str(ROOT / 'build/loop.mp3')],
        ]:
            with self.subTest(arguments=arguments):
                result = subprocess.run([sys.executable, str(ROOT / 'tool/prepare_placeholder_loops.py'), *arguments],
                                        capture_output=True, text=True)
                self.assertEqual(result.returncode, 2)
        self.assertEqual(before, MANIFEST.read_bytes())
        self.assertFalse((self.root / 'scratch').exists())


if __name__ == '__main__':
    unittest.main()
