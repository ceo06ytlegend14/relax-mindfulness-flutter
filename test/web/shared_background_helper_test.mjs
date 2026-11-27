import assert from 'node:assert/strict';
import { test } from 'node:test';
import { expectNightSkyPaintLists } from './support/shared_background_helpers.mjs';

test('shared sky accepts CSSOM serialization that repeats the paint values per layer', () => {
  assert.doesNotThrow(() => expectNightSkyPaintLists({
    size: 'cover, cover', position: '50% 0%, 50% 0%',
  }));
});

test('shared sky accepts equivalent CSS list repetition from a single paint value', () => {
  for (const size of ['cover', 'cover, cover']) {
    for (const position of ['50% 0%', '50% 0%, 50% 0%']) {
      assert.doesNotThrow(() => expectNightSkyPaintLists({ size, position }));
    }
  }
});

test('shared sky still rejects different size, alignment, or extra paint-list entries', () => {
  for (const size of ['', 'contain', 'cover, contain', 'contain, cover', 'cover, cover, cover']) {
    assert.throws(() => expectNightSkyPaintLists({ size, position: '50% 0%' }));
  }
  for (const position of ['', '50% 50%', '50% 0%, 0% 0%', '0% 0%, 50% 0%', '50% 0%, 50% 0%, 50% 0%']) {
    assert.throws(() => expectNightSkyPaintLists({ size: 'cover', position }));
  }
});
