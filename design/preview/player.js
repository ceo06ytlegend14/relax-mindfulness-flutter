'use strict';
// Independent browser representation of the Flutter player. Audio here is the
// bundled calming sample, not narration, streaming quality or simulated history.
Object.assign(icons, {
  down: '<path d="m6 12 10 10 10-10"/>',
  close: '<path d="m8 8 16 16M24 8 8 24"/>',
  check: '<path d="m6 16 7 7L27 9" stroke-width="3"/>',
  rewind: '<path d="M14 6 3 16l11 10M28 6 17 16l11 10"/>',
  forward: '<path d="m4 6 11 10L4 26M18 6l11 10-11 10"/>',
  restart: '<path d="M6 10C14-1 31 8 27 21S5 31 4 19M6 3v8h8"/>',
  loop: '<path d="M16 16C10 4 2 6 2 16s8 12 14 0 14-10 14 0-8 12-14 0Z"/>',
});
const guidedAudio = new Audio('assets/sounds/calm_guided.mp3');
guidedAudio.loop = true;
guidedAudio.preload = 'none';
guidedAudio.volume = .35;
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
          <div class="player-stream player-glass">${svg('equalizer')}<span>SOOTHING AUDIO</span><i id="session-live-dot"></i></div>
          <button id="session-minimize" class="player-circle player-glass" aria-label="Minimize session player">${svg('down')}</button>
        </header>
        <div class="breathing-art" id="breathing-art">
          <div class="breathing-ring ring-one" aria-hidden="true"></div><div class="breathing-ring ring-two" aria-hidden="true"></div><div class="breathing-ring ring-three" aria-hidden="true"></div>
          <div class="player-cover"><img id="session-art" src="assets/images/player/comfort_art.webp" alt=""><span class="player-cover-tag player-glass">${svg('leaf')}Relax</span></div>
        </div>
        <h3 id="session-title"></h3>
        <p id="session-description">Calming audio · A little space to breathe.</p>
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
        <p class="player-preview-note">Independent browser design preview · Bundled calming audio</p>
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
  updateSession();
  if (!playerDialog.open) {
    playerDialog.showModal();
    document.body.classList.add('player-open');
    document.documentElement.classList.add('sanctuary-player-expanded');
    playerDialog.querySelector('.player-scroll').scrollTop = 0;
  }
  updateMiniPlayer();
}

function minimizeSessionPlayer() {
  playerDialog.close();
  document.body.classList.remove('player-open');
  document.documentElement.classList.remove('sanctuary-player-expanded');
  updateMiniPlayer();
}

async function startGuided(session) {
  if (guidedSession?.title === session.title && guidedSession.remaining > 0) {
    openSessionPlayer();
    if (!guidedSession.playing && !guidedSession.loading) await resumeGuided();
    return;
  }
  guidedRequest++;
  guidedAudio.pause();
  playing = false;
  syncAudio();
  renderMaster();
  guidedSession = {
    ...session,
    total: session.minutes * 60,
    remaining: session.minutes * 60,
    playing: false,
    loading: false,
    error: null,
    loop: guidedLooping,
  };
  guidedAudio.currentTime = 0;
  guidedAudio.loop = guidedLooping;
  scrubSeconds = null;
  $('session-title').textContent = session.title;
  $('session-art').src = playerArtwork(session);
  openSessionPlayer();
  await resumeGuided();
}

async function resumeGuided() {
  if (!guidedSession || guidedSession.playing || guidedSession.loading) return;
  const request = ++guidedRequest;
  playing = false;
  syncAudio();
  renderMaster();
  guidedSession.loading = true;
  guidedSession.error = null;
  updateSession();
  try {
    if (guidedAudio.error) {
      const elapsed = guidedSession.total - guidedSession.remaining;
      guidedAudio.addEventListener('loadedmetadata', () => {
        if (request !== guidedRequest || !guidedSession || !Number.isFinite(guidedAudio.duration)) return;
        guidedAudio.currentTime = guidedSession.loop ? elapsed % guidedAudio.duration
          : Math.min(elapsed, Math.max(0, guidedAudio.duration - .001));
      }, { once: true });
      guidedAudio.src = 'assets/sounds/calm_guided.mp3';
    }
    await guidedAudio.play();
    if (request !== guidedRequest || !guidedSession) return;
    guidedSession.loading = false;
    guidedSession.playing = true;
    guidedSession.deadline = Date.now() + guidedSession.remaining * 1000;
    updateSession();
    updateSleepState();
  } catch (error) {
    if (request !== guidedRequest || !guidedSession) return;
    guidedSession.loading = false;
    guidedSession.playing = false;
    guidedSession.error = 'Audio could not start. Check your connection and try again.';
    updateSession();
    updateSleepState();
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
  if (!guidedSession || guidedSession.loading || !Number.isFinite(guidedAudio.duration)) return;
  syncGuidedRemaining();
  const elapsed = Math.max(0, Math.min(guidedSession.total - 1, Math.round(seconds)));
  // Sessions are timed soundscapes: the sample position wraps while Loop is on.
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
  guidedAudio.pause();
  guidedSession = null;
  scrubSeconds = null;
  minimizeSessionPlayer();
  updateSleepState();
  // This demo deliberately does not invent a wellbeing record or listening streak.
  if (automatic && !silent) toast('Your quiet moment is complete.');
}

function updateSession() {
  if (!guidedSession) return;
  syncGuidedRemaining();
  const session = guidedSession;
  const elapsed = scrubSeconds ?? Math.max(0, session.total - session.remaining);
  const ready = Number.isFinite(guidedAudio.duration) && !session.loading && !session.error;
  $('session-description').textContent = session.loop ? 'Calming audio · A little space to breathe.' : 'Calming audio · Stops when this audio ends.';
  $('session-clock').textContent = clock(session.remaining);
  $('session-elapsed').textContent = clock(Math.floor(elapsed));
  $('session-duration').textContent = clock(session.total);
  $('session-progress').max = session.total;
  $('session-progress').value = Math.floor(elapsed);
  $('session-progress').style.setProperty('--progress', `${100 * elapsed / session.total}%`);
  $('session-progress').setAttribute('aria-valuetext', `${clock(elapsed)} of ${clock(session.total)}`);
  $('session-progress').disabled = !ready;
  for (const id of ['session-back', 'session-forward', 'session-restart']) $(id).disabled = !ready;
  $('session-loop').disabled = session.loading;
  $('session-loop').setAttribute('aria-pressed', String(session.loop));
  $('session-loop').querySelector('span').textContent = session.loop ? 'Loop On' : 'Loop Off';
  $('session-pause').disabled = session.loading;
  $('session-pause').setAttribute('aria-label', session.loading ? 'Loading calming audio'
    : session.playing ? 'Pause session' : session.error ? 'Retry audio' : 'Resume session');
  $('session-pause').innerHTML = session.loading ? '<span class="player-spinner" aria-hidden="true"></span>' : svg(session.playing ? 'pause' : 'play');
  $('session-status').textContent = session.loading ? 'PREPARING YOUR SOUNDSCAPE'
    : session.playing ? 'TIME TO UNWIND' : 'PAUSED · STAY A LITTLE LONGER';
  $('session-error').hidden = !session.error;
  $('session-error').textContent = session.error || '';
  $('breathing-art').classList.toggle('is-breathing', session.playing);
  $('session-live-dot').classList.toggle('is-playing', session.playing);
  updateMiniPlayer();
}

function updateMiniPlayer() {
  const active = playing ? Object.entries(levels).filter(([, value]) => value > 0).sort((a, b) => b[1] - a[1]) : [];
  const guided = !!guidedSession && !active.length;
  const visible = !playerDialog.open && (guided || (active.length > 0 && ['meditate', 'sleep'].includes(currentTab)));
  miniPlayer.hidden = !visible;
  document.body.classList.toggle('has-mini-player', visible);
  if (!visible) return;
  const main = active[0]?.[0];
  const title = guided ? guidedSession.title : selectedPreset || (active.length === 1 ? main : `${main} + ${active.length - 1} more`);
  const isPlaying = guided ? guidedSession.playing : playing;
  $('mini-title').textContent = title;
  $('mini-art').src = guided ? playerArtwork(guidedSession) : levels['Ocean Waves'] > 0 ? OCEAN_JOURNEY.artwork : artworkForTrack(main);
  $('mini-subtitle').textContent = guided
    ? guidedSession.loading ? 'Preparing calming audio…' : guidedSession.error ? 'Audio unavailable · tap to retry'
      : `${isPlaying ? 'A moment of calm' : 'Session paused'} · ${Math.ceil(guidedSession.remaining / 60)} min left`
    : sleepDeadline !== null ? `Auto-fade · ${Math.ceil(timerRemaining() / 60)} min left`
      : `${active.length} ${active.length === 1 ? 'sound' : 'sounds'} · Your quiet space`;
  $('mini-open').setAttribute('aria-label', guided ? `Open ${title} session player` : 'Open sound mixer');
  $('mini-pause').setAttribute('aria-label', isPlaying ? 'Pause audio' : 'Resume session');
  $('mini-pause').disabled = guided && guidedSession.loading;
  $('mini-pause').innerHTML = guided && guidedSession.loading ? '<span class="player-spinner" aria-hidden="true"></span>' : svg(isPlaying ? 'pause' : 'play');
}

$('session-minimize').onclick = minimizeSessionPlayer;
playerDialog.addEventListener('cancel', (event) => { event.preventDefault(); minimizeSessionPlayer(); });
playerDialog.addEventListener('close', () => {
  if (playerDialog.open) return; // A queued close must not affect a reopened player.
  document.body.classList.remove('player-open');
  document.documentElement.classList.remove('sanctuary-player-expanded');
  updateMiniPlayer();
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
$('mini-open').onclick = () => !playing && guidedSession ? openSessionPlayer() : selectRetreatTab('sounds');
$('mini-pause').onclick = () => {
  if (!playing && guidedSession) {
    if (guidedSession.playing) pauseGuided(); else resumeGuided();
  } else {
    playing = false;
    syncAudio();
    finishGuidedSession({ silent: true });
    render();
  }
};
$('mini-stop').onclick = () => {
  playing = false;
  syncAudio();
  finishGuidedSession({ silent: true });
  render();
};
guidedAudio.addEventListener('ended', () => { if (guidedSession && !guidedAudio.loop) finishGuidedSession({ automatic: true }); });
guidedAudio.addEventListener('loadedmetadata', updateSession);
guidedAudio.addEventListener('error', () => {
  if (!guidedSession) return;
  pauseGuided();
  guidedSession.error = 'Audio could not start. Check your connection and try again.';
  updateSession();
});
updateMiniPlayer();
