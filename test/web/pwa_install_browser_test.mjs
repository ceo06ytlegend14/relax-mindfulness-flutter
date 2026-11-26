// Chromium tests of the real PWA assets and design preview, not a Flutter build.
import assert from 'node:assert/strict';
import { readFile, realpath } from 'node:fs/promises';
import { createServer } from 'node:http';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { after, before, test } from 'node:test';

const { chromium } = await import(process.env.PLAYWRIGHT_MODULE || 'playwright');
const root = path.resolve(fileURLToPath(new URL('../../', import.meta.url)));
const web = path.join(root, 'web');
const preview = path.join(root, 'design/preview');
const mime = { '.js': 'text/javascript', '.css': 'text/css', '.html': 'text/html', '.json': 'application/manifest+json', '.png': 'image/png', '.webp': 'image/webp', '.ttf': 'font/ttf', '.mp3': 'audio/mpeg' };
let browser;
let server;
let origin;
const rangeRequests = [];

function fixture(base) {
  return `<!doctype html><html lang="en"><head><base href="${base}"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><meta name="application-name" content="Sanctuary"><meta name="theme-color" content="#02132C"><link rel="manifest" href="manifest.json"><link rel="apple-touch-icon" sizes="180x180" href="icons/apple-touch-icon.png"><link rel="stylesheet" href="pwa-install.css"><script src="pwa-install.js" defer></script></head><body style="margin:0;background:#02132c;color:white"><h1 id="fixture-title">PWA integration fixture</h1><p>The actual installer and manifest, without a Flutter runtime.</p><script>window.pageMarker=Math.random();</script></body></html>`;
}

before(async () => {
  server = createServer(async (request, response) => {
    try {
      const url = new URL(request.url, 'http://test.invalid');
      const pathname = decodeURIComponent(url.pathname);
      response.setHeader('Cache-Control', 'no-store');
      if (pathname === '/blank/') {
        response.setHeader('Content-Type', 'text/html');
        response.end('<!doctype html><title>Test setup</title>');
        return;
      }
      if (pathname === '/embed/') {
        response.setHeader('Content-Type', 'text/html');
        response.end('<!doctype html><title>Embedded test</title><iframe title="Sanctuary" src="/app/?from=frame#sleep" style="width:390px;height:844px;border:0"></iframe>');
        return;
      }
      if (pathname === '/other/foreign-worker.js') {
        response.setHeader('Content-Type', 'text/javascript');
        response.end('self.addEventListener("fetch", () => {});');
        return;
      }
      if (pathname === '/app/http-error/') {
        response.writeHead(500, { 'Content-Type': 'text/html' });
        response.end('<!doctype html><h1>Server error is not an offline success</h1>');
        return;
      }
      if (pathname === '/app/assets/sounds/range-test.mp3') {
        rangeRequests.push(request.headers.range);
        const bytes = Buffer.from(Array.from({ length: 64 }, (_, index) => index));
        response.writeHead(206, { 'Content-Type': 'audio/mpeg', 'Content-Range': 'bytes 0-15/64', 'Accept-Ranges': 'bytes', 'Content-Length': 16 });
        response.end(bytes.subarray(0, 16));
        return;
      }
      const prefix = ['/nested/sanctuary/', '/app/'].find((value) => pathname.startsWith(value));
      if (prefix && (pathname === prefix || pathname === `${prefix}index.html`)) {
        response.setHeader('Content-Type', 'text/html; charset=utf-8');
        response.end(fixture(prefix));
        return;
      }
      const directory = prefix ? web : preview;
      const relative = prefix ? pathname.slice(prefix.length) : pathname.slice(1);
      const requested = path.join(directory, relative || 'index.html');
      const resolved = await realpath(requested);
      if (!resolved.startsWith(`${root}${path.sep}`)) throw new Error('Outside test repository');
      const bytes = await readFile(resolved);
      response.setHeader('Content-Type', `${mime[path.extname(resolved)] || 'application/octet-stream'}${['.html', '.js', '.css', '.json'].includes(path.extname(resolved)) ? '; charset=utf-8' : ''}`);
      response.end(bytes);
    } catch (_) {
      response.writeHead(404, { 'Content-Type': 'text/plain' });
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

async function open(t, { route = '/app/', options = {}, init, worker = true } = {}) {
  const context = await browser.newContext({ viewport: { width: 390, height: 844 }, reducedMotion: 'reduce', ...options });
  t.after(() => context.close());
  // Only synthetic prompt outcomes are exercised: never install an OS app from
  // an automated test. Manifest/worker installability is checked separately.
  await context.addInitScript(() => {
    window.addEventListener('beforeinstallprompt', (event) => {
      if (event.isTrusted) { event.preventDefault(); event.stopImmediatePropagation(); }
    }, { capture: true });
  });
  if (init) await context.addInitScript(init);
  const page = await context.newPage();
  const errors = [];
  page.on('pageerror', (error) => errors.push(error.message));
  t.after(() => assert.deepEqual(errors, [], 'No unhandled page errors'));
  await page.goto(`${origin}${route}`, { waitUntil: 'networkidle' });
  if (route.startsWith('/embed/')) await page.frameLocator('iframe').locator('#sanctuary-install-ui').waitFor({ state: 'attached' });
  else await page.waitForFunction(() => !!window.SanctuaryInstall);
  if (worker) {
    await page.evaluate(() => navigator.serviceWorker.ready);
    await page.waitForFunction(() => !!navigator.serviceWorker.controller);
  }
  return { context, page, errors };
}

async function fakePrompt(page, outcome = 'dismissed') {
  return page.evaluate((value) => {
    window.promptCalls = 0;
    const event = new Event('beforeinstallprompt', { cancelable: true });
    event.prompt = () => { window.promptCalls++; return Promise.resolve(); };
    event.userChoice = Promise.resolve({ outcome: value });
    window.dispatchEvent(event);
    return event.defaultPrevented;
  }, outcome);
}

for (const route of ['/', '/app/', '/nested/sanctuary/']) {
  test(`Chromium accepts the real manifest and scoped worker at ${route}`, { timeout: 20000 }, async (t) => {
    const { page } = await open(t, { route });
    const cdp = await page.context().newCDPSession(page);
    const result = await cdp.send('Page.getAppManifest');
    assert.deepEqual(result.errors, []);
    assert.equal(result.url, `${origin}${route}manifest.json`);
    const data = JSON.parse(result.data);
    assert.equal(data.display, 'standalone');
    assert.equal(data.id, route === '/' ? 'sanctuary-design-preview' : 'sanctuary-relax-mindfulness');
    assert.equal(result.manifest?.scope || result.parsed?.scope, `${origin}${route}`);
    assert.deepEqual((await cdp.send('Page.getInstallabilityErrors')).installabilityErrors, []);
    assert.equal(await page.evaluate(() => navigator.serviceWorker.controller.scriptURL), `${origin}${route}install-worker.js`);
  });
}

test('fallback help is accessible, dismissible, and restores keyboard focus', { timeout: 15000 }, async (t) => {
  const { page } = await open(t);
  await page.locator('.install-entry').click();
  assert.equal(await page.locator('#sanctuary-install-dialog').evaluate((dialog) => dialog.open), true);
  assert.equal(await page.locator('.install-title').evaluate((title) => title === document.activeElement), true);
  assert.match(await page.locator('.install-steps').innerText(), /browser menu|browser’s/);
  await page.keyboard.press('Escape');
  assert.equal(await page.locator('#sanctuary-install-dialog').evaluate((dialog) => dialog.open), false);
  assert.equal(await page.locator('.install-entry').evaluate((button) => button === document.activeElement), true);
});

test('native prompt is single-use, prevents a second invocation, and waits for actual installation', { timeout: 15000 }, async (t) => {
  const { page } = await open(t);
  assert.equal(await page.evaluate(() => {
    window.promptCalls = 0;
    const event = new Event('beforeinstallprompt', { cancelable: true });
    event.prompt = () => { window.promptCalls++; return Promise.resolve(); };
    event.userChoice = new Promise((resolve) => { window.finishChoice = resolve; });
    window.dispatchEvent(event);
    return event.defaultPrevented;
  }), true);
  assert.equal(await page.evaluate(() => window.isPwaInstallable), true);
  await page.locator('.install-entry').click();
  assert.equal(await page.evaluate(() => window.SanctuaryInstall.state.prompting), true);
  assert.equal(await page.evaluate(() => window.triggerPwaInstall()), 'pending');
  assert.equal(await page.evaluate(() => window.promptCalls), 1);
  await page.evaluate(() => window.finishChoice({ outcome: 'accepted' }));
  await page.waitForFunction(() => !window.SanctuaryInstall.state.prompting);
  assert.equal(await page.evaluate(() => window.SanctuaryInstall.state.installed), false);
  assert.equal(await page.evaluate(() => window.isPwaInstallable), false);
  await page.evaluate(() => window.dispatchEvent(new Event('appinstalled')));
  assert.equal(await page.locator('.install-entry').isHidden(), true);
  assert.equal(await page.evaluate(() => window.SanctuaryInstall.state.installed), true);
});

test('dismissed prompts show manual help and cannot be reused', { timeout: 15000 }, async (t) => {
  const { page } = await open(t);
  assert.equal(await fakePrompt(page), true);
  await page.locator('.install-entry').click();
  await page.waitForFunction(() => !window.SanctuaryInstall.state.prompting);
  assert.equal(await page.evaluate(() => window.promptCalls), 1);
  assert.match(await page.locator('.install-feedback').innerText(), /Not installed yet/);
  assert.equal(await page.evaluate(() => window.triggerPwaInstall()), 'help');
  assert.equal(await page.evaluate(() => window.promptCalls), 1);
  await fakePrompt(page);
  assert.equal(await page.evaluate(() => window.isPwaInstallable), true, 'A later browser event can rearm installation');
});

test('prompt failures recover to browser-menu help without an unhandled error', { timeout: 15000 }, async (t) => {
  const { page } = await open(t);
  await page.evaluate(() => {
    const event = new Event('beforeinstallprompt', { cancelable: true });
    event.prompt = () => Promise.reject(new Error('Test prompt unavailable'));
    event.userChoice = Promise.resolve({ outcome: 'dismissed' });
    window.dispatchEvent(event);
  });
  await page.locator('.install-entry').click();
  await page.waitForFunction(() => !window.SanctuaryInstall.state.prompting);
  assert.match(await page.locator('.install-feedback').innerText(), /could not open/);
  assert.equal(await page.evaluate(() => window.isPwaInstallable), false);
});

test('iPhone Safari gets manual Share → Add to Home Screen instructions', { timeout: 15000 }, async (t) => {
  const { page } = await open(t, { options: { userAgent: 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15 Version/18.0 Mobile/15E148 Safari/604.1', isMobile: true, hasTouch: true } });
  await page.locator('.install-entry').click();
  const text = await page.locator('.install-steps').innerText();
  assert.match(text, /Safari/);
  assert.match(text, /Share, then Add to Home Screen/);
  assert.match(text, /Open as Web App/);
  assert.equal(await page.locator('button.install-primary').isHidden(), true);
});

test('desktop-user-agent iPads are detected using MacIntel plus touch capability', { timeout: 15000 }, async (t) => {
  const { page } = await open(t, { init: () => {
    Object.defineProperty(navigator, 'platform', { value: 'MacIntel' });
    Object.defineProperty(navigator, 'maxTouchPoints', { value: 5 });
  } });
  await page.locator('.install-entry').click();
  assert.match(await page.locator('.install-steps').innerText(), /iPhone or iPad/);
});

test('macOS Safari gets Add to Dock instructions', { timeout: 15000 }, async (t) => {
  const { page } = await open(t, { options: { userAgent: 'Mozilla/5.0 (Macintosh; Intel Mac OS X 14_0) AppleWebKit/605.1.15 Version/17.0 Safari/605.1.15' }, init: () => Object.defineProperty(navigator, 'platform', { value: 'MacIntel' }) });
  await page.locator('.install-entry').click();
  assert.match(await page.locator('.install-steps').innerText(), /Add to Dock/);
});

for (const mode of ['standalone', 'ios']) {
  test(`${mode}: already-installed mode hides the install entry`, { timeout: 15000 }, async (t) => {
    const { page } = await open(t, { init: mode === 'ios' ? () => Object.defineProperty(navigator, 'standalone', { value: true }) : () => {
      const original = window.matchMedia;
      window.matchMedia = (query) => {
        const result = original.call(window, query);
        if (query === '(display-mode: standalone)') Object.defineProperty(result, 'matches', { value: true });
        return result;
      };
    } });
    assert.equal(await page.locator('.install-entry').isHidden(), true);
    assert.equal(await page.evaluate(() => window.triggerPwaInstall()), 'installed');
    assert.equal(await page.locator('#sanctuary-install-dialog').evaluate((dialog) => dialog.open), false);
  });
}

test('display-mode changes update the install entry without a reload', { timeout: 15000 }, async (t) => {
  const { page } = await open(t, { init: () => {
    window.testStandalone = false;
    const original = window.matchMedia;
    window.matchMedia = (query) => {
      const result = original.call(window, query);
      if (query === '(display-mode: standalone)') {
        Object.defineProperty(result, 'matches', { get: () => window.testStandalone });
        window.testDisplayQuery = result;
      }
      return result;
    };
  } });
  const marker = await page.evaluate(() => window.pageMarker);
  await page.evaluate(() => { window.testStandalone = true; window.testDisplayQuery.dispatchEvent(new Event('change')); });
  assert.equal(await page.locator('.install-entry').isHidden(), true);
  await page.evaluate(() => { window.testStandalone = false; window.testDisplayQuery.dispatchEvent(new Event('change')); });
  assert.equal(await page.locator('.install-entry').isVisible(), true);
  assert.equal(await page.evaluate(() => window.pageMarker), marker);
});

test('embedded previews open a safe top-level tab rather than invoking installation in-frame', { timeout: 20000 }, async (t) => {
  const { page, context } = await open(t, { route: '/embed/', worker: false });
  const frame = page.frames().find((candidate) => candidate.url().includes('/app/'));
  assert(frame);
  await fakePrompt(frame);
  assert.equal(await frame.evaluate(() => window.SanctuaryInstall.state.canPrompt), false);
  await frame.locator('.install-entry').click();
  assert.match(await frame.locator('.install-steps').innerText(), /own browser tab/);
  assert.equal(await frame.evaluate(() => window.promptCalls), 0);
  const popupPromise = context.waitForEvent('page');
  await frame.locator('.install-new-tab').click();
  const popup = await popupPromise;
  await popup.waitForLoadState('domcontentloaded');
  assert.equal(popup.url(), `${origin}/app/?from=frame#sleep`);
  assert.equal(await popup.evaluate(() => window.opener === null), true);
});

test('insecure contexts explain HTTPS and do not register the worker', { timeout: 15000 }, async (t) => {
  const { page } = await open(t, { worker: false, init: () => Object.defineProperty(window, 'isSecureContext', { value: false }) });
  await fakePrompt(page);
  await page.locator('.install-entry').click();
  assert.match(await page.locator('.install-steps').innerText(), /HTTPS/);
  assert.equal(await page.evaluate(() => window.isPwaInstallable), false);
  assert.equal(await page.evaluate(async () => (await navigator.serviceWorker.getRegistrations()).length), 0);
});

test('blocked service-worker storage leaves install guidance usable', { timeout: 15000 }, async (t) => {
  const { page } = await open(t, { worker: false, init: () => Object.defineProperty(navigator, 'serviceWorker', { get() { throw new DOMException('Storage denied', 'SecurityError'); } }) });
  await page.locator('.install-entry').click();
  assert.equal(await page.locator('#sanctuary-install-dialog').evaluate((dialog) => dialog.open), true);
});

test('offline navigation uses only a reconnect page, preserves settings, and can retry online', { timeout: 20000 }, async (t) => {
  const { page, context } = await open(t);
  await page.evaluate(() => localStorage.setItem('pwa-settings-test', 'keep my mix'));
  const cacheDetails = await page.evaluate(async () => {
    const names = (await caches.keys()).filter((name) => name.startsWith(`sanctuary-install:${location.origin}/app/:`));
    return Promise.all(names.map(async (name) => (await (await caches.open(name)).keys()).map((request) => request.url)));
  });
  assert.deepEqual(cacheDetails, [[`${origin}/app/offline.html`]]);
  await context.setOffline(true);
  await page.goto(`${origin}/app/?mix=Soft%20Rain%3A30#sleep`, { waitUntil: 'domcontentloaded' });
  assert.match(await page.locator('h1').innerText(), /offline/);
  assert.equal(await page.locator('body').evaluate(node => getComputedStyle(node).backgroundColor), 'rgb(2, 19, 44)', 'The cached reconnect page uses the same midnight color');
  assert.equal((await page.locator('meta[name="theme-color"]').getAttribute('content')).toLowerCase(), '#02132c');
  assert.match(await page.locator('small').innerText(), /does not download the full app or audio library/);
  assert.equal(await page.evaluate(() => localStorage.getItem('pwa-settings-test')), 'keep my mix');
  await context.setOffline(false);
  await Promise.all([page.waitForNavigation({ waitUntil: 'networkidle' }), page.locator('#retry').click()]);
  assert.equal(await page.locator('#fixture-title').textContent(), 'PWA integration fixture');
  assert.equal(new URL(page.url()).searchParams.get('mix'), 'Soft Rain:30');
  assert.equal(new URL(page.url()).hash, '#sleep');
  assert.equal(await page.evaluate(() => localStorage.getItem('pwa-settings-test')), 'keep my mix');
});

test('worker activation preserves other apps’ workers/caches and removes only its own old cache', { timeout: 20000 }, async (t) => {
  const context = await browser.newContext();
  t.after(() => context.close());
  const page = await context.newPage();
  await page.goto(`${origin}/blank/`);
  const oldCache = `sanctuary-install:${origin}/app/:v1`;
  await page.evaluate(async ({ oldCache }) => {
    await caches.open('another-app-keep-this');
    await caches.open(oldCache);
    const registration = await navigator.serviceWorker.register('/other/foreign-worker.js', { scope: '/other/' });
    const worker = registration.installing || registration.waiting;
    if (!registration.active && worker) await new Promise((resolve) => worker.addEventListener('statechange', () => { if (worker.state === 'activated') resolve(); }));
  }, { oldCache });
  await page.goto(`${origin}/app/`, { waitUntil: 'networkidle' });
  await page.evaluate(() => navigator.serviceWorker.ready);
  await page.waitForFunction(() => !!navigator.serviceWorker.controller);
  const result = await page.evaluate(async () => ({ caches: await caches.keys(), scopes: (await navigator.serviceWorker.getRegistrations()).map((registration) => registration.scope) }));
  assert(result.caches.includes('another-app-keep-this'));
  assert(!result.caches.includes(oldCache));
  assert(result.scopes.includes(`${origin}/other/`));
  assert(result.scopes.includes(`${origin}/app/`));
});

test('worker leaves audio Range requests intact and does not replace HTTP errors with an offline page', { timeout: 15000 }, async (t) => {
  const { page } = await open(t);
  const audio = await page.evaluate(async () => {
    const response = await fetch('assets/sounds/range-test.mp3', { headers: { Range: 'bytes=0-15' } });
    return { status: response.status, contentRange: response.headers.get('Content-Range'), bytes: [...new Uint8Array(await response.arrayBuffer())] };
  });
  assert.equal(audio.status, 206);
  assert.equal(audio.contentRange, 'bytes 0-15/64');
  assert.deepEqual(audio.bytes, Array.from({ length: 16 }, (_, index) => index));
  assert(rangeRequests.includes('bytes=0-15'));
  const response = await page.goto(`${origin}/app/http-error/`);
  assert.equal(response.status(), 500);
  assert.match(await page.locator('h1').innerText(), /Server error is not an offline success/);
});

test('install help fits narrow phones, wider layouts and keeps the existing footer order', { timeout: 20000 }, async (t) => {
  const { page } = await open(t, { route: '/#meditate' });
  for (const [width, height] of [[320, 640], [390, 844], [823, 1568], [1440, 1000]]) {
    await page.setViewportSize({ width, height });
    await page.locator('.install-entry').click();
    const result = await page.locator('#sanctuary-install-dialog').evaluate((dialog) => {
      const rect = dialog.getBoundingClientRect();
      return { left: rect.left, right: rect.right, width: innerWidth, scrollWidth: dialog.scrollWidth, clientWidth: dialog.clientWidth };
    });
    assert(result.left >= 0 && result.right <= result.width);
    assert(result.scrollWidth <= result.clientWidth);
    await page.keyboard.press('Escape');
    assert.deepEqual(await page.locator('.nav-item').allTextContents(), ['Home', 'Sounds', 'Meditate', 'Sleep']);
    assert.equal(await page.locator('.bottom-nav').evaluate((nav) => nav.getBoundingClientRect().bottom), height - 12);
  }
});

test('soft pages: installation help uses matte surfaces while retaining targets and keyboard focus', async t => {
  const { page } = await open(t);
  await page.keyboard.press('Tab');
  const entry = page.locator('.install-entry');
  await entry.focus();
  const entryStyle = await entry.evaluate(node => ({ border: getComputedStyle(node).borderTopWidth,
    shadow: getComputedStyle(node).boxShadow, focus: node.matches(':focus-visible'), outline: getComputedStyle(node).outlineWidth,
    height: node.getBoundingClientRect().height }));
  assert.deepEqual(entryStyle, { border: '0px', shadow: 'none', focus: true, outline: '2px', height: 44 });
  await entry.click();
  for (const selector of ['#sanctuary-install-dialog', '.install-steps']) {
    const panel = await page.locator(selector).evaluate(node => ({ border: getComputedStyle(node).borderTopWidth,
      image: getComputedStyle(node).backgroundImage, shadow: getComputedStyle(node).boxShadow }));
    assert.deepEqual(panel, { border: '0px', image: 'none', shadow: 'none' });
  }
  const primary = await page.locator('button.install-primary').evaluate(node => ({
    fill: getComputedStyle(node).backgroundColor, color: getComputedStyle(node).color, border: getComputedStyle(node).borderTopWidth,
  }));
  assert.deepEqual(primary, { fill: 'rgb(140, 231, 208)', color: 'rgb(0, 43, 38)', border: '0px' });
  await page.keyboard.press('Tab');
  await page.locator('.install-close').focus();
  assert.equal(await page.locator('.install-close').evaluate(node => node.matches(':focus-visible')), true);
  await page.keyboard.press('Escape');
  assert.equal(await entry.evaluate(node => node === document.activeElement), true);
  assert.equal(await page.evaluate(() => window.SanctuaryInstall.state.installed), false);
});
