// Checks the independent HTML design preview, not a compiled Flutter build.
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
      response.setHeader('Content-Type', mime[path.extname(resolved)] || 'application/octet-stream');
      response.setHeader('Cache-Control', 'no-store');
      response.end(await readFile(resolved));
    } catch (_) {
      response.writeHead(404);
      response.end('Not found');
    }
  });
  await new Promise((resolve) => server.listen(0, '0.0.0.0', resolve));
  origin = `http://127.0.0.1:${server.address().port}`;
  browser = await chromium.launch({
    headless: true,
    executablePath: process.env.CHROMIUM_PATH || undefined,
    args: ['--disable-dev-shm-usage'],
  });
});

after(async () => {
  await browser?.close();
  if (server) await new Promise((resolve) => server.close(resolve));
});

async function open(t, { route = '/', width = 390, height = 844, blockFonts = false } = {}) {
  const context = await browser.newContext({ viewport: { width, height }, reducedMotion: 'reduce' });
  t.after(() => context.close());
  let blockedFonts = 0;
  if (blockFonts) await context.route('**/*', (route) => {
    if (route.request().resourceType() === 'font') {
      blockedFonts++;
      return route.abort();
    }
    return route.continue();
  });
  const page = await context.newPage();
  const errors = [];
  page.on('pageerror', (error) => errors.push(error.message));
  t.after(() => assert.deepEqual(errors, [], 'No unhandled browser errors'));
  await page.goto(`${origin}${route}`, { waitUntil: 'networkidle' });
  await page.evaluate(() => document.fonts.ready);
  return { page, context, blockedFonts: () => blockedFonts };
}

async function go(page, tab) {
  await page.locator(`.bottom-nav [data-tab="${tab}"]`).click();
  assert.equal(await page.locator('.bottom-nav [aria-current="page"]').getAttribute('data-tab'), tab);
}

// Rasterize the actual inline SVG geometry rather than merely counting nodes.
async function iconPixels(page) {
  return page.locator('.bottom-nav .nav-icon').evaluateAll(async (nodes) => {
    return Promise.all(nodes.map(async (node) => {
      const rect = node.getBoundingClientRect();
      const copy = node.cloneNode(true);
      copy.setAttribute('xmlns', 'http://www.w3.org/2000/svg');
      copy.setAttribute('width', '64');
      copy.setAttribute('height', '64');
      copy.style.color = getComputedStyle(node).color;
      const image = new Image();
      image.src = `data:image/svg+xml;charset=utf-8,${encodeURIComponent(new XMLSerializer().serializeToString(copy))}`;
      await image.decode();
      const canvas = document.createElement('canvas');
      canvas.width = canvas.height = 64;
      const context = canvas.getContext('2d');
      context.drawImage(image, 0, 0, 64, 64);
      const pixels = context.getImageData(0, 0, 64, 64).data;
      let visible = 0;
      let signature = 2166136261;
      for (let offset = 0; offset < pixels.length; offset++) {
        if (offset % 4 === 3 && pixels[offset] > 24) visible++;
        signature = Math.imul(signature ^ pixels[offset], 16777619);
      }
      return { visible, signature, width: rect.width, height: rect.height, display: getComputedStyle(node).display };
    }));
  });
}

test('Home is the default dashboard, not another copy of Sounds, and never autoplays', async (t) => {
  const { page } = await open(t);
  assert.equal(await page.locator('#home-page').isVisible(), true);
  assert.equal(await page.locator('main.content').isHidden(), true);
  assert.equal(await page.locator('#home-page h1').textContent(), 'Home');
  assert.match(await page.locator('.home-headline').innerText(), /A little calm/);
  assert.equal(await page.locator('#home-page .track').count(), 0);
  assert.equal(await page.locator('#home-page input[type="range"]').count(), 0);
  assert.equal(await page.evaluate(() => playing), false);
  assert.equal(await page.evaluate(() => guidedSession), null);
  assert.equal(await page.evaluate(() => [...players.values()].some((audio) => !audio.paused)), false);
});

test('all four tabs show different pages with one active footer item', async (t) => {
  const { page } = await open(t);
  for (const [tab, selector, heading] of [
    ['sounds', 'main.content', 'Sounds'],
    ['meditate', '#meditate-page', 'Meditate'],
    ['sleep', '#sleep-page', 'Sleep'],
    ['home', '#home-page', 'Home'],
  ]) {
    await go(page, tab);
    assert.equal(await page.locator(`${selector} h1`).textContent(), heading);
    assert.equal(await page.locator('main:visible').count(), 1);
    assert.deepEqual(await page.locator('.nav-item').allTextContents(), ['Home', 'Sounds', 'Meditate', 'Sleep']);
  }
});

test('Home and Sounds have distinct direct URLs and preserve shared-mix links', async (t) => {
  const { page } = await open(t, { route: '/?mix=Ocean%20Waves%3A40#sounds' });
  assert.equal(await page.locator('main.content').isVisible(), true);
  await go(page, 'home');
  assert.equal(await page.locator('#home-mix-name').textContent(), 'Ocean Waves');
  assert.equal(await page.evaluate(() => playing), false);
  assert.equal(new URL(page.url()).searchParams.get('mix'), 'Ocean Waves:40');
  await page.reload({ waitUntil: 'networkidle' });
  assert.equal(await page.locator('#home-page').isVisible(), true);
  await page.goto(`${origin}/#home`, { waitUntil: 'networkidle' });
  assert.equal(await page.locator('#home-page').isVisible(), true);
});

test('Home quick actions open Sounds, Meditate and Sleep without starting audio', async (t) => {
  const { page } = await open(t);
  for (const [tab, selector] of [['sounds', 'main.content'], ['meditate', '#meditate-page'], ['sleep', '#sleep-page']]) {
    await page.locator(`[data-home-tab="${tab}"]`).click();
    assert.equal(await page.locator(selector).isVisible(), true);
    assert.equal(await page.evaluate(() => currentTab), tab);
    assert.equal(await page.evaluate(() => playing || !!guidedSession?.playing), false);
    await go(page, 'home');
  }
});

test('Home daily session uses the real catalog title, duration and bundled sample', async (t) => {
  const { page } = await open(t);
  await page.locator('#home-daily').click();
  assert.equal(await page.locator('#session-title').textContent(), 'Calm Mountain Horizon');
  assert.match(await page.locator('#session-clock').textContent(), /^0?9:5[89]$|^10:00$/);
  await page.waitForFunction(() => !guidedAudio.paused && guidedAudio.readyState >= 2);
  assert.equal(await page.evaluate(() => guidedSession.minutes), 10);
  await page.locator('#session-stop').click();
  assert.equal(await page.evaluate(() => guidedAudio.paused), true);
  assert.equal(await page.locator('#home-daily').innerText(), 'Begin session');
});

test('Home and Sounds share live levels; pause/reload does not lose the mix or autoplay', async (t) => {
  const { page } = await open(t);
  await page.locator('#home-mix-toggle').click();
  await page.waitForFunction(() => !players.get('Soft Rain')?.paused && players.get('Soft Rain')?.readyState >= 2);
  assert.equal(await page.locator('#home-mix-status').textContent(), 'Playing · 1 layer');
  await go(page, 'sounds');
  assert.equal(await page.locator('#play-status').textContent(), 'Soundscape Active');
  await page.locator('[data-track="Soft Rain"] input[type="range"]').evaluate((input) => {
    input.value = '65';
    input.dispatchEvent(new Event('input', { bubbles: true }));
    input.dispatchEvent(new Event('change', { bubbles: true }));
  });
  await go(page, 'home');
  await page.locator('#home-mix-toggle').click();
  assert.equal(await page.evaluate(() => playing), false);
  assert.equal(await page.evaluate(() => levels['Soft Rain']), .65);
  assert.equal(await page.evaluate(() => players.get('Soft Rain').paused), true);
  await page.reload({ waitUntil: 'networkidle' });
  assert.equal(await page.locator('#home-page').isVisible(), true);
  assert.equal(await page.evaluate(() => levels['Soft Rain']), .65);
  assert.equal(await page.evaluate(() => playing), false);
  await page.locator('#home-edit-mix').click();
  assert.equal(await page.locator('[data-track="Soft Rain"] .volume-badge').textContent(), '65%');
});

test('empty Home selections use an explicit Soft Rain fallback rather than fictional history', async (t) => {
  const { page } = await open(t);
  await go(page, 'sounds');
  await page.getByRole('switch', { name: 'Enable Soft Rain', exact: true }).click();
  await go(page, 'home');
  assert.equal(await page.locator('#home-mix-name').textContent(), 'A fresh soundscape');
  await page.locator('#home-mix-toggle').click();
  assert.equal(await page.evaluate(() => levels['Soft Rain']), .3);
  assert.equal(await page.locator('#home-mix-name').textContent(), 'Soft Rain');
});

test('a named saved mix loaded in Sounds is reflected on Home', async (t) => {
  const { page } = await open(t);
  await go(page, 'sounds');
  await page.locator('#save').click();
  await page.locator('#mix-name').fill('Night Rain');
  await page.getByRole('button', { name: 'Save mix', exact: true }).click();
  await page.getByRole('button', { name: 'Saved mixes (1)', exact: true }).click();
  await page.getByRole('button', { name: 'Night Rain', exact: true }).click();
  await go(page, 'home');
  assert.equal(await page.locator('#home-mix-name').textContent(), 'Night Rain');
});

test('the preview discloses that wellbeing tools run in the Flutter application', async (t) => {
  const { page } = await open(t);
  await page.locator('#home-wellbeing').click();
  assert.match(await page.locator('#wellbeing-preview-dialog').innerText(), /not simulated by this design preview/);
  await page.locator('#close-wellbeing-preview').click();
  assert.equal(await page.locator('#wellbeing-preview-dialog').isVisible(), false);
});

for (const [width, height] of [[320, 640], [390, 844], [823, 1568], [1440, 1000]]) {
  test(`Home and all footer icons fit at ${width}px`, async (t) => {
    const { page } = await open(t, { width, height });
    assert.equal(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth), true);
    assert.equal(await page.evaluate(() => [...document.images].every((image) => image.complete && image.naturalWidth > 0)), true);
    assert.equal(await page.locator('.bottom-nav').evaluate((nav) => nav.getBoundingClientRect().bottom), height);
    const icons = await iconPixels(page);
    assert.equal(icons.length, 4);
    assert.equal(new Set(icons.map((icon) => icon.signature)).size, 4);
    for (const icon of icons) {
      assert(icon.width >= 24 && icon.height >= 24);
      assert(icon.visible > 80);
      assert.notEqual(icon.display, 'none');
    }
  });
}

for (const tab of ['home', 'sounds', 'meditate', 'sleep']) {
  test(`${tab}: all four footer icons remain visible when every font request fails`, async (t) => {
    const { page, blockedFonts } = await open(t, { blockFonts: true });
    await go(page, tab);
    assert(blockedFonts() > 0, 'Font-failure simulation actually blocked a font request');
    const icons = await iconPixels(page);
    assert.equal(icons.length, 4);
    for (const icon of icons) assert(icon.visible > 80);
    assert.equal(await page.locator(`.nav-item[data-tab="${tab}"] > svg`).evaluate((svg) => getComputedStyle(svg).color), 'rgb(67, 233, 205)');
  });
}
