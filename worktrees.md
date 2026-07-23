# Cycles

Live `/cycle` worktrees on this checkout. Derived from git + each tree's
`.pi/cycle.json` by `agent/bin/cycle.sh regen` — never edit by hand, it is
rewritten on every fire.

`CYCLE_MAX` counts per agent, so the machine total is that cap times the
number of drivers. A `flat` agent is a driver that sets no `CYCLE_AGENT`
and claims in the original un-namespaced layout.

None live.
