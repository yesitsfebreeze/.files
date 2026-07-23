-- §head home/dot_config/wezterm/wezterm.lua:304-324 retro_tab_bar
-- §sig local function retro_tab_bar(alpha)
local p = config.colors
    local br = p.brights or {}
    -- The theme's primary accent (base0D = ansi slot 5), same accent as the GlazeWM outline.
    local accent = (p.ansi and p.ansi[5]) or br[5] or p.selection_bg
    -- The translucent window surface: an explicit opaque hex paints the bar solid (it
    -- does NOT honor window_background_opacity), so bake the theme bg + alpha into an
    -- rgba — identical surface to the cells.
    local surface = with_alpha(p.background, alpha)
    -- Active tab is FILLED with the accent, with the bg color as text so it
    -- stays readable on the accent. Inactive/new tabs sit on the same translucent
    -- surface as the strip with accent text, so the active tab reads as inverted.
    return {
        background = surface,
        active_tab = { bg_color = accent, fg_color = p.background },
        inactive_tab = { bg_color = surface, fg_color = accent },
        inactive_tab_hover = { bg_color = with_alpha(br[4] or p.selection_bg, "0.5"), fg_color = accent, italic = false },
        new_tab = { bg_color = surface, fg_color = accent },
        new_tab_hover = { bg_color = with_alpha(br[4] or p.selection_bg, "0.5"), fg_color = accent },
    }
-- §foot home/dot_config/wezterm/wezterm.lua retro_tab_bar