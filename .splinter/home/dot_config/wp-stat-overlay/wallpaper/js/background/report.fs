// §head home/dot_config/wp-stat-overlay/wallpaper/js/background.js:16-23 report
// §sig function report(msg, isError)
    if (msg) console.log("[wp-bg] " + msg);
    if (!bgstatus) return;
    if (!msg) { bgstatus.hidden = true; bgstatus.textContent = ""; return; }
    bgstatus.hidden = false;
    bgstatus.textContent = msg;
    bgstatus.style.color = isError ? "rgba(255,140,120,0.95)" : "rgba(140,255,170,0.85)";
// §foot home/dot_config/wp-stat-overlay/wallpaper/js/background.js report