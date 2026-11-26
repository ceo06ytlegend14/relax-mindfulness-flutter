'use strict';
// Independent browser representation of HomeScreen, sharing the preview's real
// selection, playback and session state. This is not a compiled Flutter page.
const homePage = document.createElement('main');
homePage.id = 'home-page';
homePage.className = 'home-page';
homePage.hidden = true;
homePage.innerHTML = `<div class="home-inner">
  <header><h1>Home</h1><p class="home-greeting" id="home-greeting"></p><h2 class="home-headline">A little calm,<br>just for you.</h2><p class="home-intro">Your daily space to breathe, listen, and unwind.</p></header>
  <section class="home-daily" aria-label="Today’s ambient practice"><img src="assets/images/meditate/forest_sunrise.webp" alt=""><div class="home-daily-copy"><p class="home-kicker">TODAY’S AMBIENT PRACTICE</p><h3>${DAILY_JOURNEY.title}</h3><div class="home-daily-meta">${svg('clock')}<span>${DAILY_JOURNEY.minutes} min · Ambient soundscape</span></div><p class="home-session-sources">${escapeHTML(sessionSourceLabel(DAILY_JOURNEY.title))}<br>Ambient mix · No narration</p><button class="home-begin" id="home-daily"><span>${svg('play')}<span>Begin session</span></span></button></div></section>
  <h2 class="section-heading">MAKE IT YOUR MOMENT</h2>
  <section class="home-actions" aria-label="Quick actions">${[['sounds','equalizer','Sounds','Build a mix'],['meditate','meditate','Meditate','Find your focus'],['sleep','bed','Sleep','Ease into rest']].map(([tab,icon,label,detail])=>`<button class="home-action surface" data-home-tab="${tab}">${svg(icon)}<span class="home-action-label">${label}</span><span class="home-action-detail">${detail}</span></button>`).join('')}</section>
  <h2 class="section-heading">YOUR SOUNDSCAPE</h2>
  <section class="home-soundscape surface" aria-label="Your selected soundscape"><div class="home-soundscape-row"><img class="home-mix-art" id="home-mix-art" src="assets/images/mixer/soft_rain.webp" alt=""><div class="home-mix-copy"><h3 id="home-mix-name">Soft Rain</h3><p id="home-mix-status">Ready when you are · Not playing</p></div><button class="home-mix-toggle" id="home-mix-toggle" aria-label="Play soundscape">${svg('play')}</button></div><button class="home-open-mixer" id="home-edit-mix">Open sound mixer ${svg('arrow')}</button></section>
  <button class="home-wellbeing surface" id="home-wellbeing">${svg('leaf')}<span><strong>Your wellbeing</strong><small>Breathing, progress &amp; backup</small></span>${svg('arrow')}</button>
  <p class="home-note">No rush. Your quiet moment is here.</p><p class="home-preview-note">Interactive design preview · The application is implemented separately in Flutter.</p>
</div>`;
nav.before(homePage);

const hour = new Date().getHours();
$('home-greeting').textContent = hour < 12 ? 'Good morning.' : hour < 17 ? 'Good afternoon.' : 'Good evening.';

function updateHomeState() {
  const selected = Object.entries(levels).filter(([, value]) => value > 0).sort((a, b) => b[1] - a[1]);
  const first = selected[0]?.[0];
  const title = selectedPreset || (!first ? 'A fresh soundscape' : selected.length === 1 ? first : `${first} + ${selected.length - 1} more`);
  $('home-mix-name').textContent = title;
  const state = ambientPlaybackState();
  const suffix = ambientStatusSuffix(state);
  const unavailable = previewUnavailableNames();
  $('home-mix-status').textContent = state.active.length
    ? `Playing · ${state.active.length} ${state.active.length === 1 ? 'layer' : 'layers'}${suffix ? ' · ' + suffix : ''}`
    : state.pending.length ? 'Preparing soundscape…'
      : unavailable.length ? `Not in this preview: ${unavailable.join(', ')} · Review mix`
        : state.failed.length ? 'Audio unavailable · Retry this recording' : 'Ready when you are · Not playing';
  const artwork = all.find((track) => track.name === first)?.artwork;
  $('home-mix-art').src = artwork || 'assets/images/sleep/continue_listening.webp';
  $('home-mix-toggle').innerHTML = svg(state.canPause ? 'pause' : 'play');
  $('home-mix-toggle').setAttribute('aria-label', state.canPause
    ? state.active.length ? 'Pause soundscape' : 'Cancel sound loading'
    : unavailable.length ? 'Review unavailable sounds' : state.failed.length ? 'Retry soundscape' : 'Play soundscape');
  $('home-mix-toggle').setAttribute('aria-busy', String(state.pending.length > 0));
  const daily = guidedSession?.playing && guidedSession.title === DAILY_JOURNEY.title;
  $('home-daily').innerHTML = `<span>${svg(daily ? 'pause' : 'play')}<span>${daily ? 'Pause session' : guidedSession?.title === DAILY_JOURNEY.title ? 'Resume session' : 'Begin session'}</span></span>`;
}

homePage.querySelectorAll('[data-home-tab]').forEach((button) => {
  button.onclick = () => selectRetreatTab(button.dataset.homeTab);
});
$('home-edit-mix').onclick = () => selectRetreatTab('sounds');
$('home-daily').onclick = () => {
  if (guidedSession?.playing && guidedSession.title === DAILY_JOURNEY.title) {
    pauseGuided();
  } else {
    startGuided(DAILY_JOURNEY);
  }
  updateHomeState();
};
$('home-mix-toggle').onclick = () => {
  if (ambientPlaybackState().canPause) {
    pauseGuided();
    playing = false;
    syncAudio();
    render();
  } else {
    const selected = Object.fromEntries(Object.entries(levels).filter(([, value]) => value > 0));
    const mix = Object.keys(selected).length ? selected : { 'Soft Rain': .3 };
    if (!canPreviewMix(mix, selectedPreset || 'Your selected mix')) return;
    pauseGuided();
    applyMix(mix, selectedPreset);
  }
  updateHomeState();
};

// The separately labelled wellbeing preview is wired by wellbeing.js. The
// Flutter app opens the real pushed WellbeingScreen and its local data tools.

selectRetreatTab(currentTab);
updateHomeState();
