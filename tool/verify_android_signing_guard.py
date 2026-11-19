#!/usr/bin/env python3
"""Negative CI test: a credential-free release build must fail at our guard."""
import os
import subprocess
from pathlib import Path

from ci_report_tests import escape


KEY_VARIABLES = ('SANCTUARY_KEYSTORE_PATH', 'SANCTUARY_KEYSTORE_PASSWORD',
                 'SANCTUARY_KEY_ALIAS', 'SANCTUARY_KEY_PASSWORD')


def validate_failure(code, output):
    if code == 0:
        raise ValueError('Release unexpectedly built without owner signing credentials or explicit unsigned opt-in.')
    if 'Release signing is not configured.' not in output:
        raise ValueError('Release failed without reaching the signing guard:\n' + output[-12000:])


def main():
    try:
        if any(os.environ.get(key) for key in KEY_VARIABLES) or Path('android/key.properties').exists():
            raise ValueError('The negative signing test requires a credential-free CI environment.')
        if os.environ.get('ORG_GRADLE_PROJECT_allowUnsignedRelease'):
            raise ValueError('Unsigned release opt-in must not be set for the negative signing test.')
        result = subprocess.run(
            ['flutter', 'build', 'appbundle', '--release', '--no-pub'],
            capture_output=True, text=True, timeout=600, check=False,
        )
        validate_failure(result.returncode, result.stdout + result.stderr)
    except (OSError, ValueError, subprocess.TimeoutExpired) as error:
        print(f'::error title=Release signing guard verification failed::{escape(error)}')
        return 1
    print('::notice title=Release signing guard verified::A credential-free release without explicit unsigned opt-in was rejected by the signing guard.')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
