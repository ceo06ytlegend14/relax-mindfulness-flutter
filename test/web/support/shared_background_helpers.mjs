import assert from 'node:assert/strict';

// CSSOM may serialize identical layer values once (Chromium 159) or once per
// layer (158). Apply CSS list repetition, then verify both paint layers exactly.
export function expectNightSkyPaintLists({ size, position }) {
  const layers = value => {
    const values = value.split(',').map(item => item.trim());
    assert(values.length === 1 || values.length === 2, 'Only the fade and image layers');
    return values.length === 1 ? [values[0], values[0]] : values;
  };
  assert.deepEqual(layers(size), ['cover', 'cover'], 'The fade and sky both cover the shared canvas');
  assert.deepEqual(layers(position), ['50% 0%', '50% 0%'], 'Both layers are pinned top-center');
}

// The preview has one persistent page layer; top-layer dialog players reuse the
// same recipe because they are deliberately mounted outside .app.
export async function expectSharedBackground(page, { player } = {}) {
  assert.equal(await page.locator('.app > .app-background').count(), 1);
  assert.equal(await page.locator('.scenery, .app > .backdrop').count(), 0, 'No second page wallpaper');
  const selector = player ? `${player} .player-backdrop` : '.app > .app-background';
  const layer = page.locator(selector);
  assert.equal(await layer.getAttribute('aria-hidden'), 'true');
  const paint = await layer.evaluate(node => {
    const css = getComputedStyle(node), rect = node.getBoundingClientRect();
    return { image: css.backgroundImage, size: css.backgroundSize, position: css.backgroundPosition,
      pointer: css.pointerEvents, animation: css.animationName, filter: css.filter,
      x: rect.x, y: rect.y, width: rect.width, height: rect.height };
  });
  assert.match(paint.image, /sleep\/night_sky\.webp/);
  assert.doesNotMatch(paint.image, /lake_dawn|moonlit_ocean|forest_sunrise|moonlit_forest/);
  expectNightSkyPaintLists(paint);
  assert.equal(paint.pointer, 'none');
  assert.equal(paint.animation, 'none');
  assert.equal(paint.filter, 'none');
  const viewport = page.viewportSize();
  const width = Math.min(viewport.width, 823);
  assert.equal(paint.y, 0, 'The sky stays pinned to the viewport top, not the scroll offset');
  assert.equal(paint.width, width);
  assert.equal(paint.x, (viewport.width - width) / 2);
  assert(Math.abs(paint.height - 620 * Math.max(.38, width / 823)) < .05);
  if (player) {
    assert.equal(paint.image, await page.locator('.app-background').evaluate(node => getComputedStyle(node).backgroundImage));
    assert.equal(await page.locator(player).evaluate(node => getComputedStyle(node).backgroundColor), 'rgb(2, 19, 44)');
  } else {
    const foreground = page.locator('main:visible');
    assert.equal(await foreground.evaluate(node => getComputedStyle(node).backgroundColor), 'rgba(0, 0, 0, 0)', 'The shared image is not hidden by an opaque page');
    assert.equal(await foreground.evaluate(node => getComputedStyle(node).backgroundImage), 'none');
    assert.equal(await page.locator('.app').evaluate(node => getComputedStyle(node).backgroundColor), 'rgb(2, 19, 44)', 'Midnight fallback remains if the bundled image cannot load');
  }
  return paint;
}
