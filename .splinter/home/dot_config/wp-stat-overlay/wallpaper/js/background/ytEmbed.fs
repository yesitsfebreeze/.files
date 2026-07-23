// §head home/dot_config/wp-stat-overlay/wallpaper/js/background.js:105-108 ytEmbed
// §sig function ytEmbed(id, live)
    var src = "https://www.youtube.com/embed/" + id + "?" + YT_PARAMS;
    return live ? src : src + "&loop=1&playlist=" + id;
// §foot home/dot_config/wp-stat-overlay/wallpaper/js/background.js ytEmbed