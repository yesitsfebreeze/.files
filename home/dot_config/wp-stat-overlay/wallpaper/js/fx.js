// fx.js — CSS/SVG post-processing layer for the whole screen.
//
// Replaces the old WebGL shaders.js. WebGL could only ever sample <img>/<video>
// into a texture; a cross-origin <iframe> (a web page, a YouTube embed, another
// live wallpaper we wrap) taints the texture and can't be read. A CSS/SVG filter
// has no such limit: the browser composites the iframe layer and then warps it,
// so the SAME effects land on every background source AND on the stats overlay.
//
// Effects split by how they have to touch the pixels:
//   • Optical / geometric (must warp the real content) live in the SVG #crt
//     filter applied to #screen: water RIPPLE, CHROMA split.
//   • Additive screen-space overlays live as CSS layers inside #screen:
//     GRAIN, SCANLINES (vhs), VIGNETTE. fx.js only sets their opacity via CSS
//     vars; their look/animation is in style.css.
//
// The expensive SVG filter is detached entirely (filter:none) whenever every
// optical effect is at 0, so the common "no ripple/chroma" case is free.
(function () {
  "use strict";

  // Strength -> magnitude mappings (full strength = these, in CSS px / unitless).
  var MAX_RIPPLE = 22;   // feDisplacementMap scale for the water warp
  var MAX_CHROMA = 6;    // feOffset px the R/B channels split apart

  var screen   = document.getElementById("screen");
  var ripple   = document.getElementById("fx-ripple");
  var rnoise   = document.getElementById("fx-ripple-noise");
  var chromaR  = document.getElementById("fx-chroma-r");
  var chromaB  = document.getElementById("fx-chroma-b");

  var strength = {};   // last-applied per-effect 0..1
  var rippleRaf = 0;   // animation handle for the live water warp

  // ---- live water ripple --------------------------------------------------
  // SVG turbulence is static per seed; oscillate its base frequency so the warp
  // breathes like water. Only runs while ripple > 0.
  function stepRipple(t) {
    if (!(strength.ripple > 0)) { rippleRaf = 0; return; }
    var f = 0.010 + 0.004 * Math.sin(t / 1400);
    rnoise.setAttribute("baseFrequency", f.toFixed(5));
    rippleRaf = requestAnimationFrame(stepRipple);
  }

  // optical effects that require the SVG filter to be mounted
  function opticalActive() {
    return (strength.ripple > 0) || (strength.chroma > 0);
  }

  function apply() {
    var ri = strength.ripple || 0;
    var ch = strength.chroma || 0;

    ripple.setAttribute("scale", (ri * MAX_RIPPLE).toFixed(2));
    var dx = (ch * MAX_CHROMA).toFixed(2);
    chromaR.setAttribute("dx", dx);
    chromaB.setAttribute("dx", (-ch * MAX_CHROMA).toFixed(2));

    // mount/unmount the whole filter so it costs nothing when fully off
    screen.style.filter = opticalActive() ? "url(#crt)" : "none";

    // additive overlays — opacity only; look + animation live in style.css
    var root = document.documentElement.style;
    root.setProperty("--fx-grain",    String(strength.grain    || 0));
    root.setProperty("--fx-scanline", String(strength.vhs      || 0));
    root.setProperty("--fx-vignette", String(strength.vignette || 0));

    if (ri > 0 && !rippleRaf) rippleRaf = requestAnimationFrame(stepRipple);
  }

  apply(); // start clean (all 0 -> filter:none)

  window.WP_FX = {
    // setSource(el): kept for API compatibility with background.js. Unlike the
    // WebGL version, the CSS/SVG filter applies to #screen regardless of source
    // type, so there is nothing to bind — web/iframe sources get effects too.
    setSource: function () {},

    // setEffects(strengths): per-effect 0..1, keys
    // chroma | grain | vhs | ripple | vignette. Absent/0 = off.
    setEffects: function (strengths) {
      strength = strengths || {};
      apply();
    }
  };
})();
