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
// User-specified recipe contract, independent of production data.
const sets = JSON.parse(await readFile(path.join(root, 'test/fixtures/curated_sound_mixes.json'), 'utf8'));
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

async function open(t, { width = 390, stored = null } = {}) {
  const context = await browser.newContext({ viewport: { width, height: 920 }, reducedMotion: 'reduce' });
  t.after(() => context.close());
  if (stored) await context.addInitScript(stored => {
    if (!localStorage.getItem('sanctuary.designPreview.v1')) localStorage.setItem('sanctuary.designPreview.v1', JSON.stringify(stored));
  }, stored);
  const page = await context.newPage();
  const errors = [];
  page.on('pageerror', error => errors.push(error.message));
  t.after(() => assert.deepEqual(errors, [], 'No unhandled browser errors'));
  await page.goto(`${origin}/#sounds`, { waitUntil: 'networkidle' });
  await page.evaluate(() => document.fonts.ready);
  return { page, context };
}
async function playSet(page, set) {
  await page.locator(`[data-vibe-set="${set.id}"]`).click();
  await minimizeAmbientForBackgroundControls(page);
  await page.waitForFunction(count => ambientPlaybackState().active.length === count && !ambientPlaybackState().pending.length, Object.keys(set.levels).length);
}

// Assert the requested replacement catalog before any playback or migration.
test('ten requested bundled mixes are discoverable without autoplay or overwriting saved mixes', async t => {
  const stored = { levels: { 'Ocean Waves': .27 }, favorites: ['Ocean Waves'], saved: [{ name: 'My kept shoreline', levels: { 'Ocean Waves': .27 } }] };
  const { page } = await open(t, { stored });
  assert.equal(await page.locator('[data-vibe-set]').count(), 10);
  assert.deepEqual(await page.locator('[data-vibe-set]').allTextContents(), sets.map(set => set.name));
  assert.equal(await page.locator('#presets [data-preset]').count(), 11, 'Available view excludes recipes with unavailable ingredients');
  await page.locator('#catalog-review > summary').click();
  await page.locator('#library-full').click();
  assert.equal(await page.locator('#presets [data-preset]').count(), 18, 'All eight older presets remain in the full catalog');
  assert.equal(await page.locator('#vibe-set-details').isHidden(), true);
  assert.deepEqual(await page.evaluate(() => levels), stored.levels);
  assert.deepEqual(await page.evaluate(() => saved), stored.saved);
  assert.equal(await page.evaluate(() => playing || !!guidedSession?.playing || players.size > 0), false);
});

for (const set of sets) {
  test(`vibe set ${set.name} plays its exact local layers and slider percentages`, async t => {
    const { page } = await open(t);
    const requests = [];
    page.on('request', request => { if (/\/assets\/sounds\/[^/?]+\.mp3/.test(request.url())) requests.push(new URL(request.url()).pathname); });
    await page.locator(`[data-vibe-set="${set.id}"]`).click();
    await minimizeAmbientForBackgroundControls(page);
    assert.deepEqual(await page.evaluate(() => levels), set.levels, 'Selection changes synchronously, not after media loads');
    const controls = await page.locator('#tracks [data-track]').evaluateAll(cards => cards.map(card => ({
      name: card.dataset.track,
      checked: card.querySelector('[role=switch]').getAttribute('aria-checked'),
      badge: card.querySelector('.volume-badge').textContent,
      slider: card.querySelector('input[type=range]')?.value ?? null,
    })));
    assert.equal(controls.length, 18);
    for (const control of controls) {
      const percent = Math.round((set.levels[control.name] || 0) * 100);
      assert.equal(control.checked, String(percent > 0), `${control.name} switch immediately reflects the recipe`);
      assert.equal(control.badge, percent + '%');
      assert.equal(control.slider, percent > 0 ? String(percent) : null);
    }
    assert.equal(await page.evaluate(() => all.every(track => (levels[track.name] || 0) === (VIBE_SETS.find(set => set.name === selectedPreset).levels[track.name] || 0))), true, 'Every unselected entry in the full 77-card catalog is at zero');
    await page.waitForFunction(count => ambientPlaybackState().active.length === count && !ambientPlaybackState().pending.length, Object.keys(set.levels).length);
    assert.equal(await page.evaluate(() => selectedPreset), set.name);
    assert.equal(await page.locator(`[data-vibe-set="${set.id}"]`).getAttribute('aria-pressed'), 'true');
    assert.equal(await page.locator('#vibe-set-name').textContent(), set.name);
    assert.equal(await page.locator('#vibe-set-purpose').textContent(), set.purpose);
    const recipe = Object.entries(set.levels).map(([name, volume]) => `${name} ${Math.round(volume * 100)}%`).join(' · ');
    assert.equal(await page.locator('#vibe-set-levels').textContent(), recipe);
    assert.match(await page.locator('#vibe-set-notice').textContent(), /Starting volumes.*not.*loudness/i);
    assert.match(await page.locator('#vibe-set-notice').textContent(), /not.*100%|need not total 100%/i);
    const gain = 1 / Object.values(set.levels).reduce((sum, value) => sum + value, 0);
    const active = await page.evaluate(() => ambientPlaybackState().active.map(([name]) => ({ name, volume: players.get(name).volume, path: new URL(players.get(name).currentSrc).pathname, loop: players.get(name).loop })));
    assert.equal(active.length, Object.keys(set.levels).length);
    for (const layer of active) {
      assert(Math.abs(layer.volume - set.levels[layer.name] * gain) < 1e-9, `${layer.name} keeps the existing overall output limiter without changing its slider percentage`);
      assert.equal(layer.loop, true);
      assert.match(layer.path, /^\/assets\/sounds\/[^/]+\.mp3$/);
    }
    assert.deepEqual(new Set(requests), new Set(active.map(layer => layer.path)), 'No remote source, substitute or rendered session asset was fetched');
    await page.locator('#master-play').click();
    await minimizeAmbientForBackgroundControls(page);
    assert.equal(await page.evaluate(() => ambientPlaybackState().active.length), 0);
    assert.deepEqual(await page.evaluate(() => levels), set.levels);
    assert.equal(await page.locator('#vibe-set-details').isVisible(), true);
    await page.locator('#master-play').click();
    await minimizeAmbientForBackgroundControls(page);
    await page.waitForFunction(count => ambientPlaybackState().active.length === count, Object.keys(set.levels).length);
    assert.deepEqual(await page.evaluate(() => levels), set.levels);
  });
}

test('switching vibe sets changes only required layers without restarting shared loops', async t => {
  const { page } = await open(t);
  await playSet(page, sets[0]);
  await page.evaluate(() => {
    window.keptRain = players.get('Soft Rain');
    window.keptBrown = players.get('Brown Noise');
    window.removedCoffee = players.get('Coffee Shop');
    window.extraPlays = 0;
    for (const audio of [keptRain, keptBrown]) {
      const play = audio.play.bind(audio);
      audio.play = () => { window.extraPlays++; return play(); };
    }
    keptRain.currentTime = 7;
  });
  await playSet(page, sets[4]);
  assert.equal(await page.evaluate(() => players.get('Soft Rain') === keptRain && players.get('Brown Noise') === keptBrown), true);
  assert.equal(await page.evaluate(() => extraPlays), 0);
  assert((await page.evaluate(() => keptRain.currentTime)) >= 6.9);
  assert.equal(await page.evaluate(() => removedCoffee.paused), true);
  assert.deepEqual(await page.evaluate(() => levels), sets[4].levels);
});

test('editing or choosing a same-named custom recipe never shows a false official recipe', async t => {
  const stored = { levels: { 'Soft Rain': .3 }, favorites: [], saved: [{ name: 'Rainy Window Café', levels: { 'Soft Rain': .19 } }] };
  const { page } = await open(t, { stored });
  await playSet(page, sets[0]);
  await page.locator('[data-track="Soft Rain"] input[type="range"]').evaluate(input => {
    input.value = '31';
    input.dispatchEvent(new Event('input', { bubbles: true }));
    input.dispatchEvent(new Event('change', { bubbles: true }));
  });
  assert.equal(await page.locator('#vibe-set-details').isHidden(), true);
  assert.equal(await page.locator('[data-vibe-set][aria-pressed=true]').count(), 0);
  await page.getByRole('button', { name: 'Saved mixes (1)', exact: true }).click();
  await page.locator('#saved-list > div > button').first().click();
  await page.waitForFunction(() => ambientPlaybackState().active.length === 1);
  assert.equal(await page.locator('#vibe-set-details').isHidden(), true);
  assert.equal(await page.locator('[data-vibe-set][aria-pressed=true]').count(), 0);
  assert.deepEqual(await page.evaluate(() => levels), { 'Soft Rain': .19 });
});

test('vibe set save/share/reload retains exact levels and never autoplays on reload', async t => {
  const { page } = await open(t);
  await playSet(page, sets[8]);
  await page.locator('#save').click();
  await page.locator('#mix-name').fill('My starlit campfire');
  await page.locator('#save-form button[type=submit]').click();
  assert.deepEqual(await page.evaluate(() => saved[0]), { name: 'My starlit campfire', levels: sets[8].levels });
  await page.evaluate(() => Object.defineProperty(navigator, 'clipboard', { configurable: true, value: { writeText: async value => { window.copiedMixLink = value; } } }));
  await page.locator('#share').click();
  const shared = new URL(await page.evaluate(() => copiedMixLink));
  assert.deepEqual(Object.fromEntries(shared.searchParams.get('mix').split(',').map(pair => {
    const split = pair.lastIndexOf(':'); return [pair.slice(0, split), Number(pair.slice(split + 1)) / 100];
  })), sets[8].levels);
  await page.reload({ waitUntil: 'networkidle' });
  assert.deepEqual(await page.evaluate(() => levels), sets[8].levels);
  assert.equal(await page.evaluate(() => playing || players.size > 0), false);
  assert.equal(await page.locator('[data-vibe-set]').count(), 10);
});

test('a failed set ingredient is explicit and switching sets never substitutes audio', async t => {
  const { page, context } = await open(t);
  await context.route('**/assets/sounds/cafe_ambience.mp3', route => route.abort());
  await page.locator('[data-vibe-set="rainy-window-cafe"]').click();
  await minimizeAmbientForBackgroundControls(page);
  await page.waitForFunction(() => ambientPlaybackState().failed.length === 1 && ambientPlaybackState().active.length === 3);
  assert.deepEqual(await page.evaluate(() => levels), sets[0].levels);
  assert.deepEqual(await page.evaluate(() => ambientPlaybackState().failed.map(([name]) => name)), ['Coffee Shop']);
  assert.match(await page.locator('#play-description').textContent(), /3 active layers.*1 unavailable/);
  assert.equal(await page.locator('#vibe-set-details').isVisible(), true, 'The displayed recipe is a selection, never proof that every layer played');
  await playSet(page, sets[6]);
  assert.equal(await page.evaluate(() => ambientPlaybackState().failed.length), 0);
  assert.deepEqual(await page.evaluate(() => levels), sets[6].levels);
});

test('choosing a vibe set pauses the session mode without changing the four destinations', async t => {
  const { page } = await open(t);
  await page.locator('.bottom-nav [data-tab="meditate"]').click();
  await page.locator('#begin-daily').click();
  await page.waitForFunction(() => guidedSession?.playing && !guidedAudio.paused);
  await page.locator('#session-minimize').click();
  await page.locator('.bottom-nav [data-tab="sounds"]').click();
  await playSet(page, sets[1]);
  assert.equal(await page.evaluate(() => guidedSession.playing || !guidedAudio.paused), false);
  assert.deepEqual(await page.locator('.bottom-nav .nav-item').allTextContents(), ['Home', 'Sounds', 'Meditate', 'Sleep']);
  await page.locator('.bottom-nav [data-tab="home"]').click();
  assert.equal(await page.locator('#home-mix-name').textContent(), sets[1].name);
  await page.locator('.bottom-nav [data-tab="sleep"]').click();
  assert.equal(await page.locator('#continue-name').textContent(), sets[1].name);
});

for (const width of [320, 390, 823]) {
  test(`all ten vibe sets keep 44px targets, keyboard focus and wrapping at ${width}px`, async t => {
    const { page } = await open(t, { width });
    await page.evaluate(() => {
      const root = document.documentElement;
      root.style.setProperty('--t', String(parseFloat(getComputedStyle(root).getPropertyValue('--t')) * 1.6));
    });
    for (const set of sets) {
      const chip = page.locator(`[data-vibe-set="${set.id}"]`);
      await chip.scrollIntoViewIfNeeded();
      const box = await chip.boundingBox();
      assert(box.width >= 44 && box.height >= 44);
      await chip.focus();
      assert.equal(await chip.evaluate(node => node === document.activeElement), true);
      const style = await chip.evaluate(node => ({ outline: getComputedStyle(node).outlineStyle, shadow: getComputedStyle(node).boxShadow, border: getComputedStyle(node).borderTopWidth }));
      assert.equal(style.outline, 'solid');
      assert.equal(style.shadow, 'none');
      assert.equal(style.border, '0px');
    }
    await page.keyboard.press('Enter');
    await page.waitForFunction(() => ambientPlaybackState().active.length === 4);
    assert.equal(await page.locator('#vibe-set-name').textContent(), sets[9].name);
    await minimizeAmbientForBackgroundControls(page);
    await page.locator('#vibe-set-details').scrollIntoViewIfNeeded();
    assert.equal(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth), true);
    assert.equal(await page.locator('#vibe-set-details').evaluate(node => node.scrollWidth <= node.clientWidth), true);
  });
}


test('customized levels save separately and reselecting the official recipe restores only its exact levels', async t => {
  const { page } = await open(t);
  await playSet(page, sets[0]);
  await page.locator('[data-track="Soft Rain"] input[type=range]').evaluate(input => {
    input.value = 41;
    input.dispatchEvent(new Event('input', { bubbles: true }));
    input.dispatchEvent(new Event('change', { bubbles: true }));
  });
  const custom = { ...sets[0].levels, 'Soft Rain': .41 };
  assert.equal(await page.locator('#vibe-set-details').isHidden(), true);
  await page.locator('#save').click();
  await page.locator('#mix-name').fill('My window café');
  await page.locator('#save-form button[type=submit]').click();
  assert.deepEqual(await page.evaluate(() => saved), [{ name: 'My window café', levels: custom }]);
  await playSet(page, sets[0]);
  assert.deepEqual(await page.evaluate(() => levels), sets[0].levels);
  assert.deepEqual(await page.evaluate(() => saved[0].levels), custom);
  assert.deepEqual(await page.evaluate(() => VIBE_SETS[0].levels), sets[0].levels, 'Custom changes never write into the official recipe');
  await page.getByRole('button', { name: 'Saved mixes (1)', exact: true }).click();
  await page.getByRole('button', { name: 'My window café', exact: true }).click();
  assert.deepEqual(await page.evaluate(() => levels), custom);
  assert.equal(await page.locator('#vibe-set-details').isHidden(), true);
});

test('loading a requested mix clears all prior local and legacy selections without editing saved snapshots', async t => {
  const stored = { levels: { 'Pink Noise': .47, 'Soothing Breeze': .22 }, favorites: ['Pink Noise'], saved: [{ name: 'Rainlit Cabin', levels: { 'Soft Rain': .42, Fireplace: .20, 'Brown Noise': .08 } }] };
  const { page } = await open(t, { stored });
  await playSet(page, sets[7]);
  assert.deepEqual(await page.evaluate(() => levels), sets[7].levels);
  assert.equal(await page.evaluate(() => levels['Pink Noise'] || levels['Soothing Breeze'] || 0), 0);
  assert.deepEqual(await page.evaluate(() => saved), stored.saved);
  assert.deepEqual(await page.evaluate(() => [...favorites]), stored.favorites);
  await page.getByRole('button', { name: 'Saved mixes (1)', exact: true }).click();
  await page.getByRole('button', { name: 'Rainlit Cabin', exact: true }).click();
  await page.waitForFunction(() => ambientPlaybackState().active.length === 3);
  assert.deepEqual(await page.evaluate(() => levels), stored.saved[0].levels);
  assert.equal(await page.locator('#vibe-set-details').isHidden(), true);
});

test('toggling an ingredient off customizes the selection without mutating the preset', async t => {
  const { page } = await open(t);
  await playSet(page, sets[9]);
  await page.locator('[data-track="Bamboo Chimes"]').getByRole('switch').click();
  assert.equal(await page.evaluate(() => levels['Bamboo Chimes']), 0);
  assert.equal(await page.locator('#vibe-set-details').isHidden(), true);
  assert.equal(await page.locator('[data-vibe-set][aria-pressed=true]').count(), 0);
  assert.deepEqual(await page.evaluate(() => VIBE_SETS[9].levels), sets[9].levels);
  await playSet(page, sets[9]);
  assert.equal(await page.locator('[data-track="Bamboo Chimes"]').getByRole('switch').getAttribute('aria-checked'), 'true');
  assert.equal(await page.locator('[data-track="Bamboo Chimes"] input[type=range]').inputValue(), '10');
});
