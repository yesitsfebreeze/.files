// §head home/dot_config/wp-stat-overlay/wallpaper/js/background.js:43-59 resolveMedia
// §sig function resolveMedia(value, endpoint)
    endpoint = endpoint || "/file";
    if (!value) return "";
    var s = stripQuotes(value);
    if (/^(https?:|data:)/i.test(s)) return s; // remote / inline — direct

    // strip a file:// prefix, then URL-decode: WE hands paths with chars like
    // ':' encoded as %3A (e.g. "C%3A/Users/..."), often with no scheme at all.
    var raw = s;
    var m = s.match(/^file:\/+(.*)$/i);
    if (m) raw = m[1];
    try { raw = decodeURIComponent(raw); } catch (e) { /* keep raw on bad escape */ }

    var isAbs = /^[a-zA-Z]:[\\/]/.test(raw) || raw.charAt(0) === "/";
    if (isAbs) return helperBase + endpoint + "?p=" + encodeURIComponent(raw);
    return s; // project-relative, same origin
// §foot home/dot_config/wp-stat-overlay/wallpaper/js/background.js resolveMedia