'use strict';
// Existing bundled sounds only. These are not alternative takes of each
// catalog recording, and this HTML preview is not compiled Flutter.
const replacementDialog = document.createElement('dialog');
replacementDialog.id = 'sound-replacement-dialog';
replacementDialog.setAttribute('aria-labelledby', 'replacement-title');
replacementDialog.innerHTML = `<div class="replacement-scroll">
  <header class="replacement-heading"><h3 id="replacement-title">Replace sound</h3><button id="replacement-close" aria-label="Close sound chooser">×</button></header>
  <p>Choose from six bundled sounds. Preview up to 8 seconds; a playing mix becomes quieter underneath. Nothing changes until you tap Use sound.</p>
  <p id="replacement-off-notice" hidden>This layer is off. Its replacement will be selected at 30%. A paused mix stays paused.</p>
  <div class="replacement-list" id="replacement-list"></div><p id="replacement-error" role="status" hidden></p>
</div><footer><button class="primary" id="replacement-use" disabled>Use sound</button></footer>`;
document.body.append(replacementDialog);
let replacementFrom = null;
let replacementSelected = null;
let soundPreviewAudio = null;
let soundPreviewName = null;
let soundPreviewLoading = false;
let soundPreviewRequest = 0;
let soundPreviewTimer;
let soundPreviewLoadTimer;

function applySoundPreviewDucking(previewing) {
  soundPreviewDuck = previewing ? .2 : 1;
  const sum = Object.values(levels).reduce((a, b) => a + b, 0);
  const gain = Math.min(1, 1 / (sum || 1));
  const remaining = timerRemaining();
  const fade = remaining !== null && remaining <= 30 ? remaining / 30 : 1;
  for (const [name, audio] of players) {
    audio.volume = Math.min(.85, (levels[name] || 0) * gain * soundPreviewDuck) * fade;
  }
}

function stopSoundPreview() {
  ++soundPreviewRequest;
  clearTimeout(soundPreviewTimer);
  clearTimeout(soundPreviewLoadTimer);
  const audio = soundPreviewAudio;
  soundPreviewAudio = null;
  soundPreviewName = null;
  soundPreviewLoading = false;
  if (audio) {
    audio.onended = null;
    audio.onerror = null;
    audio.pause();
    audio.removeAttribute('src');
    audio.load();
  }
  // Restoring gain never invokes play() or changes selected levels.
  applySoundPreviewDucking(false);
  if (replacementDialog.open) renderSoundReplacement();
}

function failSoundPreview(request) {
  if (request !== soundPreviewRequest || !replacementDialog.open) return;
  stopSoundPreview();
  $('replacement-error').textContent = 'Preview could not play. Your mix was not changed.';
  $('replacement-error').hidden = false;
}

async function toggleSoundPreview(recording) {
  if (soundPreviewName === recording.name) {
    stopSoundPreview();
    return;
  }
  stopSoundPreview();
  $('replacement-error').hidden = true;
  const request = ++soundPreviewRequest;
  const audio = new Audio(recording.assetPath);
  audio.loop = false;
  audio.volume = .08;
  soundPreviewAudio = audio;
  soundPreviewName = recording.name;
  soundPreviewLoading = true;
  audio.onended = () => { if (request === soundPreviewRequest) stopSoundPreview(); };
  audio.onerror = () => failSoundPreview(request);
  soundPreviewLoadTimer = setTimeout(() => failSoundPreview(request), 10000);
  renderSoundReplacement();
  try {
    await audio.play();
    if (request !== soundPreviewRequest || !replacementDialog.open) {
      audio.pause();
      return;
    }
    clearTimeout(soundPreviewLoadTimer);
    soundPreviewLoading = false;
    applySoundPreviewDucking(true);
    renderSoundReplacement();
    soundPreviewTimer = setTimeout(stopSoundPreview, 8000);
  } catch (_) {
    failSoundPreview(request);
  }
}

function replacementConflict(to) {
  const asset = LOCAL_AUDIO[to];
  return Object.entries(levels).find(([name, level]) =>
    name !== replacementFrom?.name && level > 0 && (name === to || (asset && LOCAL_AUDIO[name] === asset)))?.[0];
}

function renderSoundReplacement() {
  const list = $('replacement-list');
  const scroll = replacementDialog.querySelector('.replacement-scroll');
  const scrollTop = scroll.scrollTop;
  list.replaceChildren();
  for (const recording of BUNDLED_RECORDINGS) {
    const current = recording.name === replacementFrom?.name;
    const conflict = replacementConflict(recording.name);
    const row = document.createElement('div');
    row.className = 'replacement-row';
    row.dataset.recording = recording.name;
    row.dataset.selected = replacementSelected === recording.name;
    const choice = document.createElement('button');
    choice.className = 'replacement-choice';
    choice.dataset.selectRecording = recording.name;
    choice.disabled = current || !!conflict;
    choice.setAttribute('aria-pressed', replacementSelected === recording.name);
    const img = document.createElement('img');
    img.src = all.find((track) => track.name === recording.name).artwork;
    img.alt = '';
    const copy = document.createElement('span');
    copy.className = 'replacement-copy';
    const title = document.createElement('strong');
    title.textContent = recording.name;
    const detail = document.createElement('small');
    detail.textContent = current ? 'Current sound' : conflict ? `Already in mix: ${conflict}` : recording.description;
    copy.append(title, detail);
    choice.append(img, copy);
    choice.onclick = () => {
      replacementSelected = recording.name;
      $('replacement-error').hidden = true;
      renderSoundReplacement();
    };
    const preview = document.createElement('button');
    preview.className = 'replacement-preview';
    preview.dataset.previewRecording = recording.name;
    const active = soundPreviewName === recording.name;
    preview.setAttribute('aria-label', `${active ? 'Stop preview' : 'Preview'} ${recording.name}`);
    preview.title = active && soundPreviewLoading ? 'Loading preview…' : preview.getAttribute('aria-label');
    setIcon(preview, active ? 'pause' : 'play');
    preview.onclick = () => { void toggleSoundPreview(recording); };
    row.append(choice, preview);
    list.append(row);
  }
  $('replacement-use').disabled = !replacementSelected || !!replacementConflict(replacementSelected);
  scroll.scrollTop = scrollTop;
}

function openSoundReplacement(track) {
  stopSoundPreview();
  replacementFrom = track;
  replacementSelected = null;
  $('replacement-title').textContent = `Replace ${track.name}`;
  $('replacement-off-notice').hidden = levels[track.name] > 0;
  $('replacement-error').hidden = true;
  renderSoundReplacement();
  replacementDialog.showModal();
  replacementDialog.querySelector('.replacement-scroll').scrollTop = 0;
  $('replacement-close').focus({ preventScroll: true });
}

$('replacement-use').onclick = () => {
  if (!replacementFrom || !replacementSelected || replacementConflict(replacementSelected)) return;
  const from = replacementFrom.name;
  const to = replacementSelected;
  const volume = levels[from] > 0 ? levels[from] : .3;
  stopSoundPreview();
  const wasPlaying = playing;
  levels = { ...levels };
  delete levels[from];
  levels[to] = volume;
  selectedPreset = null;
  category = CATALOG.find((category) => category.tracks.some((track) => track.name === to)).id;
  playing = wasPlaying;
  persist();
  syncAudio();
  render();
  updateHomeState();
  replacementDialog.close();
  toast(`${from} replaced with ${to}. Save your mix to keep this version.`);
};
$('replacement-close').onclick = () => replacementDialog.close();
replacementDialog.addEventListener('close', stopSoundPreview);
document.addEventListener('visibilitychange', () => { if (document.hidden) stopSoundPreview(); });
addEventListener('pagehide', stopSoundPreview);
