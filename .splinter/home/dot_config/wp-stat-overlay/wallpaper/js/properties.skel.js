// §source home/dot_config/wp-stat-overlay/wallpaper/js/properties.js
// properties.js — bridges Wallpaper Engine user properties to the wallpaper.
// WE calls window.wallpaperPropertyListener.applyUserProperties(props) on load
// and whenever a slider/toggle changes. Each property arrives only when it
// changes, so we read p.<name>.value defensively.
(function () {
  "use strict";

  function has(p, k) {
// §.splinter/home/dot_config/wp-stat-overlay/wallpaper/js/properties/has.fs
}

  // ---- background source (mutually exclusive checkboxes) ----
  // Exactly one of image/video/web is active. Checking one supersedes the
  // others; each source keeps its own value so toggling back is lossless.
  var bgEnabled = { image: false, video: false, web: false };
  var bgValue = { image: "", video: "", web: "" };
  var bgVideoPick = ""; // from the WE file picker (webm/ogg)
  var bgVideoPath = ""; // from the pasted path/URL box (mp4 ok)

  // Look channels eased between a resting and a typing value by WP_LOOK.
  // Maps the WE property name -> WP_LOOK channel name. The typing variant is
  // "<weProp>_typing".
  var LOOK = {
    blur: "blur",
    brightness: "brightness",
    bgopacity: "opacity",
    zoom: "zoom",
    vignette: "vignette"
  };

  function bgToggle(kind, on) {
// §.splinter/home/dot_config/wp-stat-overlay/wallpaper/js/properties/bgToggle.fs
}

  function applyBg() {
// §.splinter/home/dot_config/wp-stat-overlay/wallpaper/js/properties/applyBg.fs
}

  window.wallpaperPropertyListener = {
    applyUserProperties: function (p) {
      // helper url — drives /file media routing and the keyboard-activity poll
      if (has(p, "helperurl")) {
        var hu = String(p.helperurl.value).trim();
        if (window.WP_BG) window.WP_BG.setHelper(hu.replace(/\/(stats|typing)\/?$/i, ""));
        if (window.WP_TYPING) window.WP_TYPING.setUrl(hu);
      }

      // background source — checkboxes (exclusive) + each source's value
      if (has(p, "bg_image")) bgToggle("image", !!p.bg_image.value);
      if (has(p, "bg_video")) bgToggle("video", !!p.bg_video.value);
      if (has(p, "bg_web"))   bgToggle("web",   !!p.bg_web.value);
      if (has(p, "bgimage"))  bgValue.image = p.bgimage.value;
      // video: a pasted path/URL (bgvideopath) wins over the webm-only picker,
      // so you can point at an mp4 the WE picker would filter out.
      if (has(p, "bgvideo"))     bgVideoPick = p.bgvideo.value;
      if (has(p, "bgvideopath")) bgVideoPath = String(p.bgvideopath.value).trim();
      if (has(p, "bgvideo") || has(p, "bgvideopath")) bgValue.video = bgVideoPath || bgVideoPick;
      if (has(p, "bgweburl")) bgValue.web = String(p.bgweburl.value).trim();
      applyBg();

      // look channels — feed WP_LOOK both the resting and the typing value;
      // "<name>_typing" is the typing variant. Eased transition time is
      // "typingease".
      if (window.WP_LOOK) {
        var L = window.WP_LOOK;
        for (var weProp in LOOK) {
          var ch = LOOK[weProp];
          if (has(p, weProp))            L.setIdle(ch, p[weProp].value);
          if (has(p, weProp + "_typing")) L.setTyping(ch, p[weProp + "_typing"].value);
        }
        if (has(p, "typingease")) L.setEase(p.typingease.value);
      }

      // typing timings: start delay (fade in) + revert delay (fade out)
      if (window.WP_TYPING) {
        if (has(p, "typingstartdelay"))  WP_TYPING.setStartDelay(p.typingstartdelay.value);
        if (has(p, "typingrevertdelay")) WP_TYPING.setRevertDelay(p.typingrevertdelay.value);
      }
    }
  };
})();
