// Source-data guards for the independent preview. This is not Dart analysis.
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { test } from 'node:test';

const read = async file => readFile(new URL('../../' + file, import.meta.url), 'utf8');
const [catalogDart, recordingsDart, appDart, data] = await Promise.all([
  read('lib/models/mixer_catalog.dart'), read('lib/models/bundled_recordings.dart'),
  read('lib/providers/app_state.dart'), read('design/preview/data.js'),
]);
const jsonConstant = name => JSON.parse(data.match(new RegExp('^const ' + name + ' = (.*);$', 'm'))[1]);
const catalog = jsonConstant('CATALOG');
const local = jsonConstant('LOCAL_AUDIO');
const choices = jsonConstant('BUNDLED_RECORDINGS');
const streamBlock = appDart.match(/soundStreamUrls\s*=\s*\{([\s\S]*?)\n  \};/)[1];
const streams = Object.fromEntries([...streamBlock.matchAll(/'([^']+)'\s*:\s*'([^']+)'/g)].map(match => [match[1], match[2]]));
const configured = new Set([...Object.keys(streams), ...Object.keys(local)]);

test('preview card names, aliases and choice names mirror the real Dart catalog', () => {
  const dartNames = [...catalogDart.matchAll(/MixerTrack\(\s*'[^']*'\s*,\s*'([^']+)'/g)].map(match => match[1]);
  const previewNames = catalog.flatMap(category => category.tracks.map(track => track.name));
  assert.deepEqual(previewNames, dartNames);
  assert.equal(previewNames.length, 77);
  const bundledBlock = recordingsDart.match(/const bundledSoundAssets\s*=\s*<String, String>\{([\s\S]*?)\n\};/)[1];
  const dartLocal = Object.fromEntries([...bundledBlock.matchAll(/'([^']+)'\s*:\s*'([^']+)'/g)].map(match => [match[1], match[2]]));
  assert.deepEqual(local, dartLocal);
  const dartChoices = [...recordingsDart.matchAll(/BundledRecording\(\s*'([^']+)'\s*,\s*'([^']+)'/g)].map(match => ({name:match[1],assetPath:match[2]}));
  assert.deepEqual(choices.map(({name,assetPath})=>({name,assetPath})),dartChoices);
  assert.equal(new Set(choices.map(choice=>choice.assetPath)).size,18);
});

test('source coverage is counted by card name, separately from new recordings and rights', async () => {
  const previewConfigured = JSON.parse(data.match(/^const CONFIGURED_AUDIO = new Set\((.*)\);$/m)[1]);
  assert.deepEqual(new Set(previewConfigured),configured);
  const tracks = catalog.flatMap(category=>category.tracks);
  const localCards = tracks.filter(track=>local[track.name]);
  const streamOnly = tracks.filter(track=>!local[track.name]&&streams[track.name]);
  const missing = tracks.filter(track=>!configured.has(track.name));
  assert.deepEqual([localCards.length,streamOnly.length,missing.length],[18,23,36]);
  const manifest = JSON.parse(await read('assets/sounds/ambient_pack.json'));
  assert.equal(manifest.sounds.length,12);
  for(const sound of manifest.sounds){
    assert.equal(local[sound.name],sound.asset);
    assert.equal(streams[sound.name],undefined,'New sources do not silently use a different old stream');
    assert(choices.find(choice=>choice.name===sound.name)?.credit);
  }
});

// These live presets reuse local recordings; they are not 10 new audio files.
test('all ten vibe recipes and descriptions match Flutter and lead the preview tray', async () => {
  const dart = await read('lib/models/vibe_sound_sets.dart');
  const pattern = /VibeSoundSet\(\s*'([^']*)',\s*'([^']*)',\s*'([^']*)',\s*'([^']*)',\s*'([^']*)',\s*\{([\s\S]*?)\},?\s*\)/g;
  const native = [...dart.matchAll(pattern)].map(([, id, name, purpose, vibe, icon, block]) => ({
    id, name, purpose, vibe, icon,
    levels: Object.fromEntries([...block.matchAll(/'([^']+)'\s*:\s*([0-9.]+)/g)].map(([, name, value]) => [name, Number(value)])),
  }));
  const sets = jsonConstant('VIBE_SETS');
  const presets = jsonConstant('PRESETS');
  assert.equal(native.length, 10);
  assert.deepEqual(sets, native);
  assert.deepEqual(presets.slice(0, 10), native);
  assert.match(appDart, /for \(final soundSet in vibeSoundSets\) soundSet\.name: soundSet\.levels/);
  assert.equal(new Set(sets.map(set => set.id)).size, 10);
  assert.equal(new Set(sets.map(set => set.name)).size, 10);
});

test('requested mixes use canonical distinct bundled sources with independent levels and existing output gain', async () => {
  const sets = jsonConstant('VIBE_SETS');
  const signatures = new Set();
  const used = new Set();
  for (const set of sets) {
    assert.match(set.id, /^[a-z][a-z0-9-]+$/);
    assert(set.vibe.length > 15);
    const layers = Object.entries(set.levels);
    assert(layers.length >= 3 && layers.length <= 4);
    const paths = [];
    let sum = 0;
    for (const [name, volume] of layers) {
      const choice = choices.find(choice => choice.name === name);
      assert(choice, `${name} is a real chooser source, not an unconfigured card or duplicate alias`);
      assert.equal(local[name], choice.assetPath);
      assert(Number.isFinite(volume) && volume > 0 && volume <= .65);
      assert(Math.abs(volume * 100 - Math.round(volume * 100)) < 1e-9);
      assert((await readFile(new URL('../../' + choice.assetPath, import.meta.url))).length > 0);
      sum += volume;
      paths.push(choice.assetPath);
      used.add(name);
    }
    assert.equal(new Set(paths).size, layers.length, 'Never stack two aliases for the same recording');
    assert(sum >= 1.10 - 1e-9 && sum <= 1.65 + 1e-9, 'Preserve the independent slider levels rather than normalizing the recipe to 100%');
    const signature = [...paths].sort().join('|');
    assert(!signatures.has(signature), 'Every set has a different ingredient combination, not just a new name');
    signatures.add(signature);
  }
  assert.equal(used.size, 15);
});

test('the eight existing curated names and levels remain unchanged beside the ten new sets', () => {
  const expected = [
    { name: '🌧️ Rainy Cabin', levels: { 'Soft Rain': .70, 'Cozy Hearth': .35, 'Ambient Piano': .20 } },
    { name: '🌊 Beach Sunset', levels: { 'Ocean Waves': .70, 'Soothing Breeze': .40, 'Bamboo Chimes': .20 } },
    { name: '🌌 Deep Space', levels: { 'Deep Space Drone': .70, 'Singing Bowls': .30 } },
    { name: '🌲 Forest Walk', levels: { 'Mountain Stream': .60, 'Forest Birds': .40, 'Soothing Breeze': .30 } },
    { name: '⚡ Thunderstorm', levels: { 'Thunderstorm': .70, 'Soft Rain': .50, 'Soothing Breeze': .20 } },
    { name: '🧘 Zen Sanctuary', levels: { 'Singing Bowls': .60, 'Bamboo Chimes': .40, 'Mountain Stream': .30 } },
    { name: '🔥 Campfire Night', levels: { 'Cozy Hearth': .75, 'Soothing Breeze': .30 } },
    { name: '🕊️ Peace Flow', levels: { 'Ambient Piano': .65, 'Soft Rain': .30, 'Singing Bowls': .25 } },
  ];
  const legacy = jsonConstant('PRESETS').filter(preset => !preset.id).map(({ name, levels }) => ({ name, levels }));
  assert.deepEqual(legacy, expected);
  for (const preset of expected) {
    const escaped = preset.name.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
    const block = appDart.match(new RegExp("'" + escaped + "'\\s*:\\s*\\{([^}]+)\\}"));
    assert(block, `${preset.name} still exists in Flutter`);
    const levels = Object.fromEntries([...block[1].matchAll(/'([^']+)'\s*:\s*([0-9.]+)/g)].map(([, name, value]) => [name, Number(value)]));
    assert.deepEqual(levels, preset.levels);
  }
});

test('related recording families match native and contain only genuinely different existing assets', () => {
  const block=recordingsDart.match(/const bundledRecordingFamilies = <String, List<String>>\{([\s\S]*?)\n\};/)[1];
  const native=Object.fromEntries([...block.matchAll(/'([^']+)'\s*:\s*\[([^\]]+)\]/g)].map(([,name,values])=>[name,[...values.matchAll(/'([^']+)'/g)].map(([,value])=>value)]));
  assert.deepEqual(jsonConstant('RECORDING_FAMILIES'),native);
  assert.deepEqual(Object.keys(native),['Fire','Birds']);
  for(const names of Object.values(native)) {
    assert.equal(names.length,2);
    assert.equal(new Set(names.map(name=>local[name])).size,2);
    assert(names.every(name=>choices.some(choice=>choice.name===name)));
  }
});

test('Meditate featured IDs and simplified filters match native without changing session identities', async () => {
  const [native,preview]=await Promise.all([read('lib/models/sanctuary_catalog.dart'),read('design/preview/sanctuary.js')]);
  for(const [dartName,jsName] of [['simpleMeditationFilters','SIMPLE_MEDITATION_FILTERS'],['featuredMeditationIds','FEATURED_MEDITATION_IDS']]) {
    const block=native.match(new RegExp('const '+dartName+' = \\[([\\s\\S]*?)\\];'))[1];
    const values=[...block.matchAll(/'([^']+)'/g)].map(([,value])=>value);
    assert.deepEqual(JSON.parse(preview.match(new RegExp('^const '+jsName+' = (.*);$','m'))[1]),values);
  }
});


test('all ten requested names, main purposes and percentages match the independent recipe contract exactly', async () => {
  const expected = JSON.parse(await read('test/fixtures/curated_sound_mixes.json'));
  assert.deepEqual(jsonConstant('VIBE_SETS').map(({ id, name, purpose, levels }) => ({ id, name, purpose, levels })), expected);
  assert.equal(jsonConstant('PRESETS').length, 18, 'Ten requested mixes plus the eight untouched legacy presets');
  const used = new Set(expected.flatMap(set => Object.keys(set.levels)));
  for (const retained of ['Pink Noise', 'Blue Noise', 'Violet Noise']) {
    assert(!used.has(retained));
    assert(choices.some(choice => choice.name === retained), 'Unused bundled sources are retained, not removed');
  }
});

test('requested slider percentages keep the existing native/browser master limiter separate', async () => {
  const [preview, nativeUI] = await Promise.all([read('design/preview/index.html'), read('lib/screens/sounds_screen.dart')]);
  assert.match(appDart, /_masterGain = sum > 1\.0 \? \(1\.0 \/ sum\) : 1\.0/);
  assert.match(preview, /const gain = Math\.min\(1, 1 \/ \(sum \|\| 1\)\)/);
  assert.match(nativeUI, /Individual levels need not total 100%/);
  assert.match(preview, /Individual levels need not total 100%/);
});

// Source guards only: the corresponding Dart tests still require Flutter.
test('bundled native recordings are a mutually exclusive local branch, never a network fallback chain', async () => {
  assert.match(appDart, /final sources = <String>\[\s*if \(localAsset != null\)\s*localAsset\s*else if \(url != null\) \.\.\.\[\s*_resolveCdnUrl\(url\),\s*if \(_resolveCdnUrl\(url\) != url\) url,/);
  assert.doesNotMatch(appDart, /if \(localAsset != null\) localAsset,\s*if \(url != null\)/);
});

test('native and preview place the 77-entry inventory behind explicit review without a paid-content gate', async () => {
  const [native, html, workflow] = await Promise.all([
    read('lib/screens/sounds_screen.dart'), read('design/preview/index.html'), read('.github/workflows/quality.yml'),
  ]);
  assert.match(native, /bool _reviewExpanded = false/);
  assert.match(native, /if \(expanded\) \.\.\.\[[\s\S]*?ValueKey\('library-full'\)/);
  assert.match(native, /ValueKey\('library-review-selected'\)/);
  assert.match(html, /<details id="catalog-review"><summary>Review unfinished catalog<\/summary>[\s\S]*?id="library-full"[\s\S]*?<\/details>/);
  assert.match(html, /18 bundled sounds, 23 stream-only entries and 36 entries without recordings/);
  assert.match(workflow, /Check release inventory drift \(not release approval\)[\s\S]*?launch_preflight\.py --inventory-only/);
});
