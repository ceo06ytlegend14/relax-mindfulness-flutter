"""Offline recipe/hash/safety checks. Full audio decoding is a separate CLI check."""
import array
import copy
import hashlib
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

from prepare_session_soundscapes import ROOT, MANIFEST, correlation, recipe_digest, validate


class SessionSoundscapesTest(unittest.TestCase):
    def setUp(self):
        self.manifest = json.loads(MANIFEST.read_text())
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        (self.root / 'assets/sounds').mkdir(parents=True)
        # Independent, tiny fixtures. Never mutate a bundled recording in a test.
        for name, recording in self.manifest['recordings'].items():
            data = ('fixture source: ' + name).encode()
            (self.root / recording['asset']).write_bytes(data)
            recording['sha256'] = hashlib.sha256(data).hexdigest()
            evidence = self.root / recording['evidence'].split('#', 1)[0]
            evidence.parent.mkdir(parents=True, exist_ok=True)
            evidence.write_text('Fixture evidence, not a rights grant')
        for session in self.manifest['sessions']:
            data = ('fixture arrangement: ' + session['id']).encode()
            (self.root / session['asset']).write_bytes(data)
            session['sha256'] = hashlib.sha256(data).hexdigest()
            session['bytes'] = len(data)
            session['pcm_sha256'] = hashlib.sha256(b'PCM:' + data).hexdigest()
            session['recipe_sha256'] = recipe_digest(session, self.manifest)

    def test_real_sources_and_all_23_outputs_match_recorded_hashes(self):
        real = json.loads(MANIFEST.read_text())
        validate(real, outputs=True)
        self.assertEqual(len(real['sessions']), 23)
        self.assertEqual(len(real['recordings']), 14)

    def test_fixture_is_self_contained_and_valid(self):
        validate(self.manifest, self.root, outputs=True)

    def test_modified_ingredient_does_not_inherit_stale_provenance(self):
        recording = next(iter(self.manifest['recordings'].values()))
        (self.root / recording['asset']).write_bytes(b'Another source')
        with self.assertRaisesRegex(ValueError, 'Input hash mismatch'):
            validate(self.manifest, self.root)

    def test_corrupt_arrangement_is_not_hidden_behind_a_generic_sample(self):
        session = self.manifest['sessions'][0]
        (self.root / session['asset']).write_bytes(b'Corrupt output')
        with self.assertRaisesRegex(ValueError, 'Output hash/size mismatch'):
            validate(self.manifest, self.root, outputs=True)

    def test_same_pair_in_another_order_is_not_another_soundscape(self):
        self.manifest['sessions'][1]['layers'] = copy.deepcopy(
            self.manifest['sessions'][0]['layers'][::-1]
        )
        with self.assertRaisesRegex(ValueError, 'Repeated source pair'):
            validate(self.manifest, self.root)

    def test_an_alias_cannot_masquerade_as_a_second_layer(self):
        layers = self.manifest['sessions'][0]['layers']
        layers[1]['recording'] = layers[0]['recording']
        with self.assertRaisesRegex(ValueError, 'Repeated source pair'):
            validate(self.manifest, self.root)

    def test_nearly_inaudible_second_layer_is_rejected(self):
        layers = self.manifest['sessions'][0]['layers']
        layers[0]['weight'], layers[1]['weight'] = .99, .01
        with self.assertRaisesRegex(ValueError, 'two contributing, bounded layers'):
            validate(self.manifest, self.root)

    def test_nonunit_or_unrendered_mixing_weights_are_rejected(self):
        layers = self.manifest['sessions'][0]['layers']
        layers[0]['weight'] = .6
        with self.assertRaisesRegex(ValueError, 'total one'):
            validate(self.manifest, self.root)
        layers[1]['weight'] = .4
        with self.assertRaisesRegex(ValueError, 'Render recipe changed'):
            validate(self.manifest, self.root, outputs=True)

    def test_unknown_ingredients_are_not_silently_substituted(self):
        self.manifest['sessions'][0]['layers'][0]['recording'] = 'Missing source'
        with self.assertRaisesRegex(ValueError, 'two contributing, bounded layers'):
            validate(self.manifest, self.root)

    def test_a_recipe_cannot_overwrite_an_existing_library_source(self):
        self.manifest['sessions'][0]['asset'] = 'assets/sounds/soft_rain.mp3'
        with self.assertRaisesRegex(ValueError, 'cannot replace a library recording'):
            validate(self.manifest, self.root)

    def test_unknown_alias_does_not_resolve_to_a_default(self):
        self.manifest['aliases']['Unknown'] = 'No such session'
        with self.assertRaisesRegex(ValueError, 'alias target'):
            validate(self.manifest, self.root)

    def test_missing_evidence_is_not_replaced_by_a_code_licence(self):
        recording = next(iter(self.manifest['recordings'].values()))
        (self.root / recording['evidence'].split('#', 1)[0]).unlink()
        with self.assertRaisesRegex(ValueError, 'Missing source credit/evidence'):
            validate(self.manifest, self.root)

    def test_rendering_cannot_mark_unresolved_rights_as_cleared(self):
        recording = next(iter(self.manifest['recordings'].values()))
        recording['rights_status'] = 'release-cleared'
        with self.assertRaisesRegex(ValueError, 'cannot grant source rights'):
            validate(self.manifest, self.root)

    def test_different_containers_with_identical_decoded_identity_fail(self):
        sessions = self.manifest['sessions']
        sessions[1]['pcm_sha256'] = sessions[0]['pcm_sha256']
        with self.assertRaisesRegex(ValueError, 'identical audio'):
            validate(self.manifest, self.root, outputs=True)

    def test_bundled_replacement_needs_both_flags_and_never_touches_originals(self):
        before = MANIFEST.read_bytes()
        for arguments in [
            ['--output-dir', str(ROOT / 'assets/sounds')],
            ['--output-dir', str(self.root / 'scratch'), '--update-manifest'],
            ['--verify', '--update-manifest'],
            ['--verify', '--report', str(ROOT / 'assets/sounds/soft_rain.mp3')],
        ]:
            with self.subTest(arguments=arguments):
                result = subprocess.run(
                    [sys.executable, str(ROOT / 'tool/prepare_session_soundscapes.py'), *arguments],
                    capture_output=True, text=True,
                )
                self.assertEqual(result.returncode, 2)
        self.assertEqual(before, MANIFEST.read_bytes())
        self.assertFalse((self.root / 'scratch').exists())

    def test_signal_comparison_catches_amplitude_changes_not_just_hashes(self):
        signal = array.array('h', [1, 20, -4, 14, -8, 9])
        self.assertAlmostEqual(correlation(signal, [2 * x for x in signal]), 1)
        self.assertAlmostEqual(correlation(signal, [-x for x in signal]), -1)
        with self.assertRaisesRegex(ValueError, 'constant'):
            correlation(signal, [0] * len(signal))
        with self.assertRaisesRegex(ValueError, 'Empty'):
            correlation([], [])


if __name__ == '__main__':
    unittest.main()
