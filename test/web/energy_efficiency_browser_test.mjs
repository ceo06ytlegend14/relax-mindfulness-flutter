// Scheduling and audio-graph regressions for the independent HTML preview.
// Virtual time verifies deadlines, not device battery, thermal state or listening.
// Real-clock loop-retention measurements are recorded separately from this suite.
import assert from 'node:assert/strict';
import { createServer } from 'node:http';
import { readFile, realpath } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { after, before, test } from 'node:test';

const { chromium } = await import(process.env.PLAYWRIGHT_MODULE || 'playwright');
const root = path.resolve(fileURLToPath(new URL('../../', import.meta.url)));
const directory = path.join(root, 'design/preview');
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
async function open(t, { route = '/#sounds', reducedMotion = 'reduce' } = {}) {
  const context = await browser.newContext({ viewport: { width: 390, height: 844 }, reducedMotion });
  t.after(() => context.close());
  await context.addInitScript(() => {
    window.previewIntervals = 0;
    const interval = window.setInterval.bind(window);
    window.setInterval = (...args) => { previewIntervals++; return interval(...args); };
  });
  const page = await context.newPage();
  await page.clock.install({ time: new Date('2026-11-19T20:00:00Z') });
  const errors = [], audioRequests = [];
  page.on('pageerror', error => errors.push(error.message));
  page.on('request', request => { if (/\/assets\/sounds\/[^/?]+\.mp3/.test(request.url())) audioRequests.push(new URL(request.url()).pathname); });
  t.after(() => assert.deepEqual(errors, [], 'No unhandled browser errors'));
  await page.goto(origin + route, { waitUntil: 'networkidle' });
  return { page, context, audioRequests };
}
async function visibility(page, hidden) {
  await page.evaluate(hidden => {
    Object.defineProperty(document, 'hidden', { configurable: true, value: hidden });
    document.dispatchEvent(new Event('visibilitychange'));
  }, hidden);
}
async function clockState(page) {
  return page.evaluate(() => ({ session: sanctuaryClockTimer !== null, breathing: breathingClockTimer !== null, intervals: previewIntervals }));
}
async function startForest(page) {
  await page.locator('[data-vibe-set="enchanted-forest-morning"]').click();
  await page.waitForFunction(() => ambientPlaybackState().active.length === 4);
}
async function rememberLoops(page) {
  await page.evaluate(() => {
    window.energyLoops = [...players].filter(([name]) => levels[name] > 0).map(([name, audio]) => ({ name, audio, node: audio.sourceNode, level: levels[name] }));
  });
}
async function retainedLoops(page) {
  assert.equal(await page.evaluate(() => energyLoops.every(({ name, audio, node, level }) => players.get(name) === audio && audio.sourceNode === node && levels[name] === level && !audio.paused)), true, 'Healthy loops and exact selected levels survive UI/deadline changes');
}

test('idle pages allocate no periodic clock or audio graph, including after tab switches', async t => {
  const { page, audioRequests } = await open(t);
  for (const tab of ['home', 'sounds', 'meditate', 'sleep']) {
    await page.locator(`.bottom-nav [data-tab="${tab}"]`).click();
    await page.clock.runFor(12000);
    assert.deepEqual(await clockState(page), { session: false, breathing: false, intervals: 0 });
    assert.equal(await page.evaluate(() => ambientLoopEngine.context), null);
  }
  assert.deepEqual(audioRequests, []);
});

test('indefinite ambience needs no UI heartbeat and hiding it never pauses live loops', async t => {
  const { page, audioRequests } = await open(t);
  await startForest(page);
  await rememberLoops(page);
  const requests = audioRequests.length;
  await page.locator('#ambient-minimize').click();
  await visibility(page, true);
  await page.clock.runFor(120000);
  assert.deepEqual(await clockState(page), { session: false, breathing: false, intervals: 0 });
  assert.equal(await page.evaluate(() => ambientLoopEngine.context.state), 'running');
  assert.equal(audioRequests.length, requests);
  await retainedLoops(page);
  await visibility(page, false);
  await retainedLoops(page);
});

test('pausing every sound suspends the idle graph; Resume reuses decoded recordings', async t => {
  const { page, audioRequests } = await open(t);
  await page.locator('#master-play').click();
  await page.waitForFunction(() => ambientPlaybackState().active.length === 1);
  await page.evaluate(() => { window.energyRain = players.get('Soft Rain'); });
  await page.locator('#ambient-pause').click();
  const position = await page.evaluate(() => energyRain.currentTime);
  await page.clock.runFor(1100);
  await page.waitForFunction(() => ambientLoopEngine.context.state === 'suspended');
  assert.equal(await page.evaluate(() => ambientLoopEngine.idleTimer), null);
  assert.equal(await page.evaluate(() => ambientLoopEngine.cache.size), 1);
  assert.deepEqual(await clockState(page), { session: false, breathing: false, intervals: 0 });
  const requests = audioRequests.length;
  await page.locator('#ambient-pause').click();
  await page.waitForFunction(() => ambientPlaybackState().active.length === 1);
  assert.equal(await page.evaluate(() => players.get('Soft Rain') === energyRain), true);
  assert.equal(await page.evaluate(() => energyRain.currentTime) >= position, true);
  assert.equal(audioRequests.length, requests, 'Resume decodes/fetches no replacement');
});

test('paused gain edits do not keep postponing the idle-suspend grace', async t => {
  const { page } = await open(t);
  await page.locator('#master-play').click();
  await page.waitForFunction(() => ambientPlaybackState().active.length === 1);
  await page.locator('#ambient-pause').click();
  await page.evaluate(() => { window.energyIdleTimer = ambientLoopEngine.idleTimer; });
  for (let step = 0; step < 4; step++) {
    await page.clock.runFor(100);
    await page.evaluate(() => syncAudio());
    assert.equal(await page.evaluate(() => ambientLoopEngine.idleTimer === energyIdleTimer), true);
  }
  await page.clock.runFor(700);
  await page.waitForFunction(() => ambientLoopEngine.context.state === 'suspended');
  assert.equal(await page.evaluate(() => ambientPlaybackState().active.length), 0);
});

test('pausing only one layer must not suspend or restart other loops', async t => {
  const { page } = await open(t);
  await startForest(page);
  await page.evaluate(() => {
    window.energyHealthy = [...players].filter(([name]) => name !== 'Forest Birds').map(([, audio]) => ({ audio, node: audio.sourceNode }));
    players.get('Forest Birds').pause();
  });
  await page.clock.runFor(3000);
  assert.equal(await page.evaluate(() => ambientLoopEngine.context.state), 'running');
  assert.equal(await page.evaluate(() => ambientPlaybackState().active.length), 3);
  assert.equal(await page.evaluate(() => energyHealthy.every(({ audio, node }) => audio.sourceNode === node && !audio.paused)), true);
});

test('an idle-suspend grace cannot silence a new pending decode; cancellation eventually sleeps', async t => {
  const { page, context } = await open(t);
  await page.locator('#master-play').click();
  await page.waitForFunction(() => ambientPlaybackState().active.length === 1);
  await page.locator('#ambient-pause').click();
  await page.locator('#ambient-minimize').click();
  let release;
  const gate = new Promise(resolve => { release = resolve; });
  await context.route('**/assets/sounds/*.mp3', async route => { await gate; await route.continue(); });
  try {
    await page.locator('[data-vibe-set="enchanted-forest-morning"]').click();
    await page.waitForFunction(() => ambientPlaybackState().pending.length === 4);
    await page.clock.runFor(1500);
    assert.equal(await page.evaluate(() => ambientLoopEngine.context.state), 'running');
    await page.locator('#ambient-pause').click();
    await page.clock.runFor(1500);
    await page.waitForFunction(() => ambientLoopEngine.context.state === 'suspended');
    assert.equal(await page.evaluate(() => ambientPlaybackState().active.length), 0);
    release();
    await context.unrouteAll({ behavior: 'wait' });
    await page.waitForTimeout(100);
    assert.equal(await page.evaluate(() => ambientPlaybackState().active.length), 0);
    assert.equal(await page.evaluate(() => ambientLoopEngine.context.state), 'suspended');
  } finally { release(); }
});

test('failed recordings also release the unused rendering graph', async t => {
  const { page, context } = await open(t);
  await context.route('**/assets/sounds/*.mp3', route => route.abort());
  await page.locator('[data-vibe-set="enchanted-forest-morning"]').click();
  await page.waitForFunction(() => ambientPlaybackState().failed.length === 4);
  await page.clock.runFor(1100);
  await page.waitForFunction(() => ambientLoopEngine.context.state === 'suspended');
  assert.equal(await page.evaluate(() => ambientLoopEngine.idleTimer), null);
  assert.deepEqual(await clockState(page), { session: false, breathing: false, intervals: 0 });
});

test('breathing renders at the displayed second, with no paused or completed polling', async t => {
  const { page } = await open(t, { route: '/#wellbeing/breathing' });
  assert.deepEqual(await clockState(page), { session: false, breathing: false, intervals: 0 });
  await page.locator('[data-breathing-duration="1"]').click();
  await page.locator('#breathing-toggle').click();
  await page.evaluate(() => {
    window.energyBreathRenders = 0;
    const render = updateBreathing;
    updateBreathing = (...args) => { energyBreathRenders++; return render(...args); };
  });
  await page.clock.runFor(4100);
  const renders = await page.evaluate(() => energyBreathRenders);
  assert(renders >= 4 && renders <= 5, `${renders} renders in 4.1 seconds, not four every second`);
  await visibility(page, true);
  assert.deepEqual(await clockState(page), { session: false, breathing: false, intervals: 0 });
  const remaining = await page.evaluate(() => breathing.remaining);
  await page.clock.runFor(120000);
  assert.equal(await page.evaluate(() => breathing.remaining), remaining);
  assert.equal(await page.evaluate(() => previewBreaths.length), 0);
  await visibility(page, false);
  assert.equal(await page.locator('#breathing-toggle').textContent(), 'Resume practice');
  await page.locator('#breathing-toggle').click();
  await page.clock.runFor(61000);
  assert.equal(await page.evaluate(() => previewBreaths.length), 1);
  assert.deepEqual(await clockState(page), { session: false, breathing: false, intervals: 0 });
  await page.clock.runFor(120000);
  assert.equal(await page.evaluate(() => previewBreaths.length), 1);
});

test('timer ticks update clocks, not playback cards, artwork rows or the Home page', async t => {
  const { page } = await open(t, { route: '/#sleep' });
  await page.locator('#begin-ocean').click();
  await page.waitForFunction(() => ambientPlaybackState().active.length === 2);
  await page.evaluate(() => {
    setSleepTimer(3);
    window.energyFullRenders = 0;
    const renderSleep = updateSleepState, renderMini = updateMiniPlayer;
    updateSleepState = (...args) => { energyFullRenders++; return renderSleep(...args); };
    updateMiniPlayer = (...args) => { energyFullRenders++; return renderMini(...args); };
    window.energyMutations = 0;
    const observer = new MutationObserver(records => { energyMutations += records.length; });
    for (const id of ['quick-mixer', 'winddown-tray', 'practice-list', 'home-page', 'ambient-layers']) observer.observe($(id), { subtree: true, childList: true, attributes: true, characterData: true });
  });
  await page.clock.runFor(5100);
  assert.equal(await page.evaluate(() => energyFullRenders), 0);
  assert.equal(await page.evaluate(() => energyMutations), 0);
  assert.match(await page.locator('#ambient-timer span').textContent(), /^02:5\d · Cancel fade$/);
  assert.deepEqual(await clockState(page), { session: true, breathing: false, intervals: 0 });
});

test('hidden sleep clocks wait for the fade, preserve levels and still stop at the deadline', async t => {
  const { page } = await open(t, { route: '/#sleep' });
  await page.locator('#begin-ocean').click();
  await page.waitForFunction(() => ambientPlaybackState().active.length === 2);
  await rememberLoops(page);
  await page.evaluate(() => {
    setSleepTimer(3);
    window.energyTicks = 0;
    const tick = tickSanctuaryClock;
    tickSanctuaryClock = (...args) => { energyTicks++; return tick(...args); };
  });
  await visibility(page, true);
  await page.clock.runFor(120000);
  assert.equal(await page.evaluate(() => energyTicks), 0, 'No one-second background heartbeat before the final fade');
  await retainedLoops(page);
  await page.clock.runFor(45000);
  assert(Math.abs(await page.evaluate(() => players.get('Ocean Waves').volume) - .35) < .04);
  assert.deepEqual(await page.evaluate(() => levels), { 'Ocean Waves': .7, 'Soft Rain': .3 });
  await page.clock.runFor(15000);
  assert.equal(await page.evaluate(() => sleepDeadline), null);
  assert.equal(await page.evaluate(() => ambientPlaybackState().active.length), 0);
  assert.equal(await page.evaluate(() => previewBreaths.length), 0);
  assert.deepEqual(await clockState(page), { session: false, breathing: false, intervals: 0 });
});

test('a delayed browser deadline is reconciled immediately when visible again', async t => {
  const { page } = await open(t);
  await startForest(page);
  await page.evaluate(() => setSleepTimer(1));
  await visibility(page, true);
  // Move wall time without delivering the scheduled callback, modelling browser
  // suspension. Becoming visible must not grant another minute of playback.
  const later = await page.evaluate(() => Date.now() + 180000);
  await page.clock.setSystemTime(later);
  await visibility(page, false);
  assert.equal(await page.evaluate(() => sleepDeadline), null);
  assert.equal(await page.evaluate(() => ambientPlaybackState().active.length), 0);
  assert.deepEqual(await clockState(page), { session: false, breathing: false, intervals: 0 });
});

test('replacing then canceling a hidden timer cannot fire its former deadline', async t => {
  const { page } = await open(t);
  await startForest(page);
  await rememberLoops(page);
  await page.evaluate(() => setSleepTimer(1));
  await visibility(page, true);
  await page.clock.runFor(20000);
  await page.evaluate(() => setSleepTimer(2));
  await page.clock.runFor(41000);
  assert(Math.abs(await page.evaluate(() => timerRemaining()) - 79) < 1);
  await retainedLoops(page);
  await page.evaluate(() => cancelSleepTimer());
  await page.clock.runFor(180000);
  await retainedLoops(page);
  assert.deepEqual(await clockState(page), { session: false, breathing: false, intervals: 0 });
});

test('guided motion stops while minimized/hidden, and extension re-arms its background deadline', async t => {
  const { page } = await open(t, { route: '/#meditate', reducedMotion: 'no-preference' });
  await page.locator('#begin-gentle-relief').click();
  await page.waitForFunction(() => guidedSession?.playing && !guidedAudio.paused);
  assert.equal(await page.locator('#breathing-art').evaluate(node => node.classList.contains('is-breathing')), true);
  await page.locator('#session-minimize').click();
  assert.equal(await page.locator('#breathing-art').evaluate(node => node.classList.contains('is-breathing')), false);
  await visibility(page, true);
  await page.evaluate(() => {
    window.energyGuidedTicks = 0;
    const tick = tickSanctuaryClock;
    tickSanctuaryClock = (...args) => { energyGuidedTicks++; return tick(...args); };
  });
  await page.clock.runFor(120000);
  assert.equal(await page.evaluate(() => energyGuidedTicks), 0);
  assert.equal(await page.evaluate(() => guidedAudio.paused), false);
  await page.evaluate(() => $('session-extend').click());
  await page.clock.fastForward(900000);
  assert.equal(await page.evaluate(() => guidedSession.playing), true, 'The replaced original 15-minute deadline cannot end an extended session');
  await page.evaluate(() => pauseGuided());
  assert.deepEqual(await clockState(page), { session: false, breathing: false, intervals: 0 });
  await page.clock.runFor(120000);
  assert.equal(await page.evaluate(() => !!guidedSession && !guidedSession.playing), true);
  await visibility(page, false);
  await page.locator('#mini-open').click();
  assert.equal(await page.locator('#breathing-art').evaluate(node => node.classList.contains('is-breathing')), false);
});
