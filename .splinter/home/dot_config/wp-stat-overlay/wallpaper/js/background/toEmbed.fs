// §head home/dot_config/wp-stat-overlay/wallpaper/js/background.js:129-157 toEmbed
// §sig function toEmbed(url)
    // direct video id: watch / shorts / embed / live/<id> / youtu.be
    var yt = url.match(/(?:youtube\.com\/(?:watch\?(?:.*&)?v=|shorts\/|embed\/|live\/)|youtu\.be\/)([\w-]{11})/i);
    if (yt) return { kind: "youtube", src: ytEmbed(yt[1], /\/live\//i.test(url)) };

    // channel live by channel id: youtube.com/channel/UC.../live → live_stream
    var ytCh = url.match(/youtube\.com\/channel\/(UC[\w-]{22})\/live/i);
    if (ytCh) {
      return {
        kind: "youtube",
        src: "https://www.youtube.com/embed/live_stream?channel=" + ytCh[1] + "&" + YT_PARAMS
      };
    }

    // channel live by handle/custom name: youtube.com/@NASA/live, /nasa/live,
    // /c/x/live, /user/x/live — no id in the URL, resolve via the helper.
    var ytLive = url.match(/youtube\.com\/(?:@|c\/|user\/)?[\w.-]+\/live\/?(?:$|\?)/i);
    if (ytLive) return { kind: "youtube-resolve", src: url };

    var vm = url.match(/vimeo\.com\/(?:video\/)?(\d+)/i);
    if (vm) {
      return {
        kind: "vimeo",
        src: "https://player.vimeo.com/video/" + vm[1] +
          "?autoplay=1&muted=1&loop=1&background=1"
      };
    }
    return { kind: "page", src: url };
// §foot home/dot_config/wp-stat-overlay/wallpaper/js/background.js toEmbed