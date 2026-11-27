'use strict';
const SIMPLE_MEDITATION_FILTERS = ["All", "Calm", "Focus", "Rest", "Saved"];
const FEATURED_MEDITATION_IDS = ["gentle-relief", "quiet-mind", "body-rest"];
const initialWellbeingHash = location.hash.startsWith('#wellbeing') ? location.hash : null;
Object.assign(icons,{
  leaf:'<path d="M27 4C12 2 4 9 5 21c9 7 23 3 22-17ZM5 28 22 10M11 21l1-8m-1 8h8"/>',
  lotus:'<path d="M16 3c-8 7-8 15 0 22 8-7 8-15 0-22ZM9 13 3 10c-2 10 2 16 13 16 11 0 15-6 13-16l-6 3M16 26v4"/>',
  clock:'<circle cx="16" cy="16" r="12"/><path d="M16 8v9l6 3"/>',
  clockFill:'<circle cx="16" cy="16" r="13" fill="currentColor" stroke="none"/><path d="M16 8v9l6 3" stroke="#1b2940"/>',
  arrow:'<path d="M4 16h23m-8-8 8 8-8 8"/>',chevron:'<path d="m12 6 10 10-10 10"/>',
  sun:'<circle cx="16" cy="16" r="6"/><path d="M16 1v4m0 22v4M1 16h4m22 0h4M5 5l3 3m16 16 3 3M5 27l3-3M24 8l3-3"/>',
  sunrise:'<path d="M2 24h28M8 24a8 8 0 0 1 16 0M16 4v6M3 12l4 4m18 0 4-4M1 19h4m22 0h4"/>',
  moon:'<path d="M27 21C14 27 5 13 13 3-4 8 0 31 17 29a13 13 0 0 0 10-8Z"/>',
  moonFill:'<path d="M26 22C15 25 7 13 13 3-3 10 2 30 18 28c4 0 7-2 8-6Z" fill="currentColor" stroke="none"/>',
  outlineHeart:'<path d="M16 28 5 17C-3 7 9-2 16 7 23-2 35 7 27 17Z"/>',
  heartFill:'<path d="M16 28 5 17C-3 7 9-2 16 7 23-2 35 7 27 17Z" fill="currentColor" stroke="none"/>',
  waves:'<path d="M3 8c4-7 6 7 13 0s9 7 13 0M3 16c4-7 6 7 13 0s9 7 13 0M3 24c4-7 6 7 13 0s9 7 13 0"/>',
  cloudRain:'<path d="M7 21a6 6 0 1 1 2-12 8 8 0 0 1 15 0 6 6 0 0 1 0 12Z" fill="currentColor" stroke="none"/><path d="m9 25-2 4m10-4-2 4m10-4-2 4"/>',
  sleepRain:'<path d="M7 21C-1 20 0 9 8 9c2-9 15-9 17 1 8 0 8 11 0 11ZM9 25l-2 4m10-4-2 4m10-4-2 4"/>',
  wind:'<path d="M3 11h18c9 0 6-12 0-7M3 17h24M3 23h14c9 0 6 12 0 7"/>',
  bolt:'<path d="m19 1-14 17h10l-2 13 14-18H17Z" fill="currentColor" stroke="none"/>',
  natureLeaf:'<path d="M28 3C10 3 3 12 6 23c12 6 23-3 22-20Z" fill="currentColor" stroke="none"/><path d="M4 29 22 10"/>',
  natureTree:'<path d="M16 2 6 14h5L3 24h10v6h6v-6h10l-8-10h5Z"/>',
  note:'<path d="M13 24V5l15-3v19M13 11l15-3"/><ellipse cx="8" cy="25" rx="5" ry="4"/><ellipse cx="23" cy="22" rx="5" ry="4"/>',
  playCircle:'<circle cx="16" cy="16" r="13"/><path d="m13 9 9 7-9 7Z" fill="currentColor" stroke="none"/>',
  book:'<path d="M16 29V7C12 3 5 3 1 6v21c5-3 11-2 15 2 4-4 10-5 15-2V6c-4-3-11-3-15 1"/>',
  dots:'<circle cx="5" cy="16" r="2" fill="currentColor"/><circle cx="16" cy="16" r="2" fill="currentColor"/><circle cx="27" cy="16" r="2" fill="currentColor"/>'
});
const escapeHTML=value=>String(value).replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const pill=(label,{id='',icon='',trailing='',classes='',aria=''}={})=>`<button class="pill-hit ${classes}" ${id?`id="${id}"`:''} aria-label="${escapeHTML(aria||label)}"><span class="pill-body">${icon?svg(icon):''}<span>${escapeHTML(label)}</span>${trailing?svg(trailing):''}</span></button>`;
const medPage=document.createElement('main');medPage.id='meditate-page';medPage.className='retreat-page meditate-page';medPage.hidden=true;
medPage.innerHTML = `<div class="retreat-inner">
  <header><h1 class="page-heading">Meditate</h1>
    <p class="med-audio-note">Ambient practice · No spoken guidance.</p></header>
  <section class="daily-journey" aria-label="Today's timed practice">
    <div class="daily-topline"><p class="kicker">${svg('sunrise')}<span>TODAY’S QUIET MOMENT</span></p><p class="session-meta">${svg('clock')}<span>${DAILY_JOURNEY.minutes} min</span></p></div>
    <div class="daily-heading"><div class="daily-copy"><h2>${escapeHTML(DAILY_JOURNEY.title)}</h2><p class="session-ingredients" data-session-sources="${DAILY_JOURNEY.id}">${escapeHTML(sessionSourceLabel(DAILY_JOURNEY.title))}</p></div><div class="practice-orbit"><img class="arched-art" src="${DAILY_JOURNEY.artwork}" alt=""></div></div>
    <div class="daily-buttons">${pill('Begin Session',{id:'begin-daily',icon:'play',aria:'Begin Calm Mountain Horizon'})}<button class="practice-save" id="daily-practice-save" aria-pressed="false" aria-label="Save Calm Mountain Horizon">${svg('outlineHeart')}</button><button class="med-options" id="daily-practice-options" aria-label="Options for Calm Mountain Horizon">${svg('dots')}</button></div>
  </section>
  <div class="intent-heading"><h2>Find a quiet moment</h2><p class="practice-count" id="practice-count" role="status">14 practices</p></div>
  <div class="intent-tray" aria-label="Practice filters"></div>
  <section class="practice-list" id="practice-list" aria-label="Meditation practices"></section>
  <button class="browse-practices" id="browse-practices">Browse all 14 practices</button>
  <p class="preview-disclosure">Independent HTML design preview · Implemented separately in Flutter.<br>Approximately 30-second mixes of existing library recordings repeat for your chosen time. Names and artwork are themes, not narration, verified frequency tuning or medical claims.</p>
</div>`;
const sleepPage=document.createElement('main');sleepPage.id='sleep-page';sleepPage.className='retreat-page sleep-page';sleepPage.hidden=true;
sleepPage.innerHTML=`<div class="scenery" aria-hidden="true"></div><div class="retreat-inner"><header><h1 class="page-heading">Sleep</h1><p class="sleep-welcome">${svg('moon')}<span>Good evening. Let the day drift away.</span></p></header><section class="timer-bar night-surface night-glow" aria-label="Sleep auto-fade timer">${svg('clockFill')}<span class="timer-label" id="sleep-timer-label">Set Sleep Auto-Fade Timer</span><button id="sleep-timer-button">Set ${svg('chevron')}</button></section><section class="ocean-journey night-surface night-glow" aria-label="Tonight’s journey"><div class="journey-topline"><span class="journey-badge">${svg('moon')}Tonight’s Journey</span><button class="journey-circle" id="ocean-circle" aria-label="Start Ocean Sleep"><span>${svg('chevron')}</span></button></div><h3>Ocean Sleep</h3><p class="journey-subtitle">Deep Relaxation</p><div class="journey-meta">${svg('clock')}<span>45 min</span><span class="separator">|</span>${svg('waves')}<span>Ocean + Rain</span></div>${pill('Begin Sleep',{id:'begin-ocean',icon:'play',classes:'ocean-glow'})}</section><div class="sleep-section-title continue-title"><h3>Continue Listening</h3><button id="saved-soundscapes">See All ${svg('chevron')}</button></div><section class="continue-card night-surface" aria-label="Continue listening"><img class="continue-art" id="continue-art" src="assets/images/mixer/soft_rain.webp" alt=""><div class="continue-copy"><h3 id="continue-name">Soft Rain</h3><p id="continue-subtitle">Your soundscape, ready when you are</p><div class="progress-row"><span id="progress-label">Level</span><div class="progress-track" id="sleep-progress" role="progressbar" aria-label="Soft Rain volume" aria-valuemin="0" aria-valuemax="100" aria-valuenow="30"><div class="progress-fill" id="sleep-progress-fill"></div></div><span class="progress-value" id="sleep-progress-value">30%</span></div></div>${pill('Play',{id:'resume-sleep',icon:'play',classes:'quiet'})}</section><div class="sleep-section-title"><h3>Wind Down Playlist</h3><button id="all-soundscapes">See All ${svg('chevron')}</button></div><div class="winddown-tray" id="winddown-tray" aria-label="Wind down soundscapes"></div><div class="sleep-section-title quick-section-title"><h3>Sleep Sounds Mixer</h3><button id="customize-sleep-mix">Customize ${svg('chevron')}</button></div><section class="quick-mixer night-surface" id="quick-mixer" aria-label="Sleep sounds mixer"></section><h2 class="stories-heading">Nighttime Journeys</h2><div class="story-filters"><button data-stories="all" aria-pressed="true"><span>All</span></button><button data-stories="saved" aria-pressed="false"><span>My Journeys</span></button></div><section class="story-list" id="story-list" aria-label="Nighttime ambient journeys"></section><p class="audio-disclosure">Different ambient mixes made from existing library recordings, repeating about every 30 seconds. No spoken stories or individual downloads.</p><button class="twilight-link night-surface" id="twilight-controls">${svg('moon')}<span><strong>Twilight Soft UI Controls</strong><small>Haptic dials, mood orb &amp; living wallpaper</small></span>${svg('chevron')}</button><p class="preview-disclosure">Interactive browser design preview · The native app uses Flutter and its audio engine.</p></div>`;
const nav=document.querySelector('.bottom-nav');nav.before(medPage,sleepPage);
const dialogs=document.createElement('div');dialogs.innerHTML=`<dialog class="night-dialog" id="timer-dialog" aria-labelledby="timer-dialog-title"><form id="timer-form"><h3 id="timer-dialog-title">Sleep Auto-Fade</h3><p>Choose how long your soundscape stays with you.</p><div class="timer-choices">${[15,30,45,60].map(n=>`<button type="button" data-timer-minutes="${n}">${n} min</button>`).join('')}</div><label for="timer-minutes">Duration in minutes</label><input id="timer-minutes" type="number" min="1" max="1439" step="1" value="30" required><p class="small-note">Ambient sounds fade during the final 30 seconds.<br>All audio stops when the timer ends.</p><footer><button type="button" data-close="timer-dialog">Cancel</button><button class="primary" type="submit">Set timer</button></footer></form></dialog><dialog class="night-dialog" id="library-dialog" aria-labelledby="library-title"><h3 id="library-title"></h3><p id="library-description"></p><div class="library-options" id="library-options"></div><footer><button data-close="library-dialog">Done</button></footer></dialog><dialog id="practice-dialog" aria-labelledby="practice-dialog-title"><h3 id="practice-dialog-title"></h3><p id="practice-dialog-description"></p><div class="practice-action-list" id="practice-action-list"></div><footer><button data-close="practice-dialog">Cancel</button></footer></dialog>`;document.body.append(dialogs);
dialogs.querySelectorAll('[data-close]').forEach(b=>b.onclick=()=>$(b.dataset.close).close());
let showAllPractices=false;
let intent='All',storiesFilter='all',currentTab='home',retreatFavorites=new Set(),sleepDeadline=null,sleepTimerTotal=0,selectedTimerMinutes=30,guidedSession=null;
try{retreatFavorites=new Set(JSON.parse(localStorage.getItem('sanctuary.retreatFavorites.v1')||'[]'))}catch{}
function persistRetreat(){try{localStorage.setItem('sanctuary.retreatFavorites.v1',JSON.stringify([...retreatFavorites]))}catch{}}
function toggleRetreatFavorite(id){retreatFavorites.has(id)?retreatFavorites.delete(id):retreatFavorites.add(id);persistRetreat()}
function renderIntents() {
  const focusedIntent=document.activeElement?.dataset.intent;
  const symbols=['leaf','outlineHeart','lotus','moon','bookmark'];
  medPage.querySelector('.intent-tray').innerHTML=SIMPLE_MEDITATION_FILTERS.map((name,i)=>`<button class="intent-chip" data-intent="${name}" aria-pressed="${intent===name}"><span>${svg(symbols[i])}${name}</span></button>`).join('');
  medPage.querySelectorAll('[data-intent]').forEach(button=>button.onclick=()=>{intent=button.dataset.intent;renderIntents();renderPractices();});
  if (focusedIntent) medPage.querySelector(`[data-intent="${focusedIntent}"]`)?.focus({preventScroll:true});
}
function matchesPracticeFilter(session) {
  return intent === 'All' || (intent === 'Calm' && ['Comfort','Healing'].includes(session.intent))
    || (intent === 'Focus' && ['Focus','Morning'].includes(session.intent))
    || (intent === 'Rest' && session.intent === 'Sleep')
    || (intent === 'Saved' && retreatFavorites.has('meditation-'+session.id));
}
const intentColors = {Comfort:'#9affe6',Morning:'#f5c998',Sleep:'#b9b8f1',Focus:'#9ad1ee',Healing:'#e5bacf'};
function toggleSavedPractice(session) {
  toggleRetreatFavorite('meditation-'+session.id);
  renderPractices();
}
function renderPractices() {
  const focused=document.activeElement;
  const practiceId=focused?.closest('[data-practice]')?.dataset.practice;
  const focusSelector=practiceId ? (focused.matches('[data-save-practice]')
    ? `[data-save-practice="${practiceId}"]` : focused.matches('[data-practice-options]')
      ? `[data-practice-options="${practiceId}"]` : focused.id===`begin-${practiceId}` ? `#begin-${practiceId}` : null) : null;
  const featured = intent === 'All' && !showAllPractices;
  const practices = featured ? FEATURED_MEDITATION_IDS.map(id=>MEDITATIONS.find(session=>session.id===id)) : MEDITATIONS.filter(matchesPracticeFilter);
  $('practice-count').textContent = `${practices.length} ${featured ? 'featured' : practices.length === 1 ? 'practice' : 'practices'}`;
  $('browse-practices').textContent = intent === 'All' && showAllPractices ? 'Show featured practices' : `Browse all ${MEDITATIONS.length} practices`;
  $('practice-list').innerHTML = practices.map(session => {
    const saved = retreatFavorites.has('meditation-'+session.id);
    return `<article class="practice-card${saved?' saved':''}" data-practice="${session.id}" style="--accent:${intentColors[session.intent]}">
      <div class="practice-thumbnail"><div class="practice-orbit"><img class="arched-art" src="${session.artwork}" alt=""></div></div>
      <div class="practice-heading"><h3>${escapeHTML(session.title)}</h3></div>
      <p class="session-ingredients" data-session-sources="${session.id}">${escapeHTML(sessionSourceLabel(session.title))}</p>
      <div class="practice-actions"><p class="session-meta">${svg('clock')}<span>${session.minutes} min</span></p>
      <button class="practice-save" data-save-practice="${session.id}" aria-label="${saved?'Unsave':'Save'} ${escapeHTML(session.title)}" aria-pressed="${saved}">${svg(saved?'heartFill':'outlineHeart')}</button>
      <button class="med-options" data-practice-options="${session.id}" aria-label="Options for ${escapeHTML(session.title)}">${svg('dots')}</button>${pill('Begin',{id:'begin-'+session.id,icon:'play',classes:'practice-play',aria:'Begin '+session.title})}</div></article>`;
  }).join('');
  if (!practices.length) $('practice-list').innerHTML = '<p class="practice-empty">No saved practices in this collection yet. Tap a heart to keep one here.</p>';
  for (const session of practices) {
    const button = $('begin-'+session.id);button.onclick=()=>toggleMeditation(session);
    const card=button.closest('.practice-card');
    card.querySelector('[data-save-practice]').onclick=()=>toggleSavedPractice(session);
    card.querySelector('[data-practice-options]').onclick=()=>showPracticeActions(session);
    card.oncontextmenu=event=>{event.preventDefault();showPracticeActions(session);};
    let hold;
    card.addEventListener('pointerdown',event=>{if(!event.target.closest('button'))hold=setTimeout(()=>showPracticeActions(session),650);});
    ['pointerup','pointerleave','pointercancel','pointermove'].forEach(event=>card.addEventListener(event,()=>clearTimeout(hold)));
  }
  const dailySaved=retreatFavorites.has('meditation-'+DAILY_JOURNEY.id);
  $('daily-practice-save').setAttribute('aria-pressed',String(dailySaved));
  $('daily-practice-save').setAttribute('aria-label',`${dailySaved?'Unsave':'Save'} ${DAILY_JOURNEY.title}`);
  setIcon($('daily-practice-save'),dailySaved?'heartFill':'outlineHeart');
  updateMeditationCards();
  if (focusSelector) (medPage.querySelector(focusSelector)||medPage.querySelector('[data-intent][aria-pressed="true"]'))?.focus({preventScroll:true});
}
$('browse-practices').onclick=()=>{
  showAllPractices = intent !== 'All' || !showAllPractices;
  intent='All';renderIntents();renderPractices();
};
$('daily-practice-save').onclick=()=>toggleSavedPractice(DAILY_JOURNEY);

function toggleMeditation(session) {
  if (guidedSession?.title === session.title && guidedSession.playing) pauseGuided();
  else void startGuided(session);
}
function updateMeditationCards() {
  for (const session of [DAILY_JOURNEY, ...MEDITATIONS]) {
    const daily = session.id === DAILY_JOURNEY.id;
    const button = $(daily ? 'begin-daily' : 'begin-'+session.id);
    if (!button) continue;
    const selected = guidedSession?.title === session.title;
    const loading = selected && guidedSession.loading;
    const active = selected && guidedSession.playing;
    const action = loading ? 'Opening…' : active ? 'Pause' : 'Begin';
    button.disabled = !!loading;
    button.setAttribute('aria-label', action+' '+session.title);
    button.setAttribute('aria-busy', String(!!loading));
    button.title = action+' '+session.title;
    button.querySelector('.pill-body').innerHTML = (loading ? '<span class="practice-spinner" aria-hidden="true"></span>' : svg(active ? 'pause' : 'play'))+'<span class="practice-play-label">'+action+(daily&&!loading?' Session':'')+'</span>';
    const card = button.closest('.practice-card');
    if (card) {
      card.classList.toggle('is-playing', !!active);
      card.classList.toggle('is-loading', !!loading);
    }
  }
}
function showPracticeActions(s){$('practice-dialog-title').textContent=s.title;$('practice-dialog-description').textContent=s.minutes+' min · Ambient mix · No narration · '+sessionSourceLabel(s.title);const list=$('practice-action-list');list.replaceChildren();for(const [text,action]of [['Begin session',()=>startGuided(s)],[retreatFavorites.has('meditation-'+s.id)?'Remove saved practice':'Save practice',()=>{toggleRetreatFavorite('meditation-'+s.id);renderPractices()}],['Copy session details',async()=>{const details=s.title+' · '+s.minutes+' min\n'+s.description+'\n'+sessionSourceLabel(s.title)+'\nAmbient mix · No narration · Sanctuary — Meditate';try{await navigator.clipboard.writeText(details);toast('Session details copied')}catch{toast('Clipboard is unavailable in this preview browser.')}}]]){const b=document.createElement('button');b.textContent=text;b.onclick=()=>{$('practice-dialog').close();action()};list.append(b)}$('practice-dialog').showModal()}
$('begin-daily').onclick=()=>toggleMeditation(DAILY_JOURNEY);$('daily-practice-options').onclick=()=>showPracticeActions(DAILY_JOURNEY);medPage.querySelector('.daily-journey').oncontextmenu=e=>{e.preventDefault();showPracticeActions(DAILY_JOURNEY)};
function clock(seconds){seconds=Math.max(0,Math.ceil(seconds));return Math.floor(seconds/60).toString().padStart(2,'0')+':'+(seconds%60).toString().padStart(2,'0')}
const quickTracks=[['Ocean','waves','Ocean Waves'],['Rain','sleepRain','Soft Rain'],['Wind','wind','Soothing Breeze'],['Thunder','bolt','Thunderstorm'],['Nature','natureTree','Mountain Stream']];
$('winddown-tray').innerHTML=SLEEP_SCENES.map(s=>`<button class="soundscape-card night-surface" data-soundscape="${s.id}" aria-label="Play ${escapeHTML(s.title)}, ${s.minutes} minutes"><div class="soundscape-image"><img src="${s.artwork}" alt=""><span>${svg('play')}</span></div><span class="soundscape-caption"><span class="soundscape-name">${escapeHTML(s.title)}</span>${previewAvailabilityLabel(s.levels)?`<span class="preview-only-label">${previewAvailabilityLabel(s.levels)}</span>`:''}<span class="soundscape-bottom"><span class="soundscape-duration">${s.minutes} min</span>${svg('equalizer')}</span></span></button>`).join('');
function soundscapeIsSelected(s) {
  const selected = Object.entries(levels).filter(([, value]) => value > 0);
  return playing && selected.length === Object.keys(s.levels).length
    && selected.every(([name, value]) => Math.abs(value - (s.levels[name] || 0)) < .01);
}
function soundscapeIsPlaying(s) {
  return soundscapeIsSelected(s) && Object.keys(s.levels).every(name => ambientTrackStatus(name) === 'playing');
}
function soundscapeIsLoading(s) {
  return soundscapeIsSelected(s) && Object.keys(s.levels).some(name => ambientTrackStatus(name) === 'loading');
}
$('winddown-tray').querySelectorAll('[data-soundscape]').forEach(b=>b.onclick=()=>{const s=SLEEP_SCENES.find(s=>s.id===b.dataset.soundscape);if(soundscapeIsPlaying(s)||soundscapeIsLoading(s)){playing=false;syncAudio();render()}else playSoundscape(s)});
$('quick-mixer').dataset.controlDesign='large-outline';
$('quick-mixer').innerHTML=quickTracks.map(([label,key,name])=>`<button class="quick-track" data-quick="${label}" aria-label="${label} sleep sound" aria-pressed="false"><span class="quick-orb">${svg(key)}</span><span class="quick-label">${label}${!localAmbientPath(name)?'<span class="preview-only-label">App stream</span>':''}</span><span class="quick-level"><span></span></span></button>`).join('');
$('quick-mixer').querySelectorAll('[data-quick]').forEach(button=>button.onclick=()=>{
  const track=quickTracks.find(item=>item[0]===button.dataset.quick)[2];
  if(!canPreviewMix({[track]:.6}, `${button.dataset.quick} sound`)) return;
  const active=playing?Object.fromEntries(Object.entries(levels).filter(([,value])=>value>0)):{};
  if(active[track]>0) delete active[track]; else active[track]=.6;
  if(!canPreviewMix(active,'Your selected mix')) return;
  pauseGuided();
  applyMix(active,null);
});
function setSleepTimer(minutes){sleepTimerTotal=minutes*60;sleepDeadline=Date.now()+sleepTimerTotal*1000;selectedTimerMinutes=minutes;syncSanctuaryClock();updateSleepState()}
function cancelSleepTimer(){sleepDeadline=null;sleepTimerTotal=0;syncSanctuaryClock();syncAudio();updateSleepState()}
function timerRemaining(){return sleepDeadline===null?null:Math.max(0,(sleepDeadline-Date.now())/1000)}
function playSoundscape(s){if(!canPreviewMix(s.levels,s.title))return;pauseGuided();setSleepTimer(s.minutes);applyMix(s.levels,s.title)}
function oceanIsSelected(){const selected=Object.entries(levels).filter(([,v])=>v>0);return playing&&levels['Ocean Waves']>0&&levels['Soft Rain']>0&&selected.every(([name])=>Object.hasOwn(OCEAN_JOURNEY.levels,name))}
function oceanIsPlaying(){return oceanIsSelected()&&Object.keys(OCEAN_JOURNEY.levels).every(name=>ambientTrackStatus(name)==='playing')}
function oceanIsLoading(){return oceanIsSelected()&&Object.keys(OCEAN_JOURNEY.levels).some(name=>ambientTrackStatus(name)==='loading')}
$('begin-ocean').onclick=$('ocean-circle').onclick=()=>{if(oceanIsPlaying()||oceanIsLoading()){playing=false;syncAudio();render()}else playSoundscape(OCEAN_JOURNEY)};
$('sleep-timer-button').onclick=()=>{if(sleepDeadline!==null)cancelSleepTimer();else{$('timer-minutes').value=selectedTimerMinutes;$('timer-dialog').showModal()}};dialogs.querySelectorAll('[data-timer-minutes]').forEach(b=>b.onclick=()=>{$('timer-minutes').value=b.dataset.timerMinutes});$('timer-form').onsubmit=e=>{e.preventDefault();const minutes=Number($('timer-minutes').value);if(!Number.isInteger(minutes)||minutes<1||minutes>1439)return;setSleepTimer(minutes);$('timer-dialog').close()};
function artworkForTrack(name){const scene=SLEEP_SCENES.find(s=>s.title===name);if(scene)return scene.artwork;return {'Soft Rain':'assets/images/sleep/rain_window.webp','Rain on Window':'assets/images/sleep/rain_window.webp','Soothing Breeze':'assets/images/meditate/quiet_mind.webp','Mountain Stream':'assets/images/meditate/quiet_mind.webp'}[name]||'assets/images/sleep/continue_listening.webp'}
function sleepContinueSubtitle(state, remaining, unavailable) {
  const suffix = ambientStatusSuffix(state), hasTimer = remaining !== null;
  return state.active.length
    ? (hasTimer ? Math.ceil(remaining / 60) + ' min remaining' : 'Your nighttime soundscape') + (suffix ? ' · ' + suffix : '')
    : state.pending.length ? 'Preparing soundscape…'
      : unavailable.length ? `${unavailable.length} not in this preview · Review your selected mix`
        : state.failed.length ? 'Audio unavailable · Retry this recording'
        : hasTimer ? Math.ceil(remaining / 60) + ' min remaining · Playback paused' : 'Your soundscape, ready when you are';
}
function updateSleepClock() {
  const remaining = timerRemaining();
  if (remaining === null) return;
  // Only time-dependent, visible UI changes on a clock tick. Playback events
  // still refresh all controls; a countdown need not replace dozens of icons.
  if (currentTab === 'sleep') {
    const pct = Math.round(Math.max(0, Math.min(1, 1 - remaining / sleepTimerTotal)) * 100);
    $('sleep-timer-label').textContent = 'Auto-Fade Timer · ' + clock(remaining);
    $('continue-subtitle').textContent = sleepContinueSubtitle(ambientPlaybackState(), remaining, previewUnavailableNames());
    $('sleep-progress-fill').style.width = pct + '%';
    $('sleep-progress-value').textContent = pct + '%';
    $('sleep-progress').setAttribute('aria-valuenow', pct);
  }
  if (typeof updateAmbientTimer === 'function' && document.querySelector('#ambient-dialog[open]')) updateAmbientTimer();
}
function updateSleepState() {
  const state = ambientPlaybackState();
  const unavailable = previewUnavailableNames();
  const remaining = timerRemaining(), hasTimer = remaining !== null;
  const selected = [...state.selected].sort((a, b) => b[1] - a[1]);
  const mainTrack = selected[0]?.[0] || 'Soft Rain', level = selected[0]?.[1] ?? .3;
  const pct = Math.round((hasTimer ? Math.max(0, Math.min(1, 1 - remaining / sleepTimerTotal)) : level) * 100);
  $('sleep-timer-label').textContent = hasTimer ? 'Auto-Fade Timer · ' + clock(remaining) : 'Set Sleep Auto-Fade Timer';
  $('sleep-timer-button').innerHTML = hasTimer ? 'Cancel' : 'Set ' + svg('chevron');
  $('sleep-timer-button').style.color = hasTimer ? '#f5c96d' : '';
  $('continue-art').src = selectedPreset === OCEAN_JOURNEY.title ? OCEAN_JOURNEY.artwork : artworkForTrack(mainTrack);
  $('continue-name').textContent = selectedPreset || (selected.length <= 1 ? mainTrack : mainTrack + ' + ' + (selected.length - 1) + ' more');
  $('continue-subtitle').textContent = sleepContinueSubtitle(state, remaining, unavailable);
  $('progress-label').textContent = hasTimer ? 'Auto-fade' : 'Level';
  $('sleep-progress-fill').style.width = pct + '%';
  $('sleep-progress-value').textContent = pct + '%';
  $('sleep-progress').setAttribute('aria-valuenow', pct);
  $('sleep-progress').setAttribute('aria-label', hasTimer ? 'Auto-fade timer elapsed' : mainTrack + ' volume');
  const played = Object.keys(levels).some(name => players.has(name));
  const resumeLabel = state.canPause ? state.active.length ? 'Pause' : 'Cancel'
    : unavailable.length ? 'Review' : state.failed.length ? 'Retry' : played ? 'Resume' : 'Play';
  $('resume-sleep').querySelector('.pill-body').innerHTML = svg(state.canPause ? 'pause' : 'play') + '<span>' + resumeLabel + '</span>';
  $('resume-sleep').setAttribute('aria-label', resumeLabel === 'Cancel' ? 'Cancel sound loading' : resumeLabel === 'Review' ? 'Review unavailable sounds' : resumeLabel + ' soundscape');
  $('resume-sleep').setAttribute('aria-busy', String(state.pending.length > 0));
  const ocean = oceanIsPlaying(), oceanLoading = oceanIsLoading();
  const oceanLabel = oceanLoading ? 'Cancel Sleep' : ocean ? 'Pause Sleep' : 'Begin Sleep';
  $('begin-ocean').querySelector('.pill-body').innerHTML = svg(ocean || oceanLoading ? 'pause' : 'play') + '<span>' + oceanLabel + '</span>';
  $('begin-ocean').setAttribute('aria-label', oceanLabel);
  $('begin-ocean').setAttribute('aria-busy', String(oceanLoading));
  $('ocean-circle').setAttribute('aria-label', oceanLoading ? 'Cancel Ocean Sleep loading' : ocean ? 'Pause Ocean Sleep' : 'Start Ocean Sleep');
  $('ocean-circle').setAttribute('aria-busy', String(oceanLoading));
  $('ocean-circle').firstElementChild.innerHTML = svg(ocean || oceanLoading ? 'pause' : 'chevron');
  for (const [label, , name] of quickTracks) {
    const button = $('quick-mixer').querySelector('[data-quick="' + label + '"]');
    const status = ambientTrackStatus(name), volume = status === 'playing' ? (levels[name] || 0) : 0;
    button.setAttribute('aria-pressed', String(volume > 0));
    button.setAttribute('aria-busy', String(status === 'loading'));
    button.setAttribute('aria-label', label + ' sleep sound' + (status === 'loading' ? ', loading; tap to cancel this layer'
      : status === 'error' ? ', unavailable; open Sounds to choose a bundled recording' : ''));
    if (!localAmbientPath(name)) button.setAttribute('aria-label', `${label} sleep sound, ${name}; not available in this preview. View source details.`);
    button.title = !localAmbientPath(name) ? `${name} uses an app stream, not a bundled preview recording. View details without changing your mix.` : status === 'error' ? 'Unavailable in this browser preview. Open Sounds to retry or replace this selected layer.'
      : status === 'loading' ? 'Preparing audio…' : '';
    button.querySelector('.quick-level>span').style.width = Math.round(volume * 100) + '%';
  }
  for (const scene of SLEEP_SCENES) {
    const button = $('winddown-tray').querySelector('[data-soundscape="' + scene.id + '"]');
    const active = soundscapeIsPlaying(scene), loading = soundscapeIsLoading(scene);
    button.classList.toggle('is-playing', active);
    button.setAttribute('aria-busy', String(loading));
    const unavailable = previewUnavailableNames(scene.levels);
    button.setAttribute('aria-label', unavailable.length ? `View sources for ${scene.title}; not available in this preview` : (loading ? 'Cancel ' : active ? 'Pause ' : 'Play ') + scene.title + ', ' + scene.minutes + ' minutes');
    button.title = unavailable.length ? `Not in this preview: ${unavailable.join(', ')}` : '';
    button.querySelector('.soundscape-image>span').innerHTML = svg(active || loading ? 'pause' : 'play');
  }
  if (typeof updateMiniPlayer === 'function') updateMiniPlayer();
  if (typeof updateHomeState === 'function') updateHomeState();
}
$('resume-sleep').onclick=()=>{
  if(ambientPlaybackState().canPause){pauseGuided();playing=false;syncAudio();render()}
  else {
    const selected=Object.fromEntries(Object.entries(levels).filter(([,value])=>value>0));
    const mix=Object.keys(selected).length?selected:{'Soft Rain':.3};
    if(!canPreviewMix(mix,selectedPreset||'Your selected mix'))return;
    pauseGuided();applyMix(mix,selectedPreset);
  }
};
function showLibrary(savedOnly=false){$('library-title').textContent=savedOnly?'Your soundscapes':'Wind Down Playlist';$('library-description').textContent=savedOnly?(saved.length?'Your saved mixes, ready for another quiet evening.':'Save a mix in Sounds to keep your favorite nighttime rituals here.'):'Each soundscape starts an auto-fade timer for its listed duration.';const parent=$('library-options');parent.replaceChildren();if(savedOnly){for(const mix of saved){const b=document.createElement('button');const span=document.createElement('span');span.textContent=mix.name;b.append(span);b.onclick=()=>{if(applyMix(mix.levels,mix.name))$('library-dialog').close()};parent.append(b)}}else{for(const s of SLEEP_SCENES){const b=document.createElement('button');b.innerHTML=`<img src="${s.artwork}" alt=""><span>${escapeHTML(s.title)}<small>${s.minutes} min · Auto-fade included</small></span>${svg('chevron')}`;b.onclick=()=>{if(!canPreviewMix(s.levels,s.title))return;$('library-dialog').close();playSoundscape(s)};parent.append(b)}}const open=document.createElement('button');open.textContent='Open sound mixer';open.onclick=()=>{$('library-dialog').close();selectRetreatTab('sounds')};parent.append(open);$('library-dialog').showModal()}
$('saved-soundscapes').onclick=()=>showLibrary(true);$('all-soundscapes').onclick=()=>showLibrary();$('customize-sleep-mix').onclick=()=>selectRetreatTab('sounds');
function renderStories(){sleepPage.querySelectorAll('[data-stories]').forEach(b=>b.setAttribute('aria-pressed',b.dataset.stories===storiesFilter));const stories=SLEEP_STORIES.filter(s=>storiesFilter==='all'||retreatFavorites.has('story-'+s.id));if(!stories.length){$('story-list').innerHTML=`<div class="empty-stories night-surface">${svg('book')}<h3>Your quiet collection</h3><p>Tap the heart on a journey to keep it close.</p><button id="browse-all-stories">Browse all journeys</button></div>`;$('browse-all-stories').onclick=()=>{storiesFilter='all';renderStories()};return}$('story-list').innerHTML=stories.map(s=>`<article class="story-card night-surface" data-story="${s.id}"><img class="story-art" src="${s.artwork}" alt=""><div class="story-copy"><h3>${escapeHTML(s.title)}</h3><p>${s.minutes} min · Ambient mix</p><p class="session-ingredients" data-session-sources="${s.id}">${escapeHTML(sessionSourceLabel(s.title))}</p></div><div class="story-buttons"><button data-save-story="${s.id}" aria-pressed="${retreatFavorites.has('story-'+s.id)}" aria-label="${retreatFavorites.has('story-'+s.id)?'Unsave':'Save'} ${escapeHTML(s.title)}">${svg(retreatFavorites.has('story-'+s.id)?'heartFill':'outlineHeart')}</button><button class="story-play" data-play-story="${s.id}" aria-label="Play ${escapeHTML(s.title)}">${svg('playCircle')}</button></div></article>`).join('');$('story-list').querySelectorAll('[data-save-story]').forEach(b=>b.onclick=()=>{toggleRetreatFavorite('story-'+b.dataset.saveStory);renderStories()});$('story-list').querySelectorAll('[data-play-story]').forEach(b=>b.onclick=()=>toggleMeditation(SLEEP_STORIES.find(s=>s.id===b.dataset.playStory)));updateStoryPlayback()}sleepPage.querySelectorAll('[data-stories]').forEach(b=>b.onclick=()=>{storiesFilter=b.dataset.stories;renderStories()});
function updateStoryPlayback() {
  for (const story of SLEEP_STORIES) {
    const button = document.querySelector(`[data-play-story="${story.id}"]`);
    if (!button) continue;
    const selected = guidedSession?.title === story.title;
    const active = selected && guidedSession.playing;
    const loading = selected && guidedSession.loading;
    button.disabled = !!loading;
    button.setAttribute('aria-label', `${loading ? 'Opening' : active ? 'Pause' : 'Play'} ${story.title}`);
    button.setAttribute('aria-pressed', String(!!active));
    button.innerHTML = svg(active ? 'pause' : 'playCircle');
  }
}
$('twilight-controls').onclick=()=>{toast('The tactile Twilight controls are available in the Flutter app. This browser preview covers Sounds, Meditate and Sleep.')};
const originalRender=render;render=function(){originalRender();updateSleepState()};
function selectRetreatTab(tab){
  if(!['home','sounds','meditate','sleep'].includes(tab))tab='home';
  currentTab=tab;
  const home=document.getElementById('home-page');
  if(home)home.hidden=tab!=='home';
  document.querySelector('main.content').hidden=tab!=='sounds';
  document.querySelector('.app>.backdrop').hidden=tab!=='sounds';
  medPage.hidden=tab!=='meditate';
  sleepPage.hidden=tab!=='sleep';
  nav.querySelectorAll('[data-tab]').forEach(b=>{const active=b.dataset.tab===tab;b.classList.toggle('active',active);if(active)b.setAttribute('aria-current','page');else b.removeAttribute('aria-current')});
  document.querySelector('meta[name="theme-color"]').content='#02132c';
  history.replaceState(null,'',location.pathname+location.search+(tab==='home'?'':'#'+tab));
  scrollTo({top:0,behavior:'instant'});
  resize();
  renderMaster();
  updateSleepState();
}
nav.querySelectorAll('[data-tab]').forEach(b=>b.onclick=()=>selectRetreatTab(b.dataset.tab));
function applySleepFade(){const remaining=timerRemaining();if(remaining===null||remaining>30)return;const sum=Object.values(levels).reduce((a,b)=>a+b,0),gain=Math.min(1,1/(sum||1)),fade=remaining/30;for(const [name,audio]of players)audio.volume=Math.min(.85,(levels[name]||0)*gain*soundPreviewDuck)*fade}
const originalSyncAudio=syncAudio;syncAudio=function(...args){originalSyncAudio(...args);applySleepFade()};
// Demand-driven clocks: indefinite ambience is run by the audio engine, not a
// JavaScript heartbeat. Hidden pages wake for deadlines and the final fade only.
let sanctuaryClockTimer = null;
function syncSanctuaryClock() {
  clearTimeout(sanctuaryClockTimer);
  sanctuaryClockTimer = null;
  const now = Date.now(), deadlines = [];
  if (sleepDeadline !== null) deadlines.push(sleepDeadline - now);
  if (guidedSession?.playing) deadlines.push(guidedSession.deadline - now);
  if (!deadlines.length) return;
  let delay = Math.max(0, Math.min(...deadlines));
  if (!document.hidden) delay = Math.min(delay, 1000);
  else if (sleepDeadline !== null) {
    const untilFade = sleepDeadline - now - 30000;
    delay = Math.min(delay, untilFade > 0 ? untilFade : 1000);
  }
  sanctuaryClockTimer = setTimeout(tickSanctuaryClock, delay);
}
function tickSanctuaryClock() {
  clearTimeout(sanctuaryClockTimer);
  sanctuaryClockTimer = null;
  if (sleepDeadline !== null) {
    if (timerRemaining() <= 0) {
      sleepDeadline = null;
      sleepTimerTotal = 0;
      stopPreviewAudio();
      toast('Your sleep timer has ended. Rest easy.');
    } else {
      applySleepFade();
      if (!document.hidden) updateSleepClock();
    }
  }
  if (guidedSession?.playing) {
    syncGuidedRemaining();
    if (guidedSession.remaining <= 0) finishGuidedSession({ automatic: true });
    else if (!document.hidden && playerDialog.open) updateSessionClock();
  }
  if (!document.hidden && typeof updateMiniPlayerClock === 'function') updateMiniPlayerClock();
  syncSanctuaryClock();
}
document.addEventListener('visibilitychange', () => {
  if (document.hidden) syncSanctuaryClock();
  else tickSanctuaryClock(); // Reconcile an overdue, browser-throttled deadline.
});
renderIntents();renderPractices();renderStories();selectRetreatTab(['home','sounds','meditate','sleep'].includes(location.hash.slice(1))?location.hash.slice(1):'home');
addEventListener('hashchange',()=>selectRetreatTab(location.hash.slice(1)));
