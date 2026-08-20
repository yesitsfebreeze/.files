export const meta = {
	name: 'mi-repair',
	description: 'Repair a board that has drifted or jammed: sweep the record against the code, replan the open work around what the sweep found, then fix the proposal against its own adversary until it is safe to apply. Reports what only the human can settle rather than deciding it.',
	whenToUse: 'When the board is what is blocking you — nodes lying about their own state, work specced nowhere, parent checklists disagreeing with their children, a tree of prose that has no claimable nodes. Produces a proposal for a human to approve; it never writes the board.',
	phases: [
		{ model: 'haiku', title: 'Profile', detail: 'the facts the auditor must not have to re-derive: claims, recipes, box counts' },
		{ model: 'opus', title: 'Reconcile', detail: 'sweep the record against the code — what does the board get wrong' },
		{ model: 'opus', title: 'Replan', detail: 'fold the drift into one streamlined forward plan' },
		{ model: 'opus', title: 'Repair', detail: 'apply the audit\'s required fixes to the proposal' },
		{ model: 'opus', title: 'Re-audit', detail: 'a fresh adversary, told nothing about the previous round' },
	],
}

// ─────────────────────────────────────────────────────────────────────────
// The repair loop exists because the failure mode it catches is specific and
// recurring: a replanner reasons well about STRUCTURE and badly about APPLY
// INSTRUCTIONS. "PRESERVE VERBATIM lines 1-244" reads as careful and silently
// deletes the closed record below line 244. So the fix is bounded — rewrite
// the instructions, never the plan — and it is re-audited by someone who was
// not told what the last round said.
//
// Both agents here are `judge` tier on purpose. There is no cheaper step in
// this workflow: a repairer that quietly drops a required fix, and an auditor
// that waves a destructive instruction through, are both failures nothing
// downstream catches. The one cheap thing — counting boxes and listing
// recipes — is done once by the Profile step so neither of them has to.
//
// Nothing below the args block names a language, a build tool or a package.
// See `_lib.md`.
//
// args: { repo, board, planDir, proposal, audit, reconcile, scope, protect,
//         rounds, refs, lib, seeds, models, effort }
//
// Pass `proposal` to skip straight to the repair loop — that is the original
// single-purpose entry point and still works. Pass `reconcile: '<path>'` to
// reuse a drift report you already have instead of sweeping again.
// ─────────────────────────────────────────────────────────────────────────

const A = (typeof args === 'object' && args) || {}
const REPO = (typeof args === 'string' && args) || A.repo || 'the repo rooted at your cwd (`git rev-parse --show-toplevel`)'
const BOARD = A.board || '.mi/prd'
// The protocol reference files. They live beside these scripts, so a repo that
// symlinks `.mi/workflows` at the shared home gets them for free — the refs
// travel with the workflows instead of being installed per repo. They are read
// on demand by the agents that need them, not registered as a skill.
const REFS = A.refs || '.mi/workflows/refs'
const PLAN_DIR = A.planDir || '/tmp/mi-plan'
// `mi-reconcile` and `mi-replan` are INTERNAL: they live in `lib/`, outside the
// directory the harness registers as slash commands, because this workflow is
// their only call site. Two call sites for one script is two places a caller
// can be wrong about what it does.
//
// Derived from the refs path so there is exactly one knob locating the
// workflows directory. `workflow()` takes a path or a registered name, so the
// call falls back to the name for a repo that still has them registered.
const LIB = A.lib || REFS.replace(/\/refs\/?$/, '') + '/lib'
let PROPOSAL = A.proposal || `${PLAN_DIR}/plan.proposed.md`
const ROUNDS = A.rounds || 2

const MODELS = Object.assign({ scan: 'haiku', probe: 'sonnet', judge: 'opus', build: 'opus' }, A.models || {})
const EFFORTS = Object.assign({ scan: 'low', probe: 'medium', judge: 'high', build: 'high' }, A.effort || {})
const at = (tier, o) => Object.assign({ model: MODELS[tier], effort: EFFORTS[tier] }, o || {})

const FACTS_SCHEMA = {
	type: 'object', additionalProperties: false,
	required: ['head', 'open', 'stub', 'closed', 'perFile', 'claimed', 'recipes', 'runner', 'memoDir', 'contextFile', 'citations'],
	properties: {
		head: { type: 'string', description: 'git rev-parse HEAD' },
		open: { type: 'integer', description: 'tree-wide count of `- [ ]` across every board file, under any heading' },
		stub: { type: 'integer', description: 'tree-wide count of `- [~]`' },
		closed: { type: 'integer', description: 'tree-wide count of `- [x]`' },
		perFile: { type: 'array', items: { type: 'string' }, description: 'one line per board file: `<path>: N open, M stub, K closed`' },
		claimed: { type: 'array', items: { type: 'string' }, description: 'one line per node carrying a `claim:` field: `<path> — <session>`. These are untouchable.' },
		runner: { type: 'string', description: 'the task runner this repo uses and the file defining it, or "none"' },
		recipes: { type: 'array', items: { type: 'string' }, description: 'every recipe or script the runner defines — the whitelist a `verify:` must come from' },
		memoDir: { type: 'string', description: 'the design-record directory, or ""' },
		contextFile: { type: 'string', description: 'CLAUDE.md / AGENTS.md / equivalent, or ""' },
		citations: { type: 'array', items: { type: 'string' }, description: 'every commit subject or body line in `git log` that cites a requirement by number — output of `git log --format=%h %s%n%b | grep -inE "requirement [0-9]+"`. Renumbering breaks these.' },
	},
}

phase('Profile')

const facts = await agent(
	`Repository: ${REPO}. READ ONLY — never edit, never commit, never run tests.

Establish the facts a plan auditor would otherwise have to re-derive by hand. All mechanical: count and list, judge nothing.

1. \`git rev-parse HEAD\`.
2. Walk \`${BOARD}\` — \`find ${BOARD} -name prd.md | sort\`. For each file count \`- [ ]\`, \`- [~]\` and \`- [x]\` across the WHOLE file, under ANY heading. Give the per-file lines and the three tree-wide totals. Counting only under \`## Requirements\` is exactly what lets an unmet acceptance clause hide.
3. Every node carrying a \`claim:\` field, with the session id.
4. The task runner and EVERY recipe or script it defines: \`just --list\`, \`make -qp | grep '^[a-z]'\`, the \`scripts\` block of \`package.json\`, the CI workflow jobs. This list is the whitelist a \`verify:\` command must come from.
5. Whether there is a design-record directory and a \`CLAUDE.md\` / \`AGENTS.md\`.
6. \`git log --format='%h %s%n%b' | grep -inE 'requirement [0-9]+'\` — every commit that cites a requirement by number. Renumbering an existing requirement silently rewrites what these commits say they did.`,
	at('scan', { label: 'facts', phase: 'Profile', schema: FACTS_SCHEMA }),
)

if (!facts) return { error: 'could not establish the board facts — an auditor without them cannot check losslessness' }

log(`board at ${facts.head}: ${facts.open} open + ${facts.stub} stub + ${facts.closed} closed · ${facts.claimed.length} claimed · ${facts.recipes.length} recipe(s) · ${facts.citations.length} requirement citation(s) in the log`)

// ─────────────────────────────────────────────────────────────────────────
// Reconcile, then replan. The loop further down repairs a PROPOSAL; these two
// stages are where one comes from. Both are separate workflows and are CALLED,
// never reimplemented — a second copy of either would be free to disagree with
// the first, and the disagreement would surface as a plan that audits clean
// against the wrong tree.
//
// Skipped entirely when the caller already has a proposal.
// ─────────────────────────────────────────────────────────────────────────
let reconcile = null
let replan = null
let replanAudit = ''

// One call, two ways to resolve it. The path is the real one; the name is the
// fallback for a repo that has not moved these into `lib/` yet. A failure of
// BOTH is reported as itself rather than silently skipping the stage — a repair
// that quietly runs without its drift sweep is worse than one that stops.
const callLib = async (name, a) => {
	try {
		return await workflow({ scriptPath: `${LIB}/${name}.js` }, a)
	} catch (byPath) {
		log(`${name}: not at ${LIB}/${name}.js (${String(byPath && byPath.message || byPath)}) — trying the registry name`)
		try {
			return await workflow(name, a)
		} catch (byName) {
			log(`${name}: not in the registry either (${String(byName && byName.message || byName)})`)
			return null
		}
	}
}

if (!A.proposal) {
	phase('Reconcile')
	if (A.reconcile) {
		log(`reusing the drift report the caller supplied: ${A.reconcile}`)
	} else {
		reconcile = await callLib('mi-reconcile', { repo: A.repo, board: BOARD, planDir: PLAN_DIR, refs: A.refs, seeds: A.seeds, models: A.models, effort: A.effort })
		if (!reconcile) return { error: `could not run mi-reconcile — looked for \`${LIB}/mi-reconcile.js\` and for a registered workflow of that name`, fix: 'pass { lib: "<dir holding mi-reconcile.js>" }, or { reconcile: "<an existing drift report>" } to skip the sweep' }
		log(reconcile ? `drift swept at ${reconcile.head}: ${reconcile.surviving} finding(s) survived an adversary, ${reconcile.killed} killed → ${reconcile.reportPath}` : 'the drift sweep returned nothing — the replan will run without it')
	}

	phase('Replan')
	// A node under a live claim is untouchable. Another session is working it
	// right now, and a restructure that moves one breaks the address its claim
	// commit was made against — so the claims measured in Profile are passed
	// through as the protected set rather than rediscovered by the planner.
	const protect = (A.protect || (facts.claimed || []).map(c => String(c).split(' ')[0])).filter(Boolean)
	if (protect.length) log(`protecting ${protect.length} claimed node(s) from the restructure: ${protect.join(', ')}`)

	replan = await callLib('mi-replan', {
		repo: A.repo, board: BOARD, planDir: PLAN_DIR, refs: A.refs,
		reconcile: (reconcile && reconcile.reportPath) || A.reconcile,
		protect, scope: A.scope, seeds: A.seeds, models: A.models, effort: A.effort,
	})

	if (!replan || !replan.proposal) {
		return {
			error: 'the replan produced no proposal, so there is nothing for the repair loop to fix',
			reconcile: (reconcile && reconcile.reportPath) || A.reconcile || '(none)',
			next: 'read the drift report by hand — a board that cannot be replanned usually has a structural problem a plan cannot express',
		}
	}
	PROPOSAL = replan.proposal
	replanAudit = replan.audit || ''
	log(`proposal at ${PROPOSAL} · its own adversary opened with: ${String(replanAudit).trim().split('\n')[0] || '(nothing)'}`)
}

const GROUND = `Repository: ${REPO}.

Read first: \`${REFS}/laws.md\`, \`${REFS}/worker.md\` (§1 boxes, §2 ready, §4 the four moves, Appendix A the node format)${facts.contextFile ? `, \`${facts.contextFile}\`` : ''}.

The subject is the proposed board restructure at \`${PROPOSAL}\`.

THE FACTS, measured at \`${facts.head}\` — do not re-derive them, but DO re-check them if you suspect HEAD has moved:
- the board holds **${facts.open} open, ${facts.stub} stubbed, ${facts.closed} closed** boxes, per file:
${facts.perFile.map(l => `  ${l}`).join('\n')}
- nodes under a live claim, untouchable: ${facts.claimed.length ? facts.claimed.join(' · ') : '(none)'}
- task runner: ${facts.runner}
- **the only commands a \`verify:\` may name, because these are the ones that exist**: ${facts.recipes.map(r => `\`${r}\``).join(', ') || '(no runner — the ecosystem\'s plain commands)'}
- design records: ${facts.memoDir || '(none — a node\'s own Requirements / Acceptance / Out of scope IS its spec)'}
- ${facts.citations.length} commit message(s) cite a requirement by number:
${facts.citations.slice(0, 20).map(c => `  ${c}`).join('\n') || '  (none)'}

NON-NEGOTIABLE CONSTRAINTS ON THE PROPOSAL:
1. **Closed nodes are the record** — \`done\` / \`out-of-scope\` nodes are not re-planned, and a closed \`[x]\` box inside an OPEN node is equally part of the record. Deletion is not expressible; corrections are appended and shadow.
2. **A node id is an address** — a claim is a commit against \`${BOARD}/<path>/prd.md\`. Renaming or moving breaks every commit that referenced it. The same holds one level down: the ${facts.citations.length} citation(s) listed above mean renumbering an existing requirement silently rewrites what those commits say they did.
3. **A node under a live claim is untouchable.** Read it; change nothing about it; it appears in no apply commit.
4. **Losslessness is measured against the BOARD, not against the map.** Every id in the migration map keeps its home and the map's internal arithmetic must stay correct — but a map that balances against itself proves nothing if the inventory it was built from was already short. The count that matters is the ${facts.open + facts.stub} open-and-stubbed boxes on disk right now, and a plan built before a commit that added a requirement in place will delete that requirement while reporting a balanced ledger.
5. **\`ready\` is computed by \`worker.md\` §2 and gates on child coverage, never on priority.** Priority is an ordering, not a gate. Any "wave" that exists only in the plan's prose does not exist.`

let audit = A.audit || replanAudit || ''
let verdict = 'DO NOT APPLY'
let round = 0

while (round < ROUNDS && !/^\s*(SAFE TO APPLY|SAFE WITH FIXES)/im.test(verdict)) {
	round++

	phase('Repair')
	await agent(
		`${GROUND}

You are the REPAIRER, round ${round}. An adversary audited the proposal and returned a verdict with numbered required fixes. Apply them to \`${PROPOSAL}\` **in place**. That file is the only thing you write — no \`${BOARD}\`, no source file, no commits.

**Fix the apply instructions; do not re-plan.** The audit's own finding is that the plan's structure is sound and its defects are in how it tells an applier to execute. Changing the node structure now would invalidate a migration map that is currently correct.

Rules for this repair:
- **Never express preservation as a line range.** "PRESERVE VERBATIM lines 1-244" is the defect: it reads as careful and deletes whatever sits below the cut. Replace every such range with an explicit enumeration of the sections and the closed \`[x]\` boxes that survive, by their text.
- **Never reuse a retired requirement number.** New boxes take the next free integer; a vacated number stays a gap, so the existing commit messages citing "requirement N" still resolve to what they meant.
- **A collision is not a choice.** Where the audit found one node given two contradictory instructions, resolve it explicitly so an applier has exactly one reading.
- **Every \`verify:\` must name a command from the list in the facts above.** If a node's gate is not on that list, either replace it with one that is, or state plainly in that node's body that it has no runnable gate yet — do not leave a command that cannot run.
- Where the audit says a claim in the document is refuted by the document's own tables, fix the CLAIM to match the tables, not the tables to match the claim.
- Where a fix would require a decision the plan cannot make (a spec contradiction, a scheduling mechanism that does not exist), write it into the affected node's body as a stated wall or an explicit \`## Out of scope\` line, and say in the document that it is unresolved. Do not paper over it.
- Keep the document's structure and its section order. Keep the migration map's arithmetic.

THE AUDIT:
${audit}

Return a numbered list: for each required fix, what you changed and where in the document. If you did NOT apply one, say which and why — an unapplied fix silently dropped is the same failure the audit exists to catch.`,
		at('judge', { label: `repair-r${round}`, phase: 'Repair', effort: 'medium' }),
	)

	log(`round ${round} repaired`)

	phase('Re-audit')
	audit = await agent(
		`${GROUND}

You are the ADVERSARY. A board restructure is proposed at \`${PROPOSAL}\`. Read it in full. Your job is to find what it BREAKS, not to confirm that it reads well. Default to "not safe to apply" and let the document talk you out of it.

You are deliberately not told what any previous reviewer found. Derive everything yourself.

Check, in this order:

1. **Preservation.** For every node the plan REWRITES, does the document say exactly which existing content survives — by section name and by box text, not by line range? Open each node file and list any closed \`[x]\` box or recorded \`## Decisions\` / \`## Findings\` / \`## Sequencing\` section that the instructions would destroy. Law 1: deletion is not expressible.

2. **Numbering.** Does any node end up with two boxes carrying the same requirement number, or a new box reusing the number of a retired one? Check against the ${facts.citations.length} citation(s) in the facts above: would any of them now resolve to different content?

3. **Losslessness, against the BOARD — not against the map.** A map balances against itself and is still short when the inventory it came from is stale. In this order:
   a. Re-count the board on disk yourself, per file, every \`- [ ]\` and \`- [~]\` under any heading, with a total.
   b. Compare to the facts above (${facts.open} open + ${facts.stub} stub = ${facts.open + facts.stub}) AND to what the plan says it inventoried. More boxes on disk than in the inventory means the plan is stale, and the difference is exactly what it silently deletes. Name those boxes.
   c. Check \`git rev-parse HEAD\` against \`${facts.head}\` and against the commit the plan says it was built at. If HEAD moved, read every commit since **with its body**, hunting specifically for a requirement **added in place** on an existing node — the node's own prose above it still describes the old shape, so no reader of the plan can catch it.
   d. Then the map against itself: ids in, placed, missing, duplicated.
   Report all four counts.

4. **Retirements.** Every "already met" claim — check it against the code yourself. A wrong retirement closes with a false proof, which is worse than a lost box.

5. **Addresses.** Any node id renamed or moved? List every path that changes and every commit referencing the old one.

6. **Closed and claimed nodes.** Does the plan touch anything \`done\`, \`out-of-scope\`, or carrying a \`claim:\`? Re-check the claim fields yourself — one may have been claimed since the facts above were taken. A change to a closed node needs a quoted \`lie\` finding; a change to a claimed node needs nothing, because it is not permitted at all.

7. **Verify commands.** Every \`verify:\` in the proposal, against the list of commands that exist: ${facts.recipes.map(r => `\`${r}\``).join(', ') || '(no runner)'}. Does it exist? Does any file it names sit on disk? And does it prove anything, or pass vacuously over an empty or fully-excluded set? A gate that finds nothing to check must fail, not pass.

8. **The real ready set.** Compute it yourself per \`worker.md\` §2 for the board AS THE PLAN WOULD LEAVE IT — \`(open ∨ reopened) ∧ unclaimed ∧ afk ∧ no \`## Escalation\` ∧ every child covered\`. Do not accept the plan's stated waves unless something on the board actually encodes them. Then take that real set and check every pair for a shared source directory. If two concurrently-claimable nodes write the same directory, the plan's parallelism claim is false and you say so with the pair and the directory.

9. **Spec contradictions.** Does any new requirement contradict ${facts.memoDir ? `the design record in \`${facts.memoDir}\` that specs its area` : 'another requirement in the same node, or the root node\'s purpose'}? That is a wall.

Return GitHub-flavoured markdown. **The FIRST line must be exactly one of** \`SAFE TO APPLY\`, \`SAFE WITH FIXES\`, or \`DO NOT APPLY\` — nothing else on that line. Then:
## Why
## Preservation defects
## Numbering defects
## Losslessness
## Wrong retirements
## Address / claim violations
## Verify commands
## The real ready set, and its collisions
## Fixes required before applying
numbered, each actionable in a sentence. Empty sections say "none".`,
		at('judge', { label: `audit-r${round}`, phase: 'Re-audit' }),
	)

	verdict = String(audit || '').trim().split('\n')[0].toUpperCase()
	log(`round ${round} verdict: ${verdict}`)
}

return {
	rounds: round,
	verdict,
	audit,
	proposal: PROPOSAL,
	head: facts.head,
	boardBoxes: { open: facts.open, stub: facts.stub, closed: facts.closed },
	safe: /^\s*(SAFE TO APPLY|SAFE WITH FIXES)/i.test(verdict),
	reconcile: reconcile ? { report: reconcile.reportPath, surviving: reconcile.surviving, killed: reconcile.killed, board: reconcile.board } : (A.reconcile || 'not swept — a proposal was supplied'),
	replan: replan ? { winner: replan.winner, scores: replan.scores, protected: replan.protected, inventoryItems: replan.inventoryItems } : 'not replanned — a proposal was supplied',
	// A workflow has no channel to the user, so it decides nothing that is the
	// user's to decide. Everything of that kind is left where a reader will
	// find it, and named here so it is not mistaken for settled.
	decisions: 'This wrote a PROPOSAL, never the board. Read the proposal and the audit before applying: anything the audit demands that is a scope, naming or cost call is the user\'s, and a workflow cannot ask. Apply only after a human has answered those.',
	next: /^\s*(SAFE TO APPLY|SAFE WITH FIXES)/i.test(verdict)
		? 'have a human read the proposal, then apply it to the board'
		: `still ${verdict} after ${round} round(s) — read the audit's required fixes; the plan is usually sound and the defects are in the apply instructions`,
}
