local new = Root.new

function Root:new(area)
	local root = new(self, area:pad(ui.Pad.xy(1)))
	root._base = {
		ui.Border(ui.Edge.ALL):area(area):type(ui.Border.ROUNDED):style(ui.Style():fg("brightblack")),
	}
	return root
end
