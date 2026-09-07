---
kind: routine
name: read-the-provenance-from-the-nodes-own-text
description: all four nodes carry their own "Established ... by ... on `<prd>`" sentence; reading it, and confirming the named directory exists, is what the contract requires instead of a guess
read_when: "executing read-the-provenance-from-the-nodes-own-text"
---

# read-the-provenance-from-the-nodes-own-text

_Origin: `pearde/workflows/read-the-provenance-from-the-nodes-own-text.md` (workflow subject: "all four nodes carry their own "Established ... by ... on `<prd>`" sentence; reading it, and confirming the named directory exists, is what the contract requires instead of a guess")_


## Do

1. For each flagged node, read its own body for the sentence recording
   what surfaced it -- a fixed phrase such as "Established ... by ... on
   `<prd>`" is common in this board's derived nodes.
2. Confirm the named PRD directory exists on disk before using it as a
   value; a name in prose that resolves to nothing is not a trace, it is a
   guess with a citation.

## Done when

- The traced value is a real, existing PRD directory, and the sentence it
  came from is quoted in the spec or report that uses it.
