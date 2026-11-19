import unittest

from verify_android_signing_guard import validate_failure


class SigningGuardTest(unittest.TestCase):
    def test_expected_guard_failure_is_required(self):
        validate_failure(1, 'GradleException: Release signing is not configured. Supply owner-controlled credentials.')

    def test_accidental_unsigned_or_debug_signed_success_fails(self):
        with self.assertRaisesRegex(ValueError, 'unexpectedly built'):
            validate_failure(0, 'Built app-release.aab')

    def test_unrelated_failure_is_not_mistaken_for_a_working_guard(self):
        with self.assertRaisesRegex(ValueError, 'without reaching'):
            validate_failure(1, 'Could not download Gradle')


if __name__ == '__main__':
    unittest.main()
