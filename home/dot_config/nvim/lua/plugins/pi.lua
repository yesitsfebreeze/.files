return {
  "yesitsfebreeze/pi",
  branch = "nvim-plugin",
  name = "pi",
  cmd = "Pi",
  config = function()
    -- Path to pi binary. Override on hosts without ~/dev/pi:
    --   let g:pi_path = "pi" (PATH fallback, or any absolute path)
    vim.g.pi_path = vim.g.pi_path ~= "" and vim.g.pi_path
        or vim.fn.expand("node ~/dev/pi/packages/coding-agent/dist/cli.js")
  end,
}