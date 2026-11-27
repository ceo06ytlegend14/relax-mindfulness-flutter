'use strict';
// A view of the mixer's existing selection and owned audio, never another
// playback engine. Showing/minimizing this dialog must not call play/load/seek.
const ambientDialog = document.createElement('dialog');
ambientDialog.id = 'ambient-dialog';
ambientDialog.className = 'immersive-player ambient-player';
ambientDialog.setAttribute('aria-labelledby', 'ambient-title');
ambientDialog.innerHTML = `
  <div class="player-backdrop" aria-hidden="true"></div>
  <div class="player-scroll">
    <header class="player-header">
      <div class="player-stream player-glass">${svg('equalizer')}<span>AMBIENT MIX</span><i id="ambient-live-dot"></i></div>
      <button id="ambient-minimize" class="player-circle player-glass" aria-label="Minimize soundscape player">${svg('down')}</button>
    </header>
    <div class="breathing-art ambient-art" id="ambient-breathing-art">
      <div class="breathing-ring ring-one" aria-hidden="true"></div><div class="breathing-ring ring-two" aria-hidden="true"></div><div class="breathing-ring ring-three" aria-hidden="true"></div>
      <div class="player-cover"><img id="ambient-art" src="assets/images/meditate/morning.webp" alt=""></div>
    </div>
    <h2 id="ambient-title"></h2>
    <p id="ambient-status" role="status"></p>
    <p class="ambient-loop-note">Continuous loops · No narration</p>
    <div class="ambient-transport">
      <button id="ambient-timer" class="ambient-secondary player-glass">${svg('clock')}<span>Set auto-fade</span></button>
      <button id="ambient-pause" class="player-toggle" aria-label="Pause soundscape">${svg('pause')}</button>
      <button id="ambient-edit" class="ambient-secondary player-glass">${svg('equalizer')}<span>Add sounds</span></button>
    </div>
    <section class="ambient-layer-section" aria-labelledby="ambient-layers-heading">
      <div class="ambient-layer-heading"><h3 id="ambient-layers-heading">YOUR SOUNDS</h3><span id="ambient-layer-count"></span></div>
      <ul id="ambient-layers"></ul>
      <p class="ambient-level-note">Individual volumes, not parts of 100%. Overall output is gain-limited.</p>
    </section>
    <footer class="ambient-ending">
      <button id="ambient-save" class="player-glass">${svg('bookmark')}<span>Save a separate mix</span></button>
      <button id="ambient-stop" class="player-glass">${svg('close')}<span>Stop soundscape</span></button>
      <p class="player-preview-note">Independent browser design preview · Existing library recordings</p>
    </footer>
  </div>`;
document.body.append(ambientDialog);

function ambientSelectedLayers() {
  // Keep recipe order stable while levels change; only playback status is
  // allowed to say Playing. Selected/loading/failed are not audible counts.
  return Object.entries(levels).filter(([, value]) => value > 0);
}
function ambientTitle() {
  const selected = ambientSelectedLayers();
  const main = [...selected].sort((a, b) => b[1] - a[1])[0]?.[0];
  return selectedPreset || (selected.length === 1 ? main : `${main} + ${selected.length - 1} more`);
}
function ambientArtwork() {
  const selected = ambientSelectedLayers();
  if (selectedPreset === OCEAN_JOURNEY.title || levels['Ocean Waves'] > 0) return OCEAN_JOURNEY.artwork;
  const main = [...selected].sort((a, b) => b[1] - a[1])[0]?.[0];
  return all.find(track => track.name === main)?.artwork || artworkForTrack(main);
}
function ambientPlaybackLabel(state = ambientPlaybackState()) {
  const suffix = ambientStatusSuffix(state);
  return state.active.length ? `Playing · ${state.active.length} ${state.active.length === 1 ? 'layer' : 'layers'}${suffix ? ' · ' + suffix : ''}`
    : state.pending.length ? 'Preparing your sounds…'
      : state.failed.length ? 'Audio unavailable · Retry your sounds'
        : 'Paused · Your sounds are kept';
}
function ambientTransportLabel(state = ambientPlaybackState()) {
  return state.canPause ? state.active.length ? 'Pause soundscape' : 'Cancel sound loading'
    : state.failed.length ? 'Retry soundscape' : 'Resume soundscape';
}
function openAmbientPlayer() {
  if (!ambientSelectedLayers().length) return;
  ambientHasSession = true;
  if (playerDialog.open) minimizeSessionPlayer();
  updateAmbientPlayer();
  if (!ambientDialog.open) {
    ambientDialog.showModal();
    ambientDialog.querySelector('.player-scroll').scrollTop = 0;
    $('ambient-minimize').focus({ preventScroll: true });
  }
  syncPlayerPresentation();
}
function syncPlayerPresentation() {
  const expanded = playerDialog.open || ambientDialog.open;
  document.body.classList.toggle('player-open', expanded);
  document.documentElement.classList.toggle('sanctuary-player-expanded', expanded);
  renderMaster();
  updateMiniPlayer();
}
function minimizeAmbientPlayer() {
  if (ambientDialog.open) ambientDialog.close();
  syncPlayerPresentation();
}
function dismissAmbientPlayer() {
  ambientHasSession = false;
  minimizeAmbientPlayer();
}
function stopPreviewAudio() {
  playing = false;
  ambientHasSession = false;
  syncAudio();
  minimizeAmbientPlayer();
  finishGuidedSession({ silent: true });
  render();
}
function retryAmbientTrack(name) {
  if (!(levels[name] > 0) || !localAmbientPath(name) || ambientStates.get(name)?.phase !== 'error') return;
  // The failed source was already released. Retry only it, never another failed
  // layer or any retained healthy loop. Existing gain limiting remains shared.
  ambientStates.delete(name);
  playing = true;
  syncAudio();
  persist();
}
function ambientLayerStatus(name) {
  if (!localAmbientPath(name)) return 'Not in this preview';
  const status = ambientTrackStatus(name);
  if (status === 'playing') return 'Playing';
  if (status === 'loading') {
    const percent = players.get(name)?.downloadProgress;
    return percent > 0 && percent < 1 ? `Loading · ${Math.floor(percent * 100)}%` : 'Preparing audio…';
  }
  if (ambientStates.get(name)?.phase === 'error') return 'Unavailable · Retry this layer';
  return 'Paused';
}
function createAmbientLayer(name) {
  const row = document.createElement('li');
  row.className = 'ambient-layer player-glass';
  row.dataset.ambientLayer = name;
  const header = document.createElement('div');
  header.className = 'ambient-layer-header';
  const art = document.createElement('img');
  art.src = all.find(track => track.name === name)?.artwork || artworkForTrack(name);
  art.alt = '';
  const copy = document.createElement('div');
  copy.className = 'ambient-layer-copy';
  const title = document.createElement('strong');
  title.textContent = name;
  const status = document.createElement('small');
  status.className = 'ambient-layer-status';
  copy.append(title, status);
  const level = document.createElement('output');
  level.className = 'ambient-layer-level';
  const remove = document.createElement('button');
  remove.className = 'ambient-layer-remove';
  remove.setAttribute('aria-label', `Remove ${name} from mix`);
  remove.innerHTML = svg('close');
  remove.onclick = () => { updatePreviewLevel(name, 0, { preservePaused: true }); render(); };
  header.append(art, copy, level, remove);
  const slider = document.createElement('input');
  slider.type = 'range';
  slider.min = '0'; slider.max = '100'; slider.step = '1';
  slider.className = 'ambient-layer-slider';
  slider.setAttribute('aria-label', `${name} volume`);
  slider.oninput = () => {
    updatePreviewLevel(name, Number(slider.value) / 100, { preservePaused: true });
    renderMaster(); renderVibeSetDetails();
  };
  slider.onchange = () => { renderTracks(); renderPresets(); };
  const retry = document.createElement('button');
  retry.className = 'ambient-layer-retry';
  retry.textContent = 'Retry layer';
  retry.setAttribute('aria-label', `Retry ${name}`);
  retry.onclick = () => retryAmbientTrack(name);
  row.append(header, slider, retry);
  return row;
}
function updateAmbientTimer() {
  const timer = timerRemaining();
  $('ambient-timer').querySelector('span').textContent = timer === null ? 'Set auto-fade' : `${clock(timer)} · Cancel fade`;
  $('ambient-timer').setAttribute('aria-label', timer === null ? 'Set sleep auto-fade timer' : `Cancel auto-fade timer, ${clock(timer)} remaining`);
}
function updateAmbientPlayer() {
  if (!ambientHasSession) return;
  const selected = ambientSelectedLayers();
  if (!selected.length) { dismissAmbientPlayer(); return; }
  const state = ambientPlaybackState();
  $('ambient-title').textContent = ambientTitle();
  $('ambient-art').src = ambientArtwork();
  $('ambient-status').textContent = ambientPlaybackLabel(state);
  $('ambient-live-dot').classList.toggle('is-playing', state.active.length > 0);
  syncPlayerMotion();
  $('ambient-layer-count').textContent = `${selected.length} selected`;
  $('ambient-pause').setAttribute('aria-label', ambientTransportLabel(state));
  $('ambient-pause').setAttribute('aria-busy', String(state.pending.length > 0));
  $('ambient-pause').innerHTML = svg(state.canPause ? state.active.length ? 'pause' : 'close' : 'play');
  updateAmbientTimer();
  const list = $('ambient-layers');
  const names = new Set(selected.map(([name]) => name));
  for (const row of [...list.children]) if (!names.has(row.dataset.ambientLayer)) {
    const focused = row.contains(document.activeElement);
    row.remove();
    if (focused) $('ambient-pause').focus({ preventScroll: true });
  }
  for (const [index, [name, value]] of selected.entries()) {
    let row = [...list.children].find(row => row.dataset.ambientLayer === name);
    if (!row) row = createAmbientLayer(name);
    if (list.children[index] !== row) list.insertBefore(row, list.children[index] || null);
    row.querySelector('output').textContent = `${Math.round(value * 100)}%`;
    row.querySelector('small').textContent = ambientLayerStatus(name);
    row.dataset.status = ambientTrackStatus(name);
    const slider = row.querySelector('input');
    slider.value = Math.round(value * 100);
    slider.style.setProperty('--progress', `${slider.value}%`);
    slider.setAttribute('aria-valuetext', `${slider.value} percent`);
    slider.disabled = !localAmbientPath(name);
    row.querySelector('.ambient-layer-retry').hidden = ambientStates.get(name)?.phase !== 'error' || !localAmbientPath(name);
  }
}
$('ambient-minimize').onclick = minimizeAmbientPlayer;
ambientDialog.addEventListener('cancel', event => { event.preventDefault(); minimizeAmbientPlayer(); });
ambientDialog.addEventListener('keydown', event => {
  if (event.key !== 'Tab') return;
  const controls = [...ambientDialog.querySelectorAll('button:not(:disabled), input:not(:disabled), [tabindex]:not([tabindex="-1"])')]
    .filter(control => control.getClientRects().length > 0 && !control.hidden);
  const first = controls[0], last = controls.at(-1);
  if (event.shiftKey && (document.activeElement === first || document.activeElement === ambientDialog)) {
    event.preventDefault(); last?.focus();
  } else if (!event.shiftKey && (document.activeElement === last || document.activeElement === ambientDialog)) {
    event.preventDefault(); first?.focus();
  }
});
ambientDialog.addEventListener('close', () => { if (!ambientDialog.open) syncPlayerPresentation(); });
$('ambient-pause').onclick = () => start({ expand: false });
$('ambient-stop').onclick = stopPreviewAudio;
$('ambient-edit').onclick = () => { minimizeAmbientPlayer(); selectRetreatTab('sounds'); };
$('ambient-save').onclick = () => $('save').click();
$('ambient-timer').onclick = () => $('sleep-timer-button').click();
document.addEventListener('visibilitychange', updateAmbientPlayer);
updateMiniPlayer();
