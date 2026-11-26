import copy
import hashlib
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

from verify_ambient_pack import ROOT, verify


class AmbientPackTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        (self.root / 'assets/sounds').mkdir(parents=True)
        self.manifest = json.loads((ROOT / 'assets/sounds/ambient_pack.json').read_text())
        evidence = self.root / self.manifest['evidence']
        evidence.parent.mkdir(parents=True)
        evidence.write_text('Test licence evidence')
        for sound in self.manifest['sounds']:
            # Small independent fixture bytes, never modify the real MP3s.
            data = (sound['name'] + ': unique fixture audio').encode()
            (self.root / sound['asset']).write_bytes(data)
            sound['bytes'] = len(data)
            sound['sha256'] = hashlib.sha256(data).hexdigest()
        self.save()

    def save(self):
        (self.root / 'assets/sounds/ambient_pack.json').write_text(json.dumps(self.manifest))

    def test_real_assets_have_exact_recorded_hashes_and_provenance(self):
        self.assertEqual(len(verify()), 12)

    def test_modified_audio_fails_instead_of_accepting_stale_provenance(self):
        (self.root / self.manifest['sounds'][0]['asset']).write_bytes(b'different recording')
        with self.assertRaisesRegex(ValueError, 'checksum/size mismatch'):
            verify(self.root)

    def test_duplicate_recording_is_not_counted_as_a_new_source(self):
        self.manifest['sounds'][1]['sha256'] = self.manifest['sounds'][0]['sha256']
        self.save()
        with self.assertRaisesRegex(ValueError, 'Duplicate audio'):
            verify(self.root)

    def test_reencoding_the_same_recording_is_not_a_distinct_source(self):
        self.manifest['sounds'][1]['source_sha256'] = self.manifest['sounds'][0]['source_sha256']
        self.save()
        with self.assertRaisesRegex(ValueError, 'Re-encoding one recording'):
            verify(self.root)

    def test_replacing_reviewed_assets_requires_both_explicit_flags(self):
        result = subprocess.run([
            sys.executable, str(ROOT / 'tool/prepare_ambient_pack.py'),
            '--output-dir', str(ROOT / 'assets/sounds'),
        ], capture_output=True, text=True)
        self.assertEqual(result.returncode, 2)
        self.assertIn('requires both', result.stderr)
        # An attempted mismatch never touched the reviewed files.
        self.assertEqual(len(verify()), 12)

    def test_scratch_rebuild_cannot_change_the_bundled_manifest(self):
        result = subprocess.run([
            sys.executable, str(ROOT / 'tool/prepare_ambient_pack.py'),
            '--output-dir', str(self.root / 'scratch'), '--update-manifest',
        ], capture_output=True, text=True)
        self.assertEqual(result.returncode, 2)
        self.assertIn('requires both', result.stderr)
        self.assertFalse((self.root / 'scratch').exists())

    def test_repository_code_licence_is_not_accepted_as_an_audio_grant(self):
        self.manifest['sounds'][0]['license'] = 'GPL-3.0-only'
        self.save()
        with self.assertRaisesRegex(ValueError, 'separate licence review'):
            verify(self.root)

    def test_unpinned_source_is_rejected(self):
        self.manifest['mirror_commit'] = 'main'
        self.save()
        with self.assertRaisesRegex(ValueError, 'must be pinned'):
            verify(self.root)

    def test_noise_cannot_be_relabelled_as_a_field_recording(self):
        changed = copy.deepcopy(self.manifest['sounds'][-1])
        changed['kind'] = 'field-recording'
        self.manifest['sounds'][-1] = changed
        self.save()
        with self.assertRaisesRegex(ValueError, 'seven recordings and five generated noises'):
            verify(self.root)

    def test_missing_original_page_evidence_is_rejected(self):
        (self.root / self.manifest['evidence']).unlink()
        with self.assertRaisesRegex(ValueError, 'Missing original-page'):
            verify(self.root)


if __name__ == '__main__':
    unittest.main()
