import struct
import tempfile
import unittest
import zipfile
from pathlib import Path

from verify_android_artifacts import check_archive, check_elf, check_manifest


def elf(*, alignment=16384, machine=183, address=0):
    data = bytearray(120)
    data[:6] = b'\x7fELF\x02\x01'
    struct.pack_into('<H', data, 18, machine)
    struct.pack_into('<Q', data, 32, 64)
    struct.pack_into('<HH', data, 54, 56, 1)
    struct.pack_into('<I', data, 64, 1)
    struct.pack_into('<Q', data, 64 + 16, address)
    struct.pack_into('<Q', data, 64 + 48, alignment)
    return data


class AndroidArtifactTest(unittest.TestCase):
    def test_valid_16_and_64_kb_elf_segments(self):
        check_elf(elf(), 'arm64-v8a', 'fixture.so')
        check_elf(elf(alignment=65536, machine=62), 'x86_64', 'fixture.so')

    def test_4_kb_or_incongruent_segments_fail(self):
        for data in [elf(alignment=4096), elf(address=1), elf(alignment=24576)]:
            with self.assertRaisesRegex(ValueError, '16 KB'):
                check_elf(data, 'arm64-v8a', 'fixture.so')

    def test_truncated_wrong_arch_or_non_elf_data_fails(self):
        for data in [b'not ELF', elf(machine=62), elf()[:80]]:
            with self.assertRaises(ValueError):
                check_elf(data, 'arm64-v8a', 'fixture.so')

    def test_archive_must_contain_64_bit_arm(self):
        with tempfile.TemporaryDirectory() as directory:
            file = Path(directory) / 'fixture.apk'
            with zipfile.ZipFile(file, 'w') as archive:
                archive.writestr('lib/arm64-v8a/libfixture.so', elf())
            self.assertEqual(check_archive(file), ['lib/arm64-v8a/libfixture.so'])
            with zipfile.ZipFile(file, 'w') as archive:
                archive.writestr('assets/not-a-library', b'x')
            with self.assertRaisesRegex(ValueError, 'no checked arm64'):
                check_archive(file)

    def test_compilation_only_bundle_rejects_signatures(self):
        with tempfile.TemporaryDirectory() as directory:
            file = Path(directory) / 'fixture.aab'
            with zipfile.ZipFile(file, 'w') as archive:
                archive.writestr('base/lib/arm64-v8a/libfixture.so', elf())
                archive.writestr('META-INF/UPLOAD.RSA', b'not a real certificate')
            with self.assertRaisesRegex(ValueError, 'unexpectedly contains'):
                check_archive(file, unsigned_bundle=True)

    def test_manifest_requires_stable_identity_api_and_billing_metadata(self):
        badging = "package: name='com.sanctuary.relax_mindfulness'\nsdkVersion:'24'\ntargetSdkVersion:'36'"
        tree = 'A: android:name(0x01010003)="com.google.android.play.billingclient.version"\n  A: android:value(0x01010024)="8.3.0"'
        self.assertEqual(check_manifest(badging, tree), (36, 8))
        for bad in [badging.replace("'36'", "'35'"), badging.replace('com.sanctuary.relax_mindfulness', 'com.example.app')]:
            with self.assertRaises(ValueError):
                check_manifest(bad, tree)
        for bad in ['', tree.replace('8.3.0', '7.0.0')]:
            with self.assertRaises(ValueError):
                check_manifest(badging, bad)


if __name__ == '__main__':
    unittest.main()
