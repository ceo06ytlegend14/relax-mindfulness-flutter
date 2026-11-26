// Offline routing/provenance guards, not Dart compilation or a listening test.
import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { readFile } from 'node:fs/promises';
import { test } from 'node:test';
import vm from 'node:vm';

const read = async file => readFile(new URL('../../' + file, import.meta.url), 'utf8');
const manifest = JSON.parse(await read('assets/sounds/session_soundscapes.json'));
const generated = await read('design/preview/session-audio.js');
const catalog = await read('design/preview/sanctuary-data.js');
const sandbox = vm.createContext({});
vm.runInContext(generated + '\n' + catalog, sandbox);
const value = expression => JSON.parse(vm.runInContext(`JSON.stringify(${expression})`, sandbox));
const cards = value('[DAILY_JOURNEY, ...MEDITATIONS, ...SLEEP_STORIES]');
const arrangements = value('SESSION_SOUNDSCAPES');

// Fail closed when a new card is added without audio, not when the user presses
// play after a release. Home references the one daily practice, not a 24th mix.
test('all 23 catalog sessions resolve to their own generated ambient arrangement', async () => {
  assert.equal(cards.length, 23);
  assert.equal(manifest.sessions.length, 23);
  assert.equal(new Set(cards.map(card => card.title)).size, 23);
  assert.equal(Object.keys(arrangements).length, 23);
  const dart = await read('lib/models/session_soundscapes.dart');
  const rows = [...dart.matchAll(/SessionSoundscape\(\s*("(?:\\.|[^"\\])*")\s*,\s*("(?:\\.|[^"\\])*")\s*,\s*(\[[\s\S]*?\])\s*,?\s*\)/g)];
  assert.equal(rows.length, 23, 'Generated Dart data has the same 23 explicit routes');
  const dartRows = rows.map(([, id, title, sources]) => ({ id: JSON.parse(id), title: JSON.parse(title), sources: JSON.parse(sources.replace(/,(\s*\])$/, '$1')) }));
  for (const card of cards) {
    const recipe = manifest.sessions.find(session => session.title === card.title);
    assert(recipe, `${card.title} has no implicit default`);
    const expected = { id: card.id, assetPath: recipe.asset, sources: recipe.layers.map(layer => layer.recording), sourceLabel: recipe.layers.map(layer => layer.recording).join(' + ') };
    assert.deepEqual(arrangements[card.title], expected);
    assert.deepEqual(dartRows.find(row => row.title === card.title), { id: card.id, title: card.title, sources: expected.sources });
  }
  assert.equal(new Set(Object.values(arrangements).map(audio => audio.assetPath)).size, 23);
});

test('arrangement bytes, decoded identities and actual source pairs are all distinct', async () => {
  const hashes = new Set(), decoded = new Set(), pairs = new Set();
  for (const session of manifest.sessions) {
    const bytes = await readFile(new URL('../../' + session.asset, import.meta.url));
    assert.equal(bytes.length, session.bytes);
    assert.equal(createHash('sha256').update(bytes).digest('hex'), session.sha256);
    hashes.add(session.sha256);
    decoded.add(session.pcm_sha256);
    const pair = session.layers.map(layer => manifest.recordings[layer.recording].sha256).sort();
    pairs.add(pair.join(':'));
    assert(session.layers.every(layer => layer.weight >= .2 && layer.weight <= .8));
    assert(Math.abs(session.layers.reduce((sum, layer) => sum + layer.weight, 0) - 1) < .0001);
  }
  assert.deepEqual([hashes.size, decoded.size, pairs.size], [23, 23, 23]);
});

test('visible ingredient labels name existing sources and preserve unresolved provenance', async () => {
  const data = await read('design/preview/data.js');
  const library = JSON.parse(data.match(/^const BUNDLED_RECORDINGS = (.*);$/m)[1]);
  assert.equal(Object.keys(manifest.recordings).length, 14, '23 arrangements do not mean 23 new recordings');
  for (const [name, source] of Object.entries(manifest.recordings)) {
    assert.equal(library.find(recording => recording.name === name)?.assetPath, source.asset);
    const bytes = await readFile(new URL('../../' + source.asset, import.meta.url));
    assert.equal(createHash('sha256').update(bytes).digest('hex'), source.sha256);
    assert(source.credit);
    assert(['legacy-provenance-unresolved', 'source-page-evidence-not-release-clearance'].includes(source.rights_status));
    assert(await read(source.evidence.split('#')[0]));
  }
  assert(cards.every(card => !Object.hasOwn(card, 'narrator')), 'No fictional narration metadata');
  assert.doesNotMatch(await read('lib/models/sanctuary_catalog.dart'), /(?:required this\.narrator|narrator\s*:)/);
});

test('unknown titles fail closed, while only explicit legacy titles are aliased', () => {
  for (const title of ['Not configured', '__proto__', 'constructor', 'toString', null]) {
    assert.equal(value(`sessionSoundscapeForTitle(${JSON.stringify(title)})`), null);
  }
  for (const [alias, title] of Object.entries(manifest.aliases)) {
    assert.deepEqual(value(`sessionSoundscapeForTitle(${JSON.stringify(alias)})`), arrangements[title]);
  }
});

test('both transports route only the selected arrangement and never the universal sample', async () => {
  const [dart, player, html] = await Promise.all([
    read('lib/providers/app_state.dart'), read('design/preview/player.js'), read('design/preview/index.html'),
  ]);
  const loader = dart.slice(dart.indexOf('  Future<void> _loadGuidedAudio'), dart.indexOf('  void _startGuidedPlayback'));
  assert.match(loader, /sessionSoundscapeForTitle\(_currentGuidedTitle\)/);
  assert.match(loader, /setAsset\(soundscape\.assetPath\)/);
  assert.doesNotMatch(loader, /setUrl\(|_resolveCdnUrl|calm_guided/);
  assert.doesNotMatch(player, /calm_guided/);
  assert.match(player, /audio\.src = session\.soundscape\.assetPath/);
  assert(html.indexOf('src="session-audio.js?') < html.indexOf('src="sanctuary.js?'), 'Routing data loads before page labels or playback');
});
