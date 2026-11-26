"""Regression checks for the CI diagnostic boundary (no Flutter needed)."""
import json
import unittest

from ci_report_tests import escape, report


def events(*values):
    return '\n'.join(json.dumps(value) for value in values)


class TestReporterTest(unittest.TestCase):
    def test_success_requires_a_final_event(self):
        ok, summary, annotations = report(events(
            {'type': 'testDone', 'result': 'success'},
            {'type': 'done', 'success': True},
        ))
        self.assertTrue(ok)
        self.assertIn('1 passed', summary)
        self.assertEqual(annotations, [])
        self.assertFalse(report(events({'type': 'testDone', 'result': 'success'}))[0])

    def test_framework_details_are_kept_for_the_failing_test(self):
        ok, summary, annotations = report(events(
            {'type': 'testStart', 'test': {'id': 1, 'name': 'narrow screen', 'suiteID': 2}},
            {'type': 'print', 'testID': 1, 'message': 'A RenderFlex overflowed by 12 pixels.'},
            {'type': 'error', 'testID': 1, 'error': 'Test failed.'},
            {'type': 'testDone', 'testID': 1, 'result': 'error'},
            {'type': 'done', 'success': False},
        ))
        self.assertFalse(ok)
        self.assertIn('1 failed', summary)
        self.assertIn('RenderFlex overflowed', annotations[0])
        self.assertIn('narrow screen', annotations[0])

    def test_skipped_hidden_and_non_json_output(self):
        ok, summary, annotations = report('Resolving dependencies...\n' + events(
            {'type': 'testDone', 'result': 'success', 'hidden': True},
            {'type': 'testDone', 'result': 'success', 'skipped': True},
            {'type': 'done', 'success': True},
        ))
        self.assertTrue(ok)
        self.assertIn('0 passed, 0 failed, 1 skipped', summary)
        self.assertEqual(annotations, [])

    def test_annotations_escape_command_and_property_delimiters(self):
        self.assertEqual(escape('x%\n::error'), 'x%25%0A::error')
        self.assertEqual(escape('a,b:c', prop=True), 'a%2Cb%3Ac')
        ok, _, annotations = report(events(
            {'type': 'error', 'error': 'bad\n::warning::not a command'},
            {'type': 'done', 'success': False},
        ))
        self.assertFalse(ok)
        self.assertNotIn('\n', annotations[0])

    def test_inconsistent_success_still_fails_closed(self):
        self.assertFalse(report(events(
            {'type': 'error', 'error': 'failure'},
            {'type': 'done', 'success': True},
        ))[0])
        self.assertFalse(report('')[0])
        self.assertFalse(report(events({'type': 'done', 'success': False}))[0])

    def test_interrupted_stream_names_only_unfinished_tests(self):
        ok, summary, annotations = report(events(
            {'type': 'suite', 'suite': {'id': 1, 'path': 'test/player_test.dart'}},
            {'type': 'testStart', 'test': {'id': 2, 'name': 'finished', 'suiteID': 1}},
            {'type': 'testDone', 'testID': 2, 'result': 'success'},
            {'type': 'testStart', 'test': {'id': 3, 'name': 'loading', 'suiteID': 1}},
            {'type': 'testDone', 'testID': 3, 'result': 'success', 'hidden': True},
            {'type': 'testStart', 'test': {'id': 4, 'name': 'waiting for audio', 'suiteID': 1}},
            {'type': 'print', 'testID': 4, 'message': 'still in setup'},
        ))
        self.assertFalse(ok)
        self.assertIn('1 passed, 0 failed', summary)
        self.assertEqual(len(annotations), 2)
        self.assertIn('Incomplete Flutter test stream', annotations[0])
        self.assertIn('waiting for audio', annotations[1])
        self.assertIn('test/player_test.dart', annotations[1])
        self.assertIn('still in setup', annotations[1])

    def test_a_failed_final_event_does_not_hide_active_tests(self):
        ok, _, annotations = report(events(
            {'type': 'testStart', 'test': {'id': 1, 'name': 'cancelled load'}},
            {'type': 'done', 'success': False},
        ))
        self.assertFalse(ok)
        self.assertTrue(any('Unfinished Flutter test' in row and 'cancelled load' in row
                            for row in annotations))

    def test_a_failed_result_without_an_error_event_is_named(self):
        ok, summary, annotations = report(events(
            {'type': 'testStart', 'test': {'id': 1, 'name': 'interrupted cleanup'}},
            {'type': 'testDone', 'testID': 1, 'result': 'error'},
            {'type': 'done', 'success': False},
        ))
        self.assertFalse(ok)
        self.assertIn('1 failed', summary)
        self.assertEqual(len(annotations), 1)
        self.assertIn('interrupted cleanup', annotations[0])
        self.assertIn('no structured error was recorded', annotations[0])

    def test_unfinished_test_annotations_are_bounded_and_escaped(self):
        ok, _, annotations = report(events(
            *({'type': 'testStart', 'test': {'id': i, 'name': 'hang,\n::warning::' + 'x' * 50000}}
              for i in range(40)),
        ))
        self.assertFalse(ok)
        self.assertEqual(len(annotations), 9)
        self.assertTrue(all(len(annotation) < 14500 for annotation in annotations))
        self.assertTrue(all('\n' not in annotation for annotation in annotations))
        self.assertIn('hang%2C%0A%3A%3Awarning', annotations[1])

    def test_error_output_is_bounded(self):
        _, _, annotations = report(events(
            *({'type': 'error', 'testID': i, 'error': 'e' * 50000} for i in range(40)),
            {'type': 'done', 'success': False},
        ))
        self.assertEqual(len(annotations), 32)
        self.assertTrue(all(len(annotation) < 14500 for annotation in annotations))


if __name__ == '__main__':
    unittest.main()
