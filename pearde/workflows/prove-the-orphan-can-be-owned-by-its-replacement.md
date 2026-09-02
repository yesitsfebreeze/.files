---
atomic: prove-the-orphan-can-be-owned-by-its-replacement
subject: "the contract asked for six `.chezmoiremove` entries; five of them named paths the replacement installs to, and the entry fires on every apply, so they would have uninstalled it forever"
date: 2026-09-02
updated: 2026-09-02
runs: 2
---

## Do

1. Before writing a durable removal entry for a deployed orphan, name what
   will sit at that path afterwards. If the answer is "the replacement, at
   the same name", the entry is an uninstaller and not a cleanup.
2. Measure the removal mechanism rather than reading its documentation.
   Build a throwaway source and destination, put the entry in, apply, then
   write a FOREIGN file at that path and apply again. Check whether it
   survives. Repeat with a symlink — a mechanism that spares one may not
   spare the other.
3. Where the replacement owns the name, write no entry. Remove the orphan
   once by hand, or let the replacement's install overwrite it at the same
   name, and say in the spec that a fresh machine never had it.
4. Where nothing will ever reinstall the name, write the entry — that half
   of `check-what-apply-left-behind` stands unchanged.

## Done when

- Every path in the removal list is one nothing else installs to.
- Every path left out of it is absent from this machine now, and absent
  from a fresh one by never having been deployed.
- Both facts are asserted after a second apply, not after the first.

## Fails when

- Reading `.chezmoiremove` as a one-shot cleanup. It fires on EVERY apply
  and deletes whatever sits at the named target path. Measured on chezmoi
  v2.72.1 in a throwaway source/destination pair: a foreign file written at
  the path after the first apply was deleted on the second and again on the
  third, and a symlink pointing outside the destination went the same way —
  four passes, four deletions. So an entry naming a path a DIFFERENT project
  installs into is a permanent uninstaller for that project.
- Reaching for `delete-the-shadow-the-replacement-leaves` here. That atomic
  is the opposite failure — an old copy left ahead on PATH, winning forever.
  This one is a removal that keeps working after it should have stopped.
  Both can be live at once: delete the shadow, and do not write the entry.
- Measuring with a scoped apply and calling it read-only. `chezmoi apply
  --destination <tmp>` scopes the file writes but not the scripts:
  `run_after_*` still execute and act on the real `$HOME`.
