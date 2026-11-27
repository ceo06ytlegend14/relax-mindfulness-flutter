// Exercises the independent browser preview, not a compiled Flutter application.
import assert from 'node:assert/strict';
import { minimizeAmbientForBackgroundControls } from './support/ambient_player_helpers.mjs';
import { expectSharedBackground } from './support/shared_background_helpers.mjs';
import { createServer } from 'node:http';
import { createHash } from 'node:crypto';
import { readFile, realpath } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { after, before, test } from 'node:test';

const { chromium } = await import(process.env.PLAYWRIGHT_MODULE || 'playwright');
const root = path.resolve(fileURLToPath(new URL('../../', import.meta.url)));
const directory = path.join(root, 'design/preview');
const sessionManifest = JSON.parse(await readFile(path.join(root, 'assets/sounds/session_soundscapes.json'), 'utf8'));
const mime = { '.html': 'text/html', '.js': 'text/javascript', '.json': 'application/manifest+json', '.css': 'text/css', '.png': 'image/png', '.webp': 'image/webp', '.ttf': 'font/ttf', '.mp3': 'audio/mpeg' };
let server;
let browser;
let origin;
const upgradePrefix = '/cache-upgrade/';
const legacyAssetRequests = new Map();
const legacyButtons = ['Ocean', 'Rain', 'Wind', 'Thunder', 'Nature'].map(label =>
  `<button data-quick="${label}"><span class="quick-orb"><svg viewBox="0 0 32 32"><path d="M7 21a6 6 0 1 1 2-12 8 8 0 0 1 15 0 6 6 0 0 1 0 12Z" fill="currentColor"/></svg></span>${label}</button>`).join('');
const legacyUpgradeFiles = {
  'before.html': '<!doctype html><html lang="en"><head><meta name="viewport" content="width=device-width,initial-scale=1"><link rel="stylesheet" href="sleep.css"></head><body><main id="sleep-page"><section id="quick-mixer"></section></main><script src="sanctuary.js"></script></body></html>',
  'sleep.css': '.quick-orb{display:grid;place-items:center;width:44px;height:44px}.quick-orb>svg{width:23px;height:23px}',
  'sanctuary.js': `document.documentElement.dataset.legacySleepControls='true';document.querySelector('#quick-mixer').innerHTML=${JSON.stringify(legacyButtons)};`,
};

before(async () => {
  server = createServer(async (request, response) => {
    try {
      const url = new URL(request.url, 'http://test.invalid');
      const pathname = decodeURIComponent(url.pathname);
      const upgrade = pathname.startsWith(upgradePrefix);
      const filename = upgrade ? pathname.slice(upgradePrefix.length) : pathname.slice(1);
      // A returning browser can hold immutable old CSS and renderer code. Keep
      // this fixture under its own path so ordinary player tests remain fresh.
      if (upgrade && Object.hasOwn(legacyUpgradeFiles, filename) && !url.searchParams.has('v')) {
        const content = legacyUpgradeFiles[filename];
        response.setHeader('Content-Type', mime[path.extname(filename)]);
        response.setHeader('Cache-Control', filename === 'before.html' ? 'no-store' : 'public, max-age=31536000, immutable');
        response.setHeader('Content-Length', Buffer.byteLength(content));
        if (filename !== 'before.html') legacyAssetRequests.set(filename, (legacyAssetRequests.get(filename) || 0) + 1);
        return response.end(content);
      }
      const resolved = await realpath(path.join(directory, filename || 'index.html'));
      if (!resolved.startsWith(`${root}${path.sep}`)) throw new Error('Outside test repository');
      const bytes = await readFile(resolved);
      response.setHeader('Content-Type', mime[path.extname(resolved)] || 'application/octet-stream');
      response.setHeader('Cache-Control', upgrade && url.searchParams.has('v') ? 'public, max-age=31536000, immutable' : 'no-store');
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
  if (blockAudio) await context.route('**/assets/sounds/session_gentle_relief.mp3', route => route.abort());
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
  await minimizeAmbientForBackgroundControls(page);
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

test('a returning browser replaces cached small mixer buttons without clearing saved sounds', async t => {
  const html = await readFile(path.join(directory, 'index.html'), 'utf8');
  const links = [...html.matchAll(/\b(?:src|href)="([^"?]+\.(?:css|js))(\?[^" ]*)?"/g)];
  assert(links.length >= 15, 'Every preview stylesheet and script participates in content versioning');
  for (const [, asset, query = ''] of links) {
    const bytes = await readFile(path.join(directory, asset));
    const expected = createHash('sha256').update(bytes).digest('hex').slice(0, 12);
    assert.equal(new URLSearchParams(query).get('v'), expected, `${asset} has a fresh content version; run node tool/version_preview_assets.mjs after edits`);
  }
  legacyAssetRequests.clear();
  const { page } = await open(t, { route: `${upgradePrefix}before.html`, width: 431, height: 809 });
  assert.equal(await page.locator('.quick-orb > svg').first().evaluate(node => node.getBoundingClientRect().width), 23);
  await page.goto(`${origin}${upgradePrefix}before.html?second-visit=1`, { waitUntil: 'networkidle' });
  assert.deepEqual(Object.fromEntries(legacyAssetRequests), { 'sleep.css': 1, 'sanctuary.js': 1 }, 'The old assets really came from the browser cache on the second visit');
  const saved = { levels: { 'Soft Rain': .4 }, favorites: ['Soft Rain'], saved: [{ name: 'My kept mix', levels: { 'Soft Rain': .4 } }] };
  await page.evaluate(saved => localStorage.setItem('sanctuary.designPreview.v1', JSON.stringify(saved)), saved);
  await page.goto(`${origin}${upgradePrefix}?ui=sleep-outline#sleep`, { waitUntil: 'networkidle' });
  await page.evaluate(() => document.fonts.ready);
  assert.equal(await page.locator('#quick-mixer').getAttribute('data-control-design'), 'large-outline');
  assert.equal(await page.evaluate(() => document.documentElement.dataset.legacySleepControls), undefined, 'The old renderer was not reused');
  assert.equal(await page.locator('[data-quick]').count(), 5);
  for (const name of ['Ocean', 'Rain', 'Wind', 'Thunder', 'Nature']) {
    const size = await page.locator(`[data-quick="${name}"] .quick-orb > svg`).evaluate(node => node.getBoundingClientRect().width);
    assert(size >= 39 && size <= 40, `${name} uses the large reference-sized symbol, not the cached 23px glyph`);
  }
  for (const name of ['Rain', 'Nature']) {
    assert.equal(await page.locator(`[data-quick="${name}"] .quick-orb path`).first().evaluate(node => getComputedStyle(node).fill), 'none');
  }
  assert.deepEqual(await page.evaluate(() => JSON.parse(localStorage.getItem('sanctuary.designPreview.v1'))), saved);
  assert.equal(await page.evaluate(() => playing), false, 'Refreshing the UI never starts the saved mix');
  assert.deepEqual(await page.locator('.nav-item').allTextContents(), ['Home', 'Sounds', 'Meditate', 'Sleep']);
  assert.deepEqual(Object.fromEntries(legacyAssetRequests), { 'sleep.css': 1, 'sanctuary.js': 1 }, 'Current UI never re-requested the obsolete unversioned files');
});

for (const [width, height] of [[320, 640], [390, 844], [431, 809], [823, 1568], [1440, 1000]]) {
  test(`Sleep fits ${width}px and preserves the original footer`, async t => {
    const { page } = await open(t, { width, height });
    assert.equal(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth), true);
    assert.equal(await page.evaluate(() => [...document.images].every(image => image.complete && image.naturalWidth > 0)), true);
    assert.deepEqual(await page.locator('.nav-item').allTextContents(), ['Home', 'Sounds', 'Meditate', 'Sleep']);
    assert.equal(await page.locator('.bottom-nav [aria-current="page"]').getAttribute('data-tab'), 'sleep');
    assert.equal(await page.locator('.install-entry').count(), 0, 'No install button is added over Sleep');
    const orbs = await page.locator('[data-quick]').evaluateAll(nodes => nodes.map(node => {
      const button = node.getBoundingClientRect();
      const orb = node.querySelector('.quick-orb').getBoundingClientRect();
      const icon = node.querySelector('.quick-orb > svg').getBoundingClientRect();
      return { button: { width: button.width, height: button.height }, orb: orb.width, icon: icon.width };
    }));
    for (const { button, orb, icon } of orbs) {
      assert(button.width >= 44 && button.height >= 44, 'Mixer controls retain their touch targets');
      assert(orb >= 44 && icon / orb >= .84 && icon / orb <= .95, 'Large symbols fill their orbs without clipping');
    }
    const tray = await page.locator('#winddown-tray').boundingBox();
    const cards = await page.locator('[data-soundscape]').evaluateAll(nodes => nodes.map(node => {
      const { x, width } = node.getBoundingClientRect(); return { x, width };
    }));
    assert.equal(cards.length, 5, 'The fifth playlist is retained');
    if (width >= 390) {
      assert(cards[0].x >= tray.x && cards[3].x + cards[3].width <= tray.x + tray.width + 1,
        'All four preferred covers fit without horizontal scrolling on a standard phone or wider screen');
    }
    await page.locator('[data-soundscape]').last().scrollIntoViewIfNeeded();
    const last = await page.locator('[data-soundscape]').last().boundingBox();
    // Chromium rounds fractional scroll offsets to whole CSS pixels.
    assert(last.x >= tray.x - 2 && last.x + last.width <= tray.x + tray.width + 2, 'The fifth playlist remains reachable');
    await page.evaluate(() => scrollTo(0, document.querySelector('#quick-mixer').getBoundingClientRect().top + scrollY - 120));
    assert(await page.evaluate(() => scrollY > 0));
    await expectSharedBackground(page);
    assert.equal(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth), true);
  });
}

test('restored mixer outlines and mint glow follow real playback, including pause and resume', async t => {
  const { page } = await open(t, { width: 431, height: 809 });
  const activeLabels = () => page.locator('[data-quick][aria-pressed="true"]').evaluateAll(nodes => nodes.map(node => node.dataset.quick));
  assert.deepEqual(await activeLabels(), []);
  for (const name of ['Rain', 'Nature']) {
    assert.equal(await page.locator(`[data-quick="${name}"] .quick-orb > svg path`).first().evaluate(node => getComputedStyle(node).fill), 'none',
      'Rain and Nature use outlines rather than small filled glyphs');
  }
  // Use local sources: Wind retains its existing stream-only binding, and the
  // independent preview deliberately does not substitute a different recording.
  await page.locator('[data-quick="Ocean"]').click();
  await minimizeAmbientForBackgroundControls(page);
  await page.locator('[data-quick="Nature"]').click();
  await minimizeAmbientForBackgroundControls(page);
  await page.waitForFunction(() => players.size === 2 && [...players.values()].every(audio => !audio.paused && audio.readyState >= 2));
  assert.deepEqual(await page.evaluate(() => levels), { 'Ocean Waves': .6, 'Mountain Stream': .6 });
  assert.deepEqual(await activeLabels(), ['Ocean', 'Nature']);
  for (const name of ['Ocean', 'Nature']) {
    const style = await page.locator(`[data-quick="${name}"]`).evaluate(node => ({
      color: getComputedStyle(node.querySelector('svg')).color,
      glow: getComputedStyle(node.querySelector('svg')).filter,
      level: node.querySelector('.quick-level > span').style.width,
    }));
    assert.equal(style.color, 'rgb(120, 238, 208)');
    assert.notEqual(style.glow, 'none');
    assert.equal(style.level, '60%');
  }
  await page.locator('#mini-pause').click();
  assert.deepEqual(await activeLabels(), [], 'Paused layers are not falsely illuminated');
  assert.equal(await page.locator('#shared-mini-player').isVisible(), true);
  assert.equal(await page.evaluate(() => [...players.values()].every(audio => audio.paused)), true);
  assert.deepEqual(await page.evaluate(() => levels), { 'Ocean Waves': .6, 'Mountain Stream': .6 }, 'Pausing preserves selected levels');
  const paused = await page.locator('.quick-orb > svg').evaluateAll(nodes => nodes.every(node => getComputedStyle(node).filter === 'none'));
  assert(paused);
  await page.locator('#resume-sleep').click();
  await minimizeAmbientForBackgroundControls(page);
  await page.waitForFunction(() => [...players.values()].filter(audio => !audio.paused && audio.readyState >= 2).length === 2);
  assert.deepEqual(await activeLabels(), ['Ocean', 'Nature']);
  assert.equal(await page.locator('#shared-mini-player').isVisible(), true);
});

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
  assert.equal(await page.locator('#shared-mini-player').isVisible(), true);
  await page.locator('#resume-sleep').click();
  await minimizeAmbientForBackgroundControls(page);
  assert.equal(await page.evaluate(() => playing), true);
});

test('each soundscape selects its own audio and shows a real play/pause state', async t => {
  const { page } = await open(t);
  await page.locator('[data-soundscape="campfire"]').click();
  await minimizeAmbientForBackgroundControls(page);
  // Pause is offered only after media starts; a pending load offers Cancel.
  await page.waitForFunction(() => ambientTrackStatus('Campfire') === 'playing'
    && !players.get('Campfire').paused && players.get('Campfire').readyState >= 2);
  assert.deepEqual(await page.evaluate(() => levels), { Campfire: .6 });
  assert.equal(await page.evaluate(() => sleepTimerTotal), 2100);
  assert.equal(await page.locator('[data-soundscape="campfire"]').getAttribute('aria-label'), 'Pause Campfire, 35 minutes');
  await page.locator('[data-soundscape="campfire"]').click();
  await minimizeAmbientForBackgroundControls(page);
  assert.equal(await page.evaluate(() => playing), false);
  assert.match(await page.locator('[data-soundscape="campfire"]').getAttribute('aria-label'), /^Play /);
  await page.locator('[data-soundscape="heavy-rain"]').click();
  await minimizeAmbientForBackgroundControls(page);
  assert.equal(await page.locator('#preview-availability-dialog').isVisible(), true);
  assert.match(await page.locator('#preview-unavailable-sources').textContent(), /Heavy Rain/);
  assert.deepEqual(await page.evaluate(() => levels), { Campfire: .6 }, 'An unavailable scene never replaces the selected recipe');
  assert.equal(await page.evaluate(() => sleepTimerTotal), 2100, 'Preflight happens before changing the timer');
  assert.equal(await page.evaluate(() => playing), false);
  await page.locator('#preview-unavailable-keep').click();
});

test('the quick mixer toggles only its named sounds and Customize opens Sounds', async t => {
  const { page } = await open(t);
  await page.locator('[data-quick="Ocean"]').click();
  await minimizeAmbientForBackgroundControls(page);
  await page.locator('[data-quick="Rain"]').click();
  await minimizeAmbientForBackgroundControls(page);
  assert.deepEqual(await page.evaluate(() => levels), { 'Ocean Waves': .6, 'Soft Rain': .6 });
  await page.locator('[data-quick="Ocean"]').click();
  await minimizeAmbientForBackgroundControls(page);
  assert.deepEqual(await page.evaluate(() => levels), { 'Soft Rain': .6 });
  await page.locator('#customize-sleep-mix').click();
  assert.equal(await page.locator('main.content').isVisible(), true);
  assert.equal(await page.locator('[data-tab="sounds"]').getAttribute('aria-current'), 'page');
});

test('the ambient mini-player reopens its full layers and stops real samples', async t => {
  const { page } = await open(t);
  await beginOcean(page);
  await page.locator('#mini-open').click();
  assert.equal(await page.locator('#ambient-dialog').isVisible(), true);
  await expectSharedBackground(page, { player: '#ambient-dialog' });
  await page.locator('#ambient-dialog .player-scroll').evaluate(node => node.scrollTo(0, node.scrollHeight));
  await expectSharedBackground(page, { player: '#ambient-dialog' });
  assert.equal(await page.evaluate(() => currentTab), 'sleep');
  assert.equal(await page.locator('[data-ambient-layer="Ocean Waves"] output').textContent(), '70%');
  await page.locator('#ambient-edit').click();
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

test('Sleep favorites and all eight ambient journeys remain functional', async t => {
  const { page } = await open(t);
  await page.locator('[data-stories="saved"]').click();
  assert.equal(await page.getByText('Your quiet collection', { exact: true }).isVisible(), true);
  await page.locator('#browse-all-stories').click();
  assert.equal(await page.locator('[data-story]').count(), 8);
  await page.locator('[data-save-story="starry-night"]').click();
  await page.locator('[data-stories="saved"]').click();
  assert.equal(await page.locator('[data-story]').count(), 1);
  await page.reload({ waitUntil: 'networkidle' });
  await page.locator('[data-stories="saved"]').click();
  assert.equal(await page.locator('[data-story="starry-night"]').count(), 1);
  assert.match(await page.locator('.audio-disclosure').textContent(), /No spoken stories or individual downloads/);
});

test('the player uses high-resolution local artwork and the real catalog duration', async t => {
  const { page } = await open(t, { route: '/#meditate' });
  await begin(page);
  assert.equal(await page.locator('#session-title').textContent(), 'Gentle Relief & Comfort');
  assert.equal(await page.evaluate(() => guidedSession.total), 900);
  assert.match(await page.locator('#session-art').getAttribute('src'), /player\/comfort_art\.webp$/);
  await expectSharedBackground(page, { player: '#session-dialog' });
  assert.equal(await page.locator('#session-art').evaluate(image => image.naturalWidth >= 800), true);
  assert.equal(await page.getByText('Fastest', { exact: true }).count(), 0);
  assert.equal(await page.getByText('HD', { exact: true }).count(), 0);
  assert.equal(await page.locator('#session-dialog .player-preview-note').isVisible(), true);
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
  await context.unroute('**/assets/sounds/session_gentle_relief.mp3');
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
    assert.equal(await page.locator('#session-dialog .breathing-ring').first().evaluate(node => getComputedStyle(node).animationName), 'none');
    await expectSharedBackground(page, { player: '#session-dialog' });
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
  await context.route('**/assets/sounds/session_gentle_relief.mp3', async route => {
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


test('player minimize/reopen never recreates an install entry or resets installation state', async t => {
  const { page } = await open(t, { route: '/#meditate' });
  const entry = page.locator('#sanctuary-install-ui .install-entry');
  const state = await page.evaluate(() => SanctuaryInstall.state);
  assert.equal(await entry.count(), 0);
  await begin(page);
  assert.equal(await entry.count(), 0);
  assert.equal(await page.evaluate(() => document.documentElement.classList.contains('sanctuary-player-expanded')), true);
  await page.locator('#session-minimize').click();
  assert.equal(await entry.count(), 0);
  assert.deepEqual(await page.evaluate(() => SanctuaryInstall.state), state);
  await page.locator('#mini-open').click();
  assert.equal(await entry.count(), 0);
  await page.locator('#session-stop').click();
  assert.equal(await entry.count(), 0);
  await page.evaluate(() => dispatchEvent(new Event('appinstalled')));
  assert.equal(await page.evaluate(() => SanctuaryInstall.state.installed), true);
  await begin(page);
  await page.locator('#session-minimize').click();
  assert.equal(await entry.count(), 0);
});

test('every meditation and nighttime card actually plays its named mix and shows its ingredients', async t => {
  const { page } = await open(t, { route: '/#meditate' });
  await page.locator('#browse-practices').click();
  const requested = [];
  page.on('request', request => {
    if (request.resourceType() === 'media') requested.push(new URL(request.url()).pathname);
  });
  for (let index = 0; index < sessionManifest.sessions.length; index++) {
    const recipe = sessionManifest.sessions[index];
    if (index === 15) await page.locator('[data-tab="sleep"]').click();
    const button = index === 0 ? '#begin-daily'
      : index < 15 ? `#begin-${recipe.id}` : `[data-play-story="${recipe.id}"]`;
    assert.equal(await page.locator(`[data-session-sources="${recipe.id}"]`).textContent(), recipe.layers.map(layer => layer.recording).join(' + '));
    await page.locator(button).click();
    await page.waitForFunction(asset => guidedSession?.playing && guidedAudio.readyState >= 2 && !guidedAudio.paused
      && new URL(guidedAudio.currentSrc).pathname.endsWith('/' + asset), recipe.asset);
    const actual = await page.evaluate(() => ({ title: guidedSession.title, volume: guidedAudio.volume, duration: guidedAudio.duration }));
    assert.equal(actual.title, recipe.title);
    assert.equal(actual.volume, .35);
    assert(actual.duration > 29.8 && actual.duration < 30.2);
    assert.equal(await page.locator('#session-sources').textContent(), recipe.layers.map(layer => layer.recording).join(' + '));
    assert.match(await page.locator('#session-description').textContent(), /Repeats about every 30 sec · No narration/);
    await page.locator('#session-stop').click();
  }
  assert.deepEqual(new Set(requested), new Set(sessionManifest.sessions.map(session => '/' + session.asset)));
  assert(!requested.some(asset => asset.endsWith('calm_guided.mp3')));
});

test('Home and Meditate reuse the one daily practice, source position and source element', async t => {
  const { page } = await open(t, { route: '/' });
  assert.match(await page.locator('.home-session-sources').textContent(), /Mountain Stream \+ Meadow Breeze/);
  await page.locator('#home-daily').click();
  await page.waitForFunction(() => guidedSession?.playing && guidedAudio.readyState >= 2);
  await pause(page);
  await seek(page, 75);
  await page.evaluate(() => { window.dailyAudioBeforeNavigation = guidedAudio; });
  const position = await page.evaluate(() => guidedAudio.currentTime);
  await page.locator('#session-minimize').click();
  await page.locator('[data-tab="meditate"]').click();
  await page.locator('#begin-daily').click();
  await page.waitForFunction(() => guidedSession?.playing && !guidedAudio.paused);
  const after = await page.evaluate(() => ({ same: guidedAudio === window.dailyAudioBeforeNavigation,
    asset: guidedAudio.currentSrc, time: guidedAudio.currentTime, total: guidedSession.total, remaining: guidedSession.remaining }));
  assert.equal(after.same, true, 'The same practice is not misleadingly made into a different mix');
  assert.match(after.asset, /session_calm_mountain\.mp3$/);
  assert.equal(after.total, 600);
  assert(after.remaining > 520 && after.remaining <= 525);
  assert(after.time >= position && after.time < position + 3);
});

test('a late load, error or end from one card cannot replace a newer soundscape', async t => {
  const { page, context } = await open(t, { route: '/#meditate' });
  let release, requested;
  const gate = new Promise(resolve => { release = resolve; });
  const started = new Promise(resolve => { requested = resolve; });
  t.after(() => release());
  await context.route('**/assets/sounds/session_gentle_relief.mp3', async route => {
    requested();
    await gate;
    try { await route.continue(); } catch (_) { /* Replaced media cancels its request. */ }
  });
  await page.locator('#begin-gentle-relief').click();
  await started;
  await page.evaluate(() => { window.discardedSessionAudio = guidedAudio; });
  await page.locator('#session-minimize').click();
  await page.locator('[data-tab="sleep"]').click();
  await page.locator('[data-play-story="starry-night"]').click();
  await page.waitForFunction(() => guidedSession?.playing && guidedAudio.readyState >= 2 && !guidedAudio.paused);
  release();
  await page.waitForLoadState('networkidle');
  await page.evaluate(() => {
    window.discardedSessionAudio.dispatchEvent(new Event('error'));
    window.discardedSessionAudio.dispatchEvent(new Event('ended'));
  });
  const state = await page.evaluate(() => ({ title: guidedSession?.title, playing: guidedSession?.playing,
    error: guidedSession?.error, asset: guidedAudio.currentSrc, oldPaused: window.discardedSessionAudio.paused,
    oldSource: window.discardedSessionAudio.getAttribute('src') }));
  assert.equal(state.title, 'The Starry Night');
  assert.equal(state.playing, true);
  assert.equal(state.error, null);
  assert.match(state.asset, /session_starry_night\.mp3$/);
  assert.equal(state.oldPaused, true);
  assert.equal(state.oldSource, null);
});

test('missing or unknown session content never requests an unrelated fallback', async t => {
  const { page } = await open(t, { route: '/#meditate', blockAudio: true });
  const requested = [];
  page.on('request', request => {
    if (request.resourceType() === 'media') requested.push(new URL(request.url()).pathname);
  });
  await page.locator('#begin-gentle-relief').click();
  await page.waitForFunction(() => !!guidedSession?.error && !guidedSession.loading);
  assert.equal(await page.locator('#session-sources').textContent(), 'Bamboo Chimes + Soft Rain');
  assert.equal(await page.locator('#session-status').textContent(), 'SOUNDSCAPE UNAVAILABLE');
  assert.equal(await page.evaluate(() => guidedSession.remaining), 900);
  assert.deepEqual([...new Set(requested)], ['/assets/sounds/session_gentle_relief.mp3']);
  const before = requested.length;
  await page.evaluate(() => startGuided({ title: '__proto__', minutes: 15 }));
  assert.equal(await page.evaluate(() => guidedSession.playing), false);
  assert.equal(await page.evaluate(() => guidedSession.remaining), 900);
  assert.equal(await page.evaluate(() => guidedAudio.getAttribute('src')), null);
  assert.equal(await page.locator('#session-progress').isDisabled(), true);
  assert.equal(requested.length, before);
});

test('retrying a runtime error keeps this source and seeks to retained session time', async t => {
  const { page } = await open(t, { route: '/#meditate', virtualClock: true });
  await begin(page);
  await pause(page);
  await seek(page, 95);
  await page.evaluate(() => guidedAudio.dispatchEvent(new Event('error')));
  assert.equal(await page.evaluate(() => guidedSession.remaining), 805);
  await page.locator('#session-pause').click();
  await page.waitForFunction(() => guidedSession?.playing && guidedAudio.readyState >= 2);
  const state = await page.evaluate(() => ({ remaining: guidedSession.remaining, position: guidedAudio.currentTime,
    duration: guidedAudio.duration, asset: guidedAudio.currentSrc, error: guidedSession.error }));
  // Media resumes between the click and this snapshot. Even with the virtual
  // app clock, the real audio clock can advance a few hundredths of a second.
  assert(state.remaining <= 805 && 805 - state.remaining < .5, 'Retry retains the paused time, allowing subsecond media progress');
  assert(Math.abs(state.position - 95 % state.duration) < .5);
  assert.match(state.asset, /session_gentle_relief\.mp3$/);
  assert.equal(state.error, null);
});

test('ambient stability: stream-only controls never glow or report audible playback', async t => {
  const { page } = await open(t);
  const media = [];
  page.on('request', request => { if (request.resourceType() === 'media') media.push(request.url()); });
  for (const label of ['Wind', 'Thunder']) {
    await page.locator(`[data-quick="${label}"]`).click();
    await minimizeAmbientForBackgroundControls(page);
    assert.equal(await page.locator(`[data-quick="${label}"]`).getAttribute('aria-pressed'), 'false');
    assert.equal(await page.locator(`[data-quick="${label}"] .quick-level > span`).getAttribute('style'), 'width: 0%;');
    assert.equal(await page.locator('#shared-mini-player').isHidden(), true);
    assert.equal(await page.locator('#preview-availability-dialog').isVisible(), true);
    assert.match(await page.locator('#preview-unavailable-sources').textContent(), /App stream/);
    assert.deepEqual(await page.evaluate(() => levels), { 'Soft Rain': .3 }, 'Unavailable taps keep the previous selection');
    assert.equal(await page.evaluate(() => playing), false);
    await page.locator('#preview-unavailable-keep').click();
  }
  assert.deepEqual(media, [], 'No unrelated sample or remote stream is attempted');
  await page.locator('[data-tab="home"]').click();
  assert.doesNotMatch(await page.locator('#home-mix-status').textContent(), /^Playing/);
  await page.locator('[data-tab="sounds"]').click();
  assert.equal(await page.locator('#play-status').textContent(), 'Mixer Paused', 'The valid previous mix was never replaced by an app-only selection');
});

test('ambient stability: a pending source stays unlit and cancelling blocks late playback', async t => {
  const { page, context } = await open(t);
  let release, requested;
  const gate = new Promise(resolve => { release = resolve; });
  const started = new Promise(resolve => { requested = resolve; });
  t.after(() => release());
  await context.route('**/assets/sounds/loop_ocean_waves.mp3', async route => {
    requested();
    await gate;
    try { await route.continue(); } catch (_) { /* Cancelled media no longer owns its load. */ }
  });
  await page.locator('[data-quick="Ocean"]').click();
  await minimizeAmbientForBackgroundControls(page);
  await started;
  await page.evaluate(() => { window.pendingAmbientAudio = players.get('Ocean Waves'); });
  assert.equal(await page.locator('[data-quick="Ocean"]').getAttribute('aria-pressed'), 'false');
  assert.equal(await page.locator('[data-quick="Ocean"]').getAttribute('aria-busy'), 'true');
  assert.equal(await page.locator('#shared-mini-player').isVisible(), true);
  await page.locator('[data-tab="sounds"]').click();
  assert.equal(await page.locator('#play-status').textContent(), 'Preparing soundscape');
  await page.locator('#master-play').click();
  await minimizeAmbientForBackgroundControls(page);
  release();
  await page.waitForLoadState('networkidle');
  assert.equal(await page.evaluate(() => pendingAmbientAudio.paused), true);
  assert.equal(await page.evaluate(() => playing), false);
  assert.deepEqual(await page.evaluate(() => levels), { 'Ocean Waves': .6 });
  assert.equal(await page.locator('#play-status').textContent(), 'Mixer Paused');
});

test('ambient stability: one failed layer does not light up or count over a healthy source', async t => {
  const { page, context } = await open(t);
  await context.route('**/assets/sounds/loop_soft_rain.mp3', route => route.abort());
  await page.locator('#begin-ocean').click();
  await minimizeAmbientForBackgroundControls(page);
  await page.waitForFunction(() => !players.get('Ocean Waves')?.paused && players.get('Ocean Waves')?.readyState >= 2);
  await page.waitForFunction(() => !players.get('Soft Rain') || !!players.get('Soft Rain').error);
  assert.deepEqual(await page.evaluate(() => levels), { 'Ocean Waves': .7, 'Soft Rain': .3 });
  assert.equal(await page.locator('[data-quick="Ocean"]').getAttribute('aria-pressed'), 'true');
  assert.equal(await page.locator('[data-quick="Rain"]').getAttribute('aria-pressed'), 'false');
  assert.match(await page.locator('#mini-subtitle').textContent(), /Playing · 1 layer/);
  assert.match(await page.locator('#mini-subtitle').textContent(), /1 unavailable/);
  await page.locator('[data-tab="home"]').click();
  assert.match(await page.locator('#home-mix-status').textContent(), /Playing · 1 layer/);
  assert.match(await page.locator('#home-mix-status').textContent(), /1 unavailable/);
});

test('ambient stability: rejected play is retryable without changing the selected recording', async t => {
  const { page } = await open(t);
  const requested = [];
  page.on('request', request => {
    if (/\/assets\/sounds\/[^/?]+\.mp3/.test(request.url())) requested.push(new URL(request.url()).pathname);
  });
  await page.evaluate(() => {
    window.ambientNativeResume = AudioContext.prototype.resume;
    AudioContext.prototype.resume = function () {
      return Promise.reject(new DOMException('Simulated playback refusal', 'NotAllowedError'));
    };
  });
  await page.locator('[data-quick="Ocean"]').click();
  await minimizeAmbientForBackgroundControls(page);
  await page.waitForFunction(() => ambientTrackStatus('Ocean Waves') === 'error');
  assert.equal(await page.locator('[data-quick="Ocean"]').getAttribute('aria-pressed'), 'false');
  assert.equal(await page.locator('#shared-mini-player').isVisible(), true);
  assert.deepEqual(await page.evaluate(() => levels), { 'Ocean Waves': .6 });
  await page.locator('[data-tab="home"]').click();
  assert.match(await page.locator('#home-mix-status').textContent(), /^Audio unavailable/);
  assert.equal(await page.locator('#home-mix-toggle').getAttribute('aria-label'), 'Retry soundscape');
  await page.evaluate(() => { AudioContext.prototype.resume = window.ambientNativeResume; });
  await page.locator('#home-mix-toggle').click();
  await minimizeAmbientForBackgroundControls(page);
  await page.waitForFunction(() => ambientTrackStatus('Ocean Waves') === 'playing');
  assert.equal(await page.locator('#home-mix-status').textContent(), 'Playing · 1 layer');
  assert.deepEqual(await page.evaluate(() => levels), { 'Ocean Waves': .6 });
  assert.equal(await page.evaluate(() => players.get('Ocean Waves').volume), .6);
  assert.deepEqual([...new Set(requested)], ['/assets/sounds/loop_ocean_waves.mp3']);
});

test('ambient stability: an expired load is released and cannot become late playback', async t => {
  const { page, context } = await open(t, { virtualClock: true });
  let release, requested;
  const gate = new Promise(resolve => { release = resolve; });
  const started = new Promise(resolve => { requested = resolve; });
  t.after(() => release());
  await context.route('**/assets/sounds/loop_ocean_waves.mp3', async route => {
    requested();
    await gate;
    try { await route.continue(); } catch (_) { /* Timed-out audio no longer owns this request. */ }
  });
  await page.locator('[data-quick="Ocean"]').click();
  await minimizeAmbientForBackgroundControls(page);
  await started;
  await page.evaluate(() => { window.expiredAmbientAudio = players.get('Ocean Waves'); });
  await page.clock.fastForward(21000);
  assert.equal(await page.evaluate(() => ambientTrackStatus('Ocean Waves')), 'error');
  assert.equal(await page.locator('[data-quick="Ocean"]').getAttribute('aria-busy'), 'false');
  assert.equal(await page.locator('#resume-sleep').getAttribute('aria-label'), 'Retry soundscape');
  assert.equal(await page.evaluate(() => expiredAmbientAudio.getAttribute('src')), null);
  release();
  await page.waitForLoadState('networkidle');
  await page.evaluate(() => {
    expiredAmbientAudio.dispatchEvent(new Event('playing'));
    expiredAmbientAudio.dispatchEvent(new Event('error'));
  });
  assert.equal(await page.evaluate(() => expiredAmbientAudio.paused), true);
  assert.equal(await page.locator('#shared-mini-player').isVisible(), true);
  assert.deepEqual(await page.evaluate(() => levels), { 'Ocean Waves': .6 });
});

test('ambient stability: rapid off/on fences old loads and events from the newer player', async t => {
  const { page, context } = await open(t);
  let release, requested, requests = 0;
  const gate = new Promise(resolve => { release = resolve; });
  const started = new Promise(resolve => { requested = resolve; });
  t.after(() => release());
  await context.route('**/assets/sounds/loop_ocean_waves.mp3', async route => {
    if (++requests === 1) { requested(); await gate; }
    try { await route.continue(); } catch (_) { /* The first load is intentionally discarded. */ }
  });
  await page.locator('[data-quick="Ocean"]').click();
  await minimizeAmbientForBackgroundControls(page);
  await started;
  await page.evaluate(() => { window.discardedAmbientAudio = players.get('Ocean Waves'); });
  await page.locator('[data-quick="Ocean"]').click();
  await minimizeAmbientForBackgroundControls(page);
  assert.equal(await page.evaluate(() => playing), false);
  await page.locator('[data-quick="Ocean"]').click();
  await minimizeAmbientForBackgroundControls(page);
  await page.waitForFunction(() => ambientTrackStatus('Ocean Waves') === 'playing');
  assert.equal(await page.evaluate(() => players.get('Ocean Waves') === discardedAmbientAudio), false);
  release();
  await page.waitForLoadState('networkidle');
  await page.evaluate(() => {
    discardedAmbientAudio.dispatchEvent(new Event('error'));
    discardedAmbientAudio.dispatchEvent(new Event('playing'));
    discardedAmbientAudio.dispatchEvent(new Event('pause'));
  });
  assert.equal(await page.evaluate(() => ambientTrackStatus('Ocean Waves')), 'playing');
  assert.equal(await page.evaluate(() => players.get('Ocean Waves').paused), false);
  assert.equal(await page.evaluate(() => discardedAmbientAudio.paused), true);
  assert.equal(await page.evaluate(() => discardedAmbientAudio.getAttribute('src')), null);
  assert.equal(await page.locator('[data-quick="Ocean"]').getAttribute('aria-pressed'), 'true');
  assert.deepEqual(await page.evaluate(() => levels), { 'Ocean Waves': .6 });
});

test('ambient stability: retrying one failed layer keeps the healthy player and safe levels', async t => {
  const { page, context } = await open(t);
  const requested = [];
  page.on('request', request => {
    if (/\/assets\/sounds\/[^/?]+\.mp3/.test(request.url())) requested.push(new URL(request.url()).pathname);
  });
  await context.route('**/assets/sounds/loop_soft_rain.mp3', route => route.abort());
  await page.locator('#begin-ocean').click();
  await minimizeAmbientForBackgroundControls(page);
  await page.waitForFunction(() => ambientTrackStatus('Ocean Waves') === 'playing'
    && ambientTrackStatus('Soft Rain') === 'error');
  await page.evaluate(() => {
    window.healthyOceanAudio = players.get('Ocean Waves');
    window.healthyOceanPosition = healthyOceanAudio.currentTime;
    window.healthyOceanPlays = 0;
    const originalPlay = healthyOceanAudio.play.bind(healthyOceanAudio);
    healthyOceanAudio.play = () => { healthyOceanPlays++; return originalPlay(); };
    // Gain/fade refreshes are not permission to retry a failed layer.
    syncAudio();
    cancelSleepTimer();
  });
  const attempts = requested.filter(asset => asset.endsWith('soft_rain.mp3')).length;
  assert.equal(attempts, 1);
  await context.unroute('**/assets/sounds/loop_soft_rain.mp3');
  await page.locator('#begin-ocean').click();
  await minimizeAmbientForBackgroundControls(page);
  await page.waitForFunction(() => ambientTrackStatus('Soft Rain') === 'playing');
  assert.equal(await page.evaluate(() => players.get('Ocean Waves') === healthyOceanAudio), true);
  assert.equal(await page.evaluate(() => healthyOceanPlays), 0, 'A healthy loop was not restarted');
  assert.equal(await page.evaluate(() => healthyOceanAudio.currentTime >= healthyOceanPosition), true);
  assert.deepEqual(await page.evaluate(() => levels), { 'Ocean Waves': .7, 'Soft Rain': .3 });
  assert.equal(await page.evaluate(() => healthyOceanAudio.volume), .7);
  assert.equal(await page.evaluate(() => players.get('Soft Rain').volume), .3);
  assert.equal(await page.locator('[data-quick="Rain"]').getAttribute('aria-pressed'), 'true');
  assert.doesNotMatch(await page.locator('#mini-subtitle').textContent(), /unavailable/);
  assert.deepEqual(new Set(requested), new Set(['/assets/sounds/loop_ocean_waves.mp3', '/assets/sounds/loop_soft_rain.mp3']));
});

test('ambient stability: waiting and runtime errors remove live glow without losing selection', async t => {
  const { page } = await open(t);
  await page.locator('[data-quick="Ocean"]').click();
  await minimizeAmbientForBackgroundControls(page);
  await page.waitForFunction(() => ambientTrackStatus('Ocean Waves') === 'playing');
  // Simulate platform events after real playback; this is not a device/network certification.
  await page.evaluate(() => { players.get('Ocean Waves').dispatchEvent(new Event('waiting')); });
  assert.equal(await page.locator('[data-quick="Ocean"]').getAttribute('aria-pressed'), 'false');
  assert.equal(await page.locator('[data-quick="Ocean"]').getAttribute('aria-busy'), 'true');
  assert.equal(await page.locator('#shared-mini-player').isVisible(), true);
  await page.evaluate(() => { players.get('Ocean Waves').dispatchEvent(new Event('playing')); });
  assert.equal(await page.locator('[data-quick="Ocean"]').getAttribute('aria-pressed'), 'true');
  await page.evaluate(() => { players.get('Ocean Waves').dispatchEvent(new Event('error')); });
  assert.equal(await page.locator('[data-quick="Ocean"]').getAttribute('aria-pressed'), 'false');
  assert.equal(await page.locator('#resume-sleep').getAttribute('aria-label'), 'Retry soundscape');
  assert.deepEqual(await page.evaluate(() => levels), { 'Ocean Waves': .6 });
  await page.locator('#resume-sleep').click();
  await minimizeAmbientForBackgroundControls(page);
  await page.waitForFunction(() => ambientTrackStatus('Ocean Waves') === 'playing');
  assert.equal(await page.locator('[data-quick="Ocean"]').getAttribute('aria-busy'), 'false');
});

test('ambient stability: starting Sounds cancels a pending timed session instead of overlapping it', async t => {
  const { page, context } = await open(t, { route: '/#meditate' });
  let release, requested;
  const gate = new Promise(resolve => { release = resolve; });
  const started = new Promise(resolve => { requested = resolve; });
  t.after(() => release());
  await context.route('**/assets/sounds/session_gentle_relief.mp3', async route => {
    requested();
    await gate;
    try { await route.continue(); } catch (_) { /* The cancelled session may stop fetching. */ }
  });
  await page.locator('#begin-gentle-relief').click();
  await started;
  await page.locator('#session-minimize').click();
  await page.locator('[data-tab="sounds"]').click();
  await page.locator('#master-play').click();
  await minimizeAmbientForBackgroundControls(page);
  await page.waitForFunction(() => ambientTrackStatus('Soft Rain') === 'playing');
  release();
  await page.waitForLoadState('networkidle');
  assert.equal(await page.evaluate(() => guidedSession.playing), false);
  assert.equal(await page.evaluate(() => guidedSession.loading), false);
  assert.equal(await page.evaluate(() => guidedAudio.paused), true);
  assert.equal(await page.evaluate(() => guidedSession.remaining), 900);
  assert.equal(await page.locator('#play-status').textContent(), 'Soundscape Active');
});

test('ambient stability: starting a timed session cancels a pending mixer load', async t => {
  const { page, context } = await open(t);
  let release, requested;
  const gate = new Promise(resolve => { release = resolve; });
  const started = new Promise(resolve => { requested = resolve; });
  t.after(() => release());
  await context.route('**/assets/sounds/loop_ocean_waves.mp3', async route => {
    requested();
    await gate;
    try { await route.continue(); } catch (_) { /* A new session cancels the mixer source. */ }
  });
  await page.locator('[data-quick="Ocean"]').click();
  await minimizeAmbientForBackgroundControls(page);
  await started;
  await page.evaluate(() => { window.interruptedAmbientAudio = players.get('Ocean Waves'); });
  await page.locator('[data-tab="meditate"]').click();
  await begin(page);
  release();
  await page.waitForLoadState('networkidle');
  assert.equal(await page.evaluate(() => playing), false);
  assert.equal(await page.evaluate(() => interruptedAmbientAudio.paused), true);
  assert.equal(await page.evaluate(() => interruptedAmbientAudio.getAttribute('src')), null);
  assert.equal(await page.evaluate(() => guidedSession.playing), true);
  assert.equal(await page.evaluate(() => guidedAudio.paused), false);
  assert.deepEqual(await page.evaluate(() => levels), { 'Ocean Waves': .6 });
});
