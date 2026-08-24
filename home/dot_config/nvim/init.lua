-- Load order (epic I1): options -> keymaps -> autocmds -> lazy. The leader
-- is set in config.options, before any plugin spec is evaluated.
--
-- SEAM: a require of a missing module aborts startup — this file requires
-- exactly what is built. 02-keymaps (E.3) INSERTS its require ABOVE the
-- require("config.autocmds") line, in I1's order; require("config.lazy")
-- stays last.
require("config.options")

vim.filetype.add({
  extension = {
    jd = "markdown",
  },
})

require("config.keymaps")

-- 14-shift-select gets its own module rather than riding in the general
-- keymap file: that file's gate forbids shift-select machinery and autocmds
-- per call site. It loads after the general maps and before the plugin
-- manager, keeping I1's order. (Prose here names no module: a sibling gate
-- greps this file for a module name to prove its own require was stripped.)
require("config.shift-select")

require("config.autocmds")

require("config.lazy")
