-- §head home/dot_config/nvim/lua/config/keymaps.lua:76-81 select_extend
-- §sig local function select_extend(motion)
return function()
    shift_select = true
    feed(motion)
  end
-- §foot home/dot_config/nvim/lua/config/keymaps.lua select_extend