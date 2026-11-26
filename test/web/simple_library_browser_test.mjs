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

test('available library defaults to the 18 real local sources without autoplay', async t => {
 const {page}=await open(t);
 assert.equal(await page.locator('#library-available').getAttribute('aria-pressed'),'true');
 assert.equal(await page.locator('#tracks [data-track]').count(),18);
 assert.equal(await page.locator('[data-track="Rain on Umbrella"]').count(),0);
 assert.equal(await page.locator('#tracks [role=switch]:disabled').count(),0);
 assert.equal(await page.evaluate(()=>playing || players.size>0),false);
 assert.match(await page.locator('#library-notice').textContent(),/18 bundled/);
});
test('full catalog keeps unavailable entries honest and never calls them paid locks', async t => {
 const {page}=await open(t);
 await page.locator('#catalog-review > summary').click();
  await page.locator('#library-full').click();
 assert.equal(await page.locator('#tracks [data-track]').count(),77);
 const umbrella=page.locator('[data-track="Rain on Umbrella"]');
 assert.match(await umbrella.textContent(),/Streaming in app.*not in this preview/i);
 assert.equal(await umbrella.getByRole('switch').isDisabled(),true);
 assert.match(await page.locator('[data-track="Rain Cave"]').textContent(),/No recording.*unavailable/i);
 assert.equal(await page.locator('[data-track="Rain Cave"]').getByRole('switch').isDisabled(),true);
 assert.equal(await page.locator('[data-track] [aria-label*=Premium]').count(),0);
 assert.equal(await page.evaluate(()=>playing || players.size>0),false);
});
test('scope, favorites and categories are only views, never edits to a saved mix', async t => {
 const stored={levels:{'Rain on Umbrella':.22,'Soft Rain':.31},favorites:['Rain on Umbrella','Soft Rain'],saved:[{name:'Kept',levels:{'Rain on Umbrella':.22}}]};
 const {page}=await open(t,{stored});
 assert.match(await page.locator('#library-selection-notice').textContent(),/Rain on Umbrella/);
 await page.locator('#catalog-review > summary').click();
  await page.locator('#library-full').click();
 await page.locator('#library-available').click();
 await page.locator('[data-category=favorites]').click();
 assert.deepEqual(await page.locator('#tracks [data-track]').evaluateAll(nodes=>nodes.map(node=>node.dataset.track)),['Soft Rain']);
 assert.deepEqual(await page.evaluate(()=>levels),stored.levels);
 assert.deepEqual(await page.evaluate(()=>saved),stored.saved);
 assert.deepEqual(await page.evaluate(()=>[...favorites]),stored.favorites);
 assert.equal(await page.evaluate(()=>playing || players.size>0),false);
});
for(const [name,other,family] of [['Campfire','Fireplace','Fire'],['Forest Birds','Woodland Morning','Birds']]){
 test(`${family} chooser contains two genuine related recordings, not fake rain variants`,async t=>{
  const {page}=await open(t,{stored:{levels:{[name]:.43,'Pink Noise':.12},favorites:[],saved:[]}});
  await page.locator(`[data-choose-recording="${name}"]`).click();
  assert.equal(await page.locator('#replacement-title').textContent(),`Choose ${family.toLowerCase()} recording`);
  assert.equal(await page.locator('#replacement-search').isHidden(),true);
  assert.equal(await page.locator('.replacement-search-label').isHidden(),true);
  assert.deepEqual(new Set(await page.locator('[data-select-recording]').evaluateAll(nodes=>nodes.map(node=>node.dataset.selectRecording))),new Set([name,other]));
  assert.equal(await page.evaluate(()=>soundPreviewAudio || players.size>0),false);
  await page.locator(`[data-select-recording="${other}"]`).click();
  await page.locator('#replacement-use').click();
  assert.deepEqual(await page.evaluate(()=>levels),{[other]:.43,'Pink Noise':.12});
  assert.equal(await page.evaluate(()=>playing || players.size>0),false);
 });
}
test('Change sound still offers all 18 sources and Soft Rain has no invented alternate take', async t=>{
 const {page}=await open(t);
 assert.equal(await page.locator('[data-choose-recording="Soft Rain"]').count(),0);
 await page.locator('[data-sound-options="Soft Rain"]').click();
 assert.equal(await page.locator('#replacement-title').textContent(),'Change Soft Rain');
 assert.equal(await page.locator('[data-select-recording]').count(),18);
 assert.equal(await page.locator('#replacement-search').isVisible(),true);
 assert.match(await page.locator('#replacement-description').textContent(),/different sound.*volume/i);
});
test('shuffle selects only distinct bundled source identities',async t=>{
 const {page}=await open(t);
 for(let i=0;i<8;i++){
    await page.locator('#shuffle').click();
    await minimizeAmbientForBackgroundControls(page);
  await page.waitForFunction(()=>ambientPlaybackState().active.length===3);
  const sources=await page.evaluate(()=>Object.entries(levels).filter(([,v])=>v>0).map(([name])=>localAmbientPath(name)));
  assert.equal(new Set(sources).size,3);assert(sources.every(Boolean));
 }
});
test('Meditate starts with today and three compact real practices; all 14 remain browsable',async t=>{
 const {page}=await open(t);
 await page.locator('.bottom-nav [data-tab=meditate]').click();
 assert.deepEqual(await page.locator('[data-practice]').evaluateAll(nodes=>nodes.map(node=>node.dataset.practice)),['gentle-relief','quiet-mind','body-rest']);
 assert.deepEqual(await page.locator('[data-intent]').evaluateAll(nodes=>nodes.map(node=>node.dataset.intent)),['All','Calm','Focus','Rest','Saved']);
 assert.equal(await page.locator('.practice-card .kicker, .practice-card .description, .daily-description').count(),0);
 assert.match(await page.locator('.med-audio-note').textContent(),/No spoken guidance/);
 await page.locator('#browse-practices').click();
 assert.equal(await page.locator('[data-practice]').count(),14);
 await page.locator('#browse-practices').click();
 assert.equal(await page.locator('[data-practice]').count(),3);
 assert.equal(await page.evaluate(()=>playing || !!guidedSession?.playing || players.size>0),false);
});
test('visible Save and Saved filter retain existing favorite identities without playing',async t=>{
 const {page}=await open(t);
 await page.locator('.bottom-nav [data-tab=meditate]').click();
 await page.locator('[data-save-practice=body-rest]').click();
 assert.equal(await page.locator('[data-save-practice=body-rest]').getAttribute('aria-pressed'),'true');
 await page.locator('[data-intent=Saved]').click();
 assert.deepEqual(await page.locator('[data-practice]').evaluateAll(nodes=>nodes.map(node=>node.dataset.practice)),['body-rest']);
 assert.deepEqual(await page.evaluate(()=>[...retreatFavorites]),['meditation-body-rest']);
 await page.locator('[data-save-practice=body-rest]').click();
 assert.match(await page.locator('#practice-list').textContent(),/No saved practices/);
 assert.equal(await page.evaluate(()=>!!guidedSession?.playing),false);
});
test('filtering during playback keeps the session and truthful pause button',async t=>{
 const {page}=await open(t);
 await page.locator('.bottom-nav [data-tab=meditate]').click();
 await page.locator('#begin-quiet-mind').click();
 await page.waitForFunction(()=>guidedSession?.playing&&!guidedAudio.paused);
 await page.locator('#session-minimize').click();
 const title=await page.evaluate(()=>guidedSession.title);
 await page.locator('[data-intent=Rest]').click();
 await page.locator('[data-intent=Focus]').click();
 assert.equal(await page.evaluate(()=>guidedSession.title),title);
 assert.equal(await page.locator('#begin-quiet-mind').getAttribute('aria-label'),`Pause ${title}`);
});
for(const width of [320,390,823]){
 test(`simple library and Meditate remain usable with larger text at ${width}px`,async t=>{
  const {page}=await open(t,{width});
  await page.evaluate(()=>{const r=document.documentElement;r.style.setProperty('--t',String(parseFloat(getComputedStyle(r).getPropertyValue('--t'))*1.6));});
  await page.locator('#catalog-review > summary').click();
  for(const selector of ['#library-available','#library-full','[data-choose-recording="Campfire"]']){
   const node=page.locator(selector);await node.scrollIntoViewIfNeeded();const box=await node.boundingBox();assert(box.height>=44&&box.width>=44);
  }
  await page.locator('.bottom-nav [data-tab=meditate]').click();
  for(const selector of ['#begin-daily','#daily-practice-save','#browse-practices','[data-save-practice=gentle-relief]']){
   const node=page.locator(selector);await node.scrollIntoViewIfNeeded();const box=await node.boundingBox();assert(box.height>=44&&box.width>=44);await node.focus();assert.equal(await node.evaluate(n=>n===document.activeElement),true);
  }
  assert.equal(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth),true);
 });
}


test('related previews retain duplicate guards, eight-second stop and gain recovery', async t => {
  const stored = { levels: { Campfire: .43, Fireplace: .21, 'Pink Noise': .12 }, favorites: [], saved: [] };
  const { page } = await open(t, { stored, virtualClock: true });
  await page.locator('#master-play').click();
  await minimizeAmbientForBackgroundControls(page);
  await page.waitForFunction(() => ambientPlaybackState().active.length === 3);
  await page.evaluate(() => { window.familyPlayers = [...players.values()]; });
  await page.locator('[data-choose-recording="Campfire"]').click();
  assert.equal(await page.locator('[data-select-recording="Fireplace"]').isDisabled(), true);
  assert.equal(await page.locator('#replacement-use').isDisabled(), true);
  await page.locator('[data-preview-recording="Fireplace"]').click();
  await page.waitForFunction(() => soundPreviewAudio && !soundPreviewAudio.paused && !soundPreviewLoading);
  assert.equal(await page.evaluate(() => soundPreviewDuck), .2);
  assert.deepEqual(await page.evaluate(() => levels), stored.levels);
  await page.clock.fastForward(8100);
  assert.equal(await page.evaluate(() => soundPreviewAudio), null);
  assert.equal(await page.evaluate(() => soundPreviewDuck), 1);
  await page.locator('#replacement-close').click();
  assert.equal(await page.evaluate(() => familyPlayers.every((audio, index) => audio === [...players.values()][index] && !audio.paused)), true);
  assert.deepEqual(await page.evaluate(() => levels), stored.levels);
});

test('keyboard Save and filters retain focus through updates and an empty Saved list', async t => {
  const { page } = await open(t);
  await page.locator('.bottom-nav [data-tab=meditate]').click();
  const save = page.locator('[data-save-practice=body-rest]');
  await save.focus();
  await page.keyboard.press('Enter');
  assert.equal(await save.evaluate(node => node === document.activeElement), true);
  assert.equal(await save.getAttribute('aria-pressed'), 'true');
  const savedFilter = page.locator('[data-intent=Saved]');
  await savedFilter.focus();
  await page.keyboard.press('Enter');
  assert.equal(await savedFilter.evaluate(node => node === document.activeElement), true);
  await save.focus();
  await page.keyboard.press('Enter');
  assert.equal(await page.locator('[data-practice]').count(), 0);
  assert.equal(await savedFilter.evaluate(node => node === document.activeElement), true);
  const browse = page.locator('#browse-practices');
  await browse.focus();
  await page.keyboard.press('Enter');
  assert.equal(await page.locator('[data-practice]').count(), 14);
  assert.equal(await browse.evaluate(node => node === document.activeElement), true);
  assert.equal(await page.evaluate(() => !!guidedSession?.playing || playing), false);
});
