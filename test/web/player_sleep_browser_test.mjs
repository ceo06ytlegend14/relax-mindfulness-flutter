// Exercises the independent browser preview, not a compiled Flutter application.
import assert from 'node:assert/strict';
import { createServer } from 'node:http';
import { readFile, realpath } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { after, before, test } from 'node:test';

const { chromium } = await import(process.env.PLAYWRIGHT_MODULE || 'playwright');
const root = path.resolve(fileURLToPath(new URL('../../', import.meta.url)));
const directory = path.join(root, 'design/preview');
const mime = { '.html': 'text/html', '.js': 'text/javascript', '.json': 'application/manifest+json', '.css': 'text/css', '.png': 'image/png', '.webp': 'image/webp', '.ttf': 'font/ttf', '.mp3': 'audio/mpeg' };
let server;
let browser;
let origin;

before(async () => {
  server = createServer(async (request, response) => {
    try {
      const pathname = decodeURIComponent(new URL(request.url, 'http://test.invalid').pathname);
      const resolved = await realpath(path.join(directory, pathname === '/' ? 'index.html' : pathname.slice(1)));
      if (!resolved.startsWith(`${root}${path.sep}`)) throw new Error('Outside test repository');
      const bytes = await readFile(resolved);
      response.setHeader('Content-Type', mime[path.extname(resolved)] || 'application/octet-stream');
      response.setHeader('Cache-Control', 'no-store');
      response.setHeader('Accept-Ranges', 'bytes');
      const range = request.headers.range?.match(/^bytes=(\d+)-(\d*)$/);
      if (range) {
        const start = Number(range[1]);
        const end = Math.min(bytes.length - 1, range[2] ? Number(range[2]) : bytes.length - 1);
        if (start > end) { response.writeHead(416); return response.end(); }
        response.writeHead(206, { 'Content-Range': `bytes ${start}-${end}/${bytes.length}`, 'Content-Length': end - start + 1 });
        response.end(bytes.subarray(start, end + 1));
      } else {
        response.setHeader('Content-Length', bytes.length);
        response.end(bytes);
      }
    } catch (_) {
      response.writeHead(404);
      response.end('Not found');
    }
  });
  await new Promise(resolve => server.listen(0, '0.0.0.0', resolve));
  origin = `http://127.0.0.1:${server.address().port}`;
  browser = await chromium.launch({ headless: true, executablePath: process.env.CHROMIUM_PATH || undefined, args: ['--disable-dev-shm-usage'] });
});
after(async () => {
  await browser?.close();
  if (server) await new Promise(resolve => server.close(resolve));
});

async function open(t, { route = '/#sleep', width = 390, height = 844, blockFonts = false, blockAudio = false, virtualClock = false } = {}) {
  const context = await browser.newContext({ viewport: { width, height }, reducedMotion: 'reduce' });
  t.after(() => context.close());
  let fontsBlocked = 0;
  if (blockFonts) await context.route('**/*', route => {
    if (route.request().resourceType() === 'font') { fontsBlocked++; return route.abort(); }
    return route.continue();
  });
  if (blockAudio) await context.route('**/assets/sounds/calm_guided.mp3', route => route.abort());
  const page = await context.newPage();
  if (virtualClock) await page.clock.install({ time: new Date('2026-11-19T20:00:00Z') });
  const errors = [];
  page.on('pageerror', error => errors.push(error.message));
  t.after(() => assert.deepEqual(errors, [], 'No unhandled browser errors'));
  await page.goto(`${origin}${route}`, { waitUntil: 'networkidle' });
  await page.evaluate(() => document.fonts.ready);
  return { page, context, fontsBlocked: () => fontsBlocked };
}
async function begin(page, id = 'gentle-relief') {
  await page.locator(`#begin-${id}`).click();
  await page.waitForFunction(() => !!guidedSession?.playing && !guidedAudio.paused && guidedAudio.readyState >= 2);
}
async function beginOcean(page) {
  await page.locator('#begin-ocean').click();
  await page.waitForFunction(() => [...players.values()].filter(audio => !audio.paused && audio.readyState >= 2).length === 2);
}
async function pause(page) {
  await page.locator('#session-pause').click();
  assert.equal(await page.evaluate(() => guidedAudio.paused), true);
  assert.equal(await page.evaluate(() => guidedSession.playing), false);
}
async function seek(page, seconds) {
  await page.locator('#session-progress').evaluate((slider, seconds) => {
    slider.value = seconds;
    slider.dispatchEvent(new Event('input', { bubbles: true }));
    slider.dispatchEvent(new Event('change', { bubbles: true }));
  }, seconds);
}
async function svgPixels(locator) {
  return locator.evaluateAll(nodes => Promise.all(nodes.map(async node => {
    const clone = node.cloneNode(true);
    clone.setAttribute('xmlns', 'http://www.w3.org/2000/svg');
    clone.setAttribute('width', '64'); clone.setAttribute('height', '64');
    clone.style.color = getComputedStyle(node).color;
    const image = new Image();
    image.src = `data:image/svg+xml;charset=utf-8,${encodeURIComponent(new XMLSerializer().serializeToString(clone))}`;
    await image.decode();
    const canvas = document.createElement('canvas'); canvas.width = canvas.height = 64;
    const context = canvas.getContext('2d'); context.drawImage(image, 0, 0);
    const bytes = context.getImageData(0, 0, 64, 64).data;
    let visible = 0; let signature = 2166136261;
    for (let offset = 0; offset < bytes.length; offset++) {
      if (offset % 4 === 3 && bytes[offset] > 24) visible++;
      signature = Math.imul(signature ^ bytes[offset], 16777619);
    }
    return { visible, signature, width: node.getBoundingClientRect().width };
  })));
}

test('Sleep opens with moonlit artwork, five playlists and no fictional playback', async t => {
  const { page } = await open(t);
  assert.equal(await page.locator('#sleep-page').isVisible(), true);
  assert.match(await page.locator('.ocean-journey').evaluate(node => getComputedStyle(node, '::before').backgroundImage), /moonlit_shore\.webp/);
  assert.equal(await page.locator('[data-soundscape]').count(), 5);
  assert.equal(await page.locator('[data-quick]').count(), 5);
  assert.equal(await page.evaluate(() => playing), false);
  assert.equal(await page.evaluate(() => guidedSession), null);
  assert.equal(await page.locator('#shared-mini-player').isHidden(), true);
  assert.equal(await page.locator('#progress-label').textContent(), 'Level');
  assert.equal(await page.locator('#sleep-progress-value').textContent(), '30%');
  assert.equal(await page.locator('#sleep-timer-label').textContent(), 'Set Sleep Auto-Fade Timer');
});

for (const [width, height] of [[320, 640], [390, 844], [823, 1568], [1440, 1000]]) {
  test(`Sleep fits ${width}px and preserves the original footer`, async t => {
    const { page } = await open(t, { width, height });
    assert.equal(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth), true);
    assert.equal(await page.evaluate(() => [...document.images].every(image => image.complete && image.naturalWidth > 0)), true);
    assert.deepEqual(await page.locator('.nav-item').allTextContents(), ['Home', 'Sounds', 'Meditate', 'Sleep']);
    assert.equal(await page.locator('.bottom-nav [aria-current="page"]').getAttribute('data-tab'), 'sleep');
    const install = page.locator('#sanctuary-install-ui .install-entry');
    assert.equal(await install.count(), 1, 'The actual install control is tested, not skipped');
    assert.equal(await install.isVisible(), true);
    const button = await install.boundingBox();
    const welcome = await page.locator('.sleep-welcome').boundingBox();
    assert(button.y + button.height <= welcome.y || button.x >= welcome.x + welcome.width, 'Install button does not cover Sleep copy');
  });
}

test('Ocean Sleep drives actual ocean/rain samples, timer, mixer icons and mini-player', async t => {
  const { page } = await open(t);
  await beginOcean(page);
  assert.deepEqual(await page.evaluate(() => levels), { 'Ocean Waves': .7, 'Soft Rain': .3 });
  assert.equal(await page.evaluate(() => sleepTimerTotal), 2700);
  assert.equal(await page.locator('[data-quick="Ocean"]').getAttribute('aria-pressed'), 'true');
  assert.equal(await page.locator('[data-quick="Rain"]').getAttribute('aria-pressed'), 'true');
  assert.equal(await page.locator('#mini-title').textContent(), 'Ocean Sleep');
  assert.equal(await page.locator('#shared-mini-player').isVisible(), true);
  await page.locator('#mini-pause').click();
  assert.equal(await page.evaluate(() => [...players.values()].every(audio => audio.paused)), true);
  assert.deepEqual(await page.evaluate(() => levels), { 'Ocean Waves': .7, 'Soft Rain': .3 });
  assert.equal(await page.locator('#shared-mini-player').isHidden(), true);
  await page.locator('#resume-sleep').click();
  assert.equal(await page.evaluate(() => playing), true);
});

test('each soundscape selects its own audio and shows a real play/pause state', async t => {
  const { page } = await open(t);
  await page.locator('[data-soundscape="campfire"]').click();
  assert.deepEqual(await page.evaluate(() => levels), { Campfire: .6 });
  assert.equal(await page.evaluate(() => sleepTimerTotal), 2100);
  assert.equal(await page.locator('[data-soundscape="campfire"]').getAttribute('aria-label'), 'Pause Campfire, 35 minutes');
  await page.locator('[data-soundscape="campfire"]').click();
  assert.equal(await page.evaluate(() => playing), false);
  assert.match(await page.locator('[data-soundscape="campfire"]').getAttribute('aria-label'), /^Play /);
  await page.locator('[data-soundscape="heavy-rain"]').click();
  assert.deepEqual(await page.evaluate(() => levels), { 'Heavy Rain': .6 });
  assert.equal(await page.evaluate(() => sleepTimerTotal), 1800);
});

test('the quick mixer toggles only its named sounds and Customize opens Sounds', async t => {
  const { page } = await open(t);
  await page.locator('[data-quick="Ocean"]').click();
  await page.locator('[data-quick="Rain"]').click();
  assert.deepEqual(await page.evaluate(() => levels), { 'Ocean Waves': .6, 'Soft Rain': .6 });
  await page.locator('[data-quick="Ocean"]').click();
  assert.deepEqual(await page.evaluate(() => levels), { 'Soft Rain': .6 });
  await page.locator('#customize-sleep-mix').click();
  assert.equal(await page.locator('main.content').isVisible(), true);
  assert.equal(await page.locator('[data-tab="sounds"]').getAttribute('aria-current'), 'page');
});

test('the ambient mini-player opens the real shared mixer and stops real samples', async t => {
  const { page } = await open(t);
  await beginOcean(page);
  await page.locator('#mini-open').click();
  assert.equal(await page.evaluate(() => currentTab), 'sounds');
  await page.locator('[data-category="nature"]').click();
  assert.equal(await page.locator('[data-track="Ocean Waves"] .volume-badge').textContent(), '70%');
  await page.locator('[data-tab="sleep"]').click();
  await page.locator('#mini-stop').click();
  assert.equal(await page.evaluate(() => playing), false);
  assert.equal(await page.evaluate(() => [...players.values()].every(audio => audio.paused)), true);
});

test('auto-fade progress reflects the actual countdown, not volume or a saved position', async t => {
  const { page } = await open(t);
  await beginOcean(page);
  await page.evaluate(() => { sleepTimerTotal = 1800; sleepDeadline = Date.now() + 900000; updateSleepState(); });
  assert.equal(await page.locator('#progress-label').textContent(), 'Auto-fade');
  assert.equal(await page.locator('#sleep-progress-value').textContent(), '50%');
  assert.equal(await page.locator('#sleep-progress').getAttribute('aria-label'), 'Auto-fade timer elapsed');
  await page.locator('#sleep-timer-button').click();
  assert.equal(await page.locator('#progress-label').textContent(), 'Level');
  assert.equal(await page.locator('#sleep-progress-value').textContent(), '70%');
});

test('the last 30 seconds fade ambient volume and expiry stops playback', async t => {
  const { page } = await open(t, { virtualClock: true });
  await beginOcean(page);
  await page.evaluate(() => setSleepTimer(1));
  await page.clock.fastForward(31000);
  const fading = await page.evaluate(() => ({ remaining: timerRemaining(), volume: players.get('Ocean Waves').volume }));
  assert(fading.remaining <= 30 && fading.remaining > 0);
  assert(fading.volume < .7 && fading.volume > 0);
  await page.clock.fastForward(31000);
  assert.equal(await page.evaluate(() => playing), false);
  assert.equal(await page.evaluate(() => [...players.values()].every(audio => audio.paused)), true);
  assert.equal(await page.evaluate(() => sleepDeadline), null);
});

test('Sleep favorites and the existing eight-story library remain functional', async t => {
  const { page } = await open(t);
  await page.locator('[data-stories="saved"]').click();
  assert.equal(await page.getByText('Your bedtime bookshelf', { exact: true }).isVisible(), true);
  await page.locator('#browse-all-stories').click();
  assert.equal(await page.locator('[data-story]').count(), 8);
  await page.locator('[data-save-story="starry-night"]').click();
  await page.locator('[data-stories="saved"]').click();
  assert.equal(await page.locator('[data-story]').count(), 1);
  await page.reload({ waitUntil: 'networkidle' });
  await page.locator('[data-stories="saved"]').click();
  assert.equal(await page.locator('[data-story="starry-night"]').count(), 1);
  assert.match(await page.locator('.audio-disclosure').textContent(), /Individual story narration and downloads are not included/);
});

test('the player uses high-resolution local artwork and the real catalog duration', async t => {
  const { page } = await open(t, { route: '/#meditate' });
  await begin(page);
  assert.equal(await page.locator('#session-title').textContent(), 'Gentle Relief & Comfort');
  assert.equal(await page.evaluate(() => guidedSession.total), 900);
  assert.match(await page.locator('#session-art').getAttribute('src'), /player\/comfort_art\.webp$/);
  assert.match(await page.locator('.player-backdrop').evaluate(node => getComputedStyle(node).backgroundImage), /player\/lake_dawn\.webp/);
  assert.equal(await page.locator('#session-art').evaluate(image => image.naturalWidth >= 800), true);
  assert.equal(await page.getByText('Fastest', { exact: true }).count(), 0);
  assert.equal(await page.getByText('HD', { exact: true }).count(), 0);
  assert.equal(await page.locator('.player-preview-note').isVisible(), true);
});

test('pause keeps the full player open; resume preserves both countdown and audio position', async t => {
  const { page } = await open(t, { route: '/#meditate', virtualClock: true });
  await begin(page);
  await pause(page);
  await seek(page, 83);
  const position = await page.evaluate(() => guidedAudio.currentTime);
  const remaining = await page.evaluate(() => guidedSession.remaining);
  await page.clock.fastForward(300000);
  assert.equal(await page.locator('#session-dialog').evaluate(dialog => dialog.open), true);
  assert.equal(await page.evaluate(() => guidedSession.remaining), remaining);
  assert.equal(await page.locator('#session-clock').textContent(), '13:37');
  assert.match(await page.locator('#session-status').textContent(), /^PAUSED/);
  await page.locator('#session-pause').click();
  await page.waitForFunction(() => guidedSession.playing && !guidedAudio.paused);
  const resumed = await page.evaluate(() => guidedAudio.currentTime);
  assert(resumed >= position && resumed < position + 3, 'Resuming did not restart the audio');
  assert.equal(await page.evaluate(() => guidedSession.total), 900);
});

test('progress and ±10 second transport seek the actual bundled audio', async t => {
  const { page } = await open(t, { route: '/#meditate' });
  await begin(page);
  await pause(page);
  await seek(page, 100);
  const duration = await page.evaluate(() => guidedAudio.duration);
  assert(Math.abs(await page.evaluate(() => guidedAudio.currentTime) - 100 % duration) < .3);
  assert.equal(await page.locator('#session-elapsed').textContent(), '01:40');
  assert.equal(await page.locator('#session-clock').textContent(), '13:20');
  await page.locator('#session-back').click();
  assert.equal(await page.evaluate(() => guidedSession.remaining), 810);
  await page.locator('#session-forward').click();
  assert.equal(await page.evaluate(() => guidedSession.remaining), 800);
  assert.equal(await page.evaluate(() => guidedAudio.paused), true);
});

test('extend changes total and remaining time; restart does not hardcode ten minutes', async t => {
  const { page } = await open(t);
  await page.locator('[data-play-story="starry-night"]').click();
  await page.waitForFunction(() => guidedSession?.playing);
  await pause(page);
  await seek(page, 120);
  await page.locator('#session-extend').click();
  assert.equal(await page.evaluate(() => guidedSession.total), 2700);
  assert.equal(await page.locator('#session-clock').textContent(), '43:00');
  await page.locator('#session-restart').click();
  assert.equal(await page.locator('#session-clock').textContent(), '45:00');
  assert.equal(await page.locator('#session-duration').textContent(), '45:00');
  assert.equal(await page.evaluate(() => guidedAudio.currentTime), 0);
  assert.equal(await page.evaluate(() => guidedAudio.paused), true);
});

test('Loop changes the media element and source completion really ends playback', async t => {
  const { page } = await open(t, { route: '/#meditate' });
  await begin(page);
  await page.locator('#session-loop').click();
  assert.equal(await page.evaluate(() => guidedAudio.loop), false);
  assert.equal(await page.locator('#session-loop').getAttribute('aria-pressed'), 'false');
  await page.evaluate(() => { guidedAudio.currentTime = guidedAudio.duration - .05; });
  await page.waitForFunction(() => guidedSession === null);
  assert.equal(await page.evaluate(() => guidedAudio.paused), true);
  assert.equal(await page.locator('#session-dialog').isVisible(), false);
});

test('minimize and Escape do not stop audio, and a paused mini-player stays reachable', async t => {
  const { page } = await open(t, { route: '/#meditate' });
  await begin(page);
  await page.locator('#session-minimize').click();
  assert.equal(await page.evaluate(() => guidedAudio.paused), false);
  assert.equal(await page.locator('#shared-mini-player').isVisible(), true);
  await page.locator('#mini-pause').click();
  assert.equal(await page.evaluate(() => guidedAudio.paused), true);
  assert.equal(await page.locator('#shared-mini-player').isVisible(), true);
  await page.locator('[data-tab="home"]').click();
  assert.equal(await page.locator('#shared-mini-player').isVisible(), true);
  await page.locator('#mini-open').click();
  assert.equal(await page.locator('#session-dialog').evaluate(dialog => dialog.open), true);
  assert.match(await page.locator('#session-status').textContent(), /^PAUSED/);
  await page.keyboard.press('Escape');
  assert.equal(await page.locator('#session-dialog').isVisible(), false);
  assert.equal(await page.evaluate(() => guidedSession !== null), true);
});

test('mini-player resume and Home resume reuse the same session without resetting', async t => {
  const { page } = await open(t, { route: '/' });
  await page.locator('#home-daily').click();
  await page.waitForFunction(() => guidedSession?.playing);
  await pause(page);
  await seek(page, 75);
  await page.locator('#session-minimize').click();
  assert.equal(await page.locator('#home-daily').innerText(), 'Resume session');
  await page.locator('#mini-pause').click();
  await page.waitForFunction(() => guidedSession.playing);
  await page.locator('#mini-pause').click();
  await page.locator('#home-daily').click();
  await page.waitForFunction(() => guidedSession.playing);
  assert.equal(await page.evaluate(() => guidedSession.total), 600);
  assert((await page.evaluate(() => guidedSession.remaining)) <= 525);
  assert((await page.evaluate(() => guidedSession.remaining)) > 520);
});

test('Complete ends the session, while a new visit never autoplays old state', async t => {
  const { page } = await open(t, { route: '/#meditate' });
  await begin(page);
  await page.locator('#session-stop').click();
  assert.equal(await page.evaluate(() => guidedAudio.paused), true);
  assert.equal(await page.evaluate(() => guidedSession), null);
  assert.equal(await page.locator('#shared-mini-player').isHidden(), true);
  await page.reload({ waitUntil: 'networkidle' });
  assert.equal(await page.evaluate(() => guidedSession), null);
  assert.equal(await page.evaluate(() => guidedAudio.paused), true);
});

test('a session deadline completes the timer and stops the real audio sample', async t => {
  const { page } = await open(t, { route: '/#meditate', virtualClock: true });
  await begin(page);
  await page.clock.fastForward(901000);
  assert.equal(await page.evaluate(() => guidedSession), null);
  assert.equal(await page.evaluate(() => guidedAudio.paused), true);
  assert.equal(await page.locator('#session-dialog').isVisible(), false);
});

test('unavailable audio shows a retryable error instead of a live countdown', async t => {
  const { page, context } = await open(t, { route: '/#meditate', blockAudio: true });
  await page.locator('#begin-gentle-relief').click();
  await page.waitForFunction(() => !!guidedSession?.error && !guidedSession.loading);
  assert.equal(await page.evaluate(() => guidedSession.playing), false);
  assert.equal(await page.locator('#session-clock').textContent(), '15:00');
  assert.equal(await page.locator('#session-progress').isDisabled(), true);
  assert.equal(await page.locator('#session-pause').getAttribute('aria-label'), 'Retry audio');
  await context.unroute('**/assets/sounds/calm_guided.mp3');
  await page.locator('#session-pause').click();
  await page.waitForFunction(() => guidedSession?.playing && !guidedAudio.paused);
  assert.equal(await page.locator('#session-error').isHidden(), true);
});

for (const [width, height] of [[320, 640], [390, 844], [823, 1568], [1440, 1000]]) {
  test(`full player fits ${width}×${height} and completion remains reachable`, async t => {
    const { page } = await open(t, { route: '/#meditate', width, height });
    await begin(page);
    const dialog = await page.locator('#session-dialog').boundingBox();
    assert.equal(dialog.width, Math.min(823, width));
    assert.equal(dialog.height, height);
    assert.equal(await page.locator('#session-dialog').evaluate(node => node.scrollWidth <= node.clientWidth), true);
    await page.locator('#session-stop').scrollIntoViewIfNeeded();
    const finish = await page.locator('#session-stop').boundingBox();
    assert(finish.y >= 0 && finish.y + finish.height <= height);
    for (const selector of ['#session-pause', '#session-minimize', '#session-back', '#session-forward']) {
      const bounds = await page.locator(selector).boundingBox();
      assert(bounds.width >= 44 && bounds.height >= 44);
    }
    assert.equal(await page.locator('.breathing-ring').first().evaluate(node => getComputedStyle(node).animationName), 'none');
  });
}

test('long session titles can scroll without covering the finish action', async t => {
  const { page } = await open(t, { route: '/#meditate', width: 320, height: 640 });
  await begin(page);
  await page.evaluate(() => { $('session-title').textContent = 'A longer moment of gentle relief, a little comfort, and room to breathe'; });
  assert.equal(await page.locator('#session-dialog').evaluate(node => node.scrollWidth <= node.clientWidth), true);
  await page.locator('#session-stop').scrollIntoViewIfNeeded();
  await page.locator('#session-stop').click();
  assert.equal(await page.evaluate(() => guidedSession), null);
});

test('mixer and player SVGs paint distinct pixels when all font requests fail', async t => {
  const { page, fontsBlocked } = await open(t, { blockFonts: true });
  assert(fontsBlocked() > 0);
  const quick = await svgPixels(page.locator('#quick-mixer .quick-orb > svg'));
  assert.equal(quick.length, 5);
  assert.equal(new Set(quick.map(icon => icon.signature)).size, 5);
  quick.forEach(icon => assert(icon.visible > 80 && icon.width >= 23));
  await page.locator('[data-tab="meditate"]').click();
  await begin(page);
  const transport = await svgPixels(page.locator('#session-back > svg, #session-pause > svg, #session-forward > svg, #session-loop > svg'));
  assert.equal(transport.length, 4);
  assert.equal(new Set(transport.map(icon => icon.signature)).size, 4);
  transport.forEach(icon => assert(icon.visible > 80));
});

test('starting a session pauses the ambient mix without losing its selected levels', async t => {
  const { page } = await open(t);
  await beginOcean(page);
  await page.locator('[data-tab="meditate"]').click();
  await begin(page);
  assert.equal(await page.evaluate(() => playing), false);
  assert.deepEqual(await page.evaluate(() => levels), { 'Ocean Waves': .7, 'Soft Rain': .3 });
  assert.equal(await page.evaluate(() => [...players.values()].every(audio => audio.paused)), true);
  assert.equal(await page.evaluate(() => guidedAudio.paused), false);
});

test('loading is explicit and completing during a pending request cannot revive audio', async t => {
  const { page, context } = await open(t, { route: '/#meditate' });
  let release;
  let started;
  const gate = new Promise(resolve => { release = resolve; });
  const requested = new Promise(resolve => { started = resolve; });
  t.after(() => release());
  await context.route('**/assets/sounds/calm_guided.mp3', async route => {
    started();
    await gate;
    try { await route.continue(); } catch (_) { /* A closed test context cancels media. */ }
  });
  await page.locator('#begin-gentle-relief').click();
  await requested;
  assert.equal(await page.evaluate(() => guidedSession.loading), true);
  assert.equal(await page.evaluate(() => guidedSession.playing), false);
  assert.equal(await page.locator('#session-clock').textContent(), '15:00');
  assert.equal(await page.locator('#session-pause').isDisabled(), true);
  assert.equal(await page.locator('#session-progress').isDisabled(), true);
  await page.locator('#session-stop').click();
  release();
  await page.waitForLoadState('networkidle');
  assert.equal(await page.evaluate(() => guidedSession), null);
  assert.equal(await page.evaluate(() => guidedAudio.paused), true);
  assert.equal(await page.locator('#session-dialog').isVisible(), false);
});


test('the real install entry never covers Minimize and returns without resetting install state', async t => {
  const { page } = await open(t, { route: '/#meditate' });
  const entry = page.locator('#sanctuary-install-ui .install-entry');
  const state = await page.evaluate(() => SanctuaryInstall.state);
  assert.equal(await entry.isVisible(), true);
  await begin(page);
  assert.equal(await entry.isHidden(), true);
  assert.equal(await page.evaluate(() => document.documentElement.classList.contains('sanctuary-player-expanded')), true);
  await page.locator('#session-minimize').click();
  assert.equal(await entry.isVisible(), true);
  assert.deepEqual(await page.evaluate(() => SanctuaryInstall.state), state);
  await page.locator('#mini-open').click();
  assert.equal(await entry.isHidden(), true);
  await page.locator('#session-stop').click();
  assert.equal(await entry.isVisible(), true);
  // A real installation stays hidden even when the player releases the corner.
  await page.evaluate(() => dispatchEvent(new Event('appinstalled')));
  assert.equal(await entry.isHidden(), true);
  await begin(page);
  await page.locator('#session-minimize').click();
  assert.equal(await entry.isHidden(), true);
});
