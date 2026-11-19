// Framework-free structural guards. These do not compile or launch Android.
import assert from 'node:assert/strict';
import { readFile, readdir } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { test } from 'node:test';

const root = fileURLToPath(new URL('../../', import.meta.url));
const android = path.join(root, 'android/app/src/main');
const manifest = await readFile(path.join(android, 'AndroidManifest.xml'), 'utf8');
const gradle = await readFile(path.join(root, 'android/app/build.gradle.kts'), 'utf8');
async function files(directory) {
  const entries = await readdir(directory, { withFileTypes: true });
  return (await Promise.all(entries.map(entry => entry.isDirectory()
    ? files(path.join(directory, entry.name)) : path.join(directory, entry.name)))).flat();
}

test('Android launcher activity exists in the application namespace', async () => {
  const namespace = gradle.match(/namespace\s*=\s*"([^"]+)"/)?.[1];
  assert(namespace);
  const activity = manifest.match(/<activity\b[^>]*android:name="([^"]+)"/)?.[1];
  assert(activity);
  const qualified = activity.startsWith('.') ? `${namespace}${activity}` : activity;
  const source = await readFile(path.join(android, 'kotlin', `${qualified.replaceAll('.', '/')}.kt`), 'utf8');
  assert.match(source, new RegExp(`^package ${namespace.replaceAll('.', '\\.')}\\s*$`, 'm'));
  assert.match(source, /class MainActivity\s*:\s*FlutterActivity\(\)/);
});

test('both launcher icon references resolve to actual Android resources', async () => {
  const resources = await files(path.join(android, 'res'));
  for (const attribute of ['icon', 'roundIcon']) {
    const reference = manifest.match(new RegExp(`android:${attribute}="@(mipmap|drawable)/([^"/]+)"`));
    assert(reference, `${attribute} has a valid resource reference`);
    assert(resources.some(file => path.basename(file).replace(/\.[^.]+$/, '') === reference[2]
      && path.basename(path.dirname(file)).split('-')[0] === reference[1]), `${attribute} exists`);
  }
});

test('launcher identity does not change the existing application ID', () => {
  assert.match(gradle, /applicationId\s*=\s*"com\.sanctuary\.relax_mindfulness"/);
  assert.match(manifest, /android:label="Sanctuary"/);
});

test('native platform safety defaults remain in place', () => {
  assert.match(manifest, /android:allowBackup="false"/);
  assert.match(manifest, /android:networkSecurityConfig="@xml\/network_security_config"/);
  assert.match(manifest, /android:exported="true"/);
});

test('declared SDK minimums match the existing lockfile requirements', async () => {
  const pubspec = await readFile(path.join(root, 'pubspec.yaml'), 'utf8');
  const lock = await readFile(path.join(root, 'pubspec.lock'), 'utf8');
  assert.match(pubspec, /sdk:\s*'>=3\.8\.0 <4\.0\.0'/);
  assert.match(pubspec, /flutter:\s*'>=3\.32\.0'/);
  assert.match(lock, /dart:\s*">=3\.8\.0 <4\.0\.0"/);
  assert.match(lock, /flutter:\s*">=3\.32\.0"/);
});

test('quality automation has no repository-write or deployment capability', async () => {
  const workflow = await readFile(path.join(root, '.github/workflows/quality.yml'), 'utf8');
  assert.match(workflow, /permissions:\s*\n  contents: read/);
  assert.doesNotMatch(workflow, /pull_request_target|secrets\.|contents: write|npm publish|gh release|firebase deploy/);
  for (const action of workflow.matchAll(/uses:\s*([^\s]+)@([^\s]+)/g)) {
    assert.match(action[2], /^[a-f0-9]{40}$/, `${action[1]} is SHA-pinned`);
  }
  assert.match(workflow, /flutter test --reporter expanded/);
  assert.match(workflow, /flutter build web --release/);
  assert.match(workflow, /flutter build apk --debug/);
  assert.match(workflow, /npm run test:web/);
});

test('the unconnected feedback UI no longer claims a message was received', async () => {
  const wellbeing = await readFile(path.join(root, 'lib/screens/wellbeing_screen.dart'), 'utf8');
  assert.doesNotMatch(wellbeing, /Your feedback has been received/);
  assert.match(wellbeing, /const DataBackupScreen\(\)/);
});
