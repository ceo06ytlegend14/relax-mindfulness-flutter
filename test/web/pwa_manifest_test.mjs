import assert from 'node:assert/strict';
import { readFile, realpath } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import path from 'node:path';
import test from 'node:test';

const root = fileURLToPath(new URL('../../', import.meta.url));
const read = (name) => readFile(path.join(root, name), 'utf8');
const manifest = JSON.parse(await read('web/manifest.json'));
const previewManifest = JSON.parse(await read('design/preview/manifest.json'));

function pngSize(bytes) {
  assert.deepEqual(bytes.subarray(0, 8), Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]));
  assert.equal(bytes.toString('ascii', 12, 16), 'IHDR');
  return [bytes.readUInt32BE(16), bytes.readUInt32BE(20)];
}

for (const [name, data, directory] of [
  ['Flutter app', manifest, 'web'],
  ['design preview', previewManifest, 'design/preview'],
]) {
  test(`${name}: install metadata and standalone launch are valid`, () => {
    assert(data.name && data.short_name && data.description && data.id);
    assert.equal(data.display, 'standalone');
    assert.equal(data.start_url, './');
    assert.equal(data.scope, './');
    assert.equal(data.theme_color.toUpperCase(), '#001B24');
    assert.equal(data.background_color.toUpperCase(), '#001B24');
    assert.equal(data.prefer_related_applications, false);
  });

  for (const prefix of ['/', '/allinone/']) {
    test(`${name}: URLs stay within ${prefix} on a subpath deployment`, () => {
      const base = new URL(prefix, 'https://example.test');
      const scope = new URL(data.scope, base);
      for (const value of [data.start_url, data.id, ...data.icons.map((icon) => icon.src)]) {
        const resolved = new URL(value, base);
        assert.equal(resolved.origin, base.origin);
        assert(resolved.pathname.startsWith(scope.pathname));
      }
    });
  }

  test(`${name}: normal and maskable icons have their advertised PNG sizes`, async () => {
    for (const purpose of ['any', 'maskable']) {
      for (const size of [192, 512]) {
        const icon = data.icons.find((item) => item.purpose === purpose && item.sizes === `${size}x${size}`);
        assert(icon, `${purpose} ${size}px icon is missing`);
        assert.equal(icon.type, 'image/png');
        const bytes = await readFile(path.join(root, directory, icon.src));
        assert.deepEqual(pngSize(bytes), [size, size]);
        assert.equal(bytes[25], 2, 'Icons must be opaque RGB PNGs, including maskable variants');
      }
    }
  });
}

test('existing Flutter application identity is preserved; the demo has its own identity', () => {
  assert.equal(manifest.id, 'sanctuary-relax-mindfulness');
  assert.notEqual(previewManifest.id, manifest.id);
  assert.match(previewManifest.name, /Preview/);
  assert.match(previewManifest.description, /separate from the Flutter/);
});

test('Apple touch icon and favicon are real 180px and 32px opaque PNGs', async () => {
  for (const [name, size] of [['web/icons/apple-touch-icon.png', 180], ['web/favicon.png', 32]]) {
    const bytes = await readFile(path.join(root, name));
    assert.deepEqual(pngSize(bytes), [size, size]);
    assert.equal(bytes[25], 2);
  }
});

test('Flutter web entry includes the install UI and correct Apple metadata', async () => {
  const html = await read('web/index.html');
  assert.match(html, /<base href="\$FLUTTER_BASE_HREF">/);
  assert.match(html, /rel="manifest" href="manifest\.json"/);
  assert.match(html, /rel="apple-touch-icon" sizes="180x180" href="icons\/apple-touch-icon\.png"/);
  assert.match(html, /name="apple-mobile-web-app-capable" content="yes"/);
  assert.match(html, /name="theme-color" content="#001B24"/);
  assert.match(html, /href="pwa-install\.css"/);
  assert.match(html, /src="pwa-install\.js" defer/);
  assert.equal((html.match(/src="pwa-install\.js"/g) || []).length, 1);
  assert.doesNotMatch(html, /getRegistrations|\.unregister\(/);
  assert.doesNotMatch(html, /beforeinstallprompt/);
  assert.doesNotMatch(html, /Offline-First PWA \(Works Without Internet\)/);
});

test('custom Flutter bootstrap leaves worker registration to the installer', async () => {
  const bootstrap = await read('web/flutter_bootstrap.js');
  assert.match(bootstrap, /\{\{flutter_js\}\}/);
  assert.match(bootstrap, /\{\{flutter_build_config\}\}/);
  assert.match(bootstrap, /_flutter\.loader\.load\(\)/);
  assert.doesNotMatch(bootstrap, /serviceWorkerSettings|serviceWorkerVersion/);
});

test('preview shares the actual install controller, worker and icons, not copied versions', async () => {
  for (const name of ['pwa-install.js', 'pwa-install.css', 'install-worker.js', 'offline.html', 'favicon.png', 'icons']) {
    assert.equal(await realpath(path.join(root, 'design/preview', name)), await realpath(path.join(root, 'web', name)));
  }
});

test('fake icon-as-screenshot entries and nonfunctional launch shortcuts are not advertised', () => {
  assert.equal(manifest.screenshots, undefined);
  assert.equal(manifest.shortcuts, undefined);
});

test('offline fallback has no external resources and accurately describes its limits', async () => {
  const html = await read('web/offline.html');
  assert.doesNotMatch(html, /(?:src|href)="https?:/);
  assert.match(html, /does not download the full app or audio library/);
  assert.match(html, /window\.location\.reload\(\)/);
});
