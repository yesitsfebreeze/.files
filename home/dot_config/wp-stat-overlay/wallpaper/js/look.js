// look.js — typing-reactive look controller.
//
// Every continuous "look" setting has two values: a resting (not-typing) value
// and a typing value. typing.js flips the state via WP_LOOK.setState(); this
// module eases each setting from one to the other over the transition time set
// by WP_LOOK.setEase (the single timing slider).
//
// Two kinds of setting, eased two ways:
//   • CSS settings (blur, brightness, opacities, radius, overlay) are plain CSS
//     vars — we just set the target and let a CSS transition (duration
//     --look-ease) do the easing for free.
//   • Shader FX settings (chroma, grain, vhs, …) are WebGL uniforms pushed via
//     WP_FX.setEffects(); CSS can't ease those, so we tween them in JS with rAF
//     over the same duration and push every frame.
//
// properties.js feeds raw Wallpaper Engine values in here (px, 0..200, 0..100…);
// the per-channel conversion lives here so it's defined once.
(function () {
  "use strict";

  var root = document.documentElement;

  // CSS-var channels: raw WE value -> CSS var value. Eased by CSS transitions.
  var CSS = {
    blur:           { v: "--bg-blur",         f: function (x) { return Number(x) + "px"; } },
    brightness:     { v: "--bg-brightness",   f: function (x) { return Number(x) / 100; } },
    bgopacity:      { v: "--bg-opacity",      f: function (x) { return Number(x) / 100; } },
    panelopacity:   { v: "--panel-opacity",   f: function (x) { return Number(x) / 100; } },
    cardradius:     { v: "--card-radius",     f: function (x) { return Number(x) + "px"; } },
    overlayopacity: { v: "--overlay-opacity", f: function (x) { return Number(x) / 100; } },
    overlayscale:   { v: "--overlay-scale",   f: function (x) { return Number(x) / 100; } }
  };

  // Shader-fx channels: channel name -> key in the WP_FX strengths object.
  // Raw WE value is 0..100; WP_FX wants 0..1. Tweened in JS.
  var FX = {
    fx_chroma: "chroma", fx_grain: "grain",
    fx_vhs: "vhs", fx_ripple: "ripple", fx_vignette: "vignette"
  };

  var idle = {};            // raw resting values, keyed by channel name
  var typing = {};          // raw typing values, keyed by channel name
  var isTyping = false;
  var easeMs = 600;         // FX tween duration (CSS uses the --look-ease var)

  // live shader strengths (0..1) currently pushed to WP_FX
  var fxLive = {};
  for (var fk in FX) fxLive[FX[fk]] = 0;

  // resolve the target raw value for a channel in the current state; an unset
  // typing value falls back to the resting value
  function target(name) {
    var v = isTyping ? typing[name] : idle[name];
    if (typeof v === "undefined") v = idle[name];
    return v;
  }

  function applyCss(name) {
    var v = target(name);
    if (typeof v === "undefined") return;
    root.style.setProperty(CSS[name].v, CSS[name].f(v));
  }

  function pushFx() {
    if (window.WP_FX) window.WP_FX.setEffects(fxLive);
  }

  // jump shader strengths straight to their target (no tween) — used on the
  // initial property load and when easing is disabled
  function setFxImmediate() {
    for (var n in FX) {
      var v = target(n);
      fxLive[FX[n]] = (typeof v === "undefined" ? 0 : Number(v) / 100);
    }
    pushFx();
  }

  // ---- FX tween (requestAnimationFrame) ----
  var raf = null, tStart = 0, fxFrom = null, fxTo = null;

  function startFxTween() {
    if (!window.WP_FX || easeMs <= 0) { setFxImmediate(); return; }
    fxFrom = {}; fxTo = {};
    for (var n in FX) {
      var key = FX[n];
      fxFrom[key] = fxLive[key];
      var v = target(n);
      fxTo[key] = (typeof v === "undefined" ? 0 : Number(v) / 100);
    }
    tStart = performance.now();
    if (raf === null) raf = requestAnimationFrame(stepFx);
  }

  function stepFx(t) {
    var p = Math.min(1, (t - tStart) / easeMs);
    // easeInOutQuad — matches the feel of the CSS "ease" on the look vars
    var e = p < 0.5 ? 2 * p * p : 1 - Math.pow(-2 * p + 2, 2) / 2;
    for (var key in fxTo) fxLive[key] = fxFrom[key] + (fxTo[key] - fxFrom[key]) * e;
    pushFx();
    raf = p < 1 ? requestAnimationFrame(stepFx) : null;
  }

  window.WP_LOOK = {
    // resting value for one channel (raw WE value)
    setIdle: function (name, value) {
      if (!CSS[name] && !FX[name]) return;
      idle[name] = value;
      if (!isTyping) { if (CSS[name]) applyCss(name); else setFxImmediate(); }
    },
    // typing value for one channel (raw WE value)
    setTyping: function (name, value) {
      if (!CSS[name] && !FX[name]) return;
      typing[name] = value;
      if (isTyping) { if (CSS[name]) applyCss(name); else setFxImmediate(); }
    },
    // transition duration in seconds for the resting<->typing morph
    setEase: function (seconds) {
      var s = Number(seconds);
      if (!(s >= 0)) s = 0;
      easeMs = s * 1000;
      root.style.setProperty("--look-ease", s + "s");
    },
    // flip resting <-> typing; no-op if unchanged so transitions only fire on a
    // real state change
    setState: function (typingNow) {
      typingNow = !!typingNow;
      if (typingNow === isTyping) return;
      isTyping = typingNow;
      for (var n in CSS) applyCss(n); // CSS eases these itself
      startFxTween();                 // FX eased here
    }
  };
})();
