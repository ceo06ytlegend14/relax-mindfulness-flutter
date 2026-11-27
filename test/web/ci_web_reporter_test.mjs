import assert from 'node:assert/strict';
import path from 'node:path';
import { test } from 'node:test';
import githubFailures from '../../tool/ci_web_reporter.mjs';

const collect = async events => {
  const lines = [];
  for await (const line of githubFailures(events)) lines.push(line);
  return lines;
};

test('CI reporter leaves passes and test totals to the normal Node reporter', async () => {
  assert.deepEqual(await collect([
    { type: 'test:pass', data: { name: 'passed' } },
    { type: 'test:summary', data: { failed: 0 } },
  ]), []);
});

test('CI reporter annotates the real assertion and repository file without changing results', async () => {
  const error = new Error('Expected pinned sky; actual y was 20');
  const lines = await collect([{ type: 'test:fail', data: {
    name: 'pinned background', file: path.join(process.cwd(), 'test/web/background_test.mjs'), line: 12,
    details: { error },
  } }]);
  assert.equal(lines.length, 1);
  assert.match(lines[0], /^::error title=Browser regression,file=test\/web\/background_test\.mjs,line=12::/);
  assert.match(lines[0], /pinned background%0AError: Expected pinned sky; actual y was 20/);
  assert.equal(error.message, 'Expected pinned sky; actual y was 20');
});

test('CI reporter escapes command delimiters and never points outside the repository', async () => {
  const lines = await collect([{ type: 'test:fail', data: {
    name: 'A 50% label\n::warning::not another command', file: path.resolve('..', 'outside.mjs'), line: 4,
    details: { error: new Error('first\r\nsecond') },
  } }]);
  assert.equal(lines.length, 1);
  assert.equal(lines[0].split('\n').length, 2, 'Exactly one annotation command and its trailing newline');
  assert.match(lines[0], /50%25 label%0A::warning::not another command/);
  assert.match(lines[0], /first%0D%0Asecond/);
  assert.doesNotMatch(lines[0], /file=/);
});
