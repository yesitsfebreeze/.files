--- @sync entry

return {
	entry = function()
		local tab = cx.active
		if tab.finder or not tab.mode.is_normal or tab.current.files.filter
			or #tab.selected > 0 or tab.current.cwd.spec.is_search then
			return ya.emit("escape", {})
		end
		if #cx.yanked > 0 then
			return ya.emit("unyank", {})
		end
		ya.emit("quit", {})
	end,
}
