#!/usr/bin/env python3
"""Fail on dependency drift and expose its source-only diff in CI diagnostics."""
import subprocess
import sys

from ci_report_tests import escape


def main():
    diff = subprocess.run(
        ['git', 'diff', '--exit-code', '--', 'pubspec.lock'],
        check=False, capture_output=True, text=True,
    )
    if diff.returncode:
        detail = diff.stdout or 'Could not verify pubspec.lock against the checkout.'
        print(f'::error file=pubspec.lock,line=1,title=Dependency lockfile drift::{escape(detail[:50000])}')
        return 1
    print('Resolved dependencies match the committed pubspec.lock.')
    return 0


if __name__ == '__main__':
    sys.exit(main())
