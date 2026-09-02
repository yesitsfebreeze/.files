---
title: 00-delivery/verification-gates
type: prd
state: done
origin: requested
priority: 12
complexity: 0
blast: low
needs:
  - "[[05-platform/01-deploy-mechanism/repo-skeleton]]"
---

# Verification gates

`state: done · origin: requested · priority 12 · complexity 0 · blast —`

## Fed by (needs this one)

- [[06-help/04-drift-check]]

## Needs (gates this one behind)

- [[05-platform/01-deploy-mechanism/repo-skeleton]]

## Children (derived from this)

- [[00-delivery/corrections/d3-tick-breaks-unticked-rule]]
- [[00-delivery/corrections/g1-verify-still-red-on-just-gates]]
- [[00-delivery/corrections/gates-frontmatter-port]]
- [[00-delivery/corrections/tree-links-selftest-stale-pin]]
- [[00-delivery/corrections/tree-links-tier-b-paths]]

## Specs

- [[prds/00-delivery/verification-gates/specs/spec01]]
- [[prds/00-delivery/verification-gates/specs/spec02]]
- [[prds/00-delivery/verification-gates/specs/spec03]]
- [[prds/00-delivery/verification-gates/specs/spec04]]
- [[prds/00-delivery/verification-gates/specs/spec05]]
- [[prds/00-delivery/verification-gates/specs/spec06]]

## Decisions

- [[a-concurrent-lane-trips-the-scratch-guard]] — gates/selftest.sh's "wrote nothing outside its scratch" check cannot tell a misbehaving gate from another lane writing concurrently — a red naming a file you did not touch is the artifact, not a finding
