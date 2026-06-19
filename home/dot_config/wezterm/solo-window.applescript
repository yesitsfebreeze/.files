-- Solo the terminal on macOS: hide every app except the frontmost one (WezTerm,
-- since the keybinding only fires while it is focused). macOS has no per-window
-- "minimize others", but hiding the other apps achieves the same end — WezTerm is
-- left alone in front. Requires WezTerm to hold Accessibility permission
-- (System Settings > Privacy & Security > Accessibility) the first time.
tell application "System Events"
	set frontApp to name of first application process whose frontmost is true
	repeat with proc in (application processes whose visible is true)
		if name of proc is not frontApp then
			set visible of proc to false
		end if
	end repeat
end tell
