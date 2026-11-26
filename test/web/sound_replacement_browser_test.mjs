// Exercises the independent browser preview, not a compiled Flutter application.
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

async function open(t, { route = '/#sounds', width = 390, height = 844, blockFonts = false, virtualClock = false } = {}) {
  const context = await browser.newContext({ viewport: { width, height }, reducedMotion: 'reduce' });
  t.after(() => context.close());
  let fontsBlocked = 0;
  if (blockFonts) await context.route('**/*', route => {
    if (route.request().resourceType() === 'font') { fontsBlocked++; return route.abort(); }
    return route.continue();
  });
  const page = await context.newPage();
  if (virtualClock) await page.clock.install({ time: new Date('2026-11-19T20:00:00Z') });
  const errors = [];
  page.on('pageerror', error => errors.push(error.message));
  t.after(() => assert.deepEqual(errors, [], 'No unhandled browser errors'));
  await page.goto(`${origin}${route}`, { waitUntil: 'networkidle' });
  await page.evaluate(() => document.fonts.ready);
  return { page, context, fontsBlocked: () => fontsBlocked };
}
async function chooser(page, name = 'Soft Rain') {
  await page.locator(`[data-sound-options="${name}"]`).click();
  assert.equal(await page.locator('#sound-replacement-dialog').isVisible(), true);
}
async function choose(page, name) {
  await page.locator(`[data-select-recording="${name}"]`).click();
}
async function preview(page, name) {
  await page.locator(`[data-preview-recording="${name}"]`).click();
  await page.waitForFunction(() => soundPreviewAudio && !soundPreviewAudio.paused && !soundPreviewLoading && soundPreviewAudio.readyState >= 2);
}

test('all 75 familiar sounds plus two new cards have working local images', async t => {
  const { page } = await open(t);
  assert.equal(await page.evaluate(() => all.length), 77);
  await page.locator('#catalog-review > summary').click();
  await page.locator('#library-full').click();
  assert.equal(await page.locator('[data-sound-options="Soft Rain"] svg circle').count(), 3, 'Options are actual three-dot vectors on the first render');
  for (const category of await page.evaluate(() => CATALOG.map(c => c.id))) {
    await page.locator(`[data-category="${category}"]`).click();
    const covers = await page.locator('#tracks .art img').evaluateAll(async images => {
      await Promise.all(images.map(image => image.decode()));
      return images.map(image => ({ src: image.getAttribute('src'), width: image.naturalWidth }));
    });
    assert.equal(covers.length, await page.locator('#tracks .track').count());
    assert.ok(covers.every(cover => cover.src.startsWith('assets/images/') && cover.width > 0));
    assert.equal(await page.locator('#tracks .art').evaluateAll(nodes => nodes.some(n => n.textContent.trim())), false);
  }
  assert.deepEqual(await page.locator('.bottom-nav .nav-item').allTextContents(), ['Home', 'Sounds', 'Meditate', 'Sleep']);
});

test('opening, choosing and canceling do not autoplay or edit selected levels', async t => {
  const { page } = await open(t);
  const before = await page.evaluate(() => JSON.stringify(levels));
  await chooser(page);
  assert.equal(await page.evaluate(() => soundPreviewAudio), null);
  assert.equal(await page.evaluate(() => players.size), 0);
  assert.equal(await page.locator('#replacement-use').isDisabled(), true);
  await choose(page, 'Ocean Waves');
  assert.equal(await page.evaluate(() => JSON.stringify(levels)), before);
  assert.equal(await page.evaluate(() => soundPreviewAudio), null);
  await page.locator('#replacement-close').click();
  assert.equal(await page.evaluate(() => JSON.stringify(levels)), before);
  assert.equal(await page.evaluate(() => playing), false);
  assert.equal(await page.evaluate(() => players.size), 0);
});

for (const [name, file] of [
  ['Soft Rain', 'soft_rain'], ['Ocean Waves', 'ocean_waves'], ['Forest Birds', 'forest_birds'],
  ['Campfire', 'campfire'], ['Bamboo Chimes', 'wind_chimes'], ['Temple Bowl', 'tibetan_bowls'],
  ['Woodland Morning', 'woodland_morning'], ['Boat Deck', 'boat_deck'], ['Mountain Stream', 'woodland_stream'],
  ['Meadow Breeze', 'meadow_wind'], ['Coffee Shop', 'cafe_ambience'], ['Fireplace', 'fireplace'], ['Crickets', 'night_crickets'],
  ['White Noise', 'noise_white'], ['Pink Noise', 'noise_pink'], ['Brown Noise', 'noise_brown'],
  ['Blue Noise', 'noise_blue'], ['Violet Noise', 'noise_violet'],
]) {
  test(`explicit ${name} preview decodes and plays its actual bundled clip`, async t => {
    const { page } = await open(t);
    await chooser(page);
    await preview(page, name);
    assert.equal(await page.evaluate(() => soundPreviewAudio.volume), .08);
    assert.equal(await page.evaluate(() => soundPreviewAudio.loop), false);
    assert.ok((await page.evaluate(() => soundPreviewAudio.currentSrc)).endsWith(`/${file}.mp3`));
    assert.ok(await page.evaluate(() => soundPreviewAudio.duration > 0));
    assert.equal(await page.evaluate(() => playing), false);
    assert.deepEqual(await page.evaluate(() => levels), { 'Soft Rain': .3 });
    await page.evaluate(() => { window.previousPreview = soundPreviewAudio; });
    await page.locator('#replacement-close').click();
    await page.waitForFunction(() => soundPreviewAudio === null);
    assert.equal(await page.evaluate(() => previousPreview.paused), true);
    assert.equal(await page.evaluate(() => soundPreviewDuck), 1);
  });
}

test('Use swaps only one playing layer at its existing level and preserves other players', async t => {
  const { page } = await open(t);
  await page.evaluate(() => applyMix({ 'Soft Rain': .6, 'Forest Birds': .2 }, 'Before'));
  await minimizeAmbientForBackgroundControls(page);
  await page.waitForFunction(() => [...players.values()].filter(a => !a.paused && a.readyState >= 2).length === 2);
  await chooser(page);
  assert.ok(Math.abs(await page.evaluate(() => players.get('Soft Rain').volume) - .6) < .001);
  await preview(page, 'Ocean Waves');
  assert.ok(Math.abs(await page.evaluate(() => players.get('Soft Rain').volume) - .12) < .001);
  assert.ok(Math.abs(await page.evaluate(() => players.get('Forest Birds').volume) - .04) < .001);
  await choose(page, 'Ocean Waves');
  assert.deepEqual(await page.evaluate(() => levels), { 'Soft Rain': .6, 'Forest Birds': .2 });
  await page.evaluate(() => { window.birdPlayer = players.get('Forest Birds'); window.birdTime = birdPlayer.currentTime; window.previousPreview = soundPreviewAudio; });
  await page.locator('#replacement-use').click();
  await page.waitForFunction(() => !players.get('Ocean Waves')?.paused && players.get('Ocean Waves')?.readyState >= 2);
  assert.deepEqual(await page.evaluate(() => levels), { 'Ocean Waves': .6, 'Forest Birds': .2 });
  assert.equal(await page.evaluate(() => players.get('Soft Rain').paused), true);
  assert.equal(await page.evaluate(() => players.get('Forest Birds') === birdPlayer), true);
  assert.ok(await page.evaluate(() => birdPlayer.currentTime >= birdTime));
  assert.equal(await page.evaluate(() => birdPlayer.volume), .2);
  assert.equal(await page.evaluate(() => previousPreview.paused), true);
  assert.equal(await page.evaluate(() => selectedPreset), null);
  assert.equal(await page.evaluate(() => category), 'nature');
});

test('a paused replacement, saved mix and reload preserve the chosen sound without autoplay', async t => {
  const { page } = await open(t);
  await chooser(page);
  await choose(page, 'Ocean Waves');
  await page.locator('#replacement-use').click();
  assert.equal(await page.evaluate(() => playing), false);
  assert.deepEqual(await page.evaluate(() => levels), { 'Ocean Waves': .3 });
  assert.equal(await page.evaluate(() => players.size), 0);
  await page.locator('#save').click();
  await page.locator('#mix-name').fill('Shoreline swap');
  await page.getByRole('button', { name: 'Save mix', exact: true }).click();
  await page.reload({ waitUntil: 'networkidle' });
  assert.deepEqual(await page.evaluate(() => levels), { 'Ocean Waves': .3 });
  assert.deepEqual(await page.evaluate(() => saved[0]), { name: 'Shoreline swap', levels: { 'Ocean Waves': .3 } });
  assert.equal(await page.evaluate(() => playing), false);
  await page.getByRole('button', { name: 'Saved mixes (1)', exact: true }).click();
  await page.getByRole('button', { name: 'Shoreline swap', exact: true }).click();
  await page.waitForFunction(() => !players.get('Ocean Waves')?.paused);
  assert.equal(await page.evaluate(() => selectedPreset), 'Shoreline swap');
});

test('existing sounds and legacy aliases are not offered as independent duplicates', async t => {
  const { page } = await open(t);
  await page.evaluate(() => { levels = { 'Soft Rain': .3, 'Ocean Waves': .2, 'Cozy Hearth': .1 }; render(); });
  await chooser(page);
  assert.equal(await page.locator('[data-select-recording="Ocean Waves"]').isDisabled(), true);
  assert.equal(await page.locator('[data-select-recording="Campfire"]').isDisabled(), true);
  assert.equal(await page.locator('[data-select-recording="Soft Rain"]').isDisabled(), true);
  assert.match(await page.locator('[data-recording="Campfire"]').innerText(), /Already in mix: Cozy Hearth/);
  assert.equal(await page.locator('.replacement-row').count(), 18);
});

test('preview errors do not change a live mix or expose platform payloads', async t => {
  const { page, context } = await open(t);
  await page.locator('#master-play').click();
  await minimizeAmbientForBackgroundControls(page);
  await page.waitForFunction(() => !players.get('Soft Rain')?.paused);
  await context.route('**/assets/sounds/ocean_waves.mp3', route => route.abort());
  await chooser(page);
  await page.locator('[data-preview-recording="Ocean Waves"]').click();
  await page.waitForFunction(() => !$('replacement-error').hidden);
  assert.equal(await page.locator('#replacement-error').textContent(), 'Preview could not play. Your mix was not changed.');
  assert.deepEqual(await page.evaluate(() => levels), { 'Soft Rain': .3 });
  assert.equal(await page.evaluate(() => players.get('Soft Rain').paused), false);
  assert.equal(await page.evaluate(() => players.get('Soft Rain').volume), .3);
  assert.equal(await page.evaluate(() => soundPreviewAudio), null);
});

test('closing during a delayed load prevents late preview autoplay', async t => {
  const { page, context } = await open(t);
  let pending;
  await context.route('**/assets/sounds/ocean_waves.mp3', route => { pending = route; });
  await chooser(page);
  await page.locator('[data-preview-recording="Ocean Waves"]').click();
  await page.waitForFunction(() => soundPreviewLoading);
  await page.evaluate(() => { window.previousPreview = soundPreviewAudio; });
  await page.locator('#replacement-close').click();
  await page.waitForFunction(() => soundPreviewAudio === null);
  if (pending) await pending.continue().catch(() => {});
  assert.equal(await page.evaluate(() => previousPreview.paused), true);
  assert.equal(await page.evaluate(() => playing), false);
  assert.equal(await page.evaluate(() => soundPreviewDuck), 1);
});

test('the explicit eight-second preview limit stops audio and restores mix gain', async t => {
  const { page } = await open(t, { virtualClock: true });
  await chooser(page);
  await preview(page, 'Ocean Waves');
  await page.evaluate(() => { window.previousPreview = soundPreviewAudio; });
  await page.clock.fastForward(8100);
  assert.equal(await page.evaluate(() => soundPreviewAudio), null);
  assert.equal(await page.evaluate(() => previousPreview.paused), true);
  assert.equal(await page.evaluate(() => soundPreviewDuck), 1);
});

test('unconfigured names are labelled and cannot silently play generic rain', async t => {
  const { page } = await open(t);
  await page.getByRole('switch', { name: 'Enable Soft Rain', exact: true }).click();
  assert.equal(await page.evaluate(() => players.size), 0);
  await page.locator('#catalog-review > summary').click();
  await page.locator('#library-full').click();
  const card = page.locator('[data-track="Rain Cave"]');
  assert.match(await card.locator('.track-info p').innerText(), /No recording configured/);
  assert.equal(await card.getByRole('switch').isDisabled(), true);
  assert.equal(await page.evaluate(() => players.size), 0);
  assert.equal(await page.evaluate(() => playing), false);
  await chooser(page, 'Rain Cave');
  await choose(page, 'Ocean Waves');
  await page.locator('#replacement-use').click();
  assert.equal(await page.evaluate(() => levels['Rain Cave']), undefined);
  assert.equal(await page.evaluate(() => levels['Ocean Waves']), .3);
  assert.equal(await page.evaluate(() => playing), false, 'Replacing a selected but unavailable layer does not autoplay');
  assert.equal(await page.evaluate(() => ambientPlaybackState().active.length), 0);
});

for (const [width, height] of [[320, 640], [390, 844], [823, 1024], [844, 390]]) {
  test(`replacement sheet is scrollable and font-independent at ${width}×${height}`, async t => {
    const { page } = await open(t, { width, height, blockFonts: true });
    await chooser(page);
    await choose(page, 'Temple Bowl');
    const use = await page.locator('#replacement-use').boundingBox();
    assert.ok(use && use.y >= 0 && use.y + use.height <= height);
    assert.ok(use.height >= 44);
    assert.equal(await page.locator('[data-preview-recording="Temple Bowl"] svg').count(), 1);
    assert.ok(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth));
    await page.locator('#replacement-use').click();
    assert.deepEqual(await page.evaluate(() => Object.fromEntries(Object.entries(levels).filter(([,v]) => v > 0))), { 'Temple Bowl': .3 });
    assert.equal(await page.evaluate(() => playing), false);
  });
}

test('the chooser temporarily hides the real install entry without changing player or install state', async t => {
  const { page } = await open(t);
  const entry = page.locator('#sanctuary-install-ui .install-entry');
  assert.equal(await entry.isVisible(), true);
  await chooser(page);
  assert.equal(await page.evaluate(() => document.documentElement.classList.contains('sanctuary-sound-chooser-open')), true);
  assert.equal(await entry.isVisible(), false);
  // The player has a separate visibility owner; closing the chooser must not
  // reveal the entry if a different full-screen overlay still owns the corner.
  await page.evaluate(() => document.documentElement.classList.add('sanctuary-player-expanded'));
  await page.locator('#replacement-close').click();
  await page.waitForFunction(() => !document.documentElement.classList.contains('sanctuary-sound-chooser-open'));
  assert.equal(await entry.isVisible(), false);
  await page.evaluate(() => document.documentElement.classList.remove('sanctuary-player-expanded'));
  assert.equal(await entry.isVisible(), true);
  assert.equal(await page.evaluate(() => playing), false);
});

test('new sounds are searchable, attributed and usable without starting a paused mix', async t => {
  const { page } = await open(t);
  await chooser(page);
  await page.locator('#replacement-search').fill('noise');
  assert.equal(await page.locator('.replacement-row').count(),5);
  assert.equal(await page.locator('.replacement-credit').count(),5);
  assert.equal(await page.evaluate(()=>soundPreviewAudio),null);
  assert.deepEqual(await page.evaluate(()=>levels),{'Soft Rain':.3});
  await choose(page,'Blue Noise');
  await page.locator('#replacement-use').click();
  assert.deepEqual(await page.evaluate(()=>levels),{'Blue Noise':.3});
  assert.equal(await page.evaluate(()=>playing),false);
  assert.equal(await page.evaluate(()=>category),'noise');
  await page.locator('#master-play').click();
  await minimizeAmbientForBackgroundControls(page);
  await page.waitForFunction(()=>players.get('Blue Noise')?.readyState>=2&&!players.get('Blue Noise').paused);
  assert.match(await page.evaluate(()=>players.get('Blue Noise').currentSrc),/noise_blue\.mp3$/);
});

test('empty sound searches have a useful state and do not alter selections', async t => {
  const { page } = await open(t);
  await chooser(page);
  await page.locator('#replacement-search').fill('no recording with this name');
  assert.match(await page.locator('#replacement-list').innerText(),/No local sounds match/);
  assert.equal(await page.locator('#replacement-use').isDisabled(),true);
  assert.equal(await page.evaluate(()=>soundPreviewAudio),null);
  await page.locator('#replacement-search').fill('');
  assert.equal(await page.locator('.replacement-row').count(),18);
});
