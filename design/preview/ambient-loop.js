'use strict';
// Gapless local ambience in the independent HTML preview, not Flutter's native
// engine. Decode the original file once; loop the same AudioBufferSourceNode on
// the audio clock. No timer-driven restarts, replacement recordings or new files.
const ambientLoopEngine = {
  context: null,
  cache: new Map(),
  players: new Set(),
  cacheBudget: 64 * 1024 * 1024,
  idleTimer: null,
  cancelIdleSuspend() {
    clearTimeout(this.idleTimer);
    this.idleTimer = null;
  },
  hasPlaybackIntent() {
    // Use intent, not the paused getter: a platform-interrupted clock still
    // owns live nodes which only an explicit Resume may unlock.
    return [...this.players].some(player => !player._paused);
  },
  suspendIfIdle() {
    const context = this.context;
    if (!context || context.state !== 'running' || this.hasPlaybackIntent()) {
      this.cancelIdleSuspend();
      return;
    }
    if (this.idleTimer !== null) return; // Paused gain edits must not postpone sleep.
    // Coalesce rapid mix switches. Never keep an empty audio rendering graph
    // running indefinitely, and never suspend a pending decode or healthy loop.
    this.idleTimer = setTimeout(() => {
      this.idleTimer = null;
      if (this.context !== context || context.state !== 'running' || this.hasPlaybackIntent()) return;
      context.suspend().catch(() => {}); // A later Play still resumes in its gesture.
    }, 1000);
  },
  getContext() {
    if (this.context?.state === 'closed') this.context = null;
    if (!this.context) {
      const Context = window.AudioContext || window.webkitAudioContext;
      const context = this.context = new Context();
      context.addEventListener('statechange', () => {
        for (const player of this.players) {
          if (player._paused || !player.sourceNode) continue;
          if (context.state === 'closed') {
            player.error = { code: 4 };
            player.dispatchEvent(new Event('error'));
          } else {
            // An interrupted/suspended clock is not playing. Keep the same node
            // and position so a deliberate Resume can unlock it without a seek.
            player.dispatchEvent(new Event(context.state === 'running' ? 'playing' : 'pause'));
          }
        }
      });
    }
    return this.context;
  },
  retain(url, buffer, player) {
    let entry = this.cache.get(url);
    if (!entry) {
      entry = { buffer, bytes: buffer.length * buffer.numberOfChannels * 4, users: new Set() };
    }
    this.cache.delete(url);
    this.cache.set(url, entry);
    entry.users.add(player);
    this.trim();
  },
  release(url, player) {
    this.cache.get(url)?.users.delete(player);
    this.trim();
  },
  trim() {
    let bytes = [...this.cache.values()].reduce((sum, entry) => sum + entry.bytes, 0);
    for (const [url, entry] of this.cache) {
      if (bytes <= this.cacheBudget) break;
      if (entry.users.size) continue; // Never evict/restart an active loop.
      this.cache.delete(url);
      bytes -= entry.bytes;
    }
  },
};

class BufferedAmbientLoop extends EventTarget {
  constructor(path) {
    super();
    this.src = new URL(path, document.baseURI).href;
    this.currentSrc = this.src;
    this.loop = true;
    this.preload = 'none';
    this.paused = true;
    this.ended = false;
    this.error = null;
    this.downloadProgress = 0;
    this.sourceNode = null;
    this.gainNode = null;
    this._volume = 1;
    this._offset = 0;
    this._duration = NaN;
    this._startedAt = 0;
    this._generation = 0;
    this._controller = null;
    this._pending = null;
    this._buffer = null;
    this.backend = 'decoded-loop';
    ambientLoopEngine.players.add(this);
  }
  get duration() { return this._duration; }
  get paused() {
    return this._paused || (!!this.sourceNode && ambientLoopEngine.context?.state !== 'running');
  }
  set paused(value) { this._paused = value; }
  get readyState() {
    return this._buffer || ambientLoopEngine.cache.has(this.currentSrc) ? 4 : 0;
  }
  get buffered() {
    const duration = this.duration;
    const ready = this.readyState === 4;
    return { length: ready ? 1 : 0, start: () => 0, end: () => duration };
  }
  get volume() { return this._volume; }
  set volume(value) {
    this._volume = Math.max(0, Math.min(1, Number(value) || 0));
    if (!this.gainNode) return;
    const context = ambientLoopEngine.context;
    const parameter = this.gainNode.gain;
    // Short gain ramp avoids control/duck/fade clicks; raw sliders stay intact.
    parameter.cancelScheduledValues(context.currentTime);
    parameter.setValueAtTime(parameter.value, context.currentTime);
    parameter.linearRampToValueAtTime(this._volume, context.currentTime + .015);
  }
  get currentTime() {
    const elapsed = !this._paused && this.sourceNode
      ? ambientLoopEngine.context.currentTime - this._startedAt : 0;
    const time = this._offset + elapsed;
    return this.loop && this.duration > 0 ? time % this.duration : time;
  }
  set currentTime(value) {
    if (!Number.isFinite(value)) return;
    const running = !this.paused && !!this.sourceNode;
    this._offset = this.duration > 0 ? Math.max(0, value) % this.duration : Math.max(0, value);
    if (running) {
      this._stopNode();
      this._startNode();
    }
  }
  _stopNode() {
    const source = this.sourceNode;
    this.sourceNode = null;
    if (source) {
      source.onended = null;
      try { source.stop(); } catch (_) {}
      source.disconnect();
    }
    this.gainNode?.disconnect();
    this.gainNode = null;
  }
  _startNode() {
    const context = ambientLoopEngine.getContext();
    const source = context.createBufferSource();
    const gain = context.createGain();
    source.buffer = this._buffer;
    source.loop = this.loop;
    gain.gain.value = this._volume;
    source.connect(gain);
    gain.connect(context.destination);
    this.sourceNode = source;
    this.gainNode = gain;
    this._startedAt = context.currentTime;
    this.ended = false;
    source.onended = () => {
      if (this.sourceNode !== source || this.loop || this.paused) return;
      this.paused = true;
      this.ended = true;
      this._stopNode();
      this.dispatchEvent(new Event('ended'));
      ambientLoopEngine.suspendIfIdle();
    };
    source.start(0, this.duration > 0 ? this._offset % this.duration : 0);
  }
  async _decode(context, signal) {
    const cached = ambientLoopEngine.cache.get(this.currentSrc);
    if (cached) return cached.buffer;
    const response = await fetch(this.currentSrc, { signal, cache: 'force-cache' });
    if (!response.ok) throw new Error('Recording could not load');
    const total = Number(response.headers.get('content-length')) || 0;
    let bytes;
    if (response.body?.getReader) {
      const reader = response.body.getReader();
      const chunks = [];
      let size = 0;
      while (true) {
        const result = await reader.read();
        if (result.done) break;
        if (signal.aborted) throw new DOMException('Cancelled', 'AbortError');
        chunks.push(result.value);
        size += result.value.byteLength;
        this.downloadProgress = total ? Math.min(.99, size / total) : null;
        this.dispatchEvent(new Event('progress'));
      }
      bytes = new Uint8Array(size);
      let offset = 0;
      for (const chunk of chunks) { bytes.set(chunk, offset); offset += chunk.byteLength; }
      bytes = bytes.buffer;
    } else {
      bytes = await response.arrayBuffer();
      this.dispatchEvent(new Event('progress'));
    }
    if (signal.aborted) throw new DOMException('Cancelled', 'AbortError');
    return context.decodeAudioData(bytes);
  }
  play() {
    if (!this.src) return Promise.reject(new Error('No recording configured'));
    ambientLoopEngine.cancelIdleSuspend();
    if (!this._paused && this.sourceNode) {
      // Resume a suspended audio clock without replacing any healthy source.
      return ambientLoopEngine.getContext().resume().then(() => {
        if (!this._paused && this.sourceNode) this.dispatchEvent(new Event('playing'));
      });
    }
    if (this._pending) return this._pending;
    const generation = ++this._generation;
    const context = ambientLoopEngine.getContext();
    // Resume synchronously in the user's gesture before waiting for file/decode.
    const resume = context.resume();
    const controller = this._controller = new AbortController();
    this.paused = false;
    this.error = null;
    this.dispatchEvent(new Event('loadstart'));
    this.dispatchEvent(new Event('waiting'));
    const operation = (async () => {
      try {
        const [buffer] = await Promise.all([this._decode(context, controller.signal), resume]);
        if (generation !== this._generation || this.paused || controller.signal.aborted) throw new DOMException('Cancelled', 'AbortError');
        this._buffer = buffer;
        this._duration = buffer.duration;
        this.downloadProgress = 1;
        ambientLoopEngine.retain(this.currentSrc, buffer, this);
        this._startNode();
        this.dispatchEvent(new Event('loadedmetadata'));
        this.dispatchEvent(new Event('canplaythrough'));
        this.dispatchEvent(new Event('playing'));
      } catch (error) {
        if (generation === this._generation && error.name !== 'AbortError') {
          this.error = { code: 4 }; // Never leak platform/network payloads.
          this.paused = true;
          this.dispatchEvent(new Event('error'));
        }
        throw error;
      } finally {
        if (generation === this._generation) {
          this._pending = null;
          this._controller = null;
        }
        ambientLoopEngine.suspendIfIdle();
      }
    })();
    this._pending = operation;
    return operation;
  }
  pause() {
    const changed = !this.paused;
    this._offset = this.currentTime;
    this.paused = true;
    ++this._generation;
    this._controller?.abort();
    this._controller = null;
    this._pending = null;
    this._stopNode();
    ambientLoopEngine.release(this.currentSrc, this);
    this._buffer = null; // The bounded cache, not paused players, retains PCM.
    if (changed) this.dispatchEvent(new Event('pause'));
    ambientLoopEngine.suspendIfIdle();
  }
  getAttribute(name) {
    return name === 'src' ? this.src || null : null;
  }
  removeAttribute(name) {
    if (name !== 'src') return;
    this.pause();
    this.src = '';
    this.currentSrc = '';
    ambientLoopEngine.players.delete(this);
  }
  load() {
    this.pause();
    this.error = null;
    this._offset = 0;
    this._duration = NaN;
  }
}

function createAmbientLoopAudio(path) {
  if (window.AudioContext || window.webkitAudioContext) return new BufferedAmbientLoop(path);
  // Compatibility only, using the very same local file, never another source.
  const audio = new Audio(path);
  audio.backend = 'media-element';
  return audio;
}
