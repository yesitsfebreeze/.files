// §head home/dot_config/wp-stat-overlay/wallpaper/js/typing.js:72-76 restart
// §sig function restart()
    if (timer) clearInterval(timer);
    tick();
    timer = setInterval(tick, POLL_MS);
// §foot home/dot_config/wp-stat-overlay/wallpaper/js/typing.js restart