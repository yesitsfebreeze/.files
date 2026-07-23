-- §head home/dot_config/nvim/lua/config/keymaps.lua:68-73 select_start
-- §sig local function select_start(motion)
return function()
    shift_select = true
    feed("v" .. motion)
  end
-- §foot home/dot_config/nvim/lua/config/keymaps.lua select_start