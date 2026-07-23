-- §head home/dot_config/nvim/lua/config/keymaps.lua:84-89 select_start_insert
-- §sig local function select_start_insert(keys)
return function()
    shift_select = true
    feed("<Esc>" .. keys)
  end
-- §foot home/dot_config/nvim/lua/config/keymaps.lua select_start_insert