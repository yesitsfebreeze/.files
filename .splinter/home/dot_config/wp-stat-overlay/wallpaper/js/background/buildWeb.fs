// §head home/dot_config/wp-stat-overlay/wallpaper/js/background.js:160-196 buildWeb
// §sig function buildWeb(url)
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
      // Clear the loading note once framed. A cross-origin page that refuses
      // framing (X-Frame-Options/CSP) still fires onload but renders blank — we
      // can't read it to confirm, so there's nothing more to report either way.
      report("");
    };
    if (e.kind === "youtube-resolve") {
      // No id in the URL yet — ask the helper, then point the iframe at the
      // live player once it answers.
      resolveYouTubeLive(url, function (id, err) {
        if (id) { f.src = ytEmbed(id, true); report(""); }
        else { report("couldn't resolve YouTube live (" + (err || "no live video") + "): " + url, true); }
      });
      return { el: f, note: "resolving YouTube live stream…" };
    }
    f.src = e.src;
    return { el: f, note: "loading " + e.kind + "…" };
// §foot home/dot_config/wp-stat-overlay/wallpaper/js/background.js buildWeb