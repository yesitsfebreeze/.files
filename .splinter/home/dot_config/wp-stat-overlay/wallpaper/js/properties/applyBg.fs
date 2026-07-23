// §head home/dot_config/wp-stat-overlay/wallpaper/js/properties.js:34-41 applyBg
// §sig function applyBg()
    var active = "none", value = "";
    ["image", "video", "web"].forEach(function (k) {
      if (bgEnabled[k]) { active = k; value = bgValue[k]; }
    });
    if (!value) active = "none";
    if (window.WP_BG) window.WP_BG.apply(active, value);
// §foot home/dot_config/wp-stat-overlay/wallpaper/js/properties.js applyBg