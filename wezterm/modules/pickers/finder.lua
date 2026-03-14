-- modules/pickers/finder.lua: Single-pane file/grep finder
-- Leader+f+f → fzf file picker with bat preview
-- Leader+f+g → ripgrep → fzf with bat preview

local pane_mode = require("modules.pane_mode")

local M = {}

-- ── Mode: find_files ────────────────────────────────────────────

pane_mode.define("find_files", function(cwd)
  return 'cd /d "' .. cwd .. '" && '
    .. "rg --files --hidden"
    .. ' --glob "!*.git*" --glob "!node_modules"'
    .. ' --glob "!__pycache__" --glob "!.venv"'
    .. " | fzf"
    .. " --min-length=2 --layout=reverse --border=none"
    .. ' --preview "bat --color=always --style=plain --line-range=:200 {}"'
end)

-- ── Mode: find_grep ─────────────────────────────────────────────

pane_mode.define("find_grep", function(cwd)
  return 'cd /d "' .. cwd .. '" && '
    .. "rg --hidden --line-number --color=always --smart-case ."
    .. ' --glob "!*.git*" --glob "!node_modules"'
    .. ' --glob "!__pycache__" --glob "!.venv"'
    .. " | fzf --ansi --layout=reverse --border=none"
    .. ' --delimiter=: --preview "bat --color=always --highlight-line={2} {1}"'
end)

-- ── Actions ─────────────────────────────────────────────────────

function M.find_files_action()
  return pane_mode.activate("find_files")
end

function M.find_grep_action()
  return pane_mode.activate("find_grep")
end

return M

return M
