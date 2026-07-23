-- §head home/dot_config/nvim/lua/plugins/telescope.lua:25-33 multi_or_select
-- §sig local function multi_or_select(prompt_bufnr)
local picker = action_state.get_current_picker(prompt_bufnr)
            if #picker:get_multi_selection() > 0 then
                actions.send_selected_to_qflist(prompt_bufnr)
                actions.open_qflist(prompt_bufnr)
            else
                actions.select_default(prompt_bufnr)
            end
-- §foot home/dot_config/nvim/lua/plugins/telescope.lua multi_or_select