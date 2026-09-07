---
kind: routine
name: recover-the-contract
description: the PRD body was an unfilled template; two independent sources named the two lines, which is what made building possible without asking
read_when: "executing recover-the-contract"
---

# recover-the-contract

_Origin: `pearde/workflows/recover-the-contract.md` (workflow subject: "the PRD body was an unfilled template; two independent sources named the two lines, which is what made building possible without asking")_


## Do

1. Read the PRD body. If it is still the template's angle-bracket text, the
   contract is not in the repository and must be recovered before building.
2. Query the project memory and the knowledge base for the PRD's directory
   name — a PRD filed from a working session is usually named in the note
   that filed it.
3. Confirm what you recovered against the tool's own documentation — its
   install notes, its README, the string its code actually prints. Build only
   on a contract two independent sources agree on.

## Done when

- Two independent sources name the same change, and neither is your inference
  from the other.
