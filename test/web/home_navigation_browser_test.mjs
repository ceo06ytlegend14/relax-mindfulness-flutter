// Checks the independent HTML design preview, not a compiled Flutter build.
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

async function open(t, { route = '/', width = 390, height = 844, blockFonts = false, virtualClock = false } = {}) {
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
  if (virtualClock) await page.clock.install({ time: new Date('2026-11-19T12:00:00Z') });
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
  await minimizeAmbientForBackgroundControls(page);
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
  await minimizeAmbientForBackgroundControls(page);
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
  await minimizeAmbientForBackgroundControls(page);
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
  await minimizeAmbientForBackgroundControls(page);
  await go(page, 'home');
  assert.equal(await page.locator('#home-mix-name').textContent(), 'Night Rain');
});

test('wellbeing has real pushed-page designs and discloses the separate browser history', async (t) => {
  const { page } = await open(t);
  await page.locator('#home-wellbeing').click();
  assert.equal(await page.locator('#wellbeing-page').isVisible(), true);
  assert.equal(await page.locator('#wellbeing-route-title').textContent(), 'Your wellbeing');
  assert.match(await page.locator('.wellbeing-week').innerText(), /0 \/ 7/);
  assert.match(await page.locator('.wellbeing-preview-label').innerText(), /not your Flutter app/);
  assert.equal(await page.locator('.install-entry').count(), 0, 'No install entry is mounted over a pushed-page header');
  await page.locator('[data-wellbeing-route="breathing"]').click();
  assert.equal(await page.locator('#wellbeing-route-title').textContent(), 'Breathing room');
  assert.equal(await page.locator('#meditate-page').isVisible(), false, 'Breathing never aliases to Meditate');
  assert.equal(await page.locator('#breathing-time').textContent(), '03:00');
  await page.locator('#wellbeing-back').click();
  assert.equal(await page.locator('#wellbeing-route-title').textContent(), 'Your wellbeing');
  await page.locator('[data-wellbeing-route="backup"]').click();
  assert.match(await page.locator('.wellbeing-preview-boundary').innerText(), /cannot access or replace your Flutter data/);
  assert.equal(await page.getByRole('button', {name:'Copy backup in the Flutter app'}).isDisabled(), true);
  await page.locator('[data-tab="home"]').click();
  assert.equal(await page.locator('#home-page').isVisible(), true);
  assert.equal(await page.locator('.install-entry').count(), 0, 'Returning Home never recreates the removed install entry');
});

for (const [width, height] of [[320, 640], [390, 844], [823, 1568], [1440, 1000]]) {
  test(`Home and all footer icons fit at ${width}px`, async (t) => {
    const { page } = await open(t, { width, height });
    assert.equal(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth), true);
    assert.equal(await page.evaluate(() => [...document.images].every((image) => image.complete && image.naturalWidth > 0)), true);
    assert.equal(await page.locator('.bottom-nav').evaluate((nav) => nav.getBoundingClientRect().bottom), height - 12);
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
    assert.equal(await page.locator(`.nav-item[data-tab="${tab}"] > svg`).evaluate((svg) => getComputedStyle(svg).color), 'rgb(154, 255, 230)');
  });
}

for (const width of [320, 390, 823]) {
  test(`Meditate has a solid background, creative inset cards and working filters at ${width}px`, async t => {
    const { page } = await open(t, { route: '/#meditate', width });
    const background = await page.locator('#meditate-page').evaluate(node => ({ color:getComputedStyle(node).backgroundColor, image:getComputedStyle(node).backgroundImage }));
    assert.deepEqual(background, { color:'rgb(2, 19, 44)', image:'none' });
    assert.equal(await page.locator('#meditate-page .scenery').count(), 0);
    assert.equal(await page.locator('.practice-orbit .arched-art').first().evaluate(image => image.naturalWidth > 0), true);
    await page.locator('[data-intent="Calm"]').click();
    assert.equal(await page.locator('[data-practice]').count(), await page.evaluate(() => MEDITATIONS.filter(s=>['Comfort','Healing'].includes(s.intent)).length));
    assert.equal(await page.locator('[data-practice="morning-awakening"]').count(), 0);
    assert.equal(await page.evaluate(()=>guidedSession), null);
    await page.locator('[data-practice-options="gentle-relief"]').click();
    await page.getByRole('button', {name:'Save practice',exact:true}).click();
    assert.equal(await page.locator('[data-practice="gentle-relief"]').evaluate(node=>node.classList.contains('saved')), true);
    assert.equal(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth), true);
    await page.locator('[data-intent="All"]').click();
    assert.equal(await page.locator('[data-practice]').count(), 3);
    await page.locator('#browse-practices').click();
    assert.equal(await page.locator('[data-practice]').count(), 14);
  });

  test(`all wellbeing destinations remain plain and scrollable at ${width}px`, async t => {
    const { page } = await open(t, {route:'/#wellbeing/hub',width});
    for (const section of ['hub','breathing','progress','reflection','backup']) {
      await page.evaluate(section=>openWellbeing(section), section);
      assert.equal(await page.locator('#wellbeing-page').isVisible(), true);
      assert.equal(await page.locator('#wellbeing-page').evaluate(node=>getComputedStyle(node).backgroundImage), 'none');
      assert.equal(await page.locator('#wellbeing-page img').count(), 0);
      assert.equal(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth), true);
      assert.equal(await page.locator('.bottom-nav [aria-current="page"]').getAttribute('data-tab'), 'home');
      // scrollIntoViewIfNeeded ignores fixed-footer occlusion if a node is
      // already inside the viewport. Exercise the real reachable scroll end.
      await page.evaluate(()=>scrollTo(0,document.documentElement.scrollHeight));
      const boundary=await page.locator('.wellbeing-preview-label').boundingBox();
      const footer=await page.locator('.bottom-nav').boundingBox();
      assert(boundary.y+boundary.height<=footer.y, 'The final content scrolls above the unchanged footer');
    }
  });
}

test('breathing pause/resume preserves its phase and pattern changes reset safely', async t => {
  const { page } = await open(t, {route:'/#wellbeing/breathing',virtualClock:true});
  await page.locator('[data-breathing-pattern="2"]').click();
  await page.locator('#breathing-toggle').click();
  await page.clock.fastForward(2100);
  assert.equal(await page.locator('#breathing-phase-seconds').textContent(), '3');
  await page.locator('#breathing-toggle').click();
  const time=await page.locator('#breathing-time').textContent();
  await page.clock.fastForward(600000);
  assert.equal(await page.locator('#breathing-time').textContent(),time);
  assert.equal(await page.locator('#breathing-toggle').textContent(),'Resume practice');
  await page.locator('#breathing-toggle').click();
  await page.clock.fastForward(3100);
  assert.equal(await page.locator('#breathing-phase').textContent(),'Breathe out');
  await page.locator('[data-breathing-pattern="0"]').click();
  assert.equal(await page.locator('#breathing-time').textContent(),'03:00');
  assert.equal(await page.locator('#breathing-phase-seconds').textContent(),'4');
  assert.equal(await page.evaluate(()=>previewBreaths.length),0);
});

test('a completed breathing practice adds one actual preview record, never sample progress', async t => {
  const { page } = await open(t, {route:'/#wellbeing/breathing',virtualClock:true});
  await page.locator('[data-breathing-duration="1"]').click();
  await page.locator('#breathing-toggle').click();
  await page.clock.fastForward(61000);
  assert.equal(await page.locator('#breathing-time').textContent(),'00:00');
  assert.equal(await page.evaluate(()=>previewBreaths.length),1);
  await page.clock.fastForward(120000);
  assert.equal(await page.evaluate(()=>previewBreaths.length),1);
  await page.locator('#wellbeing-back').click();
  assert.match(await page.locator('.wellbeing-week').innerText(),/1 \/ 7/);
  await page.locator('[data-wellbeing-route="progress"]').click();
  assert.equal(await page.locator('.progress-total').textContent(),'1 min');
  assert.equal(await page.locator('.wellbeing-session').count(),1);
  await page.reload({waitUntil:'networkidle'});
  assert.equal(await page.locator('.wellbeing-session').count(),1);
  assert.equal(await page.evaluate(()=>guidedSession),null);
});

test('hiding the browser or changing footer tabs pauses breathing without adding a session', async t => {
  const { page } = await open(t, {route:'/#wellbeing/breathing',virtualClock:true});
  await page.locator('#breathing-toggle').click();
  await page.clock.fastForward(2100);
  await page.evaluate(()=>{Object.defineProperty(document,'hidden',{configurable:true,value:true});document.dispatchEvent(new Event('visibilitychange'));});
  const paused=await page.locator('#breathing-time').textContent();
  await page.clock.fastForward(600000);
  await page.evaluate(()=>{Object.defineProperty(document,'hidden',{configurable:true,value:false});document.dispatchEvent(new Event('visibilitychange'));});
  assert.equal(await page.locator('#breathing-time').textContent(),paused);
  assert.equal(await page.locator('#breathing-toggle').textContent(),'Resume practice');
  await page.locator('#breathing-toggle').click();
  await go(page,'sounds');
  await page.clock.fastForward(600000);
  assert.equal(await page.evaluate(()=>breathing.running),false);
  assert.equal(await page.evaluate(()=>previewBreaths.length),0);
});

test('reflection safely renders local text and reports clipboard denial without claiming a save', async t => {
  const { page } = await open(t, {route:'/#wellbeing/reflection'});
  const prompt='<img src=x onerror="window.unwanted=true">';
  await page.locator('#wellbeing-reflection-input').fill(prompt);
  await page.locator('#wellbeing-create-reflection').click();
  assert.match(await page.locator('#wellbeing-reflection-output').textContent(),/<img src=x/);
  assert.equal(await page.locator('#wellbeing-reflection-output img').count(),0);
  assert.equal(await page.evaluate(()=>window.unwanted),undefined);
  await page.evaluate(()=>Object.defineProperty(navigator,'clipboard',{configurable:true,value:{writeText:async()=>{throw new Error('denied');}}}));
  await page.locator('#wellbeing-copy-reflection').click();
  assert.equal(await page.locator('#wellbeing-reflection-notice').textContent(),'Clipboard access failed. Nothing was saved.');
  await page.locator('#wellbeing-back').click();
  await page.locator('[data-wellbeing-route="reflection"]').click();
  assert.equal(await page.locator('#wellbeing-reflection-input').inputValue(),'');
});

// The softer-surface trial is deliberately Home-only. Playback and the four-tab
// shell remain the real shared preview, not inert screenshot replacements.
test('soft Home: cards use matte fills instead of decorative borders and glow', async t => {
  const { page } = await open(t);
  const cards = await page.locator('.home-daily, .home-action, .home-soundscape, .home-wellbeing').evaluateAll(nodes => nodes.map(node => {
    const style = getComputedStyle(node);
    return { name: node.className, borders: [style.borderTopWidth, style.borderRightWidth, style.borderBottomWidth, style.borderLeftWidth],
      shadow: style.boxShadow, fill: style.backgroundColor, radius: parseFloat(style.borderTopLeftRadius) };
  }));
  assert.equal(cards.length, 6);
  for (const card of cards) {
    assert.deepEqual(card.borders, ['0px', '0px', '0px', '0px'], card.name);
    assert.equal(card.shadow, 'none', card.name);
    assert.notEqual(card.fill, 'rgba(0, 0, 0, 0)', 'Grouping remains visible through filled surfaces');
    assert(card.radius >= 10, 'The existing rounded-card vocabulary remains');
  }
  const decorations = await page.locator('#home-page .section-heading').evaluateAll(nodes => nodes.map(node => getComputedStyle(node, '::after').content));
  assert.deepEqual(decorations, ['none', 'none'], 'Section labels no longer draw decorative rules');
  assert.equal(await page.locator('#home-mix-toggle').evaluate(node => getComputedStyle(node).borderTopWidth), '0px');
  assert.equal(await page.locator('#home-daily > span').evaluate(node => getComputedStyle(node).backgroundImage), 'none');
  assert.equal(await page.evaluate(() => playing || !!guidedSession?.playing), false);
});

test('soft Home: borderless actions retain touch targets, text contrast and visible keyboard focus', async t => {
  const { page } = await open(t);
  await page.keyboard.press('Tab');
  for (const selector of ['#home-daily', '[data-home-tab="sounds"]', '[data-home-tab="meditate"]', '[data-home-tab="sleep"]', '#home-mix-toggle', '#home-edit-mix', '#home-wellbeing']) {
    const button = page.locator(selector);
    await button.focus();
    const style = await button.evaluate(node => {
      const rect = node.getBoundingClientRect(), css = getComputedStyle(node);
      return { width: rect.width, height: rect.height, visible: node.matches(':focus-visible'), outlineWidth: parseFloat(css.outlineWidth), outlineStyle: css.outlineStyle };
    });
    assert(style.width >= 44 && style.height >= 44, selector + ' keeps a 44px target');
    assert(style.visible && style.outlineWidth >= 2 && style.outlineStyle === 'solid', selector + ' retains a visible focus ring');
  }
  const colors = await page.evaluate(() => [
    ['.home-action-detail', '.home-action'],
    ['#home-mix-status', '.home-soundscape'],
    ['.home-wellbeing small', '.home-wellbeing'],
    ['#home-daily > span', '#home-daily > span'],
  ].map(([text, surface]) => ({ foreground: getComputedStyle(document.querySelector(text)).color,
    background: getComputedStyle(document.querySelector(surface)).backgroundColor })));
  const luminance = rgb => {
    const [r, g, b] = rgb.match(/[\d.]+/g).slice(0, 3).map(Number).map(value => {
      value /= 255; return value <= .04045 ? value / 12.92 : ((value + .055) / 1.055) ** 2.4;
    });
    return .2126 * r + .7152 * g + .0722 * b;
  };
  for (const { foreground, background } of colors) {
    const values = [luminance(foreground), luminance(background)].sort((a, b) => b - a);
    assert((values[0] + .05) / (values[1] + .05) >= 4.5, 'Normal text on the new solid fills retains at least 4.5:1 contrast');
  }
  await page.locator('[data-home-tab="sounds"]').focus();
  await page.keyboard.press('Enter');
  assert.equal(await page.locator('main.content').isVisible(), true);
  assert.equal(await page.evaluate(() => playing), false, 'Keyboard navigation does not start audio');
});

for (const width of [320, 390]) {
  test(`soft Home: larger text wraps and final actions stay reachable at ${width}px`, async t => {
    const { page } = await open(t, { width, height: 844 });
    await page.evaluate(() => {
      const root = document.documentElement;
      const size = parseFloat(getComputedStyle(root).getPropertyValue('--t'));
      root.style.setProperty('--t', String(size * 1.6));
    });
    assert.equal(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth), true);
    for (const selector of ['#home-daily', '[data-home-tab="meditate"]', '#home-mix-toggle', '#home-wellbeing']) {
      await page.locator(selector).scrollIntoViewIfNeeded();
      const bounds = await page.locator(selector).boundingBox();
      assert(bounds.width >= 44 && bounds.height >= 44);
      assert(bounds.x >= 0 && bounds.x + bounds.width <= width + 1);
    }
    await page.evaluate(() => scrollTo(0, document.documentElement.scrollHeight));
    const note = await page.locator('.home-note').boundingBox();
    const footer = await page.locator('.bottom-nav').boundingBox();
    assert(note.y + note.height <= footer.y, 'The last Home content clears the unchanged footer');
    assert.equal(await page.evaluate(() => playing || !!guidedSession?.playing), false);
  });
}

// The user approved extending the Home trial. Container borders are no longer
// isolation requirements; meaningful symbol, focus and state outlines still are.
async function expectMatte(page, selector) {
  const panels = await page.locator(selector).evaluateAll(nodes => nodes.map(node => {
    const css = getComputedStyle(node);
    return { name: node.id || node.className, borders: [css.borderTopWidth, css.borderRightWidth, css.borderBottomWidth, css.borderLeftWidth],
      shadow: css.boxShadow, image: css.backgroundImage, fill: css.backgroundColor };
  }));
  assert(panels.length > 0, selector + ' matches rendered panels');
  for (const panel of panels) {
    assert.deepEqual(panel.borders, ['0px', '0px', '0px', '0px'], panel.name);
    assert.equal(panel.shadow, 'none', panel.name);
    assert.equal(panel.image, 'none', panel.name + ' uses a matte fill, not a card gradient');
    assert.notEqual(panel.fill, 'rgba(0, 0, 0, 0)', panel.name + ' retains tonal grouping');
  }
}

async function expectTouchFocus(page, selectors) {
  await page.keyboard.press('Tab');
  for (const selector of selectors) {
    const action = page.locator(selector).first();
    await action.focus();
    const style = await action.evaluate(node => {
      const rect = node.getBoundingClientRect(), css = getComputedStyle(node);
      return { width: rect.width, height: rect.height, visible: node.matches(':focus-visible'), outline: css.outlineStyle, size: parseFloat(css.outlineWidth) };
    });
    assert(style.width >= 44 && style.height >= 44, selector + ' keeps a 44px target');
    assert(style.visible && style.outline === 'solid' && style.size >= 2, selector + ' keeps keyboard focus');
  }
}

async function expectContrast(page, pairs) {
  const colors = await page.evaluate(pairs => pairs.map(([text, surface]) => ({ name: text,
    foreground: getComputedStyle(document.querySelector(text)).color,
    background: getComputedStyle(document.querySelector(surface)).backgroundColor,
  })), pairs);
  const luminance = rgb => rgb.match(/[\d.]+/g).slice(0, 3).map(Number).map(value => {
    value /= 255; return value <= .04045 ? value / 12.92 : ((value + .055) / 1.055) ** 2.4;
  }).reduce((total, value, index) => total + value * [.2126, .7152, .0722][index], 0);
  for (const { name, foreground, background } of colors) {
    const [light, dark] = [luminance(foreground), luminance(background)].sort((a, b) => b - a);
    assert((light + .05) / (dark + .05) >= 4.5, name + ' retains at least 4.5:1 contrast on its solid fill');
  }
}

test('soft pages: shared panels are matte while Sleep symbols and selected navigation remain distinct', async t => {
  const { page } = await open(t);
  await go(page, 'sounds');
  await expectMatte(page, '.master.surface, #tracks .track');
  assert.equal(await page.locator('.section-heading').first().evaluate(node => getComputedStyle(node, '::after').content), 'none');
  await go(page, 'meditate');
  assert.equal(await page.locator('#meditate-page').evaluate(node => getComputedStyle(node).backgroundColor), 'rgb(2, 19, 44)');
  await expectMatte(page, '#meditate-page .daily-journey, #meditate-page .practice-card');
  await go(page, 'sleep');
  await expectMatte(page, '#sleep-page .night-surface');
  assert.equal(await page.locator('#quick-mixer').getAttribute('data-control-design'), 'large-outline');
  assert.equal(await page.locator('#quick-mixer [data-quick]').count(), 5);
  assert.equal(await page.locator('[data-quick="Thunder"] .quick-orb').evaluate(node => getComputedStyle(node).color), 'rgb(245, 201, 109)');
  assert.equal(await page.locator('[data-quick="Rain"] .quick-orb path').first().evaluate(node => getComputedStyle(node).fill), 'none');
  await expectTouchFocus(page, ['#sleep-timer-button', '.story-filters button', '[data-quick="Thunder"]']);
  for (const tab of ['home', 'sounds', 'meditate', 'sleep']) {
    await go(page, tab);
    assert.equal(await page.locator('.bottom-nav').evaluate(node => getComputedStyle(node).borderTopWidth), '1px');
    assert.notEqual(await page.locator('.nav-item.active > span').evaluate(node => getComputedStyle(node, '::before').content), 'none', 'The selected capsule also has a non-color dot indicator');
  }
  assert.equal(await page.evaluate(() => playing || !!guidedSession?.playing), false);
});

test('soft pages: Sounds controls retain touch, focus, contrast and non-color selected cues', async t => {
  const { page } = await open(t, { route: '/#sounds' });
  await expectMatte(page, '.play-dial, #save, .mix-chip, .category');
  await expectTouchFocus(page, ['#master-play', '#save', '#shuffle', '#share', '.mix-chip', '.category', '[data-sound-options="Soft Rain"]', '.toggle-hit', '.slider']);
  await page.locator('[data-category="nature"]').click();
  assert.match(await page.locator('[data-category="nature"]').evaluate(node => getComputedStyle(node).textDecorationLine), /underline/);
  assert.equal(await page.locator('.category[aria-selected=true]').count(), 1);
  await expectContrast(page, [['#save', '#save'], ['.category[aria-selected=true]', '.category[aria-selected=true]'], ['.track-info p', '.track']]);
  assert.equal(await page.evaluate(() => playing), false);
});

test('soft pages: Meditate keeps inset artwork and underlined selected intents without card outlines', async t => {
  const { page } = await open(t, { route: '/#meditate' });
  await expectMatte(page, '#meditate-page .intent-chip > span, #meditate-page .pill-body');
  await expectTouchFocus(page, ['#begin-daily', '#meditate-page .med-options', '#meditate-page .intent-chip', '#meditate-page .practice-actions .pill-hit']);
  await page.locator('[data-intent="Focus"]').click();
  assert.match(await page.locator('[data-intent="Focus"] > span').evaluate(node => getComputedStyle(node).textDecorationLine), /underline/);
  assert(await page.locator('#meditate-page .arched-art').count() > 1);
  assert(await page.locator('#meditate-page .practice-orbit').first().evaluate(node => parseFloat(getComputedStyle(node, '::before').borderTopWidth)) > 0, 'Artwork orbit remains artwork');
  await expectContrast(page, [['#meditate-page .pill-body', '#meditate-page .pill-body'], ['#meditate-page .practice-card .session-ingredients', '#meditate-page .practice-card']]);
  assert.equal(await page.evaluate(() => playing || !!guidedSession?.playing), false);
});

test('soft pages: player and mini-player use flat controls without changing pause or loop', async t => {
  const { page } = await open(t);
  await page.locator('#home-daily').click();
  await page.waitForFunction(() => guidedSession?.playing && guidedAudio.readyState >= 2);
  await expectMatte(page, '#session-dialog .player-glass, #session-dialog .player-toggle');
  assert.equal(await page.locator('#session-dialog .player-cover').evaluate(node => getComputedStyle(node).borderTopWidth), '0px');
  assert.equal(await page.locator('#session-dialog .breathing-ring').count(), 3);
  await expectTouchFocus(page, ['#session-minimize', '#session-back', '#session-pause', '#session-forward', '#session-loop', '#session-stop', '#session-progress']);
  await expectContrast(page, [['#session-pause', '#session-pause'], ['#session-loop', '#session-loop']]);
  await page.locator('#session-loop').click();
  assert.equal(await page.locator('#session-loop').getAttribute('aria-pressed'), 'false');
  await page.locator('#session-pause').click();
  assert.equal(await page.evaluate(() => guidedAudio.paused), true);
  await page.locator('#session-minimize').click();
  await expectMatte(page, '#shared-mini-player, #mini-pause');
  await expectTouchFocus(page, ['#mini-open', '#mini-pause', '#mini-stop']);
  assert.match(await page.locator('#mini-subtitle').innerText(), /paused/);
});

test('soft pages: sound chooser keeps a visible non-color selection and form focus', async t => {
  const { page } = await open(t, { route: '/#sounds' });
  const before = await page.evaluate(() => JSON.stringify(levels));
  await page.locator('[data-sound-options="Soft Rain"]').click();
  await expectMatte(page, '#sound-replacement-dialog, .replacement-row');
  await page.locator('[data-select-recording="Ocean Waves"]').click();
  const selected = '[data-recording="Ocean Waves"]';
  await expectMatte(page, selected);
  assert.equal(await page.locator(`${selected} [aria-pressed=true]`).count(), 1);
  assert.match(await page.locator(`${selected} .replacement-copy strong`).evaluate(node => getComputedStyle(node).textDecorationLine), /underline/);
  await expectTouchFocus(page, ['#replacement-close', '#replacement-search', '[data-select-recording="Ocean Waves"]', '[data-preview-recording="Ocean Waves"]', '#replacement-use']);
  await expectContrast(page, [['#replacement-use', '#replacement-use'], [`${selected} .replacement-copy small`, selected]]);
  assert.equal(await page.evaluate(() => JSON.stringify(levels)), before);
  assert.equal(await page.evaluate(() => playing || !!soundPreviewAudio), false);
});

test('soft pages: wellbeing hub, progress and backup use filled panels without invented progress', async t => {
  const { page } = await open(t, { route: '/#wellbeing/hub' });
  for (const route of ['hub', 'progress', 'backup']) {
    await page.goto(`${origin}/#wellbeing/${route}`);
    await expectMatte(page, '.wellbeing-surface');
    assert.equal(await page.locator('.wellbeing-top').evaluate(node => getComputedStyle(node).borderBottomWidth), '0px');
    await expectTouchFocus(page, ['#wellbeing-back']);
  }
  await page.goto(`${origin}/#wellbeing/hub`);
  assert.equal(await page.locator('.wellbeing-days i.recorded').count(), 0);
  assert.equal(await page.locator('.wellbeing-days i').count(), 7);
  await expectContrast(page, [['.wellbeing-footnote', '.wellbeing-week'], ['.wellbeing-destination small', '.wellbeing-destination']]);
  assert.equal(await page.evaluate(() => playing || !!guidedSession?.playing), false);
});

test('soft pages: breathing choices have non-color state cues while the timer and guide rings remain', async t => {
  const { page } = await open(t, { route: '/#wellbeing/breathing' });
  await expectMatte(page, '.wellbeing-surface, .wellbeing-choices button, .wellbeing-primary');
  await expectTouchFocus(page, ['#breathing-toggle', '#breathing-reset', '[data-breathing-pattern="0"]', '[data-breathing-duration="1"]']);
  await page.locator('[data-breathing-duration="1"]').click();
  assert.equal(await page.locator('[data-breathing-duration="1"]').getAttribute('aria-pressed'), 'true');
  assert.match(await page.locator('[data-breathing-duration="1"]').evaluate(node => getComputedStyle(node).textDecorationLine), /underline/);
  assert.equal(await page.locator('#breathing-time').textContent(), '01:00');
  assert(await page.locator('.wellbeing-orbit').evaluate(node => parseFloat(getComputedStyle(node).borderTopWidth)) > 0);
  await expectContrast(page, [['#breathing-toggle', '#breathing-toggle'], ['[data-breathing-duration="1"]', '[data-breathing-duration="1"]']]);
});

test('soft pages: reflection has an explicit focused input and solid primary action', async t => {
  const { page } = await open(t, { route: '/#wellbeing/reflection' });
  await page.locator('#wellbeing-reflection-input').fill('A quiet pause');
  await expectMatte(page, '#wellbeing-create-reflection');
  await expectTouchFocus(page, ['#wellbeing-reflection-input', '#wellbeing-create-reflection']);
  await expectContrast(page, [['#wellbeing-create-reflection', '#wellbeing-create-reflection'], ['#wellbeing-reflection-input', '#wellbeing-reflection-input']]);
  await page.locator('#wellbeing-create-reflection').click();
  assert.match(await page.locator('#wellbeing-reflection-output').textContent(), /A quiet pause/);
});

for (const width of [320, 823]) {
  test(`soft pages: main tabs and utility pages remain reachable at ${width}px with larger text`, async t => {
    const { page } = await open(t, { width, height: 920 });
    await page.evaluate(() => {
      const root = document.documentElement;
      root.style.setProperty('--t', String(parseFloat(getComputedStyle(root).getPropertyValue('--t')) * 1.6));
    });
    for (const tab of ['sounds', 'meditate', 'sleep', 'home']) {
      await go(page, tab);
      assert.equal(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth), true, tab + ' has no document overflow');
    }
    for (const route of ['hub', 'breathing', 'progress', 'reflection', 'backup']) {
      await page.goto(`${origin}/#wellbeing/${route}`);
      assert.equal(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth), true, route + ' has no document overflow');
      await expectTouchFocus(page, ['#wellbeing-back']);
    }
    assert.equal(await page.evaluate(() => playing || !!guidedSession?.playing), false);
  });
}

// Meditate's visual refresh is intentionally a layout change, not just a new
// fill: two starter controls fit above the footer and art anchors compact rows.
for (const [width, height] of [[390, 844], [538, 882]]) {
  test(`refined Meditate: distinct featured and compact library layouts at ${width}px`, async t => {
    const { page } = await open(t, { route: '/#meditate', width, height });
    assert((await page.locator('.daily-journey').boundingBox()).height < 310, 'The feature no longer consumes the first screen');
    const first = page.locator('[data-practice="gentle-relief"]');
    assert((await first.boundingBox()).height < 160, 'Library rows are genuinely compact');
    const art = await first.locator('.arched-art').boundingBox();
    const title = await first.locator('h3').boundingBox();
    assert(art.x + art.width < title.x, 'Thumbnail-led rows differ from the featured card');
    const footer = await page.locator('.bottom-nav').boundingBox();
    for (const id of ['gentle-relief', 'quiet-mind']) {
      const button = page.getByRole('button', { name: `Begin ${id === 'gentle-relief' ? 'Gentle Relief & Comfort' : 'Quiet Mind Sanctuary'}`, exact: true });
      const bounds = await button.boundingBox();
      assert.equal(bounds.width, 44);
      assert.equal(bounds.height, 44);
      assert(bounds.y + bounds.height <= footer.y, 'Two practice actions are visible without scrolling');
      assert.equal(await button.evaluate(node => {
        const r = node.getBoundingClientRect();
        return node.contains(document.elementFromPoint(r.x + r.width / 2, r.y + r.height / 2));
      }), true, 'The visible control is not covered by the fixed footer');
    }
    assert.match(await page.locator('#practice-count').innerText(), /3 featured/);
    await expectContrast(page, [['.daily-journey .kicker', '.daily-journey'], ['.daily-journey .session-ingredients', '.daily-journey'], ['.daily-topline .session-meta', '.daily-topline .session-meta']]);
    assert.equal(await page.evaluate(() => playing || !!guidedSession?.playing), false);
  });
}

test('refined Meditate: narrow large-text and font-failure layouts never clip actions', async t => {
  const { page, blockedFonts } = await open(t, { route: '/#meditate', width: 320, height: 844, blockFonts: true });
  assert(blockedFonts() > 0);
  await page.evaluate(() => {
    const root = document.documentElement;
    root.style.setProperty('--t', String(parseFloat(getComputedStyle(root).getPropertyValue('--t')) * 2));
  });
  await expectTouchFocus(page, ['#begin-daily', '#daily-practice-save', '#daily-practice-options', '[data-save-practice="gentle-relief"]', '[data-practice-options="gentle-relief"]', '#begin-gentle-relief', '#browse-practices']);
  for (const selector of ['#begin-daily', '#daily-practice-options', '#begin-gentle-relief', '#begin-body-rest', '#browse-practices']) {
    const button = page.locator(selector);
    await button.evaluate(node => node.scrollIntoView({ block: 'center' }));
    const bounds = await button.boundingBox();
    const footer = await page.locator('.bottom-nav').boundingBox();
    assert(bounds.x >= 0 && bounds.x + bounds.width <= 320);
    assert(bounds.y >= 0 && bounds.y + bounds.height <= footer.y);
  }
  assert.equal(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth), true);
  await page.evaluate(() => scrollTo(0, document.documentElement.scrollHeight));
  const note = await page.locator('#meditate-page .preview-disclosure').boundingBox();
  const footer = await page.locator('.bottom-nav').boundingBox();
  assert(note.y + note.height <= footer.y, 'The final disclosure clears the footer');
  assert.equal(await page.evaluate(() => playing || !!guidedSession?.playing), false);
});

test('refined Meditate: circular transport names and drawings follow real loading, play and pause', async t => {
  const { page, context } = await open(t, { route: '/#meditate' });
  const asset = await page.evaluate(() => sessionSoundscapeForTitle('Gentle Relief & Comfort').assetPath);
  let release;
  const responseGate = new Promise(resolve => { release = resolve; });
  t.after(() => release());
  await context.route(`**/${asset}`, async route => { await responseGate; await route.continue(); });
  const card = page.locator('[data-practice="gentle-relief"]');
  const button = page.locator('#begin-gentle-relief');
  await button.click();
  await page.waitForFunction(() => guidedSession?.loading);
  await page.locator('#session-minimize').click();
  assert.equal(await button.isDisabled(), true);
  assert.equal(await button.getAttribute('aria-busy'), 'true');
  assert.match(await button.getAttribute('aria-label'), /^Opening… Gentle Relief & Comfort$/);
  assert.equal(await button.locator('.practice-spinner').count(), 1);
  assert.equal(await card.evaluate(node => node.classList.contains('is-loading')), true);
  release();
  await page.waitForFunction(() => guidedSession?.playing && !guidedAudio.paused);
  assert.equal(await button.isDisabled(), false);
  assert.equal(await button.getAttribute('aria-busy'), 'false');
  assert.equal(await button.getAttribute('aria-label'), 'Pause Gentle Relief & Comfort');
  assert.equal(await button.getAttribute('title'), 'Pause Gentle Relief & Comfort');
  assert.equal(await button.locator('svg rect').count(), 2, 'A pause drawing replaces the play triangle');
  assert.equal(await card.evaluate(node => node.classList.contains('is-playing')), true);
  await button.click();
  assert.equal(await page.evaluate(() => guidedAudio.paused && !guidedSession.playing), true);
  assert.equal(await button.getAttribute('aria-label'), 'Begin Gentle Relief & Comfort');
  assert.equal(await card.evaluate(node => node.classList.contains('is-playing')), false);
  assert.equal(await button.locator('.practice-spinner').count(), 0);
});

for (const width of [320, 390, 538, 823, 1440]) {
  test(`moonlight shell: every tab shares Sleep's palette and an inset iPhone-style footer at ${width}px`, async t => {
    const { page } = await open(t, { width, height: 920 });
    for (const [tab, panel] of [['home', '.home-soundscape'], ['sounds', '.master.surface'], ['meditate', '.practice-card'], ['sleep', '.timer-bar']]) {
      await go(page, tab);
      const activePage = page.locator('main:visible');
      assert.equal(await activePage.evaluate(node => getComputedStyle(node).backgroundColor), 'rgb(2, 19, 44)', 'One shared midnight page color');
      assert.equal(await activePage.locator(panel).first().evaluate(node => getComputedStyle(node).backgroundColor), 'rgb(18, 41, 69)', 'The same soft blue surface as Sleep');
      assert.equal(await page.locator('meta[name="theme-color"]').getAttribute('content'), '#02132c');
      const footer = await page.locator('.bottom-nav').boundingBox();
      assert(footer.width <= 520 && footer.x >= 16 && footer.x + footer.width <= width - 16);
      assert.equal(footer.y + footer.height, 908, 'The capsule floats 12px above the viewport edge');
      assert.equal(await page.locator('.bottom-nav').evaluate(node => getComputedStyle(node).borderRadius), '40px');
      for (const button of await page.locator('.bottom-nav .nav-item').all()) {
        const bounds = await button.boundingBox();
        assert(bounds.width >= 44 && bounds.height >= 44);
      }
      const selected = page.locator('.bottom-nav .nav-item.active');
      assert.equal(await selected.evaluate(node => getComputedStyle(node).backgroundColor), 'rgb(42, 70, 100)');
      assert.equal(await selected.evaluate(node => getComputedStyle(node).fontWeight), '700');
      assert.notEqual(await selected.locator('span').evaluate(node => getComputedStyle(node, '::before').content), 'none');
      assert.equal(await page.locator('.bottom-nav [aria-current="page"]').count(), 1);
      assert.equal(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth), true);
    }
    await expectContrast(page, [['.nav-item.active', '.nav-item.active'], ['.nav-item:not(.active)', '.bottom-nav']]);
    assert.equal(await page.locator('#home-page').evaluate(node => getComputedStyle(node, '::before').content), 'none', 'No old teal forest sits behind the shared page color');
    assert.equal(await page.locator('.app > .backdrop').evaluate(node => getComputedStyle(node).display), 'none');
    assert.equal(await page.evaluate(() => playing || !!guidedSession?.playing), false);
  });
}

test('moonlight shell: enlarged fallback labels grow the footer and its reserved inset together', async t => {
  const { page, blockedFonts } = await open(t, { width: 320, height: 844, blockFonts: true });
  assert(blockedFonts() > 0);
  const original = await page.locator('.bottom-nav').boundingBox();
  await page.locator('.nav-item').evaluateAll(nodes => nodes.forEach(node => { node.style.fontSize = '24px'; }));
  await page.waitForFunction(() => {
    const height = document.querySelector('.bottom-nav').getBoundingClientRect().height;
    return height > 72 && parseFloat(document.documentElement.style.getPropertyValue('--nav')) === Math.ceil(height + 12);
  });
  const grown = await page.locator('.bottom-nav').boundingBox();
  assert(grown.height > original.height);
  assert.equal(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth), true);
  for (const tab of ['home', 'sounds', 'meditate', 'sleep']) {
    const button = page.locator(`.bottom-nav [data-tab="${tab}"]`);
    await button.focus();
    await page.keyboard.press('Enter');
    assert.equal(await page.locator('.bottom-nav [aria-current="page"]').getAttribute('data-tab'), tab);
    const bounds = await button.boundingBox();
    assert(bounds.width >= 44 && bounds.height >= 44);
    assert.equal(await button.evaluate(node => node.scrollWidth <= node.clientWidth), true, 'No clipped tab label');
    assert.equal(await button.evaluate(node => node.matches(':focus-visible')), true);
  }
  await page.locator('.nav-item').evaluateAll(nodes => nodes.forEach(node => { node.style.fontSize = ''; }));
  await page.waitForFunction(() => document.querySelector('.bottom-nav').getBoundingClientRect().height === 72 && document.documentElement.style.getPropertyValue('--nav') === '84px');
  assert.equal(await page.evaluate(() => playing || !!guidedSession?.playing), false);
});

test('moonlight shell: a paused mini-player and final page actions stay above the floating footer', async t => {
  const { page } = await open(t, { route: '/#meditate', width: 390, height: 844 });
  await page.locator('#begin-daily').click();
  await page.waitForFunction(() => guidedSession?.playing && !guidedAudio.paused);
  await page.locator('#session-pause').click();
  await page.locator('#session-minimize').click();
  const session = await page.evaluate(() => ({ title: guidedSession.title, remaining: guidedSession.remaining }));
  for (const [tab, last] of [['home', '.home-preview-note'], ['sounds', 'main.content .help'], ['meditate', '#meditate-page .preview-disclosure'], ['sleep', '#sleep-page .preview-disclosure']]) {
    await go(page, tab);
    const mini = await page.locator('#shared-mini-player').boundingBox();
    const footer = await page.locator('.bottom-nav').boundingBox();
    assert(mini.y + mini.height <= footer.y - 8, 'The player and capsule do not overlap');
    assert.equal(await page.locator('#shared-mini-player').isVisible(), true);
    await page.evaluate(() => scrollTo(0, document.documentElement.scrollHeight));
    const end = await page.locator(last).boundingBox();
    assert(end.y + end.height <= mini.y, 'The final content scrolls clear of both controls');
  }
  await go(page, 'home');
  await page.evaluate(() => scrollTo(0, document.documentElement.scrollHeight));
  await page.locator('#home-wellbeing').click();
  for (const route of ['hub', 'breathing', 'progress', 'reflection', 'backup']) {
    await page.evaluate(route => openWellbeing(route), route);
    assert.equal(await page.locator('#wellbeing-page').evaluate(node => getComputedStyle(node).backgroundColor), 'rgb(2, 19, 44)');
    await page.evaluate(() => scrollTo(0, document.documentElement.scrollHeight));
    const end = await page.locator('.wellbeing-preview-label').boundingBox();
    const mini = await page.locator('#shared-mini-player').boundingBox();
    assert(end.y + end.height <= mini.y, 'Pushed tools clear the paused player too');
  }
  assert.equal(await page.evaluate(() => guidedAudio.paused && !guidedSession.playing), true);
  assert.deepEqual(await page.evaluate(() => ({ title: guidedSession.title, remaining: guidedSession.remaining })), session);
});

test('moonlight shell: reduced transparency uses a solid capsule and content clears it without a player', async t => {
  const { page, context } = await open(t, { width: 320, height: 640 });
  const client = await context.newCDPSession(page);
  await client.send('Emulation.setEmulatedMedia', { features: [
    { name: 'prefers-reduced-transparency', value: 'reduce' },
    { name: 'prefers-reduced-motion', value: 'reduce' },
  ] });
  const styles = await page.locator('.bottom-nav').evaluate(node => ({
    color: getComputedStyle(node).backgroundColor,
    blur: getComputedStyle(node).backdropFilter,
    transition: getComputedStyle(node.querySelector('.nav-item')).transitionDuration,
  }));
  assert.deepEqual(styles, { color: 'rgb(18, 41, 69)', blur: 'none', transition: '0s' });
  for (const [tab, last] of [['home', '.home-preview-note'], ['sounds', 'main.content .help'], ['meditate', '#meditate-page .preview-disclosure'], ['sleep', '#sleep-page .preview-disclosure']]) {
    await go(page, tab);
    await page.evaluate(() => scrollTo(0, document.documentElement.scrollHeight));
    const end = await page.locator(last).boundingBox();
    const capsule = await page.locator('.bottom-nav').boundingBox();
    assert(end.y + end.height <= capsule.y, 'Final content remains readable above the floating bar');
    assert.equal(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth), true);
  }
  assert.equal(await page.evaluate(() => playing || !!guidedSession?.playing), false);
});
