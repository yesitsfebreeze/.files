// typing.js — polls the wpstats helper for keyboard activity and tells WP_LOOK
// whether the user is currently typing. A WE web wallpaper sits behind every
// window and never receives global key events itself, so the helper owns the
// global keyboard hook and reports "ms since last keystroke"; we poll it fast
// and treat anything under THRESHOLD_MS as "typing".
//
// The eased fade between looks is handled by WP_LOOK; the THRESHOLD is the
// debounce that keeps brief gaps between keystrokes from dropping out of the
// typing state.
(function () {
  "use strict";

  var THRESHOLD_MS = 600; // gap under which we're still considered "typing"
  var POLL_MS = 150;

  var origin = "http://localhost:8787"; // derived from the helper URL property
  var timer = null;

  function tick() {
    fetch(origin + "/typing", { cache: "no-store" })
      .then(function (r) { return r.ok ? r.json() : null; })
      .then(function (d) {
        if (!d || typeof d.keyIdleMs === "undefined") return;
        var typing = (d.keyIdleMs | 0) < THRESHOLD_MS;
        if (window.WP_LOOK) window.WP_LOOK.setState(typing);
      })
      .catch(function () {
        // helper offline (or no /typing endpoint): stay in the resting look
        if (window.WP_LOOK) window.WP_LOOK.setState(false);
      });
  }

  function restart() {
    if (timer) clearInterval(timer);
    tick();
    timer = setInterval(tick, POLL_MS);
  }

  window.WP_TYPING = {
    // accepts the same URL as the stats helper (".../stats"); /typing is on the
    // same origin
    setUrl: function (statsUrl) {
      try { origin = new URL(statsUrl).origin; } catch (e) { /* keep previous */ }
      restart();
    }
  };

  restart();
})();
