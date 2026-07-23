-- §head home/dot_config/wezterm/wezterm.lua:401-461 set_background
-- §sig local function set_background(input)
local script = table.concat({
        "set -e",
        "input='" .. input .. "'",
        'tmp="$(mktemp)"',
        -- FIX E: GUI-launched wezterm inherits launchd's minimal PATH on macOS, so
        -- sh -lc won't find brew's magick/curl; seed Homebrew up front (no-op on
        -- linux/WSL, where bash -lc already has /usr/bin).
        'export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"',
        -- FIX C: clean the temp on any exit/interrupt, not just the success path.
        'blurred="$tmp.blur"',
        "trap 'rm -f \"$tmp\" \"$blurred\"' EXIT INT TERM",
        'src_dir="$(chezmoi source-path "$HOME/.config/wezterm" 2>/dev/null)" || exit 1',
        '[ -n "$src_dir" ] || exit 1',
        'mkdir -p "$src_dir"',
        "if grep -qi microsoft /proc/version 2>/dev/null; then " .. WIN_LIVE_DIR .. "; "
        .. 'else live_dir="$HOME/.config/wezterm"; fi',
        'mkdir -p "$live_dir"',
        -- Obtain the source image into $tmp: download http(s) URLs, else treat the
        -- input as a local file -- strip a file:// prefix, expand a leading ~, and
        -- convert a Windows drive path via wslpath (WSL only). A missing local file
        -- aborts before any dest write.
        'case "$input" in '
        .. 'http://*|https://*) curl -fsSL "$input" -o "$tmp" ;; '
        .. '*) src="${input#file://}"; '
        .. 'case "$src" in "~/"*) src="$HOME/${src#\\~/}" ;; esac; '
        ..
        'case "$src" in [A-Za-z]:[/\\\\]*) if command -v wslpath >/dev/null 2>&1; then src="$(wslpath -u "$src")"; fi ;; esac; '
        .. '[ -f "$src" ] || exit 1; cp "$src" "$tmp" ;; '
        .. "esac",
        "blur() { if command -v magick >/dev/null 2>&1; then magick \"$1\" -blur 0x16 \"$2\"; "
        .. 'else convert "$1" -blur 0x16 "$2"; fi; }',
        -- Blur into a temp FIRST: this doubles as image validation. A non-image input
        -- (e.g. an HTML page from a non-direct URL) makes magick/convert fail here, and
        -- set -e aborts before ANY dest file is written. Only once the blur succeeds do
        -- we publish to both dirs.
        'blur "$tmp" "$blurred"',
        'cp "$blurred" "$src_dir/background.png"',
        'cp "$blurred" "$live_dir/background.png"',
        -- Apply that blurred copy as the OS DESKTOP wallpaper (not a wezterm layer):
        -- Windows (from WSL) via reg + rundll32 on the wslpath -w form, macOS via
        -- osascript, otherwise GNOME via gsettings. Best-effort per OS.
        'wp="$live_dir/background.png"',
        'if grep -qi microsoft /proc/version 2>/dev/null; then '
        .. 'win_wp="$(wslpath -w "$wp")"; '
        .. 'reg.exe add "HKCU\\Control Panel\\Desktop" /v Wallpaper /t REG_SZ /d "$win_wp" /f >/dev/null 2>&1 || true; '
        .. 'reg.exe add "HKCU\\Control Panel\\Desktop" /v WallpaperStyle /t REG_SZ /d 10 /f >/dev/null 2>&1 || true; '
        .. 'rundll32.exe user32.dll,UpdatePerUserSystemParameters 1, True >/dev/null 2>&1 || true; '
        .. 'elif [ "$(uname)" = "Darwin" ]; then '
        ..
        'osascript -e "tell application \\"System Events\\" to tell every desktop to set picture to \\"$wp\\"" >/dev/null 2>&1 || true; '
        .. 'else '
        .. 'gsettings set org.gnome.desktop.background picture-uri "file://$wp" >/dev/null 2>&1 || true; '
        .. 'gsettings set org.gnome.desktop.background picture-uri-dark "file://$wp" >/dev/null 2>&1 || true; '
        .. 'fi',
    }, "; ")
    local success, _, stderr = run_bg_script(script)
    if not success then
        wezterm.log_error("set wallpaper failed: " .. (stderr or ""))
    end
-- §foot home/dot_config/wezterm/wezterm.lua set_background