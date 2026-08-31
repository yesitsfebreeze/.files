-- The real live-fire: the :ClaudeCode command path, as the user would press it.
local ok, err = pcall(vim.cmd, "ClaudeCode")
print("CMD-COMMOND-OPEN", ok, ok and "" or tostring(err):gsub("%s+", " "))
-- and the focus variant
local ok2, err2 = pcall(vim.cmd, "ClaudeCodeFocus")
print("CMD-FOCUS", ok2, ok2 and "" or tostring(err2):gsub("%s+", " "))
