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
    if (msg) console.log("[wp-bg] " + msg);
    if (!bgstatus) return;
    if (!msg) { bgstatus.hidden = true; bgstatus.textContent = ""; return; }
    bgstatus.hidden = false;
    bgstatus.textContent = msg;
    bgstatus.style.color = isError ? "rgba(255,140,120,0.95)" : "rgba(140,255,170,0.85)";
  }

  // resolveMedia — for <img>/<video>, a local file in another folder is blocked
  // by Chromium from a file:// origin, so route absolute local paths through the
  // helper's /file endpoint (an http origin). Remote URLs and in-project relative
  // paths load directly.
  // stripQuotes — paths pasted from a file manager (Windows "Copy as path",
  // shells) arrive wrapped in surrounding quotes; drop a matching pair so the
  // path resolves instead of being treated as a literal quoted string.
  function stripQuotes(s) {
    s = String(s == null ? "" : s).trim();
    if (s.length >= 2) {
      var q = s.charAt(0);
      if ((q === '"' || q === "'") && s.charAt(s.length - 1) === q) {
        s = s.slice(1, -1).trim();
      }
    }
    return s;
  }

  function resolveMedia(value, endpoint) {
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
  }

  // playVideo — mount a local/remote video. Local files go through /video, which
  // may transcode mp4→webm (WE's Chromium lacks H.264); while that runs the
  // helper returns 503, so we poll until the cached webm is ready. The token
  // guards against the background being switched mid-transcode.
  function playVideo(value, myToken) {
    var url = resolveMedia(value, "/video");
    if (!url) { report("video selected but no file set", true); return; }

    function mount() {
      if (myToken !== token) return;
      var v = document.createElement("video");
      v.autoplay = true; v.loop = true; v.muted = true; v.playsInline = true;
      v.addEventListener("canplay", function () { v.play().catch(function () {}); report(""); });
      v.addEventListener("error", function () { report("video failed to play (codec?): " + url, true); });
      bg.appendChild(v);
      v.src = url;
      if (window.WP_FX) window.WP_FX.setSource(v);
    }

    var isHelper = url.indexOf(helperBase + "/video") === 0;
    if (!isHelper) { mount(); report("loading video…"); return; }

    report("preparing video…");
    (function probe() {
      if (myToken !== token) return;
      fetch(url, { method: "HEAD", cache: "no-store" }).then(function (res) {
        if (myToken !== token) return;
        if (res.ok) { mount(); }
        else if (res.status === 503) { report("transcoding mp4 → webm (first load only)…"); setTimeout(probe, 2500); }
        else { res.text().then(function (t) { report("video error " + res.status + ": " + (t || ""), true); }); }
      }).catch(function () {
        if (myToken !== token) return;
        report("helper unreachable for video — is wpstats running?", true);
        setTimeout(probe, 3000);
      });
    })();
  }

  // ytEmbed — the player URL for a known video id (looped, muted, chromeless).
  function ytEmbed(id) {
    return "https://www.youtube.com/embed/" + id +
      "?autoplay=1&mute=1&loop=1&playlist=" + id +
      "&controls=0&modestbranding=1&playsinline=1&rel=0&iv_load_policy=3&disablekb=1&fs=0";
  }

  // resolveYouTubeLive — channel "live" URLs (youtube.com/@NASA/live,
  // youtube.com/nasa/live, /c/x/live, /user/x/live) carry no video id, so we
  // can't build an /embed link from them here. The helper fetches the page
  // server-side (no CORS wall) and reads out the current live videoId; cb(id) on
  // success, cb(null, err) otherwise.
  function resolveYouTubeLive(url, cb) {
    var api = helperBase + "/yt?u=" + encodeURIComponent(url);
    fetch(api, { cache: "no-store" }).then(function (r) {
      if (!r.ok) { r.text().then(function (t) { cb(null, "helper " + r.status + (t ? " " + t.trim() : "")); }); return null; }
      return r.json();
    }).then(function (j) {
      if (j) cb(j.videoId || null, j.videoId ? null : "no live video");
    }).catch(function () {
      cb(null, "helper unreachable — is wpstats running?");
    });
  }

  // toEmbed — turn a pasted page URL into something that actually embeds and
  // plays as a wallpaper. Watch/share URLs don't embed; their player URLs do.
  function toEmbed(url) {
    // direct video id: watch / shorts / embed / live/<id> / youtu.be
    var yt = url.match(/(?:youtube\.com\/(?:watch\?(?:.*&)?v=|shorts\/|embed\/|live\/)|youtu\.be\/)([\w-]{11})/i);
    if (yt) return { kind: "youtube", src: ytEmbed(yt[1]) };

    // channel live by channel id: youtube.com/channel/UC.../live → live_stream
    var ytCh = url.match(/youtube\.com\/channel\/(UC[\w-]{22})\/live/i);
    if (ytCh) {
      return {
        kind: "youtube",
        src: "https://www.youtube.com/embed/live_stream?channel=" + ytCh[1] +
          "&autoplay=1&mute=1&controls=0&modestbranding=1&playsinline=1&rel=0&iv_load_policy=3&disablekb=1&fs=0"
      };
    }

    // channel live by handle/custom name: youtube.com/@NASA/live, /nasa/live,
    // /c/x/live, /user/x/live — no id in the URL, resolve via the helper.
    var ytLive = url.match(/youtube\.com\/(?:@|c\/|user\/)?[\w.-]+\/live\/?(?:$|\?)/i);
    if (ytLive) return { kind: "youtube-resolve", src: url };

    var vm = url.match(/vimeo\.com\/(?:video\/)?(\d+)/i);
    if (vm) {
      return {
        kind: "vimeo",
        src: "https://player.vimeo.com/video/" + vm[1] +
          "?autoplay=1&muted=1&loop=1&background=1"
      };
    }
    return { kind: "page", src: url };
  }

  // buildWeb — pick the right element for a pasted URL and return it (+ a note).
  function buildWeb(url) {
    if (/\.(mp4|webm|ogv|ogg|mov|m4v)(\?|#|$)/i.test(url)) {
      var v = document.createElement("video");
      v.src = url; v.autoplay = true; v.loop = true; v.muted = true; v.playsInline = true; v.crossOrigin = "anonymous";
      v.addEventListener("canplay", function () { v.play().catch(function () {}); report(""); });
      v.addEventListener("error", function () { report("video URL failed (CORS or bad link): " + url, true); });
      return { el: v, note: "loading video URL…" };
    }
    if (/\.(jpe?g|png|gif|webp|avif|bmp|svg)(\?|#|$)/i.test(url)) {
      var img = document.createElement("img");
      img.onload = function () { report(""); };
      img.onerror = function () { report("image URL failed: " + url, true); };
      img.src = url;
      return { el: img, note: "loading image URL…" };
    }
    var e = toEmbed(url);
    var f = document.createElement("iframe");
    f.setAttribute("scrolling", "no");
    f.allow = "autoplay; fullscreen; encrypted-media; picture-in-picture";
    f.onload = function () {
      // A cross-origin page that refuses framing (X-Frame-Options/CSP) still
      // fires onload but renders blank — we can't read it to confirm. Clear the
      // note for media embeds; warn gently for arbitrary pages.
      report(e.kind === "page" ? "" : "");
    };
    if (e.kind === "youtube-resolve") {
      // No id in the URL yet — ask the helper, then point the iframe at the
      // live player once it answers.
      resolveYouTubeLive(url, function (id, err) {
        if (id) { f.src = ytEmbed(id); report(""); }
        else { report("couldn't resolve YouTube live (" + (err || "no live video") + "): " + url, true); }
      });
      return { el: f, note: "resolving YouTube live stream…" };
    }
    f.src = e.src;
    return { el: f, note: "loading " + e.kind + "…" };
  }

  function clear() {
    while (bg.firstChild) bg.removeChild(bg.firstChild);
  }

  function rebuild() {
    clear();
    // Reset the shader layer up front; the image/video branches re-attach it to
    // the new source. web / none / error paths simply leave it dormant.
    if (window.WP_FX) window.WP_FX.setSource(null);
    token++; // invalidate any in-flight transcode polling from a prior source
    var myToken = token;
    // images go through the helper when local; video is handled by playVideo
    // (transcode-aware); web is handled in its own branch (smart embedding).
    var src = state.type === "image" ? resolveMedia(state.value) : "";
    switch (state.type) {
      case "video":
        playVideo(state.value, myToken);
        break;
      case "image":
        if (!src) { report("image selected but no file set", true); return; }
        var img = document.createElement("img");
        img.onload = function () { report(""); };
        img.onerror = function () { report("image blocked/not found: " + src, true); };
        img.src = src;
        bg.appendChild(img);
        if (window.WP_FX) window.WP_FX.setSource(img);
        report("loading image…");
        break;
      case "web":
        var url = stripQuotes(state.value);
        if (!url) { report("web selected but no URL set", true); return; }
        var web = buildWeb(url);
        bg.appendChild(web.el);
        report(web.note || "loading web…");
        break;
      case "none":
      default:
        report("");
        break; // transparent
    }
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
