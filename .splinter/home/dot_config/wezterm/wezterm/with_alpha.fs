-- §head home/dot_config/wezterm/wezterm.lua:293-299 with_alpha
-- §sig local function with_alpha(hex, a)
local r, g, b = (hex or ""):match("^#(%x%x)(%x%x)(%x%x)$")
    if not r then
        return hex
    end
    return string.format("rgba(%d, %d, %d, %s)", tonumber(r, 16), tonumber(g, 16), tonumber(b, 16), a)
-- §foot home/dot_config/wezterm/wezterm.lua with_alpha