// stats.js — polls the wpstats helper for a JSON snapshot once a second and
// renders the overlay. Also measures wallpaper render FPS locally.
(function () {
  "use strict";

  var url = "http://localhost:8787/stats";
  var POLL_MS = 1000;     // target cadence
  var FETCH_TIMEOUT = 2500; // abort a hung request before it stalls the cadence
  var pollTimer = null;
  var failStreak = 0;
  var inFlight = false;   // guard: never let a slow/hung fetch stack up another

  var el = function (id) { return document.getElementById(id); };
  var statusEl = el("status");

  // ---- formatters ----
  function bytes(n) {
    if (!n && n !== 0) return "—";
    var u = ["B", "KB", "MB", "GB", "TB"], i = 0;
    while (n >= 1024 && i < u.length - 1) { n /= 1024; i++; }
    return (i === 0 ? n.toFixed(0) : n.toFixed(1)) + " " + u[i];
  }
  function rate(n) { return bytes(n) + "/s"; }
  function pct(n) { return (n != null ? n.toFixed(0) : "—") + "%"; }
  function pad(n) { return String(n).padStart(2, "0"); }
  function dur(s) {
    s = Math.floor(s || 0);
    var d = Math.floor(s / 86400); s -= d * 86400;
    var h = Math.floor(s / 3600);  s -= h * 3600;
    var m = Math.floor(s / 60);
    if (d > 0) return d + "d " + h + "h";
    if (h > 0) return h + "h " + m + "m";
    return m + "m";
  }

  // ---- render ----
  var coresBuilt = 0;
  function ensureCores(n) {
    var box = el("cores");
    if (coresBuilt === n) return;
    box.innerHTML = "";
    for (var i = 0; i < n; i++) {
      var c = document.createElement("div");
      c.className = "core";
      var fill = document.createElement("i");
      c.appendChild(fill);
      box.appendChild(c);
    }
    coresBuilt = n;
  }

  function setBar(id, percent) {
    var b = el(id);
    if (b) b.style.width = Math.max(0, Math.min(100, percent || 0)) + "%";
  }

  function render(s) {
    // clock
    var now = s.time ? new Date(s.time * 1000) : new Date();
    el("clock").textContent = pad(now.getHours()) + ":" + pad(now.getMinutes()) + ":" + pad(now.getSeconds());
    el("date").textContent = now.toLocaleDateString(undefined, { weekday: "short", month: "short", day: "numeric" });
    el("uptime").textContent = "up " + dur(s.uptime);

    // cpu + ram
    el("cpu").textContent = pct(s.cpu);
    setBar("cpuBar", s.cpu);
    el("mem").textContent = bytes(s.memUsed) + " / " + bytes(s.memTotal) + "  (" + pct(s.memPercent) + ")";
    setBar("memBar", s.memPercent);

    if (s.cpuTemp) {
      el("cpuTempRow").hidden = false;
      el("cpuTemp").textContent = s.cpuTemp.toFixed(0) + " °C";
    } else {
      el("cpuTempRow").hidden = true;
    }

    // per-core bars
    if (s.cpuCore && s.cpuCore.length) {
      ensureCores(s.cpuCore.length);
      var box = el("cores");
      var horiz = box.classList.contains("horizontal"); // bars grow by width, not height
      var fills = box.querySelectorAll(".core > i");
      for (var i = 0; i < fills.length; i++) {
        var v = Math.max(0, Math.min(100, s.cpuCore[i] || 0)) + "%";
        // clear the inactive axis so a leftover inline value can't fight the CSS
        fills[i].style.height = horiz ? "" : v;
        fills[i].style.width = horiz ? v : "";
      }
    }

    // net + disk
    el("netDown").textContent = rate(s.netDown);
    el("netUp").textContent = rate(s.netUp);
    el("diskRead").textContent = rate(s.diskRead);
    el("diskWrite").textContent = rate(s.diskWrite);

    // gpu — populate data and record availability; visibility is resolved by
    // applyShow() (user toggle AND data present).
    window.WP_GPU_PRESENT = !!s.gpu;
    if (s.gpu) {
      el("gpuName").textContent = s.gpu.name || "GPU";
      el("gpu").textContent = pct(s.gpu.usage);
      setBar("gpuBar", s.gpu.usage);
      el("vram").textContent = bytes(s.gpu.memUsed) + " / " + bytes(s.gpu.memTotal);
      setBar("vramBar", s.gpu.memTotal ? (s.gpu.memUsed / s.gpu.memTotal) * 100 : 0);
      el("gpuTemp").textContent = s.gpu.temp ? s.gpu.temp.toFixed(0) + " °C" : "—";
    }
  }

  function poll() {
    // skip this tick if the previous request is still outstanding — keeps the
    // cadence regular instead of stacking overlapping in-flight fetches
    if (inFlight) return;
    inFlight = true;

    // abort a request that outlives the timeout so it can't wedge the loop
    var ctl = (typeof AbortController !== "undefined") ? new AbortController() : null;
    var killer = ctl ? setTimeout(function () { ctl.abort(); }, FETCH_TIMEOUT) : null;

    fetch(url, { cache: "no-store", signal: ctl ? ctl.signal : undefined })
      .then(function (r) { if (!r.ok) throw new Error("HTTP " + r.status); return r.json(); })
      .then(function (s) {
        failStreak = 0;
        statusEl.className = "status ok";
        render(s);
        // re-apply group visibility (GPU availability can change between polls)
        if (window.WP_APPLY_SHOW) window.WP_APPLY_SHOW();
      })
      .catch(function (e) {
        failStreak++;
        if (failStreak >= 2) {
          statusEl.className = "status";
          statusEl.textContent = "helper offline — run wpstats (" + url + ")";
        }
      })
      .then(function () {
        if (killer) clearTimeout(killer);
        inFlight = false;
      });
  }

  function restart() {
    if (pollTimer) clearInterval(pollTimer);
    poll();
    pollTimer = setInterval(poll, POLL_MS);
  }

  // re-sync the moment the wallpaper regains focus or the network returns,
  // instead of waiting out the rest of the interval
  function kick() { inFlight = false; poll(); }
  document.addEventListener("visibilitychange", function () {
    if (!document.hidden) kick();
  });
  window.addEventListener("online", kick);

  // ---- FPS meter ----
  var frames = 0, lastFpsT = performance.now();
  function loop(t) {
    frames++;
    if (t - lastFpsT >= 1000) {
      var fps = Math.round((frames * 1000) / (t - lastFpsT));
      var f = el("fps");
      if (f) f.textContent = fps;
      frames = 0;
      lastFpsT = t;
    }
    requestAnimationFrame(loop);
  }
  requestAnimationFrame(loop);

  window.WP_STATS = {
    setUrl: function (u) { if (u && u !== url) { url = u; restart(); } }
  };

  restart();
})();
