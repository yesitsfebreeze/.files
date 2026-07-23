// §head home/dot_config/wp-stat-overlay/wallpaper/js/background.js:202-234 rebuild
// §sig function rebuild()
    clear();
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
// §foot home/dot_config/wp-stat-overlay/wallpaper/js/background.js rebuild