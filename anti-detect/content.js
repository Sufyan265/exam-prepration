(function () {
  'use strict';
  const W = window;
  const D = W.Document.prototype, E = W.Element.prototype,
    Win = W.Window.prototype, S = W.Screen.prototype, Doc = W.document;

  const set = (o, p, v) => { try { Object.defineProperty(o, p, { configurable: true, writable: true, value: v }); } catch (e) { } };
  const get = (o, p, f) => { try { Object.defineProperty(o, p, { configurable: true, enumerable: true, get: f }); } catch (e) { } };
  const both = (p, f) => { get(D, p, f); get(Doc, p, f); };

  /* ---- 1. FULLSCREEN: real fullscreen works, page never sees the state ---- */
  const realRequest = E.requestFullscreen || E.webkitRequestFullscreen ||
    E.webkitRequestFullScreen || E.mozRequestFullScreen || E.msRequestFullscreen;
  const realExit = D.exitFullscreen || D.webkitExitFullscreen ||
    D.webkitCancelFullScreen || D.mozCancelFullScreen || D.msExitFullscreen;

  let fakeEl = null;
  const fsEl = () => fakeEl || Doc.documentElement;

  ['fullscreenElement', 'webkitFullscreenElement', 'webkitCurrentFullScreenElement',
    'mozFullScreenElement', 'msFullscreenElement'].forEach(p => both(p, fsEl));
  ['fullscreen', 'webkitIsFullScreen', 'mozFullScreen', 'webkitFullScreen', 'isFullScreen'].forEach(p => both(p, () => true));
  ['fullscreenEnabled', 'webkitFullscreenEnabled', 'mozFullScreenEnabled', 'msFullscreenEnabled'].forEach(p => both(p, () => true));
  get(Win, 'fullScreen', () => true);

  const EV = ['fullscreenchange', 'webkitfullscreenchange', 'mozfullscreenchange', 'MSFullscreenChange'];
  const synth = new W.WeakSet();
  const fire = t => EV.forEach(n => {
    const ev = new W.Event(n, { bubbles: true });
    synth.add(ev);
    try { t.dispatchEvent(ev); } catch (e) { }
  });

  const reqFS = function () {
    const el = this;
    fakeEl = (el === Doc) ? Doc.documentElement : el;
    let p;
    try { p = realRequest.call(el); } catch (e) { }
    W.setTimeout(() => fire(fakeEl), 0);
    return W.Promise.resolve(p).catch(() => { });
  };
  const exitFS = function () {
    let p;
    try { p = realExit.call(Doc); } catch (e) { }
    W.setTimeout(() => fire(Doc), 0);
    return W.Promise.resolve(p).catch(() => { });
  };
  ['requestFullscreen', 'webkitRequestFullscreen', 'webkitRequestFullScreen',
    'mozRequestFullScreen', 'msRequestFullscreen'].forEach(p => set(E, p, reqFS));
  ['exitFullscreen', 'webkitExitFullscreen', 'webkitCancelFullScreen',
    'mozCancelFullScreen', 'msExitFullscreen'].forEach(p => set(D, p, exitFS));

  EV.forEach(n => W.addEventListener(n, e => {
    if (synth.has(e)) return;
    e.stopImmediatePropagation();
  }, true));

  /* ---- 2. VISIBILITY + FOCUS ---- */
  ['visibilityState', 'webkitVisibilityState', 'mozVisibilityState'].forEach(p => both(p, () => 'visible'));
  ['hidden', 'webkitHidden', 'mozHidden', 'msHidden'].forEach(p => both(p, () => false));
  set(D, 'hasFocus', () => true);
  set(Doc, 'hasFocus', () => true);

  /* ---- 3. WINDOW SIZE == SCREEN SIZE ---- */
  const w = () => W.screen.width, h = () => W.screen.height;
  [Win, W].forEach(o => {
    get(o, 'innerWidth', w); get(o, 'innerHeight', h);
    get(o, 'outerWidth', w); get(o, 'outerHeight', h);
    get(o, 'screenX', () => 0); get(o, 'screenY', () => 0);
    get(o, 'screenLeft', () => 0); get(o, 'screenTop', () => 0);
  });
  get(S, 'availWidth', w); get(S, 'availHeight', h); get(S, 'isExtended', () => false);

  /* ---- 4. matchMedia: fullscreen YES, browser-mode NO ---- */
  const realMM = W.matchMedia.bind(W);
  W.matchMedia = function (q) {
    const mql = realMM(q);
    if (/display-mode\s*:\s*fullscreen/i.test(q)) {
      return new W.Proxy(mql, { get: (t, p) => p === 'matches' ? true : p === 'media' ? q : (typeof t[p] === 'function' ? t[p].bind(t) : t[p]) });
    }
    if (/display-mode\s*:\s*browser/i.test(q)) {
      return new W.Proxy(mql, { get: (t, p) => p === 'matches' ? false : p === 'media' ? q : (typeof t[p] === 'function' ? t[p].bind(t) : t[p]) });
    }
    return mql;
  };

  /* ---- 5. EVENT KILLS — narrowed so nothing else breaks ---- */
  // alerting handlers + selection + right-click: kill outright
  ['contextmenu', 'copy', 'cut', 'paste', 'dragstart', 'selectstart',
    'visibilitychange', 'webkitvisibilitychange'].forEach(t =>
      W.addEventListener(t, e => e.stopImmediatePropagation(), true));

  // left button only — Moodle's prevent_mouse only halts left clicks
  ['mousedown', 'mouseup'].forEach(t =>
    W.addEventListener(t, e => { if (e.button === 0) e.stopImmediatePropagation(); }, true));

  // window-level blur/focus ONLY — element focus/blur pass through
  ['blur', 'focus'].forEach(t =>
    W.addEventListener(t, e => { if (e.target === W) e.stopImmediatePropagation(); }, true));

  W.addEventListener('mouseleave', e => e.stopImmediatePropagation(), true);

  /* ---- 6. KEY KILLS ---- */
  const bad = e => {
    const k = (e.key || '').toLowerCase();
    if (e.key === 'F12') return true;
    if (e.ctrlKey || e.metaKey) {
      if (['c', 'v', 'x', 'u', 's', 'p'].includes(k)) return true;
      if (e.shiftKey && ['i', 'j', 'c'].includes(k)) return true;
    }
    return false;
  };
  ['keydown', 'keyup', 'keypress'].forEach(t =>
    W.addEventListener(t, e => { if (bad(e)) e.stopImmediatePropagation(); }, true));

  W.__inSEB = /SEB\//.test(navigator.userAgent);
  W.__antiDetect = 'v3';
})();