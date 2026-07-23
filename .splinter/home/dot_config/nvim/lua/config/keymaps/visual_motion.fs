-- §head home/dot_config/nvim/lua/config/keymaps.lua:93-103 visual_motion
-- §sig local function visual_motion(motion)
return function()
    local count = vim.v.count > 0 and tostring(vim.v.count) or ""
    if shift_select then
      shift_select = false
      feed("<Esc>" .. count .. motion)
    else
      feed(count .. motion)
    end
  end
-- §foot home/dot_config/nvim/lua/config/keymaps.lua visual_motion