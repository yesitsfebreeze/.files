// §head home/dot_config/wp-stat-overlay/wallpaper/js/typing.js:31-56 evaluate
// §sig function evaluate(keyIdleMs, nowMs)
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
// §foot home/dot_config/wp-stat-overlay/wallpaper/js/typing.js evaluate