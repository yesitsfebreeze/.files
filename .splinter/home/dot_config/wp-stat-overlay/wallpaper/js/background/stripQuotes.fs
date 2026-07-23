// §head home/dot_config/wp-stat-overlay/wallpaper/js/background.js:32-41 stripQuotes
// §sig function stripQuotes(s)
    s = String(s == null ? "" : s).trim();
    if (s.length >= 2) {
      var q = s.charAt(0);
      if ((q === '"' || q === "'") && s.charAt(s.length - 1) === q) {
        s = s.slice(1, -1).trim();
      }
    }
    return s;
// §foot home/dot_config/wp-stat-overlay/wallpaper/js/background.js stripQuotes