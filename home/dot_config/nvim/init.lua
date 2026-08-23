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

require("config.autocmds")

require("config.lazy")
