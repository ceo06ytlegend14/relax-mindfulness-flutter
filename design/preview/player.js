'use strict';
// Independent browser representation of the Flutter player. Audio here is the
// per-card ambient arrangements of existing recordings, not narrated sessions.
Object.assign(icons, {
  down: '<path d="m6 12 10 10 10-10"/>',
  close: '<path d="m8 8 16 16M24 8 8 24"/>',
  check: '<path d="m6 16 7 7L27 9" stroke-width="3"/>',
  rewind: '<path d="M14 6 3 16l11 10M28 6 17 16l11 10"/>',
  forward: '<path d="m4 6 11 10L4 26M18 6l11 10-11 10"/>',
  restart: '<path d="M6 10C14-1 31 8 27 21S5 31 4 19M6 3v8h8"/>',
  loop: '<path d="M16 16C10 4 2 6 2 16s8 12 14 0 14-10 14 0-8 12-14 0Z"/>',
});
// One arrangement at a time. Replacing the media element also fences off late
// metadata/error/play events from a previous card; no source is preloaded here.
let guidedAudio = createSessionAudio();
function createSessionAudio() {
  const audio = new Audio();
  audio.preload = 'none';
  audio.volume = .35;
  audio.addEventListener('loadedmetadata', () => {
    if (audio !== guidedAudio || !guidedSession) return;
    const elapsed = guidedSession.total - guidedSession.remaining;
    if (Number.isFinite(audio.duration) && audio.duration > 0) {
      audio.currentTime = guidedSession.loop ? elapsed % audio.duration
        : Math.min(elapsed, Math.max(0, audio.duration - .001));
      guidedSession.ready = true;
    }
    updateSession();
  });
  audio.addEventListener('ended', () => {
    if (audio === guidedAudio && guidedSession && !audio.loop) finishGuidedSession({ automatic: true });
  });
  audio.addEventListener('error', () => {
    if (audio === guidedAudio && guidedSession) failSessionAudio(guidedRequest);
  });
  return audio;
}
function releaseSessionAudio(audio) {
  audio.pause();
  audio.removeAttribute('src');
  audio.load(); // Cancel a pending fetch/play without loading a replacement.
}
function failSessionAudio(request) {
  if (request !== guidedRequest || !guidedSession) return;
  pauseGuided();
  guidedSession.ready = false;
  guidedSession.error = 'This session’s soundscape is unavailable. Try again.';
  updateSession();
}
let guidedRequest = 0;
let guidedLooping = true;
let scrubSeconds = null;

const playerDialog = document.createElement('dialog');
playerDialog.id = 'session-dialog';
playerDialog.className = 'session-dialog immersive-player';
playerDialog.setAttribute('aria-labelledby', 'session-title');
playerDialog.innerHTML = `
  <div class="player-backdrop" aria-hidden="true"></div>
  <div class="player-scroll">
    <div class="player-layout">
      <div class="player-main">
        <header class="player-header">
          <div class="player-stream player-glass">${svg('equalizer')}<span>AMBIENT SOUNDSCAPE</span><i id="session-live-dot"></i></div>
          <button id="session-minimize" class="player-circle player-glass" aria-label="Minimize session player">${svg('down')}</button>
        </header>
        <div class="breathing-art" id="breathing-art">
          <div class="breathing-ring ring-one" aria-hidden="true"></div><div class="breathing-ring ring-two" aria-hidden="true"></div><div class="breathing-ring ring-three" aria-hidden="true"></div>
          <div class="player-cover"><img id="session-art" src="assets/images/player/comfort_art.webp" alt=""><span class="player-cover-tag player-glass">${svg('leaf')}Relax</span></div>
        </div>
        <h3 id="session-title"></h3>
        <p id="session-sources" class="session-sources"></p>
        <p id="session-description">Ambient arrangement · No narration</p>
        <p id="session-error" role="status" hidden></p>
        <p class="session-clock" id="session-clock">15:00</p>
        <p id="session-status" class="session-status">PREPARING YOUR SOUNDSCAPE</p>
        <div class="player-progress">
          <input type="range" id="session-progress" min="0" max="900" step="1" value="0" aria-label="Session progress">
          <div class="player-time-labels"><span id="session-elapsed">00:00</span><span id="session-duration">15:00</span></div>
        </div>
        <div class="player-transport">
          <div class="seek-control"><button id="session-back" class="player-circle player-glass" aria-label="Back 10 seconds">${svg('rewind')}</button><span>−10 sec</span></div>
          <button id="session-pause" class="player-toggle" aria-label="Pause session">${svg('pause')}</button>
          <div class="seek-control"><button id="session-forward" class="player-circle player-glass" aria-label="Forward 10 seconds">${svg('forward')}</button><span>+10 sec</span></div>
        </div>
        <div class="player-options">
          <button id="session-extend" class="player-glass">${svg('clock')}<span>+10 Min</span></button>
          <button id="session-loop" class="player-glass" aria-pressed="true">${svg('loop')}<span>Loop On</span></button>
          <button id="session-restart" class="player-glass">${svg('restart')}<span>Restart</span></button>
        </div>
      </div>
      <footer class="player-ending">
        <button id="session-stop" class="player-complete player-glass"><span class="player-check">${svg('check')}</span><span><strong>Complete &amp; End Session</strong><small>Take this little moment of calm with you.</small></span>${svg('arrow')}</button>
        <p class="player-preview-note">Independent browser design preview · Mixed from existing library recordings</p>
      </footer>
    </div>
  </div>`;
document.body.append(playerDialog);

const miniPlayer = document.createElement('aside');
miniPlayer.id = 'shared-mini-player';
miniPlayer.className = 'shared-mini-player';
miniPlayer.setAttribute('aria-label', 'Audio player');
miniPlayer.hidden = true;
miniPlayer.innerHTML = `<button class="mini-open" id="mini-open"><img id="mini-art" src="assets/images/sleep/moonlit_shore.webp" alt=""><span><strong id="mini-title"></strong><small id="mini-subtitle"></small></span></button><button id="mini-pause" class="mini-toggle" aria-label="Pause audio">${svg('pause')}</button><button id="mini-stop" class="mini-close" aria-label="Stop all audio">${svg('close')}</button>`;
nav.before(miniPlayer);

function playerArtwork(session) {
  return SLEEP_STORIES.some(story => story.title === session.title) || session.intent === 'Sleep'
    ? 'assets/images/sleep/moonlit_shore.webp'
    : 'assets/images/player/comfort_art.webp';
}

function syncGuidedRemaining() {
  if (guidedSession?.playing) {
    guidedSession.remaining = Math.max(0, (guidedSession.deadline - Date.now()) / 1000);
  }
}

function openSessionPlayer() {
  if (!guidedSession) return;
  if (typeof dismissAmbientPlayer === 'function') dismissAmbientPlayer();
  updateSession();
  if (!playerDialog.open) {
    playerDialog.showModal();
    document.body.classList.add('player-open');
    document.documentElement.classList.add('sanctuary-player-expanded');
    playerDialog.querySelector('.player-scroll').scrollTop = 0;
  }
  renderMaster();
  updateMiniPlayer();
}

function minimizeSessionPlayer() {
  if (playerDialog.open) playerDialog.close();
  if (typeof syncPlayerPresentation === 'function') syncPlayerPresentation();
  else {
    document.body.classList.remove('player-open');
    document.documentElement.classList.remove('sanctuary-player-expanded');
    renderMaster();
    updateMiniPlayer();
  }
}

async function startGuided(session) {
  if (!Number.isInteger(session.minutes) || session.minutes <= 0) return;
  const soundscape = sessionSoundscapeForTitle(session.title);
  if (guidedSession?.title === session.title && guidedSession.remaining > 0) {
    openSessionPlayer();
    if (!guidedSession.playing && !guidedSession.loading) await resumeGuided();
    return;
  }
  guidedRequest++;
  const previousAudio = guidedAudio;
  guidedAudio = createSessionAudio();
  releaseSessionAudio(previousAudio);
  playing = false;
  syncAudio();
  renderMaster();
  guidedSession = {
    ...session,
    soundscape,
    total: session.minutes * 60,
    remaining: session.minutes * 60,
    playing: false,
    loading: false,
    ready: false,
    error: null,
    loop: guidedLooping,
  };
  guidedAudio.loop = guidedLooping;
  scrubSeconds = null;
  $('session-title').textContent = session.title;
  $('session-art').src = playerArtwork(session);
  openSessionPlayer();
  await resumeGuided();
}

async function resumeGuided() {
  if (!guidedSession || guidedSession.playing || guidedSession.loading) return;
  if (typeof dismissAmbientPlayer === 'function') dismissAmbientPlayer();
  const request = ++guidedRequest;
  const audio = guidedAudio;
  const session = guidedSession;
  playing = false;
  syncAudio();
  renderMaster();
  session.loading = true;
  session.error = null;
  updateSession();
  try {
    // Never derive a URL from the title or fall back to unrelated audio. A
    // retry reloads only this arrangement, restoring its retained elapsed time.
    if (!session.soundscape) throw new Error('No arrangement is configured');
    if (!session.ready || audio.error) {
      session.ready = false;
      audio.src = session.soundscape.assetPath;
      audio.load();
    }
    await audio.play();
    if (request !== guidedRequest || session !== guidedSession) {
      // A cancelled old play cannot revive discarded or paused audio. Do not
      // interrupt a newer successful resume of the same media element.
      if (audio !== guidedAudio || !guidedSession?.playing) audio.pause();
      return;
    }
    session.loading = false;
    session.playing = true;
    session.deadline = Date.now() + session.remaining * 1000;
    updateSession();
    updateSleepState();
  } catch (error) {
    failSessionAudio(request);
  }
}

function pauseGuided() {
  if (!guidedSession) return;
  guidedRequest++;
  syncGuidedRemaining();
  guidedSession.playing = false;
  guidedSession.loading = false;
  guidedAudio.pause();
  updateSession();
  updateMiniPlayer();
  if (typeof updateHomeState === 'function') updateHomeState();
}

function seekGuided(seconds) {
  if (!guidedSession?.ready || guidedSession.loading || guidedSession.error || !Number.isFinite(guidedAudio.duration) || guidedAudio.duration <= 0) return;
  syncGuidedRemaining();
  const elapsed = Math.max(0, Math.min(guidedSession.total - 1, Math.round(seconds)));
  // Timed ambient arrangements repeat; seek within this card’s own recording.
  guidedAudio.currentTime = guidedSession.loop ? elapsed % guidedAudio.duration
    : Math.min(elapsed, Math.max(0, guidedAudio.duration - .001));
  guidedSession.remaining = guidedSession.total - elapsed;
  if (guidedSession.playing) guidedSession.deadline = Date.now() + guidedSession.remaining * 1000;
  scrubSeconds = null;
  updateSession();
  updateMiniPlayer();
}

function finishGuidedSession({ automatic = false, silent = false } = {}) {
  guidedRequest++;
  guidedSession = null;
  syncSanctuaryClock();
  releaseSessionAudio(guidedAudio);
  scrubSeconds = null;
  minimizeSessionPlayer();
  updateSleepState();
  // This demo deliberately does not invent a wellbeing record or listening streak.
  if (automatic && !silent) toast('Your quiet moment is complete.');
}

function syncPlayerMotion() {
  const visible = !document.hidden;
  $('breathing-art').classList.toggle('is-breathing', visible && playerDialog.open && !!guidedSession?.playing);
  const ambientArt = $('ambient-breathing-art');
  if (ambientArt) ambientArt.classList.toggle('is-breathing', visible && !!document.querySelector('#ambient-dialog[open]') && ambientPlaybackState().active.length > 0);
}
function updateSessionClock() {
  if (!guidedSession) return;
  const session = guidedSession;
  const elapsed = scrubSeconds ?? Math.max(0, session.total - session.remaining);
  $('session-clock').textContent = clock(session.remaining);
  $('session-elapsed').textContent = clock(Math.floor(elapsed));
  $('session-duration').textContent = clock(session.total);
  $('session-progress').max = session.total;
  $('session-progress').value = Math.floor(elapsed);
  $('session-progress').style.setProperty('--progress', `${100 * elapsed / session.total}%`);
  $('session-progress').setAttribute('aria-valuetext', `${clock(elapsed)} of ${clock(session.total)}`);
}
function updateSession() {
  if (!guidedSession) return;
  syncGuidedRemaining();
  syncSanctuaryClock();
  const session = guidedSession;
  const ready = session.ready && Number.isFinite(guidedAudio.duration) && !session.loading && !session.error;
  $('session-sources').textContent = session.soundscape?.sourceLabel || 'No soundscape configured';
  $('session-description').textContent = session.loop ? 'Ambient mix · Repeats about every 30 sec · No narration' : 'Ambient mix · Ends after this ~30 sec recording · No narration';
  updateSessionClock();
  $('session-progress').disabled = !ready;
  for (const id of ['session-back', 'session-forward', 'session-restart']) $(id).disabled = !ready;
  $('session-loop').disabled = session.loading;
  $('session-loop').setAttribute('aria-pressed', String(session.loop));
  $('session-loop').querySelector('span').textContent = session.loop ? 'Loop On' : 'Loop Off';
  $('session-pause').disabled = session.loading;
  $('session-pause').setAttribute('aria-label', session.loading ? 'Loading ambient soundscape'
    : session.playing ? 'Pause session' : session.error ? 'Retry audio' : 'Resume session');
  $('session-pause').innerHTML = session.loading ? '<span class="player-spinner" aria-hidden="true"></span>' : svg(session.playing ? 'pause' : 'play');
  $('session-status').textContent = session.loading ? 'PREPARING YOUR SOUNDSCAPE'
    : session.error ? 'SOUNDSCAPE UNAVAILABLE' : session.playing ? 'TIME TO UNWIND' : 'PAUSED · STAY A LITTLE LONGER';
  $('session-error').hidden = !session.error;
  $('session-error').textContent = session.error || '';
  syncPlayerMotion();
  $('session-live-dot').classList.toggle('is-playing', session.playing);
  updateMiniPlayer();
}

function updateMiniPlayerClock() {
  if (miniPlayer.hidden) return;
  const guided = !!guidedSession && !ambientHasSession && !playing;
  const text = guided
    ? guidedSession.loading ? 'Preparing soundscape…' : guidedSession.error ? 'Audio unavailable · tap to retry'
      : `${guidedSession.playing ? sessionSourceLabel(guidedSession.title) : 'Session paused'} · ${Math.ceil(guidedSession.remaining / 60)} min left`
    : [typeof ambientPlaybackLabel === 'function' ? ambientPlaybackLabel() : 'Your selected sounds',
      sleepDeadline !== null ? `Auto-fade · ${Math.ceil(timerRemaining() / 60)} min left` : ''].filter(Boolean).join(' · ');
  if ($('mini-subtitle').textContent !== text) $('mini-subtitle').textContent = text;
}
function updateMiniPlayer() {
  syncPlayerMotion();
  updateMeditationCards();
  updateStoryPlayback();
  const state = ambientPlaybackState();
  const selected = [...state.selected].sort((a, b) => b[1] - a[1]);
  const guided = !!guidedSession && !ambientHasSession && !playing;
  const ambientExpanded = !!document.querySelector('#ambient-dialog[open]');
  const visible = !playerDialog.open && !ambientExpanded && (guided || (ambientHasSession && selected.length > 0));
  miniPlayer.hidden = !visible;
  document.body.classList.toggle('has-mini-player', visible);
  if (typeof updateAmbientPlayer === 'function') updateAmbientPlayer();
  if (!visible) return;
  const main = selected[0]?.[0];
  const title = guided ? guidedSession.title : selectedPreset || (selected.length === 1 ? main : `${main} + ${selected.length - 1} more`);
  const isPlaying = guided ? guidedSession.playing : state.active.length > 0;
  $('mini-title').textContent = title;
  $('mini-art').src = guided ? playerArtwork(guidedSession) : typeof ambientArtwork === 'function' ? ambientArtwork() : artworkForTrack(main);
  updateMiniPlayerClock();
  $('mini-open').setAttribute('aria-label', guided ? `Open ${title} session player` : `Open ${title} soundscape player`);
  $('mini-pause').setAttribute('aria-label', guided ? isPlaying ? 'Pause audio' : 'Resume session'
    : typeof ambientTransportLabel === 'function' ? ambientTransportLabel(state) : 'Resume soundscape');
  $('mini-pause').disabled = guided && guidedSession.loading;
  $('mini-pause').innerHTML = guided && guidedSession.loading ? '<span class="player-spinner" aria-hidden="true"></span>'
    : svg(guided ? isPlaying ? 'pause' : 'play' : state.canPause ? state.active.length ? 'pause' : 'close' : 'play');
}

$('session-minimize').onclick = minimizeSessionPlayer;
playerDialog.addEventListener('cancel', (event) => { event.preventDefault(); minimizeSessionPlayer(); });
playerDialog.addEventListener('close', () => {
  if (playerDialog.open) return; // A queued close must not affect a reopened player.
  if (typeof syncPlayerPresentation === 'function') syncPlayerPresentation();
  else {
    document.body.classList.remove('player-open');
    document.documentElement.classList.remove('sanctuary-player-expanded');
    updateMiniPlayer();
  }
});
$('session-pause').onclick = () => guidedSession?.playing ? pauseGuided() : resumeGuided();
$('session-stop').onclick = () => finishGuidedSession();
$('session-back').onclick = () => { syncGuidedRemaining(); seekGuided(guidedSession.total - guidedSession.remaining - 10); };
$('session-forward').onclick = () => { syncGuidedRemaining(); seekGuided(guidedSession.total - guidedSession.remaining + 10); };
$('session-restart').onclick = () => seekGuided(0);
$('session-progress').oninput = (event) => { scrubSeconds = Number(event.target.value); updateSession(); };
$('session-progress').onchange = (event) => seekGuided(Number(event.target.value));
$('session-extend').onclick = () => {
  if (!guidedSession) return;
  syncGuidedRemaining();
  guidedSession.total += 600;
  guidedSession.remaining += 600;
  if (guidedSession.playing) guidedSession.deadline += 600000;
  updateSession();
};
$('session-loop').onclick = () => {
  if (!guidedSession) return;
  guidedLooping = !guidedSession.loop;
  guidedSession.loop = guidedLooping;
  guidedAudio.loop = guidedLooping;
  updateSession();
};
$('mini-open').onclick = () => !ambientHasSession && guidedSession ? openSessionPlayer() : openAmbientPlayer();
$('mini-pause').onclick = () => {
  if (!ambientHasSession && guidedSession) {
    if (guidedSession.playing) pauseGuided(); else resumeGuided();
  } else start({ expand: false });
};
$('mini-stop').onclick = () => stopPreviewAudio();
document.addEventListener('visibilitychange', syncPlayerMotion);
updateMiniPlayer();
