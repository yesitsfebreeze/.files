// §source home/dot_config/wp-stat-overlay/wallpaper/js/background.js
// background.js — builds the wrapped background layer (#bg) from the active
// source. Exactly one source is active at a time (image / video / web / none);
// properties.js decides which and calls apply(). Blur / brightness / opacity
// are CSS variables on #bg, so this module only swaps the media element.
(function () {
  "use strict";

  var bg = document.getElementById("bg");
  var bgstatus = document.getElementById("bgstatus");
  var state = { type: "none", value: "" };
  var helperBase = "http://localhost:8787"; // updated from the helper URL property
  var token = 0; // bumped each rebuild; guards async video transcode polling

  // Surface what the background layer is doing, so a silently-failing local
  // file path becomes visible instead of just "no background".
  function report(msg, isError) {
// §.splinter/home/dot_config/wp-stat-overlay/wallpaper/js/background/report.fs
}

  // resolveMedia — for <img>/<video>, a local file in another folder is blocked
  // by Chromium from a file:// origin, so route absolute local paths through the
  // helper's /file endpoint (an http origin). Remote URLs and in-project relative
  // paths load directly.
  // stripQuotes — paths pasted from a file manager (Windows "Copy as path",
  // shells) arrive wrapped in surrounding quotes; drop a matching pair so the
  // path resolves instead of being treated as a literal quoted string.
  function stripQuotes(s) {
// §.splinter/home/dot_config/wp-stat-overlay/wallpaper/js/background/stripQuotes.fs
}

  function resolveMedia(value, endpoint) {
// §.splinter/home/dot_config/wp-stat-overlay/wallpaper/js/background/resolveMedia.fs
}

  // playVideo — mount a local/remote video. Local files go through /video, which
  // may transcode mp4→webm (WE's Chromium lacks H.264); while that runs the
  // helper returns 503, so we poll until the cached webm is ready. The token
  // guards against the background being switched mid-transcode.
  function playVideo(value, myToken) {
// §.splinter/home/dot_config/wp-stat-overlay/wallpaper/js/background/playVideo.fs
}

  // Shared muted/chromeless embed params for every YouTube player URL (by id and
  // by channel live_stream), kept in one place so the two builders can't drift.
  var YT_PARAMS = "autoplay=1&mute=1&controls=0&modestbranding=1&playsinline=1&rel=0&iv_load_policy=3&disablekb=1&fs=0";

  // ytEmbed — the player URL for a known video id (muted, chromeless). A LIVE
  // stream must NOT get loop/playlist: you can't loop a live broadcast and YT's
  // player errors out (blank) if you try — so only VOD ids are looped.
  function ytEmbed(id, live) {
// §.splinter/home/dot_config/wp-stat-overlay/wallpaper/js/background/ytEmbed.fs
}

  // resolveYouTubeLive — channel "live" URLs (youtube.com/@NASA/live,
  // youtube.com/nasa/live, /c/x/live, /user/x/live) carry no video id, so we
  // can't build an /embed link from them here. The helper fetches the page
  // server-side (no CORS wall) and reads out the current live videoId; cb(id) on
  // success, cb(null, err) otherwise.
  function resolveYouTubeLive(url, cb) {
// §.splinter/home/dot_config/wp-stat-overlay/wallpaper/js/background/resolveYouTubeLive.fs
}

  // toEmbed — turn a pasted page URL into something that actually embeds and
  // plays as a wallpaper. Watch/share URLs don't embed; their player URLs do.
  function toEmbed(url) {
// §.splinter/home/dot_config/wp-stat-overlay/wallpaper/js/background/toEmbed.fs
}

  // buildWeb — pick the right element for a pasted URL and return it (+ a note).
  function buildWeb(url) {
// §.splinter/home/dot_config/wp-stat-overlay/wallpaper/js/background/buildWeb.fs
}

  function clear() {
// §.splinter/home/dot_config/wp-stat-overlay/wallpaper/js/background/clear.fs
}

  function rebuild() {
// §.splinter/home/dot_config/wp-stat-overlay/wallpaper/js/background/rebuild.fs
}

  window.WP_BG = {
    // apply(type, value): set the single active background and rebuild if changed.
    apply: function (type, value) {
      type = type || "none";
      value = value || "";
      if (type === state.type && value === state.value) return;
      state.type = type;
      state.value = value;
      rebuild();
    },
    // setHelper(base): point /file routing at the same host as the stats helper.
    setHelper: function (base) {
      base = String(base || "").replace(/\/+$/, "");
      if (!base || base === helperBase) return;
      helperBase = base;
      if (state.type === "image" || state.type === "video") rebuild();
    }
  };
})();
