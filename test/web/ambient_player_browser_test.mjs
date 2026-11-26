// Real local decoding/UI regression tests for the independent HTML preview.
// Not a compiled Flutter run, a recording of speaker output or human listening.
import assert from 'node:assert/strict';
import { createServer } from 'node:http';
import { readFile, realpath } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { after, before, test } from 'node:test';

const { chromium } = await import(process.env.PLAYWRIGHT_MODULE || 'playwright');
const root = path.resolve(fileURLToPath(new URL('../../', import.meta.url)));
const directory = path.join(root, 'design/preview');
const recipes = JSON.parse(await readFile(path.join(root, 'test/fixtures/curated_sound_mixes.json'), 'utf8'));
const forest = recipes[1];
const loopEdits = JSON.parse(await readFile(path.join(root, 'assets/sounds/placeholder_loops.json'), 'utf8')).loops;
const mime = { '.html': 'text/html', '.js': 'text/javascript', '.css': 'text/css', '.webp': 'image/webp', '.ttf': 'font/ttf', '.mp3': 'audio/mpeg', '.json': 'application/json' };
let server, browser, origin;

before(async () => {
  server = createServer(async (request, response) => {
    try {
      const pathname = decodeURIComponent(new URL(request.url, 'http://test.invalid').pathname);
      const resolved = await realpath(path.join(directory, pathname === '/' ? 'index.html' : pathname.slice(1)));
      if (!resolved.startsWith(`${root}${path.sep}`)) throw new Error('Outside repository');
      const bytes = await readFile(resolved);
      response.writeHead(200, { 'Content-Type': mime[path.extname(resolved)] || 'application/octet-stream', 'Content-Length': bytes.length, 'Cache-Control': 'no-store' });
      response.end(bytes);
    } catch (_) { response.writeHead(404); response.end('Not found'); }
  });
  await new Promise(resolve => server.listen(0, '0.0.0.0', resolve));
  origin = `http://127.0.0.1:${server.address().port}`;
  browser = await chromium.launch({ headless: true, executablePath: process.env.CHROMIUM_PATH || undefined, args: ['--disable-dev-shm-usage'] });
});
after(async () => {
  await browser?.close();
  if (server) await new Promise(resolve => { server.close(resolve); server.closeAllConnections(); });
});
async function open(t, { route = '/#sounds', width = 390, height = 844, stored = null, fallback = false, virtualClock = false, reducedMotion = 'reduce', blockFonts = false } = {}) {
  const context = await browser.newContext({ viewport: { width, height }, reducedMotion });
  t.after(() => context.close());
  if (stored) await context.addInitScript(stored => localStorage.setItem('sanctuary.designPreview.v1', JSON.stringify(stored)), stored);
  if (fallback) await context.addInitScript(() => { window.AudioContext = undefined; window.webkitAudioContext = undefined; });
  if (blockFonts) await context.route('**/*', route => route.request().resourceType() === 'font' ? route.abort() : route.continue());
  const page = await context.newPage();
  if (virtualClock) await page.clock.install({ time: new Date('2026-11-19T20:00:00Z') });
  const errors = [], audioRequests = [];
  page.on('pageerror', error => errors.push(error.message));
  page.on('request', request => { if (/\/assets\/sounds\/[^/?]+\.mp3/.test(request.url())) audioRequests.push(new URL(request.url()).pathname); });
  t.after(() => assert.deepEqual(errors, [], 'No unhandled browser errors'));
  await page.goto(origin + route, { waitUntil: 'networkidle' });
  return { page, context, audioRequests };
}
async function startForest(page) {
  await page.locator(`[data-vibe-set="${forest.id}"]`).click();
  assert.equal(await page.locator('#ambient-dialog').isVisible(), true, 'Intentional start opens before playback confirmation');
  await page.waitForFunction(() => ambientPlaybackState().active.length === 4);
}
async function rememberAudio(page) {
  await page.evaluate(() => {
    window.retainedAmbient = [...players].filter(([name]) => levels[name] > 0).map(([name, audio]) => ({ name, audio, node: audio.sourceNode, time: audio.currentTime, plays: 0, loads: 0 }));
    for (const item of retainedAmbient) for (const [method, counter] of [['play', 'plays'], ['load', 'loads']]) {
      const original = item.audio[method].bind(item.audio);
      item.audio[method] = (...args) => { item[counter]++; return original(...args); };
    }
  });
}
async function assertRetained(page) {
  assert.equal(await page.evaluate(() => retainedAmbient.every(item => players.get(item.name) === item.audio && item.audio.sourceNode === item.node && !item.audio.paused && item.plays === 0 && item.loads === 0)), true, 'UI/gain changes keep healthy source nodes; no play/load/seek restart');
}

test('restored selection never autoplays or creates a player until an explicit start', async t => {
  const stored = { levels: forest.levels, favorites: [], saved: [] };
  const { page, audioRequests } = await open(t, { stored });
  assert.deepEqual(await page.evaluate(() => levels), forest.levels);
  assert.equal(await page.evaluate(() => players.size || playing || ambientHasSession), false);
  assert.equal(await page.locator('#ambient-dialog').isVisible(), false);
  assert.equal(await page.locator('#shared-mini-player').isVisible(), false);
  assert.deepEqual(audioRequests, []);
});

test('Enchanted Forest opens automatically with the real four independently leveled sounds', async t => {
  const { page, audioRequests } = await open(t);
  await startForest(page);
  assert.equal(await page.locator('#ambient-title').textContent(), forest.name);
  const rows = await page.locator('[data-ambient-layer]').evaluateAll(rows => rows.map(row => ({ name: row.dataset.ambientLayer, level: row.querySelector('output').textContent, slider: Number(row.querySelector('input').value), status: row.querySelector('small').textContent })));
  assert.deepEqual(rows, Object.entries(forest.levels).map(([name, value]) => ({ name, level: `${Math.round(value * 100)}%`, slider: Math.round(value * 100), status: 'Playing' })));
  assert.match(await page.locator('#ambient-status').textContent(), /Playing · 4 layers/);
  assert.equal(await page.locator('#ambient-dialog input[aria-label="Session progress"]').count(), 0, 'Indefinite mix has no invented session timeline');
  assert.equal(await page.locator('#shared-mini-player').isVisible(), false);
  const actual = await page.evaluate(() => [...players].map(([name, audio]) => ({ name, volume: audio.volume, path: new URL(audio.currentSrc).pathname, backend: audio.backend, looping: audio.sourceNode.loop })));
  const sum = Object.values(forest.levels).reduce((a, b) => a + b, 0);
  for (const item of actual) {
    assert.equal(item.backend, 'decoded-loop'); assert.equal(item.looping, true);
    assert(Math.abs(item.volume - forest.levels[item.name] / sum) < 1e-9);
  }
  assert.deepEqual(new Set(audioRequests), new Set(actual.map(item => item.path)));
});

test('minimize, all four tabs and repeated reopening do not restart a sound or change its levels', async t => {
  const { page } = await open(t);
  await startForest(page); await rememberAudio(page);
  for (const tab of ['home', 'sounds', 'meditate', 'sleep']) {
    await page.locator('#ambient-minimize').click();
    await page.locator(`.bottom-nav [data-tab="${tab}"]`).click();
    assert.equal(await page.locator('#shared-mini-player').isVisible(), true);
    assert.equal(await page.locator('#mini-title').textContent(), forest.name);
    await page.locator('#mini-open').click();
    assert.equal(await page.locator('#ambient-dialog').isVisible(), true);
    assert.equal(await page.locator('[data-ambient-layer]').count(), 4);
    await assertRetained(page);
    assert.deepEqual(await page.evaluate(() => levels), forest.levels);
  }
});

test('paused mini-player reopens without resuming and paused volume edits keep position', async t => {
  const { page, audioRequests } = await open(t);
  await startForest(page);
  await page.locator('#ambient-pause').click();
  const positions = await page.evaluate(() => [...players.values()].map(audio => audio.currentTime));
  await page.locator('#ambient-minimize').click();
  assert.equal(await page.locator('#shared-mini-player').isVisible(), true);
  assert.match(await page.locator('#mini-subtitle').textContent(), /Paused/);
  await page.locator('#mini-open').click();
  const slider = page.locator('[data-ambient-layer="Woodland Morning"] input');
  await slider.focus(); await slider.press('ArrowLeft');
  assert.equal(await slider.inputValue(), '64');
  assert.equal(await slider.evaluate(node => document.activeElement === node), true, 'Layer updates do not replace the focused slider');
  await page.waitForTimeout(160);
  assert.equal(await page.evaluate(() => playing), false);
  assert.deepEqual(await page.evaluate(() => [...players.values()].map(audio => audio.currentTime)), positions);
  assert.equal(await page.locator('[data-ambient-layer="Woodland Morning"] output').textContent(), '64%');
  const requests = audioRequests.length;
  await page.locator('#ambient-minimize').click();
  await page.locator('#mini-pause').click();
  await page.waitForFunction(() => ambientPlaybackState().active.length === 4);
  assert.equal(await page.locator('#ambient-dialog').isVisible(), false, 'Mini transport resumes without unexpectedly expanding');
  assert.equal(audioRequests.length, requests, 'Ready decoded buffers are reused on resume');
  assert.equal(await page.evaluate(() => levels['Woodland Morning']), .64);
});

test('a deliberate Sounds-slider start still resumes a user-paused mix without undoing minimize', async t => {
  const { page } = await open(t);
  await startForest(page);
  await page.locator('#ambient-pause').click();
  await page.locator('#ambient-minimize').click();
  assert.equal(await page.evaluate(() => playing), false);
  const slider = page.locator('[data-track="Meadow Breeze"] input');
  await slider.focus(); await slider.press('ArrowRight');
  await page.waitForFunction(() => ambientPlaybackState().active.length === 4, null, { timeout: 5000 });
  assert.equal(await page.evaluate(() => levels['Meadow Breeze']), .26);
  assert.equal(await page.locator('#ambient-dialog').isVisible(), false);
  assert.equal(await page.locator('#shared-mini-player').isVisible(), true);
});

test('customization updates real gains, saves separately and never auto-expands on later slider changes', async t => {
  const { page } = await open(t);
  await startForest(page); await rememberAudio(page);
  const slider = page.locator('[data-ambient-layer="Meadow Breeze"] input');
  await slider.focus(); await slider.press('ArrowRight');
  assert.equal(await slider.inputValue(), '26');
  assert.equal(await page.locator('[data-ambient-layer="Meadow Breeze"] output').textContent(), '26%');
  assert.equal(await page.evaluate(() => selectedPreset), null);
  await assertRetained(page);
  await page.locator('#ambient-save').click();
  await page.locator('#mix-name').fill('My morning forest');
  await page.locator('#save-form button[type=submit]').click();
  assert.deepEqual(await page.evaluate(() => saved[0]), { name: 'My morning forest', levels: { ...forest.levels, 'Meadow Breeze': .26 } });
  assert.deepEqual(await page.evaluate(() => VIBE_SETS[1].levels), forest.levels);
  await page.locator('#ambient-minimize').click();
  await page.locator('[data-track="Meadow Breeze"] input').evaluate(slider => { slider.value = 27; slider.dispatchEvent(new Event('input', { bubbles: true })); });
  assert.equal(await page.locator('#ambient-dialog').isVisible(), false);
  await page.locator('#mini-open').click();
  assert.equal(await page.locator('[data-ambient-layer="Meadow Breeze"] output').textContent(), '27%');
  await assertRetained(page);
});

test('failed layers stay inspectable at their selected levels and retry only their original recording', async t => {
  const { page, context, audioRequests } = await open(t);
  await context.route('**/assets/sounds/cafe_ambience.mp3', route => route.abort());
  await page.locator('[data-vibe-set="rainy-window-cafe"]').click();
  await page.waitForFunction(() => ambientPlaybackState().active.length === 3 && ambientPlaybackState().failed.length === 1);
  const coffee = page.locator('[data-ambient-layer="Coffee Shop"]');
  assert.equal(await coffee.locator('output').textContent(), '25%');
  assert.match(await coffee.locator('small').textContent(), /Unavailable/);
  assert.match(await page.locator('#ambient-status').textContent(), /3 layers.*1 unavailable/);
  await rememberAudio(page);
  await context.unroute('**/assets/sounds/cafe_ambience.mp3');
  await coffee.getByRole('button', { name: 'Retry Coffee Shop', exact: true }).click();
  await page.waitForFunction(() => ambientPlaybackState().active.length === 4);
  await assertRetained(page);
  assert.deepEqual(await page.evaluate(() => levels), recipes[0].levels);
  assert.equal(audioRequests.filter(url => url.endsWith('cafe_ambience.mp3')).length, 2);
  assert(audioRequests.every(url => /\/(loop_soft_rain|cafe_ambience|noise_brown|loop_wind_chimes)\.mp3$/.test(url)));
});

test('pending audio has truthful layer status and a reachable cancel that fences late playback', async t => {
  const { page, context } = await open(t, { route: '/#sleep' });
  let release;
  const gate = new Promise(resolve => { release = resolve; });
  t.after(() => release());
  await context.route('**/assets/sounds/loop_ocean_waves.mp3', async route => { await gate; try { await route.continue(); } catch (_) {} });
  await page.locator('[data-quick="Ocean"]').click();
  assert.equal(await page.locator('#ambient-dialog').isVisible(), true);
  assert.match(await page.locator('[data-ambient-layer="Ocean Waves"] small').textContent(), /Preparing/);
  assert.doesNotMatch(await page.locator('#ambient-status').textContent(), /^Playing/);
  await page.evaluate(() => { window.cancelledLoop = players.get('Ocean Waves'); });
  await page.locator('#ambient-minimize').click();
  assert.equal(await page.locator('#shared-mini-player').isVisible(), true);
  assert.equal(await page.locator('#mini-pause').getAttribute('aria-label'), 'Cancel sound loading');
  await page.locator('#mini-pause').click();
  release(); await page.waitForLoadState('networkidle');
  assert.equal(await page.evaluate(() => cancelledLoop.paused && !cancelledLoop.sourceNode), true);
  assert.equal(await page.evaluate(() => ambientPlaybackState().active.length), 0);
  await page.locator('#mini-open').click();
  assert.equal(await page.locator('[data-ambient-layer="Ocean Waves"] output').textContent(), '60%');
  assert.match(await page.locator('[data-ambient-layer="Ocean Waves"] small').textContent(), /Paused/);
});

test('loading deadline renews on progress but still rejects stalled or indefinitely slow requests', async t => {
  const { page, context } = await open(t, { route: '/#sleep', virtualClock: true });
  let release;
  const gate = new Promise(resolve => { release = resolve; });
  t.after(() => release());
  await context.route('**/assets/sounds/loop_ocean_waves.mp3', async route => { await gate; try { await route.continue(); } catch (_) {} });
  await page.locator('[data-quick="Ocean"]').click();
  // Deliberately synthetic progress events test timer fencing, not real network
  // quality. The separate measured before/after run uses actual throttling.
  for (let step = 0; step < 11; step++) {
    await page.clock.fastForward(15000);
    assert.equal(await page.evaluate(() => ambientTrackStatus('Ocean Waves')), 'loading');
    await page.evaluate(() => players.get('Ocean Waves').dispatchEvent(new Event('progress')));
  }
  await page.clock.fastForward(15001);
  assert.equal(await page.evaluate(() => ambientTrackStatus('Ocean Waves')), 'error', 'Three-minute absolute cap survives repeated progress');
  assert.match(await page.locator('[data-ambient-layer="Ocean Waves"] small').textContent(), /Unavailable/);
  release(); await page.waitForLoadState('networkidle');
  assert.equal(await page.evaluate(() => ambientPlaybackState().active.length), 0);
});

test('all four real decoded recordings cross a loop boundary on their unchanged audio-clock nodes', async t => {
  const { page, audioRequests } = await open(t);
  await startForest(page);
  await page.evaluate(() => {
    window.boundaryEvents = [];
    window.boundaryNodes = [];
    for (const [name, audio] of players) {
      // Seek only for this test, then capture the node before the real boundary.
      audio.currentTime = audio.duration - .12;
      boundaryNodes.push({ name, audio, node: audio.sourceNode });
      for (const event of ['waiting', 'seeking', 'seeked', 'pause', 'error', 'ended']) audio.addEventListener(event, () => boundaryEvents.push({ name, event }));
    }
  });
  const requests = audioRequests.length;
  await page.waitForTimeout(500);
  assert.deepEqual(await page.evaluate(() => boundaryEvents), []);
  assert.equal(await page.evaluate(() => boundaryNodes.every(({ name, audio, node }) => players.get(name) === audio && audio.sourceNode === node && audio.currentTime > 0 && audio.currentTime < 1 && node.loop && audio.readyState === 4 && !audio.paused)), true);
  assert.equal(audioRequests.length, requests, 'Loop boundary fetches no bytes and performs no restart');
  assert.equal(await page.evaluate(() => ambientPlaybackState().active.length), 4);
});

test('audio-clock suspension removes Playing and Resume unlocks the same nodes without seeking', async t => {
  const { page } = await open(t);
  await startForest(page);
  await page.evaluate(() => { window.suspendedNodes = [...players.values()].map(audio => audio.sourceNode); });
  await page.evaluate(() => ambientLoopEngine.context.suspend());
  await page.waitForFunction(() => ambientPlaybackState().active.length === 0);
  assert.doesNotMatch(await page.locator('#ambient-status').textContent(), /^Playing/);
  assert.equal(await page.locator('#ambient-pause').getAttribute('aria-label'), 'Resume soundscape');
  await page.locator('#ambient-pause').click();
  await page.waitForFunction(() => ambientPlaybackState().active.length === 4);
  assert.equal(await page.evaluate(() => [...players.values()].every((audio, index) => audio.sourceNode === suspendedNodes[index])), true);
});

test('volume edits do not unlock an interrupted audio clock; explicit Resume retains every node', async t => {
  const { page, audioRequests } = await open(t);
  await startForest(page);
  await page.evaluate(() => { window.interruptedLoops = [...players.values()].map(audio => ({ audio, node: audio.sourceNode })); });
  await page.evaluate(() => ambientLoopEngine.context.suspend());
  await page.waitForFunction(() => ambientPlaybackState().active.length === 0);
  const positions = await page.evaluate(() => interruptedLoops.map(({ audio }) => audio.currentTime));
  const requests = audioRequests.length;
  const slider = page.locator('[data-ambient-layer="Meadow Breeze"] input');
  await slider.focus(); await slider.press('ArrowRight');
  await page.waitForTimeout(150);
  assert.equal(await slider.inputValue(), '26');
  assert.equal(await page.evaluate(() => ambientLoopEngine.context.state), 'suspended', 'A volume gesture is not permission to resume interrupted audio');
  assert.equal(await page.evaluate(() => ambientPlaybackState().active.length), 0);
  assert.deepEqual(await page.evaluate(() => interruptedLoops.map(({ audio }) => audio.currentTime)), positions);
  assert.equal(audioRequests.length, requests);
  await page.locator('#ambient-pause').click();
  await page.waitForFunction(() => ambientPlaybackState().active.length === 4);
  assert.equal(await page.evaluate(() => interruptedLoops.every(({ audio, node }) => audio.sourceNode === node)), true);
  assert.equal(await page.evaluate(() => levels['Meadow Breeze']), .26);
});

test('canceling auto-fade does not resume interrupted audio or replace its retained nodes', async t => {
  const { page } = await open(t);
  await startForest(page);
  await page.locator('#ambient-timer').click();
  await page.locator('#timer-minutes').fill('30');
  await page.locator('#timer-form button[type=submit]').click();
  await page.evaluate(() => { window.interruptedNodes = [...players.values()].map(audio => audio.sourceNode); });
  await page.evaluate(() => ambientLoopEngine.context.suspend());
  await page.waitForFunction(() => ambientPlaybackState().active.length === 0);
  await page.locator('#ambient-timer').click();
  await page.waitForTimeout(150);
  assert.equal(await page.evaluate(() => sleepDeadline), null);
  assert.equal(await page.evaluate(() => ambientLoopEngine.context.state), 'suspended', 'Canceling a timer changes gain/deadline only');
  assert.equal(await page.evaluate(() => ambientPlaybackState().active.length), 0);
  assert.equal(await page.evaluate(() => [...players.values()].every((audio, index) => audio.sourceNode === interruptedNodes[index])), true);
  assert.equal(await page.locator('#ambient-pause').getAttribute('aria-label'), 'Resume soundscape');
});

test('level edits keep two failed layers failed until their own explicit Retry', async t => {
  const { page, context, audioRequests } = await open(t);
  for (const file of ['woodland_morning', 'loop_forest_birds']) await context.route(`**/assets/sounds/${file}.mp3`, route => route.abort());
  await page.locator(`[data-vibe-set="${forest.id}"]`).click();
  await page.waitForFunction(() => ambientPlaybackState().active.length === 2 && ambientPlaybackState().failed.length === 2);
  await rememberAudio(page);
  const requests = audioRequests.length;
  const meadow = page.locator('[data-ambient-layer="Meadow Breeze"] input');
  await meadow.focus(); await meadow.press('ArrowRight');
  const woodland = page.locator('[data-ambient-layer="Woodland Morning"] input');
  await woodland.focus(); await woodland.press('ArrowLeft');
  await page.waitForTimeout(150);
  assert.equal(audioRequests.length, requests, 'Neither a healthy nor a failed slider retries a recording');
  assert.equal(await page.evaluate(() => ambientPlaybackState().failed.length), 2);
  assert.equal(await woodland.inputValue(), '64');
  await assertRetained(page);
  await context.unroute('**/assets/sounds/woodland_morning.mp3');
  await page.getByRole('button', { name: 'Retry Woodland Morning', exact: true }).click();
  await page.waitForFunction(() => ambientPlaybackState().active.length === 3);
  assert.equal(await page.evaluate(() => ambientPlaybackState().failed.length), 1);
  assert.equal(audioRequests.length, requests + 1);
  assert.equal(await page.evaluate(() => levels['Woodland Morning']), .64);
  await assertRetained(page);
});

test('media-element fallback gain edits do not restart a platform-paused layer', async t => {
  const { page } = await open(t, { fallback: true });
  await startForest(page);
  await page.evaluate(() => {
    window.interruptedMedia = players.get('Forest Birds');
    interruptedMedia.pause();
    window.interruptedPlayCalls = 0;
    const play = interruptedMedia.play.bind(interruptedMedia);
    interruptedMedia.play = (...args) => { interruptedPlayCalls++; return play(...args); };
  });
  await page.waitForFunction(() => ambientPlaybackState().active.length === 3);
  const slider = page.locator('[data-ambient-layer="Meadow Breeze"] input');
  await slider.focus(); await slider.press('ArrowRight');
  await page.waitForTimeout(150);
  assert.equal(await page.evaluate(() => interruptedMedia.paused), true);
  assert.equal(await page.evaluate(() => interruptedPlayCalls), 0);
  assert.equal(await page.evaluate(() => ambientPlaybackState().active.length), 3);
  assert.equal(await page.locator('[data-ambient-layer="Forest Birds"] small').textContent(), 'Paused');
});

test('closed audio context is a retryable failure rather than false Playing', async t => {
  const { page } = await open(t);
  await startForest(page);
  await page.evaluate(() => ambientLoopEngine.context.close());
  await page.waitForFunction(() => ambientPlaybackState().failed.length === 4);
  assert.doesNotMatch(await page.locator('#ambient-status').textContent(), /^Playing/);
  await page.locator('#ambient-pause').click();
  await page.waitForFunction(() => ambientPlaybackState().active.length === 4);
  assert.deepEqual(await page.evaluate(() => levels), forest.levels);
});

test('PCM cache cannot evict active loops and releases inactive buffers under its memory budget', async t => {
  const { page } = await open(t);
  await startForest(page); await rememberAudio(page);
  await page.evaluate(() => { ambientLoopEngine.cacheBudget = 1; ambientLoopEngine.trim(); });
  await assertRetained(page);
  assert.equal(await page.evaluate(() => ambientLoopEngine.cache.size), 4);
  await page.locator('#ambient-pause').click();
  assert.equal(await page.evaluate(() => ambientLoopEngine.cache.size), 0);
  assert.equal(await page.evaluate(() => [...players.values()].every(audio => audio.paused && !audio.sourceNode && !audio._buffer)), true);
});

test('browsers without Web Audio keep the same local media source and the full-player flow', async t => {
  const { page, audioRequests } = await open(t, { fallback: true });
  await page.locator('#master-play').click();
  await page.waitForFunction(() => ambientPlaybackState().active.length === 1);
  assert.equal(await page.locator('#ambient-dialog').isVisible(), true);
  assert.equal(await page.evaluate(() => players.get('Soft Rain').backend), 'media-element');
  const url = await page.evaluate(() => players.get('Soft Rain').currentSrc);
  await page.locator('#ambient-minimize').click(); await page.locator('#mini-open').click();
  assert.equal(await page.evaluate(() => players.get('Soft Rain').currentSrc), url);
  assert.deepEqual([...new Set(audioRequests)], ['/assets/sounds/loop_soft_rain.mp3']);
});

test('switching session modes closes the other full view and never overlaps their audio', async t => {
  const { page } = await open(t, { route: '/#meditate' });
  await page.locator('#begin-gentle-relief').click();
  await page.waitForFunction(() => guidedSession?.playing && !guidedAudio.paused);
  await page.locator('#session-minimize').click();
  await page.locator('.bottom-nav [data-tab="sounds"]').click();
  await startForest(page);
  assert.equal(await page.evaluate(() => guidedAudio.paused && !guidedSession.playing && !guidedSession.loading), true);
  assert.equal(await page.locator('#session-dialog').isVisible(), false);
  await page.locator('#ambient-minimize').click();
  await page.locator('.bottom-nav [data-tab="meditate"]').click();
  await page.locator('#begin-quiet-mind').click();
  await page.waitForFunction(() => guidedSession?.playing && !guidedAudio.paused);
  assert.equal(await page.evaluate(() => [...players.values()].every(audio => audio.paused)), true);
  assert.equal(await page.locator('#ambient-dialog').isVisible(), false);
  assert.deepEqual(await page.evaluate(() => levels), forest.levels);
});

test('Sleep opens the same player, its timer is editable, and timer expiry dismisses playback truthfully', async t => {
  const { page } = await open(t, { route: '/#sleep', virtualClock: true });
  await page.locator('#begin-ocean').click();
  await page.waitForFunction(() => ambientPlaybackState().active.length === 2);
  assert.equal(await page.locator('#ambient-title').textContent(), 'Ocean Sleep');
  assert.match(await page.locator('#ambient-timer').getAttribute('aria-label'), /Cancel auto-fade timer/);
  await page.locator('#ambient-timer').click();
  assert.equal(await page.evaluate(() => sleepDeadline), null);
  await page.locator('#ambient-timer').click();
  await page.locator('#timer-minutes').fill('1');
  await page.locator('#timer-form button[type=submit]').click();
  await page.clock.fastForward(31000);
  assert.equal(await page.evaluate(() => players.get('Ocean Waves').volume < .7), true);
  await page.clock.fastForward(31000);
  assert.equal(await page.locator('#ambient-dialog').isVisible(), false);
  assert.equal(await page.locator('#shared-mini-player').isVisible(), false);
  assert.equal(await page.evaluate(() => ambientPlaybackState().active.length), 0);
  assert.equal(await page.evaluate(() => sleepDeadline), null);
});

for (const entry of ['Home', 'Master', 'Shuffle', 'Saved']) {
  test(`${entry} mix entry point opens the ambient player automatically`, async t => {
    const stored = { levels: { 'Soft Rain': .31 }, favorites: [], saved: [{ name: 'Kept forest', levels: forest.levels }] };
    const { page } = await open(t, { route: entry === 'Home' ? '/#home' : '/#sounds', stored });
    if (entry === 'Saved') {
      await page.getByRole('button', { name: 'Saved mixes (1)', exact: true }).click();
      await page.getByRole('button', { name: 'Kept forest', exact: true }).click();
    } else await page.locator({ Home: '#home-mix-toggle', Master: '#master-play', Shuffle: '#shuffle' }[entry]).click();
    assert.equal(await page.locator('#ambient-dialog').isVisible(), true);
    assert.equal(await page.evaluate(() => document.querySelectorAll('dialog:modal').length), 1, 'Closed saved chooser does not cover the new player');
    assert.equal(await page.locator('[data-ambient-layer]').count(), entry === 'Saved' ? 4 : entry === 'Shuffle' ? 3 : 1);
  });
}

for (const [width, height] of [[320, 640], [390, 844], [823, 1568], [1440, 1000], [844, 390]]) {
  test(`full ambient player is scrollable, keyboard contained and font-independent at ${width}×${height}`, async t => {
    const { page } = await open(t, { width, height, blockFonts: true });
    await startForest(page);
    await page.locator('#ambient-dialog').evaluate(node => {
      for (const text of node.querySelectorAll('h2, h3, p, strong, small, output, button > span, .player-stream span')) {
        text.style.fontSize = `${parseFloat(getComputedStyle(text).fontSize) * 1.6}px`;
      }
    });
    assert.equal(await page.locator('#ambient-dialog').evaluate(node => node.scrollWidth <= node.clientWidth), true);
    assert.equal((await page.locator('#ambient-dialog').boundingBox()).width, Math.min(width, 823));
    assert.equal((await page.locator('#ambient-dialog').boundingBox()).height, height);
    await page.keyboard.press('Tab');
    for (const selector of ['#ambient-minimize', '#ambient-pause', '#ambient-timer', '#ambient-edit', '[data-ambient-layer="Meadow Breeze"] input', '[data-ambient-layer="Meadow Breeze"] .ambient-layer-remove', '#ambient-save', '#ambient-stop']) {
      const control = page.locator(selector);
      await control.scrollIntoViewIfNeeded();
      const box = await control.boundingBox();
      assert(box.width >= 44 && box.height >= 44, `${selector} keeps a 44px target`);
      await control.focus();
      assert.equal(await control.evaluate(node => document.activeElement === node), true);
      assert.equal(await control.evaluate(node => getComputedStyle(node).outlineStyle), 'solid', `${selector} has a visible keyboard focus ring`);
    }
    for (let step = 0; step < 32; step++) {
      await page.keyboard.press('Tab');
      assert.equal(await page.evaluate(() => ambientDialog.contains(document.activeElement)), true, 'Keyboard focus stays in the modal, not the tabs behind it');
    }
    await rememberAudio(page);
    await page.keyboard.press('Escape');
    assert.equal(await page.locator('#ambient-dialog').isVisible(), false);
    assert.equal(await page.locator('#shared-mini-player').isVisible(), true);
    await assertRetained(page);
  });
}

test('decorative waveform stops behind players, other tabs and offscreen without stopping audio', async t => {
  const { page } = await open(t, { reducedMotion: 'no-preference' });
  await page.locator('#master-play').click();
  await page.waitForFunction(() => ambientPlaybackState().active.length === 1);
  assert.equal(await page.evaluate(() => waveFrame), null);
  await rememberAudio(page);
  await page.locator('#ambient-minimize').click();
  await page.waitForFunction(() => waveFrame !== null);
  await page.locator('.bottom-nav [data-tab="sleep"]').click();
  assert.equal(await page.evaluate(() => waveFrame), null);
  await page.locator('.bottom-nav [data-tab="sounds"]').click();
  await page.evaluate(() => scrollTo(0, document.documentElement.scrollHeight));
  await page.waitForFunction(() => waveFrame === null);
  await page.emulateMedia({ reducedMotion: 'reduce' });
  await assertRetained(page);
});

test('removing the final layer or pressing Stop dismisses the player and cannot revive on a later event', async t => {
  const { page } = await open(t);
  await page.locator('#master-play').click();
  await page.waitForFunction(() => ambientPlaybackState().active.length === 1);
  await page.evaluate(() => { window.stoppedAmbient = players.get('Soft Rain'); });
  await page.getByRole('button', { name: 'Remove Soft Rain from mix', exact: true }).click();
  assert.equal(await page.locator('#ambient-dialog').isVisible(), false);
  assert.equal(await page.locator('#shared-mini-player').isVisible(), false);
  assert.equal(await page.evaluate(() => stoppedAmbient.paused), true);
  await page.locator('#master-play').click();
  await page.waitForFunction(() => ambientPlaybackState().active.length === 1);
  await page.locator('#ambient-stop').click();
  assert.equal(await page.locator('#ambient-dialog').isVisible(), false);
  assert.equal(await page.locator('#shared-mini-player').isVisible(), false);
  await page.evaluate(() => stoppedAmbient.dispatchEvent(new Event('playing')));
  assert.equal(await page.evaluate(() => stoppedAmbient.paused && !playing), true);
});

test('native ambient view reuses shared presentation and mixer APIs, not a view-owned audio engine', async () => {
  const [part, controller, state, shell, home, sounds, visibility] = await Promise.all(['lib/components/ambient_player.dart', 'lib/providers/mixer_controller.dart', 'lib/providers/app_state.dart', 'lib/main.dart', 'lib/screens/home_screen.dart', 'lib/screens/sounds_screen.dart', 'lib/services/pwa_player_visibility_web.dart'].map(file => readFile(path.join(root, file), 'utf8')));
  assert.match(part, /part of 'guided_player.dart'/);
  assert.match(part, /mixer\.levels\.entries/);
  assert.match(part, /mixer\.setVolume\(name, value, preservePaused: true\)/);
  assert.match(part, /app\.ambientTrackStatus\(name\)/);
  assert.match(part, /app\.minimizeAmbientPlayer/);
  assert.match(part, /_BreathingArtwork\(/);
  assert.doesNotMatch(part, /AudioPlayer\(|setAsset\(|setUrl\(|seekGuidedSession\(/);
  assert.match(controller, /if \(expandPlayer\) _app\.showAmbientPlayer\(\)/);
  assert.match(controller, /_app\.pauseAllAmbientSoundTracks\(\)/);
  assert.match(controller, /retryFailed: false/);
  assert.match(controller, /resumePaused: !hasPlaybackRequest/);
  assert.match(state, /if \(resumePaused && !_loadingTracks\.contains\(name\)\)/);
  assert.match(state, /bool expandPlayer = true/);
  assert.match(state, /if \(!_hasAmbientSession\) \{\s*_hasAmbientSession = true;\s*_isAmbientPlayerExpanded = expandPlayer;/);
  assert.match(controller, /resumePaused: resumePaused,[\s\S]*?expandPlayer: false/);
  assert.match(controller, /updateSoundTrackVolume\(name, volume\(name\), expandPlayer: false\)/);
  assert.match(state, /await player\.setLoopMode\(LoopMode\.one\)/);
  assert.match(shell, /state\.isAmbientPlayerExpanded/);
  assert.match(shell, /AmbientPlayerOverlay\(\)/);
  assert.match(home, /app\.hasGuidedSession \|\|\s*app\.hasAmbientSession/);
  assert.match(sounds, /state\.hasGuidedSession \|\|\s*state\.hasAmbientSession/);
  assert.match(visibility, /_playerOwners\.isNotEmpty/);
});

async function toggleSoundInline(page, name) {
  const control = page.getByRole('switch', { name: `Enable ${name}`, exact: true });
  await control.evaluate(node => node.scrollIntoView({ block: 'center' }));
  await control.click();
}
async function assertInlineSoundPlayer(page) {
  assert.equal(new URL(page.url()).hash, '#sounds');
  assert.equal(await page.locator('main.content').isVisible(), true);
  assert.equal(await page.locator('.bottom-nav [aria-current="page"]').getAttribute('data-tab'), 'sounds');
  assert.equal(await page.locator('#ambient-dialog').isVisible(), false, 'A sound toggle/level edit is not a request to open the full player');
  assert.equal(await page.locator('#session-dialog').isVisible(), false);
  assert.equal(await page.locator('#shared-mini-player').isVisible(), true);
  assert.equal(await page.locator('.install-entry').count(), 0, 'Inline playback does not recreate the removed install control');
  assert.equal(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth), true);
}
for (const width of [320, 390, 823]) {
  test(`Sounds switches keep the exact Soft Rain + Fireplace example inline at ${width}px`, async t => {
    const { page, audioRequests } = await open(t, { width });
    await toggleSoundInline(page, 'Fireplace');
    await page.waitForFunction(() => ambientPlaybackState().active.length === 2);
    await assertInlineSoundPlayer(page);
    assert.deepEqual(await page.evaluate(() => levels), { 'Soft Rain': .3, 'Fireplace': .3 });
    assert.equal(await page.locator('#mini-title').textContent(), 'Soft Rain + 1 more');
    assert.match(await page.locator('#mini-subtitle').textContent(), /Playing · 2 layers/);
    const mini = await page.locator('#shared-mini-player').boundingBox();
    const footer = await page.locator('.bottom-nav').boundingBox();
    assert(mini.y + mini.height <= footer.y - 8);
    await rememberAudio(page);
    const requests = audioRequests.length;
    await page.locator('#mini-open').click();
    assert.equal(await page.locator('#ambient-dialog').isVisible(), true, 'The full player is still available by explicit request');
    assert.equal(await page.locator('[data-ambient-layer]').count(), 2);
    assert.equal(await page.locator('[data-ambient-layer="Fireplace"] output').textContent(), '30%');
    await assertRetained(page);
    await page.locator('#ambient-minimize').click();
    await assertInlineSoundPlayer(page);
    await assertRetained(page);
    assert.equal(audioRequests.length, requests, 'Opening/minimizing does not fetch audio again');
  });
}

test('first, additional and re-enabled sound switches remain inline without restarting an unchanged loop', async t => {
  const { page } = await open(t, { stored: { levels: {}, favorites: ['Fireplace'], saved: [] } });
  await toggleSoundInline(page, 'Soft Rain');
  await page.waitForFunction(() => ambientPlaybackState().active.length === 1);
  await assertInlineSoundPlayer(page);
  await rememberAudio(page);
  await toggleSoundInline(page, 'Fireplace');
  await page.waitForFunction(() => ambientPlaybackState().active.length === 2);
  await assertInlineSoundPlayer(page);
  await assertRetained(page);
  await toggleSoundInline(page, 'Fireplace');
  await page.waitForFunction(() => ambientPlaybackState().active.length === 1);
  await assertInlineSoundPlayer(page);
  await assertRetained(page);
  await toggleSoundInline(page, 'Soft Rain');
  assert.equal(await page.evaluate(() => playing || ambientHasSession), false);
  assert.equal(await page.locator('#shared-mini-player').isVisible(), false);
  assert.equal(await page.locator('#ambient-dialog').isVisible(), false);
  await toggleSoundInline(page, 'Fireplace');
  await page.waitForFunction(() => ambientPlaybackState().active.length === 1);
  await assertInlineSoundPlayer(page);
  assert.deepEqual(await page.evaluate(() => Object.fromEntries(Object.entries(levels).filter(([, value]) => value > 0))), { 'Fireplace': .3 });
  assert.deepEqual(await page.evaluate(() => [...favorites]), ['Fireplace']);
  await page.locator('#mini-pause').click();
  assert.equal(await page.evaluate(() => playing), false);
  assert.equal(await page.locator('#shared-mini-player').isVisible(), true);
  await page.locator('#mini-pause').click();
  await page.waitForFunction(() => ambientPlaybackState().active.length === 1);
  await assertInlineSoundPlayer(page);
});

test('a first Sounds slider gesture also stays inline and keeps keyboard focus', async t => {
  const { page } = await open(t);
  const slider = page.locator('[data-track="Soft Rain"] input[type="range"]');
  await slider.focus();
  await slider.press('ArrowRight');
  await page.waitForFunction(() => ambientPlaybackState().active.length === 1);
  await assertInlineSoundPlayer(page);
  assert.equal(await page.evaluate(() => levels['Soft Rain']), .31);
  assert.equal(await slider.evaluate(node => node === document.activeElement), true, 'No focus is stolen by a full-screen dialog');
});

test('canceling a first inline sound load never reveals the full player on late completion', async t => {
  const { page } = await open(t, { stored: { levels: {}, favorites: [], saved: [] } });
  let release;
  const allowed = new Promise(resolve => { release = resolve; });
  await page.route('**/assets/sounds/loop_soft_rain.mp3', async route => { await allowed; await route.continue().catch(() => {}); });
  t.after(release);
  await toggleSoundInline(page, 'Soft Rain');
  await page.waitForFunction(() => ambientPlaybackState().pending.length === 1);
  await assertInlineSoundPlayer(page);
  assert.equal(await page.locator('#mini-pause').getAttribute('aria-label'), 'Cancel sound loading');
  await page.evaluate(() => { window.cancelledInlineSound = players.get('Soft Rain'); });
  await toggleSoundInline(page, 'Soft Rain');
  assert.equal(await page.locator('#shared-mini-player').isVisible(), false);
  release();
  await page.waitForTimeout(140);
  await page.evaluate(() => cancelledInlineSound.dispatchEvent(new Event('playing')));
  assert.equal(await page.evaluate(() => playing || ambientHasSession || players.has('Soft Rain')), false);
  assert.equal(await page.locator('#ambient-dialog').isVisible(), false);
  assert.equal(await page.locator('#shared-mini-player').isVisible(), false);
});

test('a first toggle failure stays inline and its same-source retry does not restart healthy audio', async t => {
  const { page, audioRequests } = await open(t);
  await page.route('**/assets/sounds/fireplace.mp3', route => route.abort());
  await toggleSoundInline(page, 'Fireplace');
  await page.waitForFunction(() => ambientPlaybackState().active.length === 1 && ambientPlaybackState().failed.length === 1);
  await assertInlineSoundPlayer(page);
  assert.deepEqual(await page.evaluate(() => levels), { 'Soft Rain': .3, 'Fireplace': .3 });
  await rememberAudio(page);
  await page.unroute('**/assets/sounds/fireplace.mp3');
  await page.locator('#mini-open').click();
  assert.equal(await page.locator('#ambient-dialog').isVisible(), true);
  await page.getByRole('button', { name: 'Retry Fireplace', exact: true }).click();
  await page.waitForFunction(() => ambientPlaybackState().active.length === 2);
  await assertRetained(page);
  assert.equal(audioRequests.filter(url => url.endsWith('/fireplace.mp3')).length, 2, 'Retry uses the same selected recording');
  assert.equal(await page.locator('[data-ambient-layer="Fireplace"] output').textContent(), '30%');
});

test('a Sounds toggle replaces paused timed-session presentation with an inline mix, not another full screen', async t => {
  const { page } = await open(t, { route: '/#home' });
  await page.locator('#home-daily').click();
  await page.waitForFunction(() => guidedSession?.playing);
  await page.locator('#session-minimize').click();
  await page.locator('.bottom-nav [data-tab="sounds"]').click();
  await toggleSoundInline(page, 'Fireplace');
  await page.waitForFunction(() => ambientPlaybackState().active.length === 2);
  await assertInlineSoundPlayer(page);
  assert.equal(await page.evaluate(() => guidedAudio.paused && !guidedSession.playing), true);
  assert.equal(await page.locator('#mini-title').textContent(), 'Soft Rain + 1 more');
});

for (const edit of loopEdits) {
  test(`${edit.name} uses its real prepared PCM and repeats on one unchanged node`, async t => {
    const { page, audioRequests } = await open(t, { stored: { levels: { [edit.name]: .3 }, favorites: [], saved: [] } });
    await page.locator('#master-play').click();
    await page.waitForFunction(() => ambientPlaybackState().active.length === 1);
    const measured = await page.evaluate(async edit => {
      const audio = players.get(edit.name);
      const prepared = audio.sourceNode.buffer;
      const decoder = new OfflineAudioContext(2, 1, prepared.sampleRate);
      const response = await fetch(edit.source_asset);
      const original = await decoder.decodeAudioData(await response.arrayBuffer());
      function stats(buffer) {
        const channels = [];
        for (let channel = 0; channel < buffer.numberOfChannels; channel++) {
          const data = buffer.getChannelData(channel);
          let squares = 0, peak = 0;
          for (let i = 1; i < data.length; i++) {
            squares += (data[i] - data[i - 1]) ** 2;
            peak = Math.max(peak, Math.abs(data[i]));
          }
          const step = Math.sqrt(squares / (data.length - 1));
          channels.push({ jumpRatio: Math.abs(data[0] - data.at(-1)) / step, peak });
        }
        return { duration: buffer.duration, channels };
      }
      // Render the actual prepared AudioBuffer over its wrap, not just DOM
      // events. The reference concatenates decoded tail/head samples directly.
      const half = 2205, offline = new OfflineAudioContext(2, half * 2, prepared.sampleRate);
      const node = offline.createBufferSource();
      node.buffer = prepared;
      node.loop = true;
      node.connect(offline.destination);
      node.start(0, (prepared.length - half) / prepared.sampleRate);
      const output = await offline.startRendering();
      let maximumError = 0;
      for (let channel = 0; channel < 2; channel++) {
        const reference = prepared.getChannelData(channel), actual = output.getChannelData(channel);
        for (let i = 0; i < actual.length; i++) {
          const expected = reference[(prepared.length - half + i) % prepared.length];
          maximumError = Math.max(maximumError, Math.abs(actual[i] - expected));
        }
      }
      audio.currentTime = audio.duration - .12; // Seek only to exercise a real wrap in this test.
      window.editedBoundary = { audio, node: audio.sourceNode, events: [] };
      for (const event of ['waiting', 'seeking', 'pause', 'ended', 'error']) {
        audio.addEventListener(event, () => editedBoundary.events.push(event));
      }
      return { path: new URL(audio.currentSrc).pathname, volume: audio.volume,
        backend: audio.backend, original: stats(original), prepared: stats(prepared), maximumError };
    }, edit);
    assert.equal(measured.path, `/${edit.asset}`);
    assert.equal(measured.volume, .3, 'Requested percentages and gain behavior remain unchanged');
    assert.equal(measured.backend, 'decoded-loop');
    assert(Math.abs(measured.prepared.duration - edit.loop_seconds) < .001);
    assert(Math.abs(measured.original.duration - edit.input_seconds) < .001);
    assert(measured.maximumError < 1e-5, 'The rendered wrap adds no silent block or restart samples');
    assert(measured.prepared.channels.every(channel => channel.peak < .7 && Number.isFinite(channel.jumpRatio)));
    const before = Math.max(...measured.original.channels.map(channel => channel.jumpRatio));
    const after = Math.max(...measured.prepared.channels.map(channel => channel.jumpRatio));
    if (before > 6) assert(after < before * .5, 'Large encoded boundary steps are reduced, not merely rescheduled');
    const requests = audioRequests.length;
    await page.waitForTimeout(350);
    assert.deepEqual(await page.evaluate(() => editedBoundary.events), []);
    assert.equal(await page.evaluate(() => {
      const { audio, node } = editedBoundary;
      return audio.sourceNode === node && !audio.paused && audio.currentTime > 0 && audio.currentTime < .6;
    }), true);
    assert.equal(audioRequests.length, requests, 'Repeat uses the same prepared file without another fetch');
    assert.deepEqual(await page.evaluate(() => levels), { [edit.name]: .3 });
  });
}
