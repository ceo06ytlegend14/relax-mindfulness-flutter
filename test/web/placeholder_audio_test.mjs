// Offline identity/routing guards. Not a native run, listening or rights review.
import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { readFile } from 'node:fs/promises';
import { test } from 'node:test';

const read = file => readFile(new URL('../../' + file, import.meta.url));
const manifest = JSON.parse(await read('assets/sounds/placeholder_loops.json'));
const data = String(await read('design/preview/data.js'));
const local = JSON.parse(data.match(/^const LOCAL_AUDIO = (.*);$/m)[1]);
const choices = JSON.parse(data.match(/^const BUNDLED_RECORDINGS = (.*);$/m)[1]);
const native = String(await read('lib/models/bundled_recordings.dart'));
const register = JSON.parse(await read('docs/release/launch-review.json'));

test('six loop edits bind the untouched originals and actual output bytes, not six new takes', async () => {
  assert.equal(manifest.loops.length, 6);
  assert.equal(manifest.additional_recordings, 0);
  assert.equal(manifest.rights_status, 'legacy-provenance-unresolved');
  assert.equal(choices.length, 18);
  assert.equal(new Set(choices.map(row => row.name)).size, 18);
  for (const row of manifest.loops) {
    assert.notEqual(row.source_asset, row.asset);
    assert(row.asset.startsWith('assets/sounds/loop_'));
    assert.equal(row.rights_status, 'legacy-provenance-unresolved');
    for (const [asset, expected] of [[row.source_asset, row.source_sha256], [row.asset, row.sha256]]) {
      assert.equal(createHash('sha256').update(await read(asset)).digest('hex'), expected);
    }
    assert.equal((await read(row.asset)).byteLength, row.bytes);
    assert(Math.abs(row.loop_seconds - (row.input_seconds - row.overlap_seconds)) < .001);
    assert(row.loop_seconds >= 24 && row.loop_seconds <= 27, 'Overlap is not a fake longer recording');
    assert(row.measurements.true_peak_dbtp <= -5.5, 'Recorded encoded digital headroom, not device volume');
  }
});

test('both mixer source maps and explicit auditions route to the same prepared recording', () => {
  for (const row of manifest.loops) {
    assert.equal(local[row.name], row.asset, `${row.name} must use the prepared file`);
    assert.equal(choices.find(choice => choice.name === row.name).assetPath, row.asset);
    assert(native.includes(`'${row.name}': '${row.asset}'`));
    assert(native.includes(`'${row.name}',\n    '${row.asset}'`) || native.includes(`'${row.name}', '${row.asset}'`));
  }
  assert.equal(new Set(Object.values(local)).size, 18);
});

test('legacy aliases keep their real recording identity instead of counting extra choices', () => {
  for (const [alias, source] of [
    ['Cozy Hearth', 'Campfire'], ['Wind Chimes', 'Bamboo Chimes'],
    ['Singing Bowl', 'Temple Bowl'], ['Singing Bowls', 'Temple Bowl'], ['Tibetan Bowls', 'Temple Bowl'],
  ]) {
    assert.equal(local[alias], local[source]);
    assert(local[alias].startsWith('assets/sounds/loop_'));
  }
  assert(!choices.some(choice => /#\d/.test(choice.name)), 'No fabricated numbered takes');
});

test('originals and derived placeholders remain pending and checksum-bound in the release register', () => {
  for (const row of manifest.loops) {
    for (const [asset, expected] of [[row.source_asset, row.source_sha256], [row.asset, row.sha256]]) {
      const review = register.local_assets.find(entry => entry.path === asset);
      assert(review, `Inventory must include ${asset}`);
      assert.equal(review.sha256, expected);
      assert.equal(review.review.status, 'pending');
    }
  }
  assert(register.gates.every(gate => gate.review.status === 'pending'));
});
