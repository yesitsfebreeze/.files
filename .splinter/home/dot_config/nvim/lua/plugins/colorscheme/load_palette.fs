-- §head home/dot_config/nvim/lua/plugins/colorscheme.lua:16-28 load_palette
-- §sig local function load_palette(path)
local f = io.open(path, "r")
            if not f then return nil end
            local palette = {}
            for line in f:lines() do
                local variant = line:match('^variant:%s*"(%w+)"')
                if variant then palette.variant = variant end
                local key, hex = line:match("^%s*(base%x%x):%s*\"(#%x+)\"")
                if key then palette[key] = hex end
            end
            f:close()
            return palette.variant and palette or nil
-- §foot home/dot_config/nvim/lua/plugins/colorscheme.lua load_palette