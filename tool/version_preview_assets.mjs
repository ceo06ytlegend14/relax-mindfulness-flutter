#!/usr/bin/env node
// Keep the independent HTML preview's asset URLs in sync with their bytes.
// No build output or duplicate CSS/JS is generated; data/storage stay untouched.
import { createHash } from 'node:crypto';
import { readFile, writeFile } from 'node:fs/promises';

const check = process.argv.includes('--check');
if (process.argv.slice(2).some(argument => argument !== '--check')) {
  throw new Error('Usage: node tool/version_preview_assets.mjs [--check]');
}
const entry = new URL('../design/preview/index.html', import.meta.url);
const html = await readFile(entry, 'utf8');
const assetLink = /\b(src|href)="((?!https?:|\/\/)[^"?]+\.(?:css|js))(?:\?v=[a-f0-9]{12})?"/g;
const hashes = new Map();
for (const [, , asset] of html.matchAll(assetLink)) {
  if (hashes.has(asset)) continue;
  const bytes = await readFile(new URL(asset, entry));
  hashes.set(asset, createHash('sha256').update(bytes).digest('hex').slice(0, 12));
}
const updated = html.replace(assetLink, (_, attribute, asset) =>
  `${attribute}="${asset}?v=${hashes.get(asset)}"`);
if (check && updated !== html) {
  console.error('Preview asset versions are stale. Run: node tool/version_preview_assets.mjs');
  process.exitCode = 1;
} else {
  if (!check && updated !== html) await writeFile(entry, updated);
  console.log(`${hashes.size} preview stylesheet/script content versions ${check ? 'verified' : 'updated'}.`);
}
