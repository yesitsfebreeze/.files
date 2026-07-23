// §source home/dot_config/wp-stat-overlay/wallpaper/js/look.js
// look.js — typing-reactive look controller.
//
// Every look setting has two values: a resting (not-typing) value and a typing
// value. typing.js flips the state via WP_LOOK.setState(); each setting is a
// plain CSS variable, so a CSS transition (duration --look-ease) eases it from
// one to the other for free — no JS animation loop.
//
// properties.js feeds raw Wallpaper Engine values in here (px, 0..200, 0..100…);
// the per-channel conversion to a CSS-var value lives here so it's defined once.
(function () {
  "use strict";

  var root = document.documentElement;

  // channel name -> { v: CSS var, f: raw WE value -> CSS var value }
  var CSS = {
    blur:       { v: "--bg-blur",       f: function (x) { return Number(x) + "px"; } },
    brightness: { v: "--bg-brightness", f: function (x) { return Number(x) / 100; } },
    opacity:    { v: "--bg-opacity",    f: function (x) { return Number(x) / 100; } },
    zoom:       { v: "--bg-zoom",       f: function (x) { return Number(x) / 100; } },
    vignette:   { v: "--vignette",      f: function (x) { return Number(x) / 100; } }
  };

  var idle = {};          // raw resting values, keyed by channel name
  var typing = {};        // raw typing values, keyed by channel name
  var isTyping = false;

  // target raw value for a channel in the current state; an unset typing value
  // falls back to the resting value
  function target(name) {
// §.splinter/home/dot_config/wp-stat-overlay/wallpaper/js/look/target.fs
}

  function applyCss(name) {
// §.splinter/home/dot_config/wp-stat-overlay/wallpaper/js/look/applyCss.fs
}

  window.WP_LOOK = {
    // resting value for one channel (raw WE value)
    setIdle: function (name, value) {
      if (!CSS[name]) return;
      idle[name] = value;
      if (!isTyping) applyCss(name);
    },
    // typing value for one channel (raw WE value)
    setTyping: function (name, value) {
      if (!CSS[name]) return;
      typing[name] = value;
      if (isTyping) applyCss(name);
    },
    // transition duration in seconds for the resting<->typing morph
    setEase: function (seconds) {
      var s = Number(seconds);
      if (!(s >= 0)) s = 0;
      root.style.setProperty("--look-ease", s + "s");
    },
    // flip resting <-> typing; no-op if unchanged so transitions only fire on a
    // real state change
    setState: function (typingNow) {
      typingNow = !!typingNow;
      if (typingNow === isTyping) return;
      isTyping = typingNow;
      for (var n in CSS) applyCss(n); // CSS eases each one itself
    }
  };
})();
