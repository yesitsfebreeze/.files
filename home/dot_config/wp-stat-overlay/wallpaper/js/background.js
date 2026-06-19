// background.js — builds the wrapped background layer (#bg) from the chosen
// source. Blur / brightness / opacity are CSS variables driven by properties.js;
// this module only swaps the media element.
(function () {
  "use strict";

  var bg = document.getElementById("bg");
  var state = { type: "none", video: "", image: "", web: "" };

  // WE file properties arrive as paths relative to the wallpaper folder, or as
  // absolute "file:///..." in some cases. Normalize lightly; leave URLs alone.
  function toSrc(p) {
    if (!p) return "";
    if (/^(https?:|file:|data:)/i.test(p)) return p;
    return p; // relative path inside the wallpaper package
  }

  function clear() {
    while (bg.firstChild) bg.removeChild(bg.firstChild);
  }

  function rebuild() {
    clear();
    switch (state.type) {
      case "video": {
        var src = toSrc(state.video);
        if (!src) return;
        var v = document.createElement("video");
        v.src = src;
        v.autoplay = true;
        v.loop = true;
        v.muted = true;
        v.playsInline = true;
        v.addEventListener("canplay", function () { v.play().catch(function () {}); });
        bg.appendChild(v);
        break;
      }
      case "image": {
        var isrc = toSrc(state.image);
        if (!isrc) return;
        var img = document.createElement("img");
        img.src = isrc;
        bg.appendChild(img);
        break;
      }
      case "web": {
        var wsrc = toSrc(state.web);
        if (!wsrc) return;
        var f = document.createElement("iframe");
        f.src = wsrc;
        f.setAttribute("scrolling", "no");
        f.allow = "autoplay; fullscreen";
        bg.appendChild(f);
        break;
      }
      case "none":
      default:
        // transparent — nothing to render
        break;
    }
  }

  window.WP_BG = {
    setType: function (t) {
      if (t && t !== state.type) { state.type = t; rebuild(); }
    },
    setVideo: function (p) { if (p !== state.video) { state.video = p; if (state.type === "video") rebuild(); } },
    setImage: function (p) { if (p !== state.image) { state.image = p; if (state.type === "image") rebuild(); } },
    setWeb:   function (p) { if (p !== state.web)   { state.web = p;   if (state.type === "web")   rebuild(); } }
  };
})();
