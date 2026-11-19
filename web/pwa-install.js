/* Framework-independent installation UI shared by Flutter Web and the demo. */
(() => {
  'use strict';
  if (window.SanctuaryInstall) return;

  const base = new URL('./', document.baseURI);
  const appName = document.querySelector('meta[name="application-name"]')?.content || 'Sanctuary';
  const standalone = window.matchMedia('(display-mode: standalone)');
  const fullscreen = window.matchMedia('(display-mode: fullscreen)');
  const ios = /iPad|iPhone|iPod/.test(navigator.userAgent) ||
    (navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1);
  const safari = /Safari/.test(navigator.userAgent) &&
    !/Chrome|Chromium|CriOS|Edg|OPR|FxiOS/.test(navigator.userAgent);
  const embedded = window.self !== window.top;
  let installedEvent = false;
  let deferredPrompt = null;
  let promptInFlight = false;
  let ui = null;
  let lastFocus = null;
  let feedback = '';

  const isInstalled = () => installedEvent || navigator.standalone === true ||
    standalone.matches || fullscreen.matches;
  const state = () => ({
    installed: isInstalled(),
    canPrompt: !!deferredPrompt && !isInstalled() && !embedded && window.isSecureContext,
    prompting: promptInFlight,
    embedded,
    secureContext: window.isSecureContext,
  });

  function publish() {
    const current = state();
    // Keep the former Flutter/JS integration points compatible and truthful.
    window.isPwaInstallable = current.canPrompt;
    render();
    window.dispatchEvent(new CustomEvent('sanctuary-install-state', { detail: current }));
  }

  function instructions() {
    if (!window.isSecureContext) return [
      'Open this app over HTTPS. Home-screen installation is not available on an insecure HTTP address.',
      'For local development, use localhost. Other devices need an HTTPS deployment.',
    ];
    if (embedded) return [
      'Open this preview in its own browser tab using the button below.',
      'In that tab, choose Install app. Installation is not available inside this embedded preview.',
    ];
    if (ios) return [
      'Open this page in Safari on your iPhone or iPad.',
      'Tap Share, then Add to Home Screen. You may need to scroll the share menu.',
      'If offered, keep Open as Web App enabled, then tap Add.',
    ];
    if (safari && /Mac/.test(navigator.platform)) return [
      'In Safari on macOS Sonoma or later, choose File → Add to Dock.',
      'Confirm the name, then choose Add. Open the app from your Dock.',
    ];
    if (deferredPrompt) return [
      'Choose Install below to open your browser’s installation dialog.',
      'Confirm in the browser dialog. The app will open in its own window.',
    ];
    return [
      'Open your browser menu (three dots), or look for an install icon in the address bar.',
      'Choose Install app or Add to Home Screen, then confirm.',
      'If no install option appears, try Chrome or Edge, or Safari on an Apple device. Some browsers do not support installation.',
    ];
  }

  function render() {
    if (!ui) return;
    const current = state();
    ui.entry.hidden = current.installed;
    ui.entry.disabled = current.prompting;
    ui.entry.setAttribute('aria-label', `Install ${appName}`);
    ui.primary.hidden = !current.canPrompt;
    ui.primary.disabled = current.prompting;
    ui.primary.textContent = current.prompting ? 'Opening installation…' : `Install ${appName}`;
    ui.newTab.hidden = !current.embedded || !current.secureContext;
    ui.steps.replaceChildren(...instructions().map((text) => {
      const item = document.createElement('li');
      item.textContent = text;
      return item;
    }));
    ui.feedback.textContent = feedback;
    ui.feedback.hidden = !feedback;
    if (current.installed) closeHelp();
  }

  function mount() {
    if (ui || !document.body) return;
    const root = document.createElement('div');
    root.id = 'sanctuary-install-ui';
    root.innerHTML = `
      <button class="install-entry" type="button" aria-haspopup="dialog" aria-controls="sanctuary-install-dialog">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M12 3v12m-4-4 4 4 4-4M5 15v5h14v-5"/></svg>
        <span>Install app</span>
      </button>
      <dialog id="sanctuary-install-dialog" aria-labelledby="sanctuary-install-title" aria-describedby="sanctuary-install-description" aria-modal="true">
        <div class="install-dialog-top"><img class="install-logo" width="64" height="64" alt=""><button class="install-close" type="button" aria-label="Close installation help">×</button></div>
        <p class="install-eyebrow">YOUR CALM, ONE TAP AWAY</p>
        <h2 class="install-title" id="sanctuary-install-title" tabindex="-1">Keep a little calm close.</h2>
        <p class="install-description" id="sanctuary-install-description"></p>
        <ol class="install-steps"></ol>
        <button class="install-primary" type="button" hidden></button>
        <a class="install-primary install-new-tab" target="_blank" rel="noopener noreferrer" hidden>Open in a new tab</a>
        <p class="install-feedback" role="status" hidden></p>
        <p class="install-note">No app store or account required to install. An internet connection is still needed to load the app and stream sounds. This does not download the audio library.</p>
      </dialog>
      <p class="install-live" aria-live="polite" aria-atomic="true"></p>`;
    document.body.append(root);
    ui = {
      root,
      entry: root.querySelector('.install-entry'),
      dialog: root.querySelector('dialog'),
      primary: root.querySelector('button.install-primary'),
      newTab: root.querySelector('.install-new-tab'),
      steps: root.querySelector('.install-steps'),
      title: root.querySelector('.install-title'),
      feedback: root.querySelector('.install-feedback'),
      live: root.querySelector('.install-live'),
    };
    root.querySelector('.install-logo').src = new URL('icons/Icon-192.png', base).href;
    root.querySelector('.install-description').textContent =
      `Add ${appName} to your home screen or desktop and open it like an app.`;
    ui.newTab.href = window.location.href;
    ui.entry.addEventListener('click', requestInstall);
    ui.primary.addEventListener('click', requestInstall);
    root.querySelector('.install-close').addEventListener('click', closeHelp);
    ui.dialog.addEventListener('cancel', (event) => {
      event.preventDefault();
      closeHelp();
    });
    // The native dialog handles focus trapping. This also covers older browsers
    // which only support the open attribute rather than showModal().
    ui.dialog.addEventListener('keydown', (event) => {
      if (typeof ui.dialog.showModal === 'function') return;
      if (event.key === 'Escape') {
        event.preventDefault();
        closeHelp();
      } else if (event.key === 'Tab') {
        const items = [...ui.dialog.querySelectorAll('button, a[href]')]
          .filter((item) => !item.hidden && !item.disabled);
        const first = items[0];
        const last = items[items.length - 1];
        if (event.shiftKey && (document.activeElement === first || document.activeElement === ui.title)) {
          event.preventDefault();
          last?.focus();
        } else if (!event.shiftKey && document.activeElement === last) {
          event.preventDefault();
          first?.focus();
        }
      }
    });
    render();
  }

  function openHelp(message = '') {
    if (isInstalled()) return;
    mount();
    if (!ui) return;
    feedback = message;
    render();
    ui.newTab.href = window.location.href;
    if (!ui.dialog.open) {
      lastFocus = document.activeElement;
      if (typeof ui.dialog.showModal === 'function') ui.dialog.showModal();
      else ui.dialog.setAttribute('open', '');
    }
    ui.title.focus();
  }

  function closeHelp() {
    if (!ui?.dialog.open) return;
    if (typeof ui.dialog.close === 'function') ui.dialog.close();
    else ui.dialog.removeAttribute('open');
    if (lastFocus?.isConnected && !lastFocus.hidden) lastFocus.focus();
    lastFocus = null;
  }

  async function requestInstall() {
    if (isInstalled()) return 'installed';
    if (promptInFlight) return 'pending';
    if (!state().canPrompt) {
      openHelp();
      return 'help';
    }
    // A beforeinstallprompt event is single-use. Consume it synchronously so a
    // second click cannot invoke it again; prompt() stays in the user gesture.
    const event = deferredPrompt;
    deferredPrompt = null;
    promptInFlight = true;
    closeHelp();
    publish();
    try {
      await event.prompt();
      const choice = await event.userChoice;
      if (choice.outcome === 'accepted') {
        if (ui) ui.live.textContent = 'Installation started. Follow your browser’s instructions.';
      } else {
        openHelp('Not installed yet. You can still install later from your browser menu.');
      }
      return choice.outcome;
    } catch (error) {
      console.warn('[Sanctuary PWA] Installation prompt could not open.', error);
      openHelp('The installation dialog could not open. Try the browser-menu steps below.');
      return 'failed';
    } finally {
      promptInFlight = false;
      publish();
    }
  }

  window.addEventListener('beforeinstallprompt', (event) => {
    event.preventDefault();
    if (!isInstalled()) deferredPrompt = event;
    publish();
  });
  window.addEventListener('appinstalled', () => {
    installedEvent = true;
    deferredPrompt = null;
    promptInFlight = false;
    if (ui) ui.live.textContent = `${appName} was installed. Open it from your home screen or app launcher.`;
    publish();
  });
  for (const query of [standalone, fullscreen]) {
    if (typeof query.addEventListener === 'function') query.addEventListener('change', publish);
    else if (typeof query.addListener === 'function') query.addListener(publish);
  }

  window.SanctuaryInstall = Object.freeze({ open: openHelp, prompt: requestInstall, get state() { return state(); } });
  window.triggerPwaInstall = requestInstall;
  window.isPwaInstallable = false;

  function registerWorker() {
    if (!window.isSecureContext || !['http:', 'https:'].includes(base.protocol)) return;
    try {
      if (!('serviceWorker' in navigator) || base.origin !== window.location.origin) return;
      navigator.serviceWorker.register(new URL('install-worker.js', base), {
        scope: base.href,
        updateViaCache: 'none',
      }).catch((error) => {
        console.warn('[Sanctuary PWA] Install worker could not register.', error);
      });
    } catch (error) {
      // Sandboxed/embedded browsers may disable SW storage. Manual install help
      // remains available and points the user to a top-level browser tab.
      console.warn('[Sanctuary PWA] Service workers are unavailable here.', error);
    }
  }

  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', mount, { once: true });
  else mount();
  if (document.readyState === 'complete') registerWorker();
  else window.addEventListener('load', registerWorker, { once: true });
})();
