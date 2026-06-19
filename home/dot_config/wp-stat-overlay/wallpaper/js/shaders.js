// shaders.js — optional WebGL post-processing layer for the background.
//
// The background (#bg) holds the active media: an <img> or <video> for local /
// remote files, or an <iframe> for web pages. When at least one shader effect
// is enabled AND the source is a sampleable element (img / video — never an
// iframe, which is cross-origin and cannot be read into WebGL), this module:
//   1. mounts a <canvas> inside #bg,
//   2. uploads each video frame (or the still image) to a texture,
//   3. runs a single fullscreen fragment-shader pass that applies every enabled
//      effect in sequence, gated by per-effect uniforms,
//   4. hides the raw media so only the shaded canvas shows.
// When no effect is on, or the source can't be sampled, it tears the canvas
// down and the raw media shows directly — zero WebGL cost in the common case.
//
// CSS blur / brightness / opacity stay on #bg (the canvas's parent), so they
// still apply on top of the shader output without extra plumbing.
//
// Cross-origin note: local files routed through the helper's http origin taint
// the texture; texImage2D then throws. We catch that, disable the effects for
// that source, and report it instead of crashing — the raw media still shows.
(function () {
  "use strict";

  var VERT = [
    "attribute vec2 a_pos;",
    "varying vec2 v_uv;",
    "void main(){",
    "  v_uv = a_pos * 0.5 + 0.5;",
    "  gl_Position = vec4(a_pos, 0.0, 1.0);",
    "}"
  ].join("\n");

  // Single pass: each effect has its OWN strength uniform (0 = off, 1 = full).
  // Effects are applied in an order that reads well visually: geometry/UV
  // distortions first, then sampling, then color/film grading.
  var FRAG = [
    "precision highp float;",
    "varying vec2 v_uv;",
    "uniform sampler2D u_tex;",
    "uniform vec2 u_res;",      // canvas pixel size
    "uniform vec2 u_cover;",    // object-fit: cover crop scale (<=1 per axis)
    "uniform float u_time;",
    "uniform float u_chroma, u_grain, u_vhs, u_ripple, u_vignette, u_pixelate, u_glitch;", // per-effect strengths
    "",
    "float hash(vec2 p){ return fract(sin(dot(p, vec2(127.1,311.7))) * 43758.5453); }",
    "",
    "void main(){",
    "  vec2 uv = (v_uv - 0.5) * u_cover + 0.5;",  // emulate object-fit: cover
    "  float t = u_time;",
    "",
    "  if (u_pixelate > 0.0) {",
    "    float bs = mix(2.0, 14.0, u_pixelate);",  // block size in px
    "    vec2 grid = max(u_res / bs, vec2(1.0));",
    "    uv = (floor(uv * grid) + 0.5) / grid;",
    "  }",
    "",
    "  if (u_ripple > 0.0) {",
    "    float amp = 0.006 * u_ripple;",
    "    uv.x += sin(uv.y * 40.0 + t * 2.0) * amp;",
    "    uv.y += cos(uv.x * 40.0 + t * 1.7) * amp;",
    "  }",
    "",
    "  if (u_glitch > 0.0) {",
    "    float band = floor(uv.y * 24.0);",
    "    float n = hash(vec2(band, floor(t * 12.0)));",
    "    uv.x += step(0.96 - 0.3 * u_glitch, n) * (n - 0.5) * 0.12 * u_glitch;",
    "  }",
    "",
    "  vec3 col;",
    "  if (u_chroma > 0.0) {",
    "    vec2 dir = uv - 0.5;",
    "    float off = 0.004 * u_chroma;",
    "    col.r = texture2D(u_tex, uv + dir * off).r;",
    "    col.g = texture2D(u_tex, uv).g;",
    "    col.b = texture2D(u_tex, uv - dir * off).b;",
    "  } else {",
    "    col = texture2D(u_tex, uv).rgb;",
    "  }",
    "",
    "  if (u_vhs > 0.0) {",
    "    col *= 1.0 - sin(uv.y * u_res.y * 1.5) * 0.06 * u_vhs;",        // scanlines
    "    col += step(0.995, hash(vec2(floor(t * 30.0), floor(uv.y * 120.0)))) * 0.15 * u_vhs;", // dropout lines
    "    col.r *= 1.0 + 0.05 * u_vhs;",                                  // warm bleed
    "  }",
    "",
    "  if (u_grain > 0.0) {",
    "    col += (hash(uv * u_res + t * 60.0) - 0.5) * 0.13 * u_grain;",
    "  }",
    "",
    "  if (u_vignette > 0.0) {",
    "    float v = smoothstep(0.85, 0.35, length(uv - 0.5) * 1.4);",
    "    col *= mix(1.0, v, u_vignette);",
    "  }",
    "",
    "  gl_FragColor = vec4(col, 1.0);",
    "}"
  ].join("\n");

  // Effect uniform names, in the order properties.js feeds strengths.
  var EFFECTS = ["chroma", "grain", "vhs", "ripple", "vignette", "pixelate", "glitch"];

  var bg = document.getElementById("bg");
  var canvas = null, gl = null, prog = null, tex = null;
  var uni = {};                       // cached uniform locations
  var source = null;                  // the <img> / <video> being sampled
  var sourceKind = "";                // "img" | "video"
  var strength = {};                  // per-effect 0..1, e.g. { chroma: 0.5, ... }
  var raf = 0;
  var start = 0;                      // first-frame timestamp, for u_time
  var warned = false;                 // tainted-source notice, shown once

  function anyEnabled() {
    for (var i = 0; i < EFFECTS.length; i++) if (strength[EFFECTS[i]] > 0) return true;
    return false;
  }

  function compile(type, src) {
    var s = gl.createShader(type);
    gl.shaderSource(s, src);
    gl.compileShader(s);
    if (!gl.getShaderParameter(s, gl.COMPILE_STATUS)) {
      console.log("[wp-fx] shader compile failed: " + gl.getShaderInfoLog(s));
      gl.deleteShader(s);
      return null;
    }
    return s;
  }

  // Build the canvas + GL program lazily, the first time effects are needed.
  function initGL() {
    if (gl) return true;
    canvas = document.createElement("canvas");
    gl = canvas.getContext("webgl", { premultipliedAlpha: false }) ||
         canvas.getContext("experimental-webgl");
    if (!gl) { console.log("[wp-fx] WebGL unavailable; effects disabled"); return false; }

    var vs = compile(gl.VERTEX_SHADER, VERT), fs = compile(gl.FRAGMENT_SHADER, FRAG);
    if (!vs || !fs) { gl = null; return false; }
    prog = gl.createProgram();
    gl.attachShader(prog, vs); gl.attachShader(prog, fs); gl.linkProgram(prog);
    if (!gl.getProgramParameter(prog, gl.LINK_STATUS)) {
      console.log("[wp-fx] link failed: " + gl.getProgramInfoLog(prog));
      gl = null; return false;
    }
    gl.useProgram(prog);

    var buf = gl.createBuffer();
    gl.bindBuffer(gl.ARRAY_BUFFER, buf);
    gl.bufferData(gl.ARRAY_BUFFER, new Float32Array([-1,-1, 3,-1, -1,3]), gl.STATIC_DRAW);
    var loc = gl.getAttribLocation(prog, "a_pos");
    gl.enableVertexAttribArray(loc);
    gl.vertexAttribPointer(loc, 2, gl.FLOAT, false, 0, 0);

    ["u_tex","u_res","u_cover","u_time",
     "u_chroma","u_grain","u_vhs","u_ripple","u_vignette","u_pixelate","u_glitch"]
      .forEach(function (n) { uni[n] = gl.getUniformLocation(prog, n); });

    tex = gl.createTexture();
    gl.bindTexture(gl.TEXTURE_2D, tex);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);
    return true;
  }

  // Intrinsic source size, for object-fit: cover emulation.
  function srcSize() {
    if (sourceKind === "video") return [source.videoWidth || 0, source.videoHeight || 0];
    return [source.naturalWidth || 0, source.naturalHeight || 0];
  }

  function sizeCanvas() {
    var dpr = Math.min(window.devicePixelRatio || 1, 1.5);
    var w = Math.round(window.innerWidth * dpr), h = Math.round(window.innerHeight * dpr);
    if (canvas.width !== w || canvas.height !== h) { canvas.width = w; canvas.height = h; }
  }

  function frame(ts) {
    if (!source) return;
    raf = requestAnimationFrame(frame);
    if (sourceKind === "video" && source.readyState < 2) return; // not enough data yet
    if (sourceKind === "img" && !source.complete) return;        // image still loading
    if (!start) start = ts;

    sizeCanvas();
    var cw = canvas.width, ch = canvas.height;
    gl.viewport(0, 0, cw, ch);

    try {
      gl.bindTexture(gl.TEXTURE_2D, tex);
      gl.pixelStorei(gl.UNPACK_FLIP_Y_WEBGL, true);
      gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, gl.RGBA, gl.UNSIGNED_BYTE, source);
    } catch (e) {
      // Cross-origin / tainted source — can't sample it. Bail out cleanly.
      if (!warned) {
        warned = true;
        console.log("[wp-fx] source is cross-origin; shader effects need CORS from the helper — showing raw media instead");
      }
      deactivate();
      return;
    }

    // object-fit: cover — crop the long axis so the texture fills without stretch.
    var sz = srcSize(), iw = sz[0], ih = sz[1], cover = [1, 1];
    if (iw > 0 && ih > 0) {
      var ca = cw / ch, ia = iw / ih;
      if (ia > ca) cover[0] = ca / ia; else cover[1] = ia / ca;
    }

    gl.uniform1i(uni.u_tex, 0);
    gl.uniform2f(uni.u_res, cw, ch);
    gl.uniform2f(uni.u_cover, cover[0], cover[1]);
    gl.uniform1f(uni.u_time, (ts - start) / 1000);
    EFFECTS.forEach(function (n) {
      gl.uniform1f(uni["u_" + n], strength[n] || 0);
    });

    gl.drawArrays(gl.TRIANGLES, 0, 3);
  }

  // Show the shaded canvas, hide the raw media, start the loop.
  function activate() {
    if (!source) return;
    if (!initGL()) return;
    if (canvas.parentNode !== bg) bg.appendChild(canvas);
    source.style.visibility = "hidden"; // keep it in the DOM so it keeps decoding
    start = 0;
    if (!raf) raf = requestAnimationFrame(frame);
  }

  // Stop the loop, drop the canvas, reveal the raw media again.
  function deactivate() {
    if (raf) { cancelAnimationFrame(raf); raf = 0; }
    if (canvas && canvas.parentNode === bg) bg.removeChild(canvas);
    if (source) source.style.visibility = "";
  }

  // Decide active vs dormant from the current source + effect strengths.
  function reconcile() {
    if (source && anyEnabled()) activate();
    else deactivate();
  }

  window.WP_FX = {
    // setSource(el): el is the <img>/<video> background just built, or null for
    // web/none sources (nothing to sample). background.js calls this on rebuild.
    setSource: function (el) {
      deactivate();
      warned = false;
      if (el && (el.tagName === "IMG" || el.tagName === "VIDEO")) {
        source = el;
        sourceKind = el.tagName === "VIDEO" ? "video" : "img";
      } else {
        source = null; sourceKind = "";
      }
      reconcile();
    },
    // setEffects(strengths): per-effect 0..1, e.g. { chroma: 0.5, vhs: 1 }.
    // An effect at 0 (or absent) is off. From properties.js.
    setEffects: function (strengths) {
      strength = strengths || {};
      reconcile();
    }
  };
})();
