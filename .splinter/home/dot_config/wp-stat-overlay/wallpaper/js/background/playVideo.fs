// §head home/dot_config/wp-stat-overlay/wallpaper/js/background.js:65-96 playVideo
// §sig function playVideo(value, myToken)
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
// §foot home/dot_config/wp-stat-overlay/wallpaper/js/background.js playVideo