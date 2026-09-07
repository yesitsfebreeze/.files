---
kind: question
description: when a provider changes its /models response (new ids, dropped ones, a price shift) how does the litellm shelf know — and what catches a stale shelf serving a 402
read_when: "trusting `llm status` numbers, or chasing a 402 from a model that was free yesterday"
---

# how-do-llm-models-go-stale-when-the-shelf-does

----
Q: The proxy serves every model it has on the shelf
(`~/.local/state/litellm/models.json`, ~550 models), with the score for
each in `performance.jsonl` and parked-state in `status.json`. A
provider's `/models` endpoint can change between `llm sync` runs
(overnight, `litellm-sync.plist` fires at 04:30): new ids, dropped
ids, a price shift. The shelf is whatever was true at the last sync.
What is the right cadence, what is the cost of being one day stale, and
what is the load on the proxy when the shelf is fresh but the upstream
has moved?
A: ?