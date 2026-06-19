// properties.js — bridges Wallpaper Engine user properties to the wallpaper.
// WE calls window.wallpaperPropertyListener.applyUserProperties(props) on load
// and whenever a slider/toggle changes. Each property arrives only when it
// changes, so we read p.<name>.value defensively.
(function () {
  "use strict";

  var root = document.documentElement;
  var overlay = document.getElementById("overlay");

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

  window.wallpaperPropertyListener = {
    applyUserProperties: function (p) {
      // accent
      if (has(p, "schemecolor")) {
        var c = weColor(p.schemecolor.value);
        if (c) { root.style.setProperty("--accent", c.rgb); root.style.setProperty("--accent-dim", c.dim); }
      }

      // helper url
      if (has(p, "helperurl") && window.WP_STATS) window.WP_STATS.setUrl(String(p.helperurl.value).trim());

      // background source
      if (has(p, "bgtype")  && window.WP_BG) window.WP_BG.setType(p.bgtype.value);
      if (has(p, "bgvideo") && window.WP_BG) window.WP_BG.setVideo(p.bgvideo.value);
      if (has(p, "bgimage") && window.WP_BG) window.WP_BG.setImage(p.bgimage.value);
      if (has(p, "bgweburl")&& window.WP_BG) window.WP_BG.setWeb(String(p.bgweburl.value).trim());

      // background look — blur / brightness / opacity
      if (has(p, "blur"))       root.style.setProperty("--bg-blur", Number(p.blur.value) + "px");
      if (has(p, "brightness")) root.style.setProperty("--bg-brightness", Number(p.brightness.value) / 100);
      if (has(p, "bgopacity"))  root.style.setProperty("--bg-opacity", Number(p.bgopacity.value) / 100);

      // overlay look
      if (has(p, "overlayopacity")) root.style.setProperty("--overlay-opacity", Number(p.overlayopacity.value) / 100);
      if (has(p, "overlayscale"))   root.style.setProperty("--overlay-scale", Number(p.overlayscale.value) / 100);
      if (has(p, "overlaypos")) {
        overlay.className = "pos-" + p.overlaypos.value;
      }

      // group toggles
      if (has(p, "show_cpu"))   show.cpu = !!p.show_cpu.value;
      if (has(p, "show_cores")) show.cores = !!p.show_cores.value;
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
