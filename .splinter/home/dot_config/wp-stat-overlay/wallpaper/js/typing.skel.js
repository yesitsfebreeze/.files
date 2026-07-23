// §source home/dot_config/wp-stat-overlay/wallpaper/js/typing.js
// typing.js — polls the wpstats helper for keyboard activity and tells WP_LOOK
// whether the user is currently typing. A WE web wallpaper sits behind every
// window and never receives global key events itself, so the helper owns the
// global keyboard hook and reports "ms since last keystroke" (keyIdleMs); we
// poll it fast and debounce both edges into a committed typing/resting state.
//
// Three user timings shape the behaviour:
//   • transition speed — how long the fade itself takes (owned by WP_LOOK / the
//     --look-ease CSS var; set elsewhere, not here).
//   • start delay      — you must keep typing this long before the look fades IN.
//   • revert delay     — after your LAST keystroke, wait this long before the
//                        look fades back OUT to resting.
(function () {
  "use strict";

  // keyIdleMs under this = a key is being pressed right now. Also the floor on
  // the revert threshold, so the look never reverts between two keystrokes of
  // normal typing (which can sit ~100-200ms apart).
  var KEY_GAP_MS = 250;
  var POLL_MS = 100;

  var origin = "http://localhost:8787"; // derived from the helper URL property
  var startDelayMs = 0;                 // before fading IN
  var revertDelayMs = 600;              // after last key, before fading OUT
  var timer = null;

  var committed = false;  // current committed look state (false = resting)
  var startSince = null;  // when sustained typing began (for the start delay)

  // Decide the committed state from keyIdleMs and the two delays.
  function evaluate(keyIdleMs, nowMs) {
// §.splinter/home/dot_config/wp-stat-overlay/wallpaper/js/typing/evaluate.fs
}

  function tick() {
// §.splinter/home/dot_config/wp-stat-overlay/wallpaper/js/typing/tick.fs
}

  function restart() {
// §.splinter/home/dot_config/wp-stat-overlay/wallpaper/js/typing/restart.fs
}

  function secToMs(s) {
// §.splinter/home/dot_config/wp-stat-overlay/wallpaper/js/typing/secToMs.fs
}

  window.WP_TYPING = {
    // accepts the same URL as the stats helper (".../stats"); /typing is on the
    // same origin
    setUrl: function (statsUrl) {
      try { origin = new URL(statsUrl).origin; } catch (e) { /* keep previous */ }
      restart();
    },
    setStartDelay: function (seconds) { startDelayMs = secToMs(seconds); },
    setRevertDelay: function (seconds) { revertDelayMs = secToMs(seconds); }
  };

  restart();
})();
