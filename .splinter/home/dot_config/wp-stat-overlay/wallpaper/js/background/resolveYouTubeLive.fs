// §head home/dot_config/wp-stat-overlay/wallpaper/js/background.js:115-125 resolveYouTubeLive
// §sig function resolveYouTubeLive(url, cb)
    var api = helperBase + "/yt?u=" + encodeURIComponent(url);
    fetch(api, { cache: "no-store" }).then(function (r) {
      if (!r.ok) { r.text().then(function (t) { cb(null, "helper " + r.status + (t ? " " + t.trim() : "")); }); return null; }
      return r.json();
    }).then(function (j) {
      if (j) cb(j.videoId || null, j.videoId ? null : "no live video");
    }).catch(function () {
      cb(null, "helper unreachable — is wpstats running?");
    });
// §foot home/dot_config/wp-stat-overlay/wallpaper/js/background.js resolveYouTubeLive