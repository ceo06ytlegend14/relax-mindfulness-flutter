'use strict';
// Independent, explicitly labelled HTML representation of the Flutter tools.
// Browser breathing history is separate from the native app. This file never
// exports/restores Flutter data, claims cloud sync, or fabricates sample sessions.
const wellbeingPage = document.createElement('main');
wellbeingPage.id = 'wellbeing-page';
wellbeingPage.className = 'wellbeing-page';
wellbeingPage.hidden = true;
wellbeingPage.innerHTML = `<nav class="wellbeing-top" aria-label="Wellbeing navigation"><button id="wellbeing-back">${svg('chevron')} Back</button><strong id="wellbeing-route-title">Your wellbeing</strong><span></span></nav><div class="wellbeing-inner" id="wellbeing-body"></div>`;
nav.before(wellbeingPage);
let wellbeingRoute = null;
let previewBreaths = [];
try {
  const saved = JSON.parse(localStorage.getItem('sanctuary.preview.breaths.v1') || '[]');
  if (Array.isArray(saved)) previewBreaths = saved.filter(s => s && typeof s.title === 'string' && s.title.length < 100 && Number.isFinite(s.timestamp) && [1,3,5,10,15].includes(s.minutes)).slice(0,100);
} catch (_) {}
const breathPatterns = [
  {id:'box4444',name:'Box 4-4-4-4',steps:[4,4,4,4]},
  {id:'relax478',name:'4-7-8',steps:[4,7,8,0]},
  {id:'resonance55',name:'Even 5-5',steps:[5,0,5,0]},
  {id:'power626',name:'Steady 6-2-6',steps:[6,2,6,2]},
];
let breathing = {pattern:0,minutes:3,remaining:180,cycleTick:0,running:false,completed:false,startedAt:0,ticks:0};
const breathingHistoryNotice = 'Independent HTML design preview · Activity here belongs only to this browser, not your Flutter app.';
const wellbeingText = text => `<p class="wellbeing-copy">${text}</p>`;
const wellbeingStat = (value,label) => `<div class="wellbeing-stat"><strong>${value}</strong><span>${label}</span></div>`;
function browserWeek() {
  const now = new Date();
  const monday = new Date(now.getFullYear(),now.getMonth(),now.getDate()-((now.getDay()+6)%7));
  return ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'].map((name,i) => {
    const date = new Date(monday.getFullYear(),monday.getMonth(),monday.getDate()+i);
    return {name,minutes:previewBreaths.filter(s => new Date(s.timestamp).toDateString()===date.toDateString()).reduce((n,s)=>n+s.minutes,0)};
  });
}
function wellbeingDestination(route,icon,title,description,accent='#43e9cd') {
  return `<button class="wellbeing-destination wellbeing-surface" data-wellbeing-route="${route}" style="--accent:${accent}"><span class="wellbeing-tile-icon">${svg(icon)}</span><span><strong>${title}</strong><small>${description}</small></span>${svg('chevron')}</button>`;
}
function renderWellbeingHub() {
  const week = browserWeek(), total = week.reduce((n,d)=>n+d.minutes,0), days = week.filter(d=>d.minutes>0).length;
  return `<p class="wellbeing-eyebrow">A LITTLE CARE, EVERY DAY</p><h1>Small steps.<br>More space for you.</h1>${wellbeingText('A place to find your breath, notice your progress, and keep your quiet moments close.')}
    <section class="wellbeing-surface wellbeing-week" aria-label="Your recorded week"><p class="wellbeing-eyebrow">YOUR WEEK, AT YOUR PACE</p><div class="wellbeing-days">${week.map(d=>`<div aria-label="${d.name}, ${d.minutes} minutes recorded"><span>${d.name.slice(0,1)}</span><i class="${d.minutes?'recorded':''}">${d.minutes?svg('check'):'–'}</i></div>`).join('')}</div><div class="wellbeing-stats">${wellbeingStat(total,'minutes this week')}${wellbeingStat(days+' / 7','days with a recorded practice')}</div><p class="wellbeing-footnote">${total?'Each completed practice adds to your week. There is no perfect score.':'A fresh page. Your first completed practice will appear here.'}</p></section>
    <button class="wellbeing-surface wellbeing-breath-card" data-wellbeing-route="breathing"><span class="wellbeing-eyebrow">${svg('wind')} THE BREATHING ROOM</span><strong>Find your rhythm.</strong><span class="wellbeing-copy">A simple visual timer. Choose a comfortable pace and take it one breath at a time.</span><span class="wellbeing-breath-link">Open breathing ${svg('arrow')}</span></button>
    <p class="wellbeing-eyebrow wellbeing-section">YOUR PERSONAL SPACE</p>
    ${wellbeingDestination('progress','equalizer','Your progress','Real activity, without the pressure')}
    ${wellbeingDestination('reflection','book','Reflection studio','Make a little room for your thoughts','#abb4e3')}
    ${wellbeingDestination('backup','restart','Backup &amp; restore','Keep a private copy of your saved data','#f5c96d')}
    <p class="wellbeing-disclosure">Yours, on this device. Nothing here is automatically uploaded or synced.</p>`;
}
function phaseInfo() {
  const pattern = breathPatterns[breathing.pattern];
  let elapsed = 0;
  for (let i=0;i<4;i++) {
    if (pattern.steps[i] && breathing.cycleTick < elapsed+pattern.steps[i]) return {index:i,left:pattern.steps[i]-(breathing.cycleTick-elapsed),label:['Breathe in','Hold gently','Breathe out','Rest'][i]};
    elapsed+=pattern.steps[i];
  }
  return {index:0,left:pattern.steps[0],label:'Breathe in'};
}
function renderBreathing() {
  const pattern = breathPatterns[breathing.pattern];
  return `<p class="wellbeing-eyebrow">ONE BREATH AT A TIME</p><h1>Find your<br>comfortable rhythm.</h1>${wellbeingText('Follow the circle, or simply breathe naturally. There is no need to keep up.')}
    <section class="wellbeing-surface breathing-timer"><div class="breathing-timer-heading"><p class="wellbeing-eyebrow">YOUR QUIET TIMER</p><strong id="breathing-time"></strong></div><div class="wellbeing-orbit"><div class="wellbeing-orb" id="wellbeing-orb"></div><div class="breathing-instructions"><strong id="breathing-phase-seconds"></strong><span id="breathing-phase" role="status"></span></div></div><p class="wellbeing-copy breathing-pattern-note">${['Inhale '+pattern.steps[0],pattern.steps[1]?'hold '+pattern.steps[1]:'', 'exhale '+pattern.steps[2],pattern.steps[3]?'rest '+pattern.steps[3]:''].filter(Boolean).join(' · ')}</p><button class="wellbeing-primary" id="breathing-toggle"></button><button class="wellbeing-text-button" id="breathing-reset">Reset timer</button></section>
    <p class="wellbeing-eyebrow wellbeing-section">CHOOSE YOUR PACE</p><div class="wellbeing-choices">${breathPatterns.map((p,i)=>`<button data-breathing-pattern="${i}" aria-pressed="${breathing.pattern===i}">${p.name}</button>`).join('')}</div>
    <p class="wellbeing-eyebrow wellbeing-section">MAKE A LITTLE TIME</p><div class="wellbeing-choices">${[1,3,5,10,15].map(m=>`<button data-breathing-duration="${m}" aria-pressed="${breathing.minutes===m}">${m} min</button>`).join('')}</div>
    <p class="wellbeing-footnote">Changing the pace or duration resets the timer. Leaving the breathing page or hiding the browser pauses the practice; it will not silently count as completed.</p><p class="wellbeing-footnote">Keep every breath comfortable. Skip holds, return to normal breathing, or stop if you feel dizzy or uncomfortable. This is a relaxation tool, not medical advice.</p>`;
}
function updateBreathing() {
  if (wellbeingRoute!=='breathing') return;
  const phase = phaseInfo();
  $('breathing-time').textContent = clock(breathing.remaining);
  $('breathing-phase-seconds').textContent = breathing.completed?'✓':phase.left;
  $('breathing-phase').textContent = breathing.completed?'Well done':phase.label;
  $('breathing-toggle').textContent = breathing.running?'Pause practice':breathing.completed?'Start again':breathing.remaining<breathing.minutes*60?'Resume practice':'Begin practice';
  $('wellbeing-orb').style.transform = `scale(${[0,1].includes(phase.index)?1:.7})`;
}
function advanceBreathing() {
  if (!breathing.running) return;
  const ticks = Math.floor((Date.now()-breathing.startedAt)/1000);
  const delta = Math.min(breathing.remaining,Math.max(0,ticks-breathing.ticks));
  breathing.ticks = ticks;
  breathing.remaining -= delta;
  const cycle = breathPatterns[breathing.pattern].steps.reduce((n,d)=>n+d,0);
  breathing.cycleTick = (breathing.cycleTick+delta)%cycle;
  if (!breathing.remaining) {
    breathing.running=false;
    breathing.completed=true;
    previewBreaths.unshift({title:breathPatterns[breathing.pattern].name+' Session',minutes:breathing.minutes,timestamp:Date.now()});
    previewBreaths=previewBreaths.slice(0,100);
    try { localStorage.setItem('sanctuary.preview.breaths.v1',JSON.stringify(previewBreaths)); } catch (_) { toast('Practice completed. This browser could not save the history.'); }
  }
  updateBreathing();
}
function pauseBreathing() {
  if (breathing.running) advanceBreathing();
  breathing.running=false;
  updateBreathing();
}
function resetBreathing() {
  breathing={...breathing,remaining:breathing.minutes*60,cycleTick:0,running:false,completed:false,ticks:0};
  updateBreathing();
}
function renderPreviewProgress() {
  const week = browserWeek(), total=week.reduce((n,d)=>n+d.minutes,0), max=Math.max(1,...week.map(d=>d.minutes));
  return `<p class="wellbeing-eyebrow">SMALL MOMENTS ADD UP</p><h1>Your own pace.<br>Your own progress.</h1>${wellbeingText('Only completed breathing practices from this browser preview appear here. This is not your Flutter app’s history.')}
    <section class="wellbeing-surface"><p class="wellbeing-eyebrow">THIS WEEK · MONDAY TO SUNDAY</p><h2 class="progress-total">${total} min</h2><div class="wellbeing-chart">${week.map(d=>`<div aria-label="${d.name}, ${d.minutes} minutes"><span>${d.minutes}</span><div class="chart-track"><i style="height:${d.minutes/max*92}px"></i></div><span>${d.name.slice(0,1)}</span></div>`).join('')}</div><p class="wellbeing-footnote">${total?'A little space you made for yourself this week.':'Nothing recorded this week yet. Start whenever you are ready.'}</p></section>
    <section class="wellbeing-surface wellbeing-stats">${wellbeingStat(previewBreaths.reduce((n,s)=>n+s.minutes,0),'minutes in saved preview history')}${wellbeingStat(previewBreaths.length,'recorded preview sessions')}</section>
    <h2 class="wellbeing-section-heading">Your recent moments</h2>${previewBreaths.length?previewBreaths.map(s=>`<article class="wellbeing-surface wellbeing-session">${svg('wind')}<div><h3>${escapeHTML(s.title)}</h3><p>Breathing · ${s.minutes} min</p><small>${escapeHTML(new Date(s.timestamp).toLocaleString('en-GB',{day:'numeric',month:'short',hour:'2-digit',minute:'2-digit'}))}</small></div></article>`).join(''):`<section class="wellbeing-surface"><h3>A fresh beginning</h3>${wellbeingText('Complete a breathing practice to begin your preview history. No sample sessions, no made-up streaks.')}<button class="wellbeing-primary" data-wellbeing-route="breathing">Try a breathing practice</button></section>`}`;
}
function renderBackupLayout() {
  return `<p class="wellbeing-eyebrow">YOURS TO KEEP</p><h1>Keep a private copy.</h1>${wellbeingText('In the Flutter app, manual backup includes saved mixes, favorites, streaks, reminder preferences and up to the latest 500 sessions. It can contain personal titles and mood ratings.')}
    <section class="wellbeing-surface"><p class="wellbeing-eyebrow">01 / MAKE A BACKUP</p><h2 class="wellbeing-section-heading">Keep it somewhere private.</h2>${wellbeingText('Copy your backup, then save it somewhere you trust. Other apps may be able to read your clipboard.')}<button class="wellbeing-primary" disabled>Copy backup in the Flutter app</button></section>
    <section class="wellbeing-surface"><p class="wellbeing-eyebrow">02 / BRING YOUR DATA BACK</p><h2 class="wellbeing-section-heading">Review before replacing.</h2><ol class="wellbeing-copy"><li>Paste your backup JSON.</li><li>Review the validated categories.</li><li>Confirm replacement in a separate dialog.</li></ol><p class="wellbeing-footnote">Nothing is uploaded or played. Purchases and notification permissions do not transfer.</p></section>
    <p class="wellbeing-preview-boundary" role="note">Layout preview only: actual backup and restore run in the Flutter application. This independent browser preview cannot access or replace your Flutter data. No action here claims a backup was saved.</p>`;
}
function renderReflection() {
  return `<p class="wellbeing-eyebrow">A MOMENT TO CHECK IN</p><h1>Make room for a quiet thought.</h1>${wellbeingText('An on-device writing template, not AI or music generation. This preview does not upload your prompt or save this draft automatically.')}<label class="wellbeing-input-label" for="wellbeing-reflection-input">What would you like to reflect on?</label><textarea id="wellbeing-reflection-input" maxlength="400" rows="4" placeholder="A feeling, an intention, or a small moment…" autocomplete="off" spellcheck="false"></textarea><button class="wellbeing-primary" id="wellbeing-create-reflection" disabled>Create reflection from template</button><p class="wellbeing-reflection-output" id="wellbeing-reflection-output" hidden></p><button class="wellbeing-text-button" id="wellbeing-copy-reflection" hidden>Copy text</button><p id="wellbeing-reflection-notice" role="status"></p><p class="wellbeing-footnote">Leaving this page discards the draft. Copying is optional; other apps may be able to read your clipboard. This general wellbeing exercise is not medical care.</p>`;
}
function wireWellbeing() {
  wellbeingPage.querySelectorAll('[data-wellbeing-route]').forEach(button=>button.onclick=()=>openWellbeing(button.dataset.wellbeingRoute));
  if (wellbeingRoute==='breathing') {
    $('breathing-toggle').onclick = () => {
      if (breathing.running) pauseBreathing();
      else { if(breathing.completed)resetBreathing();breathing.running=true;breathing.startedAt=Date.now();breathing.ticks=0;updateBreathing(); }
    };
    $('breathing-reset').onclick = resetBreathing;
    wellbeingPage.querySelectorAll('[data-breathing-pattern]').forEach(button=>button.onclick=()=>{breathing.pattern=Number(button.dataset.breathingPattern);resetBreathing();renderWellbeingRoute();});
    wellbeingPage.querySelectorAll('[data-breathing-duration]').forEach(button=>button.onclick=()=>{breathing.minutes=Number(button.dataset.breathingDuration);resetBreathing();renderWellbeingRoute();});
    updateBreathing();
  }
  if (wellbeingRoute==='reflection') {
    const input=$('wellbeing-reflection-input'), output=$('wellbeing-reflection-output'), copy=$('wellbeing-copy-reflection'), notice=$('wellbeing-reflection-notice');
    input.oninput=()=>{$('wellbeing-create-reflection').disabled=!input.value.trim();output.hidden=true;copy.hidden=true;notice.textContent='';};
    $('wellbeing-create-reflection').onclick=()=>{const subject=input.value.trim();if(!subject)return;output.textContent='A quiet reflection: '+subject+'\n\nSettle into a position that supports you. Let your breathing find its own easy pace. Notice what is here without needing to solve it all at once.\n\nBring this intention to mind: “'+subject+'”. When you are ready, notice something around you and choose one small, kind next step.';output.hidden=false;copy.hidden=false;input.blur();};
    copy.onclick=async()=>{try{await navigator.clipboard.writeText(output.textContent);notice.textContent='Text copied. Save it somewhere private if you want to keep it.';}catch(_){notice.textContent='Clipboard access failed. Nothing was saved.';}};
  }
}
function renderWellbeingRoute() {
  const names={hub:'Your wellbeing',breathing:'Breathing room',progress:'Your progress',reflection:'Reflection studio',backup:'Backup & restore'};
  $('wellbeing-route-title').textContent=names[wellbeingRoute];
  const content={hub:renderWellbeingHub,breathing:renderBreathing,progress:renderPreviewProgress,reflection:renderReflection,backup:renderBackupLayout}[wellbeingRoute]();
  $('wellbeing-body').innerHTML=content+`<p class="wellbeing-disclosure wellbeing-preview-label">${breathingHistoryNotice}</p>`;
  wireWellbeing();
}
const selectMainRetreatTab=selectRetreatTab;
function showWellbeing(section) {
  if(!['hub','breathing','progress','reflection','backup'].includes(section))section='hub';
  if(wellbeingRoute==='breathing'&&section!=='breathing')pauseBreathing();
  selectMainRetreatTab('home');
  wellbeingRoute=section;
  document.documentElement.classList.add('sanctuary-wellbeing-open');
  homePage.hidden=true;
  wellbeingPage.hidden=false;
  renderWellbeingRoute();
  history.replaceState(null,'',location.pathname+location.search+'#wellbeing/'+section);
}
function openWellbeing(section='hub') {
  if(location.hash!=='#wellbeing/'+section)history.pushState(null,'',location.pathname+location.search+'#wellbeing/'+section);
  showWellbeing(section);
}
selectRetreatTab=function(tab) {
  if(tab.startsWith('wellbeing/')) {showWellbeing(tab.split('/')[1]);return;}
  if(tab==='wellbeing') {showWellbeing('hub');return;}
  pauseBreathing();wellbeingRoute=null;wellbeingPage.hidden=true;document.documentElement.classList.remove('sanctuary-wellbeing-open');selectMainRetreatTab(tab);
};
$('home-wellbeing').onclick=()=>openWellbeing();
$('wellbeing-back').onclick=()=>wellbeingRoute==='hub'?selectRetreatTab('home'):openWellbeing('hub');
document.addEventListener('visibilitychange',()=>{if(document.hidden)pauseBreathing();});
addEventListener('pagehide',pauseBreathing);
setInterval(()=>{if(breathing.running){if(document.hidden||wellbeingRoute!=='breathing')pauseBreathing();else advanceBreathing();}},250);
if(typeof initialWellbeingHash==='string'&&initialWellbeingHash)showWellbeing(initialWellbeingHash.slice(1).split('/')[1]||'hub');
