// Independent HTML playback/UI checks, not compiled Flutter or human listening.
import assert from 'node:assert/strict';
import { minimizeAmbientForBackgroundControls } from './support/ambient_player_helpers.mjs';
import { createServer } from 'node:http';
import { readFile, realpath } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { after, before, test } from 'node:test';

const { chromium } = await import(process.env.PLAYWRIGHT_MODULE || 'playwright');
const root = path.resolve(fileURLToPath(new URL('../../', import.meta.url)));
const directory = path.join(root, 'design/preview');
const mime = { '.html': 'text/html', '.js': 'text/javascript', '.json': 'application/json', '.css': 'text/css', '.png': 'image/png', '.webp': 'image/webp', '.ttf': 'font/ttf', '.mp3': 'audio/mpeg' };
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

async function open(t, { width = 390, stored = null, virtualClock = false } = {}) {
  const context = await browser.newContext({ viewport: { width, height: 920 }, reducedMotion: 'reduce' });
  t.after(() => context.close());
  if (stored) await context.addInitScript(stored => {
    if (!localStorage.getItem('sanctuary.designPreview.v1')) localStorage.setItem('sanctuary.designPreview.v1', JSON.stringify(stored));
  }, stored);
  const page = await context.newPage();
  if (virtualClock) await page.clock.install({ time: new Date('2026-11-19T20:00:00Z') });
  const errors = [];
  page.on('pageerror', error => errors.push(error.message));
  t.after(() => assert.deepEqual(errors, [], 'No unhandled browser errors'));
  await page.goto(`${origin}/#sounds`, { waitUntil: 'networkidle' });
  await page.evaluate(() => document.fonts.ready);
  return { page, context };
}

// Launch hardening is presentation/recovery, not a paid-content gate.
test('normal browsing exposes 18 bundled sounds, not an unfinished 77-sound library', async t => {
  const { page } = await open(t);
  assert.equal(await page.locator('#catalog-review').count(), 1);
  assert.equal(await page.locator('#catalog-review').getAttribute('open'), null);
  assert.equal(await page.locator('#library-full').isHidden(), true);
  assert.equal(await page.locator('[data-track]').count(), 18);
  assert.equal(await page.locator('[data-vibe-set]').count(), 10);
  assert.equal(await page.evaluate(() => players.size || playing), false);
});

test('expanding catalog review explains the inventory without selecting or starting anything', async t => {
  const stored = { levels: { 'Soft Rain': .31, 'Rain on Umbrella': .22 }, favorites: ['Rain on Umbrella'], saved: [{ name: 'Kept', levels: { 'Rain on Umbrella': .22 } }] };
  const { page } = await open(t, { stored });
  await page.locator('#catalog-review > summary').focus();
  await page.keyboard.press('Enter');
  assert.match(await page.locator('#catalog-review-description').textContent(), /18 bundled.*23.*stream.*36.*recording/i);
  assert.equal(await page.locator('[data-track]').count(), 18);
  assert.deepEqual(await page.evaluate(() => levels), stored.levels);
  assert.deepEqual(await page.evaluate(() => saved), stored.saved);
  assert.deepEqual(await page.evaluate(() => [...favorites]), stored.favorites);
  assert.equal(await page.evaluate(() => players.size || playing), false);
});

test('full review is explicit, names unfinished content and returns to the 18-source view', async t => {
  const { page } = await open(t);
  await page.locator('#catalog-review > summary').click();
  await page.locator('#library-full').click();
  assert.equal(await page.locator('[data-track]').count(), 77);
  assert.equal(await page.locator('#presets [data-preset]').count(), 18);
  assert.match(await page.locator('#library-notice').textContent(), /Catalog review.*not.*77.*playable/i);
  assert.match(await page.locator('[data-track="Rain Cave"]').textContent(), /No recording/);
  await page.locator('#library-available').click();
  assert.equal(await page.locator('[data-track]').count(), 18);
  assert.equal(await page.locator('#library-full').isHidden(), true);
  assert.equal(await page.locator('#library-available').evaluate(node => node === document.activeElement), true);
  assert.equal(await page.evaluate(() => players.size || playing), false);
});

test('closing unfinished catalog review returns to bundled browsing without changing selected levels', async t => {
  const { page } = await open(t);
  const selected = await page.evaluate(() => levels);
  await page.locator('#catalog-review > summary').click();
  await page.locator('#library-full').click();
  await page.locator('#catalog-review > summary').click();
  await page.waitForFunction(() => availableOnly);
  assert.equal(await page.locator('[data-track]').count(), 18);
  assert.equal(await page.locator('#library-full').isHidden(), true);
  assert.deepEqual(await page.evaluate(() => levels), selected);
  assert.equal(await page.evaluate(() => players.size || playing), false);
});

test('review navigation preserves real playing identities, levels, gain and saved data', async t => {
  const { page } = await open(t);
  await page.locator('[data-vibe-set="rainy-window-cafe"]').click();
  await minimizeAmbientForBackgroundControls(page);
  await page.waitForFunction(() => ambientPlaybackState().active.length === 4);
  await page.evaluate(() => { window.launchReviewBefore = { levels: JSON.stringify(levels), players: [...players.values()], gain: [...players.values()].map(audio => audio.volume), storage: localStorage.getItem('sanctuary.designPreview.v1') }; });
  await page.locator('#catalog-review > summary').click();
  await page.locator('#library-full').click();
  await page.locator('#library-available').click();
  assert.equal(await page.evaluate(() => JSON.stringify(levels) === launchReviewBefore.levels && localStorage.getItem('sanctuary.designPreview.v1') === launchReviewBefore.storage && [...players.values()].every((audio, i) => audio === launchReviewBefore.players[i] && !audio.paused && audio.volume === launchReviewBefore.gain[i])), true);
});

test('a preserved unsupported selection can still be deliberately reviewed and changed', async t => {
  const stored = { levels: { 'Soft Rain': .31, 'Rain on Umbrella': .22 }, favorites: ['Rain on Umbrella'], saved: [{ name: 'Kept', levels: { 'Rain on Umbrella': .22 } }] };
  const { page } = await open(t, { stored });
  await page.locator('#library-review-selected').click();
  assert.equal(await page.locator('#library-full').getAttribute('aria-pressed'), 'true');
  assert.equal(await page.locator('#catalog-review').evaluate(node => node.open), true);
  assert.equal(await page.locator('[data-sound-options="Rain on Umbrella"]').evaluate(node => node === document.activeElement), true);
  assert.deepEqual(await page.evaluate(() => levels), stored.levels);
  assert.deepEqual(await page.evaluate(() => saved), stored.saved);
  assert.equal(await page.evaluate(() => players.size || playing), false);
});

test('reloading a reviewed catalog restores only the saved selection, not the unfinished browsing mode or playback', async t => {
  const { page } = await open(t);
  await page.locator('[data-vibe-set="rainy-window-cafe"]').click();
  await minimizeAmbientForBackgroundControls(page);
  await page.waitForFunction(() => ambientPlaybackState().active.length === 4);
  const selected = await page.evaluate(() => levels);
  await page.locator('#catalog-review > summary').click();
  await page.locator('#library-full').click();
  await page.reload({ waitUntil: 'networkidle' });
  assert.equal(await page.locator('[data-track]').count(), 18);
  assert.equal(await page.locator('#library-full').isHidden(), true);
  assert.deepEqual(await page.evaluate(() => levels), selected);
  assert.equal(await page.evaluate(() => players.size || playing), false);
});

for (const width of [320, 390, 823]) {
  test(`catalog review is keyboard-reachable and wraps with 1.6x text at ${width}px`, async t => {
    const { page } = await open(t, { width });
    await page.evaluate(() => document.documentElement.style.setProperty('--t', String(parseFloat(getComputedStyle(document.documentElement).getPropertyValue('--t')) * 1.6)));
    const summary = page.locator('#catalog-review > summary');
    await summary.scrollIntoViewIfNeeded();await summary.focus();
    const bounds = await summary.boundingBox();assert(bounds.height >= 44 && bounds.width >= 44);
    await page.keyboard.press('Enter');
    const review = page.locator('#library-full');await review.scrollIntoViewIfNeeded();await review.focus();
    const box = await review.boundingBox();assert(box.height >= 44 && box.width >= 44);
    assert.equal(await review.evaluate(node => node === document.activeElement), true);
    assert.equal(await page.locator('#catalog-review').evaluate(node => node.scrollWidth <= node.clientWidth), true);
    assert.equal(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth), true);
    assert.equal(await page.evaluate(() => players.size || playing), false);
  });
}
