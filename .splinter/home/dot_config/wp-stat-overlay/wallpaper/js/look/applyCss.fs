// §head home/dot_config/wp-stat-overlay/wallpaper/js/look.js:36-40 applyCss
// §sig function applyCss(name)
    var v = target(name);
    if (typeof v === "undefined") return;
    root.style.setProperty(CSS[name].v, CSS[name].f(v));
// §foot home/dot_config/wp-stat-overlay/wallpaper/js/look.js applyCss