---
type: standing
id: laws
subject: the four laws — what each solves, how they connect, how each is enforced
proof: every enforcement bullet sits under one of the three rung headings
---

*Every law defends one fact: whoever did the work will not be there to explain
it. Processes are killed mid-task, contexts are dropped, workers are born
without their dispatcher's memory, authors move on. Four laws, none derivable
from the others.*

*Enforcement is grouped by rung — **unrepresentable**, **gated**, **reviewed**
— in that order of strength. A rule that fits none of the three has nowhere to
be written down, which is the point.*

# 1. One record

- **is** — everything durable is appended to one growing record; the state on disk is a fold of it, and nothing else holds state of its own
- **solves** — knowledge dying with its holder: a process killed mid-work, a session whose context was dropped, a worker spawned with none of the dispatcher's memory, a component whose removal is a rewrite, a document whose author left
- **connects** — the ground; 2, 3 and 4 have no subject without it. Because nothing else holds state, a component detaches without residue and anything a new worker needs must travel with it explicitly. Its price: whatever cannot be re-derived — clock, model output, embedding, hash iteration order — enters as recorded data and is never consulted live. Proven only by 2, held only as far as 3 reaches, shaped by 4
- **unrepresentable**
  - a write is durable before it is visible; memory is a cache of the record, never a second copy that can disagree
  - corrections are appended and shadow the old value; deletion is not expressible
  - where a copy must exist — something readable away from its home — it is generated from the home, never authored beside it
  - everything that installs hands back its own inverse and a scope unwinds in reverse, so the system runs with every optional component absent
  - a lifecycle word is a view: what is stored is the owner, the supersession link, the outstanding obligations and the owner's one-bit assertion, so the word that summarizes them has no field to live in
  - time is passed in as a parameter, not read
  - the system owns no store of its own
- **gated**
  - every view is recomputed on read, never stored beside the record: refold from empty and compare
  - nothing reaches a view the record does not explain — a change to a view is itself an entry, and the call it produces extends the one it replaces byte for byte
  - every unordered traversal is given a total order: produce it twice and compare
  - the record of why lands in the same commit as the change it explains
- **reviewed**
  - a document does not restate another; an ungated copy goes lossy at exactly the clause that mattered, and reads as authoritative the whole time it is wrong
  - a rule is written once, at the most general scale where it is true; the specific document carries only what changes there — a sentence explaining *why* belongs at the general scale or nowhere

# 2. Nothing vouches for itself

- **is** — no claim is accepted from the thing that made it
- **solves** — the claim of an author no longer there to be asked: a confirmation for something that never happened, a task closed without its check, a finished component nothing can reach, a stored expectation updated to match the code that broke it, a decision with no rejected alternative recorded
- **connects** — the only proof law 1 holds: serialize the record, rebuild from empty, compare byte for byte. Where 3 cannot reach it — was that alternative real, was that wall genuine, does that finished box match the change actually made — it is carried by a named second party who did not write the claim, never by the author's own care. That residue is the whole of the *reviewed* rung
- **unrepresentable**
  - strict schemas at every boundary: required fields, no unknown keys, no silent default, skip or cap
  - unparseable input stops rather than being guessed
  - progress is computed from observed change, never from the actor's report
  - a lock is a durable commit, not a flag: surfaced when stale, never taken
- **gated**
  - completion requires a declared state **and** zero outstanding obligations; a faked or partial dependency counts as outstanding
  - captured expectations are replayed every run, edited only in the same change as the code, with the reason recorded
  - a worker writes only what it owns; a needed change to someone else's contract is an escalation, not an edit
  - a run narrowed to what changed is the change choosing which tests may judge it: it may answer "not yet", never "done"
- **reviewed**
  - a result names the artifact it produced; a stub says it is a stub; an ignored error names what it ignores
  - a decision names each real alternative and why it lost — never a loser invented to fill the section
  - a wall is escalated, never redefined away
  - a fact is looked up, never asked; a decision that is not yours is asked, never assumed — and an assumption made in the principal's absence is recorded as an assumption
  - a capability is read off the live surface before it is used: assumed-present is a hallucinated step, assumed-absent is work done twice
  - an independent reviewer is asked to refute each claim, not to confirm it

# 3. A rule that cannot run is a wish

- **is** — a rule exists only as far as something is assigned to run it; an unassigned rule is a wish
- **solves** — doctrine decaying the first week somebody is in a hurry; a check trusted precisely because it passes either way
- **connects** — the enforcement arm of the other three; they exist only as far as this reaches. The three rungs in order: make the violation **unrepresentable**, so it cannot be written; else **gate** it, and no gate is real until deliberately broken and watched to fail; else assign a **named adversary** who did not write the claim. Written down and assigned to nobody is the fourth rung, which is the wish. The law on the lowest rung is the one violated first, silently
- **unrepresentable**
  - types make the illegal value inexpressible: distinct identifiers, closed variants, read-only views, resources whose release is the type's own obligation
  - ordering constraints make an inconsistent state unreachable rather than detected
  - an unknown name is an error, never an empty value
  - validation happens at the boundary; inside it the types are the check, never a second layer of runtime guessing
  - a rule that names no rung has nowhere to be written down
- **gated**
  - one command runs every gate; nothing outside it is a rule
  - a gate that finds nothing to check fails rather than passes
  - a narrowed run is computed from the dependency graph and the diff, never from a list of what someone believes is affected, and it fails **open**: an input it cannot place runs everything
- **reviewed**
  - each gate is proven by introducing the violation and observing the failure
  - before a check is claimed as proof, one line says what it would have done had the requirement been unmet

# 4. One form, at every scale

- **is** — one kind of node — a name, a declared type, the facts that type requires, a body, a proof, links by reference — whatever it describes and wherever it sits; a special case is the defect
- **solves** — being told: every per-kind protocol, second dialect and "this one is different" is knowledge someone has to carry, and the carrier leaves. And n independently correct implementations of one idea drift into n behaviours, each passing its own check
- **connects** — independent of 1, and the boundary is exact: 1 governs facts, 4 governs form and behaviour. A system can hold exactly one home for every fact and still specialize a protocol by level, or carry ordering in a field instead of in a shape — neither duplicates anything, and both force a worker to be told what it is holding. It is what makes 1's fold possible — uniform nodes fold, special cases do not — and what lets 2's captured expectations transfer between subjects. It needs 3 more than the others do, because every violation of it passes the other three
- **unrepresentable**
  - an undeclared or unknown type is refused, not defaulted
  - the proof has one name across every type, and a type with nothing to run declares an empty proof rather than omitting the field — an omitted proof reads as true, a declared empty one reads as unproven
  - ordering and identity are carried by structure rather than by a field, so an inconsistent state cannot be written
  - the identifier and the parent link are the same thing
  - composition by reference, cycles refused at load, never by copy
  - membership by existence, not by a maintained list
- **gated**
  - every document carries the same header: a declared type, then the fields that type requires
  - one parser that knows n types, never n parsers that each know one
  - dependencies pinned once, so a second incompatible copy cannot exist
  - one implementation of a behaviour, one thin adapter per output — the measurement is that adding one new case touches exactly one place, and the count above one is the size of the violation
  - a test lives in a `tests/` folder and is named for what it covers; the folder says "test", so the name does not say it again — one spelling, at every scale, and a file beside its subject that restates the folder is the second dialect
- **reviewed**
  - one protocol at every level of a recursion, no per-kind variant
  - a new requirement is placed into the structure — descend, absorb, split, or refuse against a stated boundary — never appended to the end
  - new behaviour lands on an extension point, never inside the one loop every participant meets
  - one vocabulary: one noun per concept, across siblings
