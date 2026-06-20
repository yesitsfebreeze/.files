# Stat Overlay — a wrappable Wallpaper Engine stats wallpaper

A Wallpaper Engine **web wallpaper** that draws a live system-stats overlay
(CPU, per-core, RAM, GPU, net, disk, temps, clock, uptime, FPS) on top of *any*
background you point it at — a video file, another web wallpaper, or an image —
with **blur** and **brightness** controls exposed as native WE sliders.

```
dot_config/wp-stat-overlay/
  wallpaper/        the WE web wallpaper (project.json + HTML/CSS/JS)
  helper/           wpstats — a tiny Go stats agent (one file, gopsutil)
```

## How it works

WE web wallpapers run in a Chromium sandbox and **cannot read CPU/GPU/RAM
directly**. So `helper/` builds `wpstats`, a tiny agent that runs on the host and
serves a JSON snapshot at `http://localhost:8787/stats`. The wallpaper polls it
once a second and renders. That is what makes it work on *any* machine — the
helper is the portable, OS-aware piece (gopsutil for CPU/RAM/net/disk/temps,
`nvidia-smi` for GPU when present).

The background is a `#bg` layer holding a `<video>`, `<iframe>`, or `<img>`;
`blur` / `brightness` / `bgopacity` are CSS filters applied to it. "Wrap another
live wallpaper" = point the iframe at its `index.html` (or any web URL), or the
video layer at its `.mp4`/`.webm`.

**CRT effect layer (`fx.js`).** `#bg` and the stats overlay live together inside
`#screen`, and a CSS/SVG filter (`#crt`) plus three overlay layers post-process
that whole subtree — so chromatic aberration, water ripple, film grain,
scanlines/VHS and vignette land on the background **and** the overlay at
once. Because it's a CSS/SVG filter (not WebGL, which can only sample
`<img>`/`<video>`), the effects also apply to a cross-origin `<iframe>` — i.e. a
wrapped web page or another live wallpaper. Each effect is a 0–100 slider with a
typing-reactive twin.

**YouTube.** Paste a watch / `youtu.be` / `live/<id>` URL, or a channel live URL
(`youtube.com/@handle/live`, `youtube.com/name/live`). The latter carries no
video id, so the helper's `/yt` endpoint fetches the page server-side and
resolves the currently-live video for the embed.

Looking for backgrounds to wrap? <https://motionbgs.com> has a big library of
free live/motion wallpapers (grab a video URL or download the `.mp4`).

## Install (automatic via chezmoi)

`chezmoi apply` runs `run_onchange_after_install-wp-stat-overlay.sh`, which:

- **WSL → Windows:** cross-builds `wpstats.exe` (`-H windowsgui`, no console),
  copies the wallpaper into Steam's `wallpaper_engine/projects/myprojects/stat-overlay`,
  installs a minimized **Startup** shortcut, and launches the helper.
- **Native Linux:** builds `wpstats`, installs into the Linux WE `myprojects`,
  and enables a `wpstats.service` user unit.

It re-runs whenever the wallpaper or helper sources change. If Go or WE isn't
found, it skips cleanly (the source stays tracked).

Then in Wallpaper Engine, open **your own wallpapers** and pick **Stat Overlay**.

## Controls (Wallpaper Engine → wallpaper settings)

| Property | What it does |
|----------|--------------|
| Stats helper URL | where to fetch stats (default `http://localhost:8787/stats`) |
| Background source type | none / video / web / image |
| Background video / image / web URL | the wrapped wallpaper |
| **Background blur** | 0–40 px |
| **Background brightness** | 0–200 % |
| Background opacity | 0–100 % |
| Overlay opacity / size / position | the stats panel |
| Accent color | bar + accent color |
| Show CPU+RAM / cores / net+disk / GPU / clock / FPS | per-group toggles |

## Manual / dev

```sh
# run the helper
cd helper && go run .            # serves :8787
go build -o wpstats .            # or build a binary

# preview the wallpaper in a browser (helper must be running)
xdg-open wallpaper/index.html    # or just open the file
```

Stop the Windows helper: Task Manager → `wpstats.exe`, or delete the Startup
shortcut to disable autostart. GPU/temps are best-effort and hidden when the
helper can't read them.
