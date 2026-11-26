#!/usr/bin/env python3
"""Run a no-credential CI build, preserving exit status and bounded diagnostics."""
import subprocess
import sys
from collections import deque

from ci_report_tests import escape


def main():
    command = sys.argv[1:]
    if not command:
        print('Usage: python3 tool/ci_build.py <build command> [arguments...]')
        return 2
    tail = deque(maxlen=65)
    try:
        process = subprocess.Popen(
            command, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
            encoding='utf-8', errors='replace', bufsize=1,
        )
    except OSError:
        print('::error title=Build tool unavailable::The requested build executable could not be started.')
        return 1
    for line in process.stdout:
        print(line, end='', flush=True)
        tail.append(line.rstrip())
    code = process.wait()
    if code:
        # No env or signing material is supplied to these read-only CI jobs.
        detail = '\n'.join(tail)[-22000:]
        print(f'::error title=Native build failed::{escape(detail)}')
    return code if code >= 0 else 1


if __name__ == '__main__':
    raise SystemExit(main())
