-- Formatting: conform.nvim — one owner for "make this buffer well-formed".
-- Real formatters where they exist, the language server as the fallback, on
-- save and on demand.
return {
  "stevearc/conform.nvim",
  event = "BufWritePre",
  cmd = "ConformInfo",
  keys = {
    {
      "<leader>cf",
      function()
        require("conform").format({ async = true, lsp_format = "fallback" })
      end,
      desc = "Format buffer",
    },
  },
  opts = {
    formatters_by_ft = {
      lua = { "stylua" },
      rust = { "rustfmt" },
      python = { "black" },
      -- R3. prettier is here to align markdown table pipes and normalize
      -- lists; prose must stay AS WRITTEN, because the documents in this repo
      -- are hand-wrapped at ~78 columns and reflowing them churns every diff.
      -- What makes that safe is prettier's own default: proseWrap is
      -- "preserve" unless something overrides it. Nothing does — measured
      -- 2026-08-23, this repo carries no .prettierrc, .prettierrc.json,
      -- prettier.config.js or package.json at its root, so prettier's
      -- defaults are exactly what runs here. List and table normalization is
      -- therefore NOT opt-in; it is the price of the pipe alignment.
      --
      -- And this key owns more buffers than its name suggests: init.lua
      -- registers `extension = { jd = "markdown" }`, so every .jd file is a
      -- markdown buffer and prettier reformats it on save. Measured with a
      -- logging shim: saving t.jd invokes `prettier --stdin-filepath <abs
      -- path to t.jd>`. There are 27 .jd files under ~/dev, so this is the
      -- common case, not a corner.
      markdown = { "prettier" },
      -- No ["markdown.mdx"] key. Nothing in this config registers the .mdx
      -- extension, so no buffer can ever hold that filetype and the entry
      -- would be dead configuration.
    },
    -- R4. `lsp_format = "fallback"` covers TWO cases, and the second one is
    -- silent. The obvious one is a filetype with no formatter listed above.
    -- The other, measured with an in-process fake language server and an
    -- empty PATH: a filetype whose formatter IS listed but whose binary is
    -- missing also falls through to the server, which formats the buffer
    -- while vim.notify is never called — nothing at all indicates that
    -- stylua did not run. That is why install.sh provisions the four
    -- binaries rather than assuming them.
    --
    -- The write ALWAYS succeeds. Every failure mode was measured to exit 0
    -- with the file written: a timeout (WARN `Formatter 'stylua' timeout`,
    -- unformatted write, ~570 ms wall for a 2 s formatter), a formatter that
    -- fails (ERROR `Formatter failed. See :ConformInfo for details`), an
    -- absent formatter with no server (WARN `Formatters unavailable for lua
    -- file`, once per filetype per session), and no configured formatter with
    -- no server (silent). Formatting never blocks a save.
    format_on_save = { timeout_ms = 500, lsp_format = "fallback" },
  },
}
