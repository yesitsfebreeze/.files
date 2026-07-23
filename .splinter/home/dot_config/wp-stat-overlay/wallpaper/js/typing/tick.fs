// §head home/dot_config/wp-stat-overlay/wallpaper/js/typing.js:58-70 tick
// §sig function tick()
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
// §foot home/dot_config/wp-stat-overlay/wallpaper/js/typing.js tick