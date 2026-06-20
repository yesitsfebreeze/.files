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
    var active = keyIdleMs < KEY_GAP_MS; // a key is being pressed right now

    if (!committed) {
      // resting -> maybe fade in once typing is sustained for startDelay
      if (active) {
        if (startSince === null) startSince = nowMs;
        if (nowMs - startSince >= startDelayMs) {
          committed = true;
          if (window.WP_LOOK) window.WP_LOOK.setState(true);
        }
      } else {
        startSince = null; // stopped before the start delay elapsed -> cancel
      }
    } else {
      // typing -> fade out once it's been revertDelay since the last keystroke.
      // keyIdleMs *is* that timer (it counts from the last key), floored at
      // KEY_GAP_MS so a brief inter-key gap never triggers a revert.
      var revertAt = revertDelayMs > KEY_GAP_MS ? revertDelayMs : KEY_GAP_MS;
      if (keyIdleMs >= revertAt) {
        committed = false;
        startSince = null;
        if (window.WP_LOOK) window.WP_LOOK.setState(false);
      }
    }
  }

  function tick() {
    fetch(origin + "/typing", { cache: "no-store" })
      .then(function (r) { return r.ok ? r.json() : null; })
      .then(function (d) {
        if (!d || typeof d.keyIdleMs === "undefined") return;
        evaluate(d.keyIdleMs | 0, performance.now());
      })
      .catch(function () {
        // helper offline (or no /typing endpoint): settle back to resting
        startSince = null;
        if (committed && window.WP_LOOK) { committed = false; window.WP_LOOK.setState(false); }
      });
  }

  function restart() {
    if (timer) clearInterval(timer);
    tick();
    timer = setInterval(tick, POLL_MS);
  }

  function secToMs(s) { var v = Number(s); return v >= 0 ? v * 1000 : 0; }

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
