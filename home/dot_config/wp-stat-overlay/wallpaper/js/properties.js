// properties.js — bridges Wallpaper Engine user properties to the wallpaper.
// WE calls window.wallpaperPropertyListener.applyUserProperties(props) on load
// and whenever a slider/toggle changes. Each property arrives only when it
// changes, so we read p.<name>.value defensively.
(function () {
  "use strict";

  var root = document.documentElement;
  var overlay = document.getElementById("overlay");

  // Font: the default cross-platform stack, plus the user's combo/custom choice.
  var systemFont = '"Segoe UI", system-ui, -apple-system, sans-serif';
  var fontChoice = "system";
  var fontCustom = "";

  // Track which stat groups the user wants visible; resolved against data
  // availability (GPU) by applyShow().
  var show = { clock: true, cpu: true, cores: true, net: true, gpu: true, fps: true };
  window.WP_SHOW = show;

  function applyShow() {
    setGroup("clock", show.clock);
    setGroup("cpu", show.cpu);
    setGroup("net", show.net);
    setGroup("fps", show.fps);
    // GPU card shows only if the user wants it AND the helper reported a GPU.
    setGroup("gpu", show.gpu && window.WP_GPU_PRESENT === true);
    // per-core grid lives inside the CPU card
    var cores = document.getElementById("cores");
    if (cores) cores.hidden = !show.cores;
  }
  window.WP_APPLY_SHOW = applyShow;

  function setGroup(name, visible) {
    var card = document.querySelector('[data-group="' + name + '"]');
    if (card) card.hidden = !visible;
  }

  function weColor(v) {
    // WE color = "r g b" floats 0..1
    var p = String(v).split(" ").map(parseFloat);
    if (p.length < 3 || p.some(isNaN)) return null;
    var r = Math.round(p[0] * 255), g = Math.round(p[1] * 255), b = Math.round(p[2] * 255);
    return { rgb: "rgb(" + r + "," + g + "," + b + ")", dim: "rgba(" + r + "," + g + "," + b + ",0.25)" };
  }

  function has(p, k) { return p && p[k] && typeof p[k].value !== "undefined"; }

  // ---- background source (mutually exclusive checkboxes) ----
  // Exactly one of image/video/web is active. Checking one supersedes the
  // others; each source keeps its own value so toggling back is lossless.
  var bgEnabled = { image: false, video: false, web: false };
  var bgValue = { image: "", video: "", web: "" };
  var bgVideoPick = ""; // from the WE file picker (webm/ogg)
  var bgVideoPath = ""; // from the pasted path/URL box (mp4 ok)

  // Shader effects — each effect has its own strength (0 = off). Properties
  // arrive incrementally, so keep the full state here and re-send on any change.
  var fx = { chroma: 0, grain: 0, vhs: 0, ripple: 0, vignette: 0, pixelate: 0, glitch: 0 };
  var fxKeys = {
    fx_chroma: "chroma", fx_grain: "grain", fx_vhs: "vhs", fx_ripple: "ripple",
    fx_vignette: "vignette", fx_pixelate: "pixelate", fx_glitch: "glitch"
  };

  // Turning a source on clears the others, so only one is ever active.
  function bgToggle(kind, on) {
    if (on) { bgEnabled = { image: false, video: false, web: false }; bgEnabled[kind] = true; }
    else { bgEnabled[kind] = false; }
  }

  function applyBg() {
    var active = "none", value = "";
    ["image", "video", "web"].forEach(function (k) {
      if (bgEnabled[k]) { active = k; value = bgValue[k]; }
    });
    if (!value) active = "none";
    if (window.WP_BG) window.WP_BG.apply(active, value);
  }

  window.wallpaperPropertyListener = {
    applyUserProperties: function (p) {
      // accent
      if (has(p, "schemecolor")) {
        var c = weColor(p.schemecolor.value);
        if (c) { root.style.setProperty("--accent", c.rgb); root.style.setProperty("--accent-dim", c.dim); }
      }

      // font — "system" uses the default stack; "custom" reads fontcustom.
      if (has(p, "fontfamily") || has(p, "fontcustom")) {
        if (has(p, "fontfamily")) fontChoice = p.fontfamily.value;
        if (has(p, "fontcustom")) fontCustom = String(p.fontcustom.value).trim();
        var fam = systemFont;
        if (fontChoice === "custom") { if (fontCustom) fam = fontCustom; }
        else if (fontChoice && fontChoice !== "system") fam = fontChoice;
        root.style.setProperty("--font", fam);
      }

      // helper url — drives both stats polling and /file media routing
      if (has(p, "helperurl")) {
        var hu = String(p.helperurl.value).trim();
        if (window.WP_STATS) window.WP_STATS.setUrl(hu);
        if (window.WP_BG) window.WP_BG.setHelper(hu.replace(/\/stats\/?$/i, ""));
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
      if (has(p, "bgweburl")) bgValue.web   = String(p.bgweburl.value).trim();
      applyBg();

      // panel corner radius + background opacity
      if (has(p, "cardradius"))   root.style.setProperty("--card-radius", Number(p.cardradius.value) + "px");
      if (has(p, "panelopacity")) root.style.setProperty("--panel-opacity", Number(p.panelopacity.value) / 100);

      // background look — blur / brightness / opacity
      if (has(p, "blur"))       root.style.setProperty("--bg-blur", Number(p.blur.value) + "px");
      if (has(p, "brightness")) root.style.setProperty("--bg-brightness", Number(p.brightness.value) / 100);
      if (has(p, "bgopacity"))  root.style.setProperty("--bg-opacity", Number(p.bgopacity.value) / 100);

      // overlay look
      if (has(p, "show_overlay")) overlay.hidden = !p.show_overlay.value;
      if (has(p, "overlaycolor")) {
        var oc = weColor(p.overlaycolor.value);
        if (oc) root.style.setProperty("--overlay-color", oc.rgb);
      }
      if (has(p, "overlayopacity")) root.style.setProperty("--overlay-opacity", Number(p.overlayopacity.value) / 100);
      if (has(p, "overlayscale"))   root.style.setProperty("--overlay-scale", Number(p.overlayscale.value) / 100);
      if (has(p, "overlaypos")) {
        overlay.className = "pos-" + p.overlaypos.value;
      }

      // shader effects — each effect its own strength slider (0 = off)
      var fxChanged = false;
      for (var fk in fxKeys) {
        if (has(p, fk)) { fx[fxKeys[fk]] = Number(p[fk].value) / 100; fxChanged = true; }
      }
      if (fxChanged && window.WP_FX) window.WP_FX.setEffects(fx);

      // group toggles
      if (has(p, "show_cpu"))   show.cpu = !!p.show_cpu.value;
      if (has(p, "show_cores")) show.cores = !!p.show_cores.value;
      if (has(p, "cores_horizontal")) {
        var coresBox = document.getElementById("cores");
        if (coresBox) coresBox.classList.toggle("horizontal", !!p.cores_horizontal.value);
      }
      if (has(p, "show_net"))   show.net = !!p.show_net.value;
      if (has(p, "show_gpu"))   show.gpu = !!p.show_gpu.value;
      if (has(p, "show_clock")) show.clock = !!p.show_clock.value;
      if (has(p, "show_fps"))   show.fps = !!p.show_fps.value;
      applyShow();
    }
  };

  // Apply defaults immediately so the overlay looks right even before WE
  // pushes properties (and when opened as a plain web page for testing).
  applyShow();
})();
