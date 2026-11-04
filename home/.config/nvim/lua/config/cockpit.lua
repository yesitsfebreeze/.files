-- manual → internals/tmux, "Double Space".
local M = {}
local last, pending
local function now() return vim.uv.hrtime() / 1e6 end
local function enabled()
  return vim.env.TMUX_PANE and vim.fn.executable(vim.fn.expand("~/.local/bin/cockpit")) == 1
end
local function snapshot()
  local mode = vim.api.nvim_get_mode().mode
  if mode == "i" then
    local pos = vim.api.nvim_win_get_cursor(0)
    return { mode = mode, buf = vim.api.nvim_get_current_buf(), win = vim.api.nvim_get_current_win(),
      row = pos[1], col = pos[2], text = vim.api.nvim_get_current_line(), tick = vim.b.changedtick }
  elseif mode == "c" then
    return { mode = mode, text = vim.fn.getcmdline(), col = vim.fn.getcmdpos() - 1,
      kind = vim.fn.getcmdtype(), level = vim.fn.getcmdwintype() }
  end
end
local function matches(a, b)
  return a and b and a.mode == b.mode and a.buf == b.buf and a.win == b.win
    and a.row == b.row and a.col == b.col and a.text == b.text and a.tick == b.tick
    and a.kind == b.kind and a.level == b.level
end
function M.open(on_failure)
  local function fail(message)
    vim.schedule(function()
      if on_failure then on_failure() end
      vim.notify("Cockpit could not open: " .. message, vim.log.levels.WARN)
    end)
  end
  if not enabled() then fail("not available"); return false end
  local ok, err = pcall(vim.system, { "/bin/bash", vim.fn.expand("~/.local/bin/cockpit"), "--open" }, {}, function(result)
    if result.code ~= 0 then fail(result.stderr or "") end
  end)
  if not ok then fail(tostring(err)) end
  return ok
end
function M.space()
  local current, at = snapshot(), now()
  if not enabled() or not current or vim.fn.pumvisible() == 1 or vim.o.paste then
    last = nil
    return " "
  end
  local same = last and matches(last.expected, current)
  local gap = same and (at - last.at) or 1000
  if same and not last.blocked and gap >= 60 and gap <= 200 then
    pending, last = last, nil
    return "<Cmd>lua require('config.cockpit').commit()<CR>"
  end
  local expected = vim.deepcopy(current)
  expected.text = current.text:sub(1, current.col) .. " " .. current.text:sub(current.col + 1)
  expected.col = current.col + 1
  if expected.tick then expected.tick = expected.tick + 1 end
  last = { before = current, expected = expected, at = at,
    blocked = same and gap < 500 and (last.blocked or gap < 60 or gap > 200) or false }
  return " "
end
function M.commit()
  local candidate = pending
  pending = nil
  if not candidate or not matches(candidate.expected, snapshot()) then return end
  local before = candidate.before
  if before.mode == "i" then
    -- Delete exactly the inserted byte, not softtabstop's Backspace width.
    vim.cmd("silent! undojoin")
    vim.api.nvim_buf_set_text(before.buf, before.row - 1, before.col, before.row - 1, before.col + 1, {})
    vim.api.nvim_win_set_cursor(before.win, { before.row, before.col })
  else
    vim.fn.setcmdline(before.text)
    vim.fn.setcmdpos(before.col + 1)
  end
  local restored = snapshot()
  M.open(function()
    if matches(restored, snapshot()) then
      vim.api.nvim_feedkeys("  ", "in", false)
    end
  end)
end
local group = vim.api.nvim_create_augroup("cockpit_space", { clear = true })
vim.api.nvim_create_autocmd({ "InsertLeave", "CmdlineLeave", "BufLeave", "WinLeave", "FocusLost" }, {
  group = group, callback = function() last, pending = nil, nil end,
})
vim.on_key(function(_, typed)
  if typed and typed ~= "" and typed ~= " " then last = nil end
end, vim.api.nvim_create_namespace("cockpit_space"))
vim.keymap.set({ "i", "c" }, "<Space>", function()
  vim.api.nvim_feedkeys(vim.keycode(M.space()), "in", false)
end, { silent = true, desc = "Space / double-tap cockpit" })
vim.keymap.set("n", "<leader><Space>", M.open, { silent = true, desc = "Cockpit" })
return M
