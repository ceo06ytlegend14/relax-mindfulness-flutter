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

// Static browser availability must be checked before a UI action mutates audio,
// timers or saved data. Runtime decoding/network errors keep their retry path.
const dialog = '#preview-availability-dialog';
async function playOcean(page) {
  await page.locator('.bottom-nav [data-tab=sleep]').click();
  await page.locator('#begin-ocean').click();
  await minimizeAmbientForBackgroundControls(page);
  await page.waitForFunction(() => ambientPlaybackState().active.length === 2);
  await page.evaluate(() => {
    window.availabilityBefore = {
      levels: JSON.stringify(levels), deadline: sleepDeadline,
      preset: selectedPreset, stored: localStorage.getItem('sanctuary.designPreview.v1'),
      players: [...players.values()],
    };
  });
}
async function assertOceanKept(page) {
  assert.deepEqual(await page.evaluate(() => ({
    levels: JSON.stringify(levels) === availabilityBefore.levels,
    deadline: sleepDeadline === availabilityBefore.deadline,
    preset: selectedPreset === availabilityBefore.preset,
    stored: localStorage.getItem('sanctuary.designPreview.v1') === availabilityBefore.stored,
    players: [...players.values()].every((audio, index) => audio === availabilityBefore.players[index] && !audio.paused),
  })), { levels: true, deadline: true, preset: true, stored: true, players: true });
}
async function sources(page) {
  return page.locator('#preview-unavailable-sources [data-unavailable-source]').evaluateAll(nodes => nodes.map(node => node.dataset.unavailableSource));
}

for (const [label, source] of [['Wind', 'Soothing Breeze'], ['Thunder', 'Thunderstorm']]) {
  test(`${label} declares app-stream availability and cannot damage a playing mix`, async t => {
    const { page } = await open(t);
    await playOcean(page);
    const button = page.locator(`[data-quick="${label}"]`);
    assert.match(await button.textContent(), /App stream/);
    assert.match(await button.getAttribute('aria-label'), /not available in this preview/i);
    await button.click();
    assert.equal(await page.locator(dialog).isVisible(), true);
    assert.deepEqual(await sources(page), [source]);
    await assertOceanKept(page);
    assert.equal(await button.getAttribute('aria-pressed'), 'false');
    await page.locator('#preview-unavailable-keep').click();
    await assertOceanKept(page);
    assert.equal(await button.evaluate(node => node === document.activeElement), true);
    assert.doesNotMatch(await page.locator('#toast').textContent(), /Some selected sounds/);
  });
}

test('an unavailable Sleep control leaves a timed practice running', async t => {
  const { page } = await open(t);
  await page.locator('.bottom-nav [data-tab=meditate]').click();
  await page.locator('#begin-gentle-relief').click();
  await page.waitForFunction(() => guidedSession?.playing && !guidedAudio.paused);
  await page.locator('#session-minimize').click();
  await page.evaluate(() => { window.practiceAudioBefore = guidedAudio; });
  await page.locator('.bottom-nav [data-tab=sleep]').click();
  await page.locator('[data-quick="Wind"]').click();
  await minimizeAmbientForBackgroundControls(page);
  assert.equal(await page.locator(dialog).isVisible(), true);
  assert.equal(await page.evaluate(() => guidedAudio === practiceAudioBefore && !guidedAudio.paused && guidedSession.playing), true);
  assert.equal(await page.evaluate(() => sleepDeadline), null);
});

for (const [id, missing] of [
  ['night-forest', ['Night Forest', 'Soothing Breeze']],
  ['heavy-rain', ['Heavy Rain']],
  ['thunderstorm', ['Thunderstorm']],
]) {
  test(`${id} checks its whole recipe before changing a mix or sleep timer`, async t => {
    const { page } = await open(t);
    await playOcean(page);
    const card = page.locator(`[data-soundscape="${id}"]`);
    assert.match(await card.textContent(), /App stream|Unavailable/);
    await card.click();
    assert.deepEqual(await sources(page), missing);
    await assertOceanKept(page);
    const media = await page.evaluate(() => [...players.values()].map(audio => audio.currentSrc));
    assert.equal(media.length, 2, 'The healthy mix continues; no partial replacement is applied');
  });
}

test('legacy full-catalog recipes expose actual missing names without replacing the current mix', async t => {
  const { page } = await open(t);
  await playOcean(page);
  await page.locator('.bottom-nav [data-tab=sounds]').click();
  await page.locator('#catalog-review > summary').click();
  await page.locator('#library-full').click();
  const preset = page.locator('[data-preset="🌧️ Rainy Cabin"]');
  assert.match(await preset.textContent(), /Unavailable/);
  await preset.click();
  assert.deepEqual(await sources(page), ['Ambient Piano']);
  assert.match(await page.locator('#preview-unavailable-sources').textContent(), /No recording configured/);
  await assertOceanKept(page);
});

for (const entry of ['Sounds', 'Sleep']) {
  test(`unavailable saved mix from ${entry} is kept intact and never partially applied`, async t => {
    const stored = { levels: { 'Soft Rain': .3 }, favorites: ['Soft Rain'], saved: [{ name: 'Wind to keep', levels: { 'Soft Rain': .22, 'Soothing Breeze': .11 } }] };
    const { page } = await open(t, { stored });
    await playOcean(page);
    if (entry === 'Sounds') {
      await page.locator('.bottom-nav [data-tab=sounds]').click();
      await page.getByRole('button', { name: 'Saved mixes (1)', exact: true }).click();
      await page.locator('#saved-list').getByRole('button', { name: 'Wind to keep', exact: true }).click();
    } else {
      await page.locator('#saved-soundscapes').click();
      await page.locator('#library-options').getByRole('button', { name: /Wind to keep/ }).click();
    }
    assert.deepEqual(await sources(page), ['Soothing Breeze']);
    await assertOceanKept(page);
    assert.deepEqual(await page.evaluate(() => saved), stored.saved);
    await page.locator('#preview-unavailable-keep').click();
    assert.equal(await page.locator(entry === 'Sounds' ? '#saved-dialog' : '#library-dialog').isVisible(), true);
  });
}

for (const [tab, transport] of [['home', '#home-mix-toggle'], ['sounds', '#master-play'], ['sleep', '#resume-sleep']]) {
  test(`${tab} reviews non-bundled cached levels before interrupting another mode`, async t => {
    const stored = { levels: { 'Soft Rain': .31, 'Rain on Umbrella': .22 }, favorites: ['Rain on Umbrella'], saved: [] };
    const { page } = await open(t, { stored });
    await page.locator('.bottom-nav [data-tab=meditate]').click();
    await page.locator('#begin-quiet-mind').click();
    await page.waitForFunction(() => guidedSession?.playing && !guidedAudio.paused);
    await page.locator('#session-minimize').click();
    await page.locator(`.bottom-nav [data-tab=${tab}]`).click();
    assert.match(await page.locator(transport).getAttribute('aria-label'), /Review unavailable sounds/);
    await page.locator(transport).click();
    assert.deepEqual(await sources(page), ['Rain on Umbrella']);
    assert.deepEqual(await page.evaluate(() => levels), stored.levels);
    assert.equal(await page.evaluate(() => guidedSession.playing && !guidedAudio.paused), true);
    assert.equal(await page.evaluate(() => players.size), 0);
    assert.deepEqual(await page.evaluate(() => [...favorites]), stored.favorites);
  });
}

test('Review and Browse available are view-only actions with reachable source controls', async t => {
  const { page } = await open(t);
  await playOcean(page);
  await page.locator('[data-quick="Thunder"]').click();
  await minimizeAmbientForBackgroundControls(page);
  await page.locator('#preview-unavailable-review').click();
  assert.equal(await page.locator('#library-full').getAttribute('aria-pressed'), 'true');
  const change = page.locator('[data-sound-options="Thunderstorm"]');
  assert.equal(await change.evaluate(node => node === document.activeElement), true);
  await assertOceanKept(page);
  await page.locator('.bottom-nav [data-tab=sleep]').click();
  await page.locator('[data-quick="Wind"]').click();
  await minimizeAmbientForBackgroundControls(page);
  await page.locator('#preview-unavailable-available').click();
  assert.equal(await page.locator('#library-available').getAttribute('aria-pressed'), 'true');
  assert.equal(await page.locator('[data-track]').count(), 18);
  await assertOceanKept(page);
});

test('the low-level missing-source diagnostic names the source rather than offering an unrelated fix', async t => {
  const { page } = await open(t);
  await page.evaluate(() => { levels = { 'Rain Cave': .4 }; playing = true; syncAudio(); });
  assert.match(await page.locator('#toast').textContent(), /Rain Cave/);
  assert.doesNotMatch(await page.locator('#toast').textContent(), /Some selected sounds|Premium|purchase|cache/i);
  assert.equal(await page.evaluate(() => players.size), 0);
  assert.deepEqual(await page.evaluate(() => levels), { 'Rain Cave': .4 });
});

for (const width of [320, 390, 823]) {
  test(`availability details retain focus, 44px actions and large-text layout at ${width}px`, async t => {
    const { page } = await open(t, { width });
    await page.locator('.bottom-nav [data-tab=sleep]').click();
    await page.evaluate(() => document.documentElement.style.setProperty('--t', String(parseFloat(getComputedStyle(document.documentElement).getPropertyValue('--t')) * 1.6)));
    const wind = page.locator('[data-quick="Wind"]');
    await wind.focus();
    await page.keyboard.press('Enter');
    assert.equal(await page.locator(dialog).isVisible(), true);
    for (const id of ['keep', 'review', 'available']) {
      const button = page.locator(`#preview-unavailable-${id}`);
      await button.scrollIntoViewIfNeeded();
      const box = await button.boundingBox();
      assert(box.width >= 44 && box.height >= 44);
      await button.focus();
      assert.equal(await button.evaluate(node => node === document.activeElement), true);
    }
    assert.equal(await page.locator(dialog).evaluate(node => node.scrollWidth <= node.clientWidth), true);
    assert.equal(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth), true);
    await page.keyboard.press('Escape');
    assert.equal(await page.locator(dialog).isHidden(), true);
    assert.equal(await wind.evaluate(node => node === document.activeElement), true);
  });
}


test('a restored unavailable layer cannot be played indirectly by a Sounds switch', async t => {
  const stored = { levels: { 'Soft Rain': .31, 'Rain on Umbrella': .22 }, favorites: [], saved: [] };
  const { page } = await open(t, { stored });
  await page.locator('[data-track="Ocean Waves"]').getByRole('switch').click();
  assert.equal(await page.locator(dialog).isVisible(), true);
  assert.deepEqual(await sources(page), ['Rain on Umbrella']);
  assert.deepEqual(await page.evaluate(() => levels), stored.levels);
  assert.equal(await page.evaluate(() => players.size), 0);
  await page.locator('#preview-unavailable-review').click();
  await page.locator('[data-track="Rain on Umbrella"]').getByRole('switch').click();
  assert.equal(await page.evaluate(() => levels['Rain on Umbrella']), 0, 'An unsupported legacy layer is explicitly removable');
  assert.equal(await page.evaluate(() => levels['Soft Rain']), .31);
  assert.equal(await page.evaluate(() => playing || players.size > 0), false, 'Removing an unavailable layer is not permission to autoplay the others');
});

test('a restored unavailable layer cannot start via a slider or lose its cached level', async t => {
  const stored = { levels: { 'Soft Rain': .31, 'Rain on Umbrella': .22 }, favorites: [], saved: [] };
  const { page } = await open(t, { stored });
  const slider = page.locator('[data-track="Soft Rain"] input[type=range]');
  await slider.evaluate(node => { node.value = 48; node.dispatchEvent(new Event('input', { bubbles: true })); });
  assert.equal(await page.locator(dialog).isVisible(), true);
  assert.equal(await slider.inputValue(), '31');
  assert.deepEqual(await page.evaluate(() => levels), stored.levels);
  assert.deepEqual(await page.evaluate(() => JSON.parse(localStorage.getItem('sanctuary.designPreview.v1')).levels), stored.levels);
  assert.equal(await page.evaluate(() => players.size), 0);
});


test('legacy names can be explicitly removed from only the current selection, never from saved mixes', async t => {
  const stored = { levels: { 'Soft Rain': .31, 'Soothing Breeze': .22 }, favorites: ['Soothing Breeze'], saved: [{ name: 'Keep original', levels: { 'Soothing Breeze': .22 } }] };
  const { page } = await open(t, { stored });
  await page.locator('#master-play').click();
  await minimizeAmbientForBackgroundControls(page);
  await page.getByRole('button', { name: 'Remove Soothing Breeze from current mix', exact: true }).click();
  assert.deepEqual(await page.evaluate(() => levels), { 'Soft Rain': .31, 'Soothing Breeze': 0 });
  assert.deepEqual(await page.evaluate(() => saved), stored.saved);
  assert.deepEqual(await page.evaluate(() => [...favorites]), stored.favorites);
  assert.equal(await page.evaluate(() => playing || players.size > 0), false);
  await page.locator('#preview-unavailable-keep').click();
  await page.locator('#master-play').click();
  await minimizeAmbientForBackgroundControls(page);
  await page.waitForFunction(() => ambientPlaybackState().active.length === 1);
  assert.equal(await page.evaluate(() => [...players.keys()][0]), 'Soft Rain');
  assert.equal(await page.evaluate(() => ambientPlaybackState().failed.length), 0);
});
