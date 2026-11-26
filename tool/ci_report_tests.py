#!/usr/bin/env python3
"""Summarize Dart's JSON test events as bounded, escaped CI annotations.

The Flutter process still owns its exit status (the workflow uses pipefail).
This reporter additionally fails closed if the JSON stream never completes.
Only test names/errors are emitted, never environment variables or credentials.
"""
import json
import os
import sys
from collections import deque
from pathlib import Path


def escape(value, *, prop=False):
    text = str(value).replace('%', '%25').replace('\r', '%0D').replace('\n', '%0A')
    return text.replace(',', '%2C').replace(':', '%3A') if prop else text


def report(source):
    tests = {}
    suites = {}
    errors = {}
    prints = {}
    completed = []
    finished_ids = set()
    finish = None
    for line in source.splitlines():
        try:
            event = json.loads(line)
        except (ValueError, TypeError):
            continue  # Flutter can print non-JSON tool output before test events.
        if not isinstance(event, dict):
            continue
        kind = event.get('type')
        if kind == 'suite':
            suite = event.get('suite', {})
            suites[suite.get('id')] = suite.get('path', '')
        elif kind == 'testStart':
            test = event.get('test', {})
            tests[test.get('id')] = test
        elif kind == 'print':
            # Flutter framework exception details precede a generic error event.
            prints.setdefault(event.get('testID'), deque(maxlen=40)).append(
                str(event.get('message', ''))[:14000]
            )
        elif kind == 'error' and not event.get('isWarning', False):
            error = str(event.get('error', 'Unknown test error'))
            stack = str(event.get('stackTrace', ''))
            errors.setdefault(event.get('testID'), []).append(f'{error}\n{stack}'.strip())
        elif kind == 'testDone':
            # Hidden loading/setup events also finish: do not mistake them for
            # a hanging test when the stream is interrupted later.
            finished_ids.add(event.get('testID'))
            if not event.get('hidden', False):
                completed.append(event)
        elif kind == 'done':
            finish = bool(event.get('success', False))

    passed = sum(e.get('result') == 'success' and not e.get('skipped') for e in completed)
    failed = sum(e.get('result') in ('failure', 'error') for e in completed)
    skipped = sum(bool(e.get('skipped')) for e in completed)
    summary = f'Flutter tests: {passed} passed, {failed} failed, {skipped} skipped.'
    annotations = []
    # Keep diagnostics bounded while covering a multi-suite regression batch.
    for test_id, messages in list(errors.items())[:32]:
        test = tests.get(test_id, {})
        name = test.get('name', f'Test {test_id}')
        path = suites.get(test.get('suiteID'), '')
        location = ''
        if path:
            try:
                path = str(Path(path).resolve().relative_to(Path.cwd()))
                location = f',file={escape(path, prop=True)},line=1'
            except ValueError:
                pass
        detail = list(prints.get(test_id, [])) + messages
        body = '\n\n'.join(dict.fromkeys(detail))[:14000]
        annotations.append(f'::error title={escape(name[:220], prop=True)}{location}::{escape(body)}')
    if finish is None:
        annotations.append('::error title=Incomplete Flutter test stream::No final Dart test event was recorded; inspect the test process output.')
        unfinished = [(test_id, test) for test_id, test in tests.items()
                      if test_id not in finished_ids]
        for test_id, test in unfinished[:8]:
            name = str(test.get('name', f'Test {test_id}'))
            path = suites.get(test.get('suiteID'), '')
            detail = [f'Test started but did not finish: {name}', f'Suite: {path}']
            detail.extend(prints.get(test_id, []))
            annotations.append(
                f'::error title={escape(("Unfinished Flutter test: " + name)[:220], prop=True)}'
                f'::{escape(chr(10).join(detail)[:14000])}'
            )
    elif not finish and not errors:
        annotations.append('::error title=Flutter tests failed::The runner reported failure without a structured error event.')
    success = finish is True and not errors and failed == 0
    return success, summary, annotations


def main():
    if len(sys.argv) != 2 or not Path(sys.argv[1]).is_file():
        print('::error title=Missing Flutter test report::The JSON test report was not created.')
        return 1
    success, summary, annotations = report(Path(sys.argv[1]).read_text(errors='replace'))
    print(summary)
    print(f'::notice title=Flutter test totals::{escape(summary)}')
    for annotation in annotations:
        print(annotation)
    summary_file = os.environ.get('GITHUB_STEP_SUMMARY')
    if summary_file:
        with open(summary_file, 'a', encoding='utf-8') as output:
            output.write(f'## Flutter test results\n\n{summary}\n\n')
            output.write('See the test annotations and retained JSON artifact for details.\n')
    return 0 if success else 1


if __name__ == '__main__':
    raise SystemExit(main())
