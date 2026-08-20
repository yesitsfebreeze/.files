export const meta = {
	name: 'mi-replan',
	description: 'Merge and resort the open board into one streamlined forward plan — inventory, three independent plans, a judge, then a written proposal that is checked for losslessness. Writes a proposal, never the board.',
	whenToUse: 'After a reconcile, when the board has drifted into fragments: duplicate requirements across nodes, parent checklists that disagree with their children, work specced in a record and placed nowhere. Produces the proposed board for a human to approve.',
	phases: [
		{ model: 'haiku', title: 'Profile', detail: 'discover the repo and census the board' },
		{ model: 'sonnet', title: 'Inventory', detail: 'every open box against the code, the overlaps, the real dependency order, the unplaced work' },
		{ model: 'opus', title: 'Plan', detail: 'three independent plans from three angles' },
		{ model: 'opus', title: 'Judge', detail: 'score them, synthesize the winner, graft the runners-up' },
		{ model: 'opus', title: 'Draft', detail: 'render the proposed board, node by node, with the migration map' },
		{ model: 'opus', title: 'Refute', detail: 'is anything lost, reopened without cause, or contradicting a spec?' },
	],
}

// ─────────────────────────────────────────────────────────────────────────
// mi-replan — reordering and writing, not reporting.
//
// A drift report tells you the record is wrong in 98 places. It does not give
// you a plan. This does the other half: it takes the open work, merges the
// requirements that are the same requirement, resorts them into the order the
// code actually imposes, and renders the result as a board you could apply.
//
// It writes a PROPOSAL and never the board. Applying it is a separate,
// human-approved step, because a board restructure moves the addresses that
// live claims are committed against.
//
// Nothing below the args block names a language, a build tool or a package.
// See `_lib.md`.
//
// args:
//   { repo, board, planDir,
//     reconcile: '/abs/path/report.md',  // the drift sweep to fold in
//     protect: ['<node path>'],          // nodes under a live claim
//     scope: 'open' | 'all',             // default 'open'
//     seeds: ['...'], models, effort }
// ─────────────────────────────────────────────────────────────────────────

const A = (typeof args === 'object' && args) || {}
const REPO = (typeof args === 'string' && args) || A.repo || 'the repo rooted at your cwd (`git rev-parse --show-toplevel`)'
const BOARD = A.board || '.mi/prd'
// The protocol reference files. They live beside these scripts, so a repo that
// symlinks `.mi/workflows` at the shared home gets them for free — the refs
// travel with the workflows instead of being installed per repo. They are read
// on demand by the agents that need them, not registered as a skill.
const REFS = A.refs || '.mi/workflows/refs'
// Plan artifacts live OUTSIDE the repository: a proposal is not yet a fact
// worth a commit, and a scratch file inside `.mi/` is walked by the tree-wide
// gates, so every gate run would depend on whatever a planner last wrote.
const PLAN_DIR = A.planDir || '/tmp/mi-plan'
const PROPOSAL = `${PLAN_DIR}/plan.proposed.md`
const SCOPE = A.scope || 'open'
const SEEDS = A.seeds || []
let PROTECT = A.protect || []

// ── model policy ─────────────────────────────────────────────────────────
// Note where the line falls here: the inventory is `probe` because every one
// of its claims is re-derived from the tree by the Refute step, but the plans,
// the judge and the draft are `judge` because NOTHING downstream checks them —
// a planner that quietly loses a requirement is not caught by anything later.
const MODELS = Object.assign({ scan: 'haiku', probe: 'sonnet', judge: 'opus', build: 'opus' }, A.models || {})
const EFFORTS = Object.assign({ scan: 'low', probe: 'medium', judge: 'high', build: 'high' }, A.effort || {})
const at = (tier, o) => Object.assign({ model: MODELS[tier], effort: EFFORTS[tier] }, o || {})

const PROFILE_SCHEMA = {
	type: 'object', additionalProperties: false,
	required: ['head', 'dirty', 'ecosystem', 'packages', 'sourceRoots', 'runner', 'recipes', 'memoDir', 'docs', 'contextFile', 'notes'],
	properties: {
		head: { type: 'string' },
		dirty: { type: 'string' },
		ecosystem: { type: 'string', description: 'the build system actually on disk — read the manifests, do not guess from the language' },
		sourceRoots: { type: 'array', items: { type: 'string' } },
		runner: { type: 'string', description: 'the task runner this repo uses (just / make / npm scripts / none), and the file it is defined in' },
		recipes: { type: 'array', items: { type: 'string' }, description: 'every recipe or script the runner actually defines — this is the whitelist a `verify:` command must come from' },
		memoDir: { type: 'string', description: 'the design-record directory if this repo has one, else ""' },
		docs: { type: 'array', items: { type: 'string' }, description: 'prose documents that carry per-item state about the work' },
		contextFile: { type: 'string' },
		notes: { type: 'string' },
		packages: { type: 'array', items: { type: 'object', additionalProperties: false, required: ['name', 'dir'], properties: { name: { type: 'string' }, dir: { type: 'string' } } } },
	},
}

const CENSUS_SCHEMA = {
	type: 'object', additionalProperties: false,
	required: ['nodes', 'totals'],
	properties: {
		totals: { type: 'string', description: 'node count and the tree-wide open / stub / closed totals' },
		nodes: {
			type: 'array',
			items: {
				type: 'object', additionalProperties: false,
				required: ['path', 'title', 'state', 'mode', 'priority', 'verify', 'claim', 'open', 'stub', 'closed', 'escalation', 'children', 'memo'],
				properties: {
					path: { type: 'string', description: 'node directory relative to the board root; the root node is "."' },
					title: { type: 'string' }, state: { type: 'string' }, mode: { type: 'string' },
					priority: { type: 'integer', description: '-1 if absent' },
					verify: { type: 'string' }, claim: { type: 'string' },
					open: { type: 'integer' }, stub: { type: 'integer' }, closed: { type: 'integer' },
					escalation: { type: 'boolean' },
					children: { type: 'array', items: { type: 'string' } },
					memo: { type: 'string' },
				},
			},
		},
	},
}

phase('Profile')

const [profile, census] = await parallel([
	() => agent(
		`Repository: ${REPO}. READ ONLY — never edit, never commit, never run the test suite or a full build.

Profile this repository for the planners that come after you.

1. \`git rev-parse HEAD\` and \`git status --porcelain | head -20\`.
2. **The build system**, from the manifests actually on disk (\`Cargo.toml\`, \`package.json\`, \`go.mod\`, \`pyproject.toml\`, \`pom.xml\`, \`build.gradle\`, \`Gemfile\`, \`mix.exs\`, \`CMakeLists.txt\`, \`Makefile\`), and the packages, from its own metadata command where one exists.
3. **\`recipes\` — the whitelist.** List EVERY recipe or script this repo's task runner defines: \`just --list\`, \`make -qp\`, the \`scripts\` block of \`package.json\`, the CI workflow jobs. A later step checks every proposed \`verify:\` command against this list, so completeness here is what stops the plan proposing a gate that cannot run. If there is no runner, return the ecosystem's plain commands and say so.
4. **The record layers** — a design-record directory, the context file, and which prose documents carry per-item state about the work (a roadmap, a status page, a handoff note). Those are where work gets specced and then placed nowhere.`,
		at('scan', { label: 'profile', phase: 'Profile', schema: PROFILE_SCHEMA }),
	),
	() => agent(
		`Repository: ${REPO}. READ ONLY.

Census the board at \`${BOARD}\`. Mechanical: parse and count, judge nothing.

1. \`find ${BOARD} -name prd.md | sort\`. Each is a node; \`path\` is its DIRECTORY relative to \`${BOARD}\`, the root node's path is \`.\`.
2. Parse the \`---\` frontmatter, every field **verbatim**. Illegal values are reported as written, not repaired. Missing \`priority\` is \`-1\`; other missing fields are \`""\`.
3. Count boxes across the WHOLE file, under ANY heading: \`- [ ]\` → \`open\`, \`- [~]\` → \`stub\`, \`- [x]\` → \`closed\`. Counting only under \`## Requirements\` is what lets an unmet acceptance clause hide.
4. \`escalation\`: does the file carry an \`## Escalation\` heading. \`children\`: node directories one level below that hold their own \`prd.md\`. \`memo\`: the design record the node names as its spec, or \`""\`.

A node you skip is a requirement this plan deletes.`,
		at('scan', { label: 'census', phase: 'Profile', schema: CENSUS_SCHEMA }),
	),
])

if (!profile) return { error: 'profile failed' }
if (!census || !census.nodes || !census.nodes.length) return { error: `no board found at ${BOARD}`, profile }

// Any node under a live claim is protected whether or not the caller named it.
// A restructure that moves an address another session holds a claim against is
// the one failure this workflow must never commit.
const claimedNodes = census.nodes.filter(n => n.claim).map(n => n.path)
for (const p of claimedNodes) if (PROTECT.indexOf(p) === -1) PROTECT.push(p)

const openNodes = census.nodes.filter(n => n.open + n.stub > 0)
const boardOpen = census.nodes.reduce((n, x) => n + x.open, 0)
const boardStub = census.nodes.reduce((n, x) => n + x.stub, 0)

log(`${profile.ecosystem} · ${census.nodes.length} nodes · ${boardOpen} open + ${boardStub} stubbed boxes across ${openNodes.length} node(s)${PROTECT.length ? ` · protected: ${PROTECT.join(', ')}` : ''}`)

const CENSUS_TEXT = census.nodes.map(n => `- \`${n.path}\` — ${n.title} · state:${n.state} mode:${n.mode} prio:${n.priority}${n.claim ? ` **claim:${n.claim}**` : ''} · ${n.open}open/${n.stub}stub/${n.closed}closed${n.escalation ? ' · ESCALATED' : ''}${n.verify ? ` · verify: \`${n.verify}\`` : ''}${n.memo ? ` · spec: ${n.memo}` : ''}`).join('\n')

const GROUND = `Repository: ${REPO}.

THE PROTOCOL — read it first, it beats your instincts:
- \`${REFS}/laws.md\` — the four laws.
- \`${REFS}/worker.md\` — the board protocol. The node format is Appendix A; placing a new requirement is Appendix B (descend / add in place / split / refuse). Boxes: \`- [ ]\` unmet · \`- [~]\` met against a STUB · \`- [x]\` met against the real thing with the check run.
${profile.contextFile ? `- \`${profile.contextFile}\` — the tree and the conventions.` : ''}

THE REPOSITORY, profiled at \`${profile.head}\`:
- build system: ${profile.ecosystem}
- packages: ${profile.packages.map(p => `\`${p.name}\` (${p.dir})`).join(', ') || '(one, unnamed)'}
- implementations under: ${(profile.sourceRoots || []).join(', ') || '(unknown)'}
- task runner: ${profile.runner}
- **the only commands a \`verify:\` may name**, because these are the ones that exist: ${(profile.recipes || []).map(r => `\`${r}\``).join(', ') || '(no runner — use the ecosystem\'s plain commands)'}
- design records: ${profile.memoDir || '(none — a node\'s own Requirements / Acceptance / Out of scope IS its spec)'}
- prose carrying per-item state: ${(profile.docs || []).join(', ') || '(none)'}

THE BOARD, censused at that commit — ${boardOpen} open and ${boardStub} stubbed boxes in total:
${CENSUS_TEXT}
${SEEDS.length ? `\nTHE CALLER'S SEEDS — specific things to look at first. Leads, not conclusions:\n${SEEDS.map(s => `- ${s}`).join('\n')}` : ''}

THE CONSTRAINTS ON ANY PLAN YOU PROPOSE, and they are not negotiable:

1. **Closed nodes are the record.** ${SCOPE === 'open' ? 'A node that is `done` or `out-of-scope` is NOT re-planned, NOT renamed, NOT moved, NOT reworded. Law 1: corrections are appended and shadow the old value; deletion is not expressible. You may propose that a closed node be REOPENED only where a surviving finding of severity `lie` proves it closed something it did not do — and you must quote that finding.' : 'You may restructure closed nodes, but only by SUPERSESSION: the old node stays where it is, gains a `superseded_by` link, and the new node links back. Nothing is deleted or overwritten.'}
2. **A node id is an address.** A claim is a git commit against \`${BOARD}/<path>/prd.md\`. Renaming or moving a node breaks every commit that referenced it. Propose a new id only when the node is genuinely new; prefer to reuse the existing id and rewrite the body. The same holds one level down: a **requirement number** is cited by commit messages, so renumbering an existing requirement silently rewrites what those commits say they did.
3. **Nodes under a live claim are untouchable**: ${PROTECT.length ? PROTECT.map(p => `\`${p}\``).join(', ') : '(none carry a `claim:` right now — but re-check before you write, another session may have claimed one since)'}. Read them so your plan is consistent with what they will land, and change nothing about them.
4. **Merging must be lossless.** Every open \`- [ ]\` and every stubbed \`- [~]\` box on the board today — all ${boardOpen + boardStub} of them — must land somewhere in your plan: merged into another box, carried forward verbatim, or explicitly retired with a reason and the evidence that it is already met. A box that simply disappears is the failure mode this whole exercise exists to prevent.
5. **One requirement, one home.** If two nodes carry the same requirement in different words, that is the merge. Say which text survives and why.
6. **You implement nothing.** No source file is edited by anyone in this workflow.`

const INVENTORY_SCHEMA = {
	type: 'object', additionalProperties: false,
	required: ['dimension', 'items', 'coverage'],
	properties: {
		dimension: { type: 'string' },
		coverage: { type: 'string', description: 'what you actually read, and what you could not cover' },
		items: {
			type: 'array',
			items: {
				type: 'object', additionalProperties: false,
				required: ['id', 'node', 'text', 'state', 'truth', 'notes'],
				properties: {
					id: { type: 'string', description: 'a stable handle you invent: node stem + requirement number, e.g. "auth-r2"' },
					node: { type: 'string', description: 'node path relative to the board root' },
					text: { type: 'string', description: 'the box line verbatim; the first sentence is enough to identify it' },
					state: { type: 'string', enum: ['open', 'stub', 'closed'] },
					truth: { type: 'string', enum: ['genuinely-open', 'already-done', 'partly-done', 'unverifiable', 'unknown'], description: 'what the CODE says, not what the box says' },
					notes: { type: 'string', description: 'the evidence for `truth`: the symbol, path or test you found, or what you could not find' },
				},
			},
		},
	},
}

const PLAN_SCHEMA = {
	type: 'object', additionalProperties: false,
	required: ['angle', 'thesis', 'nodes', 'merges', 'retired', 'order', 'risks'],
	properties: {
		angle: { type: 'string' },
		thesis: { type: 'string', description: 'two sentences: the organising idea, and what it optimises for' },
		order: { type: 'string', description: 'the resulting sequence of node ids, and the one sentence that justifies the ordering' },
		risks: { type: 'string', description: 'what this ordering gets wrong, honestly' },
		nodes: {
			type: 'array',
			items: {
				type: 'object', additionalProperties: false,
				required: ['path', 'disposition', 'title', 'purpose', 'priority', 'verify', 'requirements', 'acceptance', 'outOfScope', 'absorbs', 'footprint'],
				properties: {
					path: { type: 'string', description: 'node path relative to the board root — an EXISTING path wherever the node survives' },
					disposition: { type: 'string', enum: ['keep', 'rewrite', 'new', 'absorb-into-parent', 'close-as-met', 'reopen'] },
					title: { type: 'string' },
					purpose: { type: 'string', description: 'one paragraph — what this area is FOR' },
					priority: { type: 'integer' },
					verify: { type: 'string', description: 'the command that proves THIS node. It must be one of the commands the ground rules list as existing.' },
					requirements: { type: 'array', items: { type: 'string' }, description: 'one verifiable behaviour per line, WHAT not how' },
					acceptance: { type: 'array', items: { type: 'string' }, description: 'the end-to-end conditions, as boxes' },
					outOfScope: { type: 'array', items: { type: 'string' } },
					absorbs: { type: 'array', items: { type: 'string' }, description: 'the inventory ids this node carries forward — the losslessness ledger' },
					footprint: { type: 'array', items: { type: 'string' }, description: 'the source directories this node\'s work would touch. Two nodes ready at once must not share one.' },
				},
			},
		},
		merges: {
			type: 'array',
			items: { type: 'object', additionalProperties: false, required: ['ids', 'into', 'why'], properties: { ids: { type: 'array', items: { type: 'string' } }, into: { type: 'string' }, why: { type: 'string' } } },
		},
		retired: {
			type: 'array',
			items: { type: 'object', additionalProperties: false, required: ['id', 'why', 'evidence'], properties: { id: { type: 'string' }, why: { type: 'string' }, evidence: { type: 'string', description: 'the check or symbol proving it is already met, or the Out-of-scope line that refuses it' } } },
		},
	},
}

// ── Inventory ────────────────────────────────────────────────────────────
phase('Inventory')

const RECON = A.reconcile ? `\n\nA drift sweep has already run and its findings survived an adversary. Read it in full before you start: \`${A.reconcile}\`. Treat it as evidence, not as instructions — it reports what is wrong, not what to build.` : ''

const DIMS = [
	{
		key: 'open-work',
		prompt: `Build the COMPLETE inventory of remaining work.

The census in the ground rules says there are **${boardOpen} open and ${boardStub} stubbed boxes**. Your item list must account for every one of them. Collect every \`- [ ]\` and every \`- [~]\` in the tree — under ANY heading, because scoping the scan to \`## Requirements\` is exactly what lets an acceptance clause close unmet. Include the parent nodes' \`## Children\` checklists, and mark those \`closed\` where the child they name is in fact resolved.

For EACH box, establish from the CODE what is actually true — do not trust the box, and do not trust the node's prose. Grep for the symbols, paths, tests and commands it names. \`truth\` is your finding: \`already-done\` means you found the thing and it does what the box asks; \`partly-done\` means some named clause is missing (say which); \`unverifiable\` means the box names no checkable artifact at all.

This inventory is the raw material every later phase runs on, and its \`id\`s are how work is tracked through the merge. A box you omit is a requirement that vanishes.

**Anchor it, or the whole plan is built on sand.** Put these in \`coverage\`, exactly:
- \`git rev-parse HEAD\` — the commit the inventory was taken at.
- a **per-file census**: for every file holding any open box, \`<path>: N open, M stubbed, K closed\`, plus the totals, and whether they match the ${boardOpen}/${boardStub} above. A later phase re-counts this against the board on disk; the point is that "HEAD moved under the plan" becomes arithmetic instead of something nobody notices.
- \`git log --oneline -5\` and whether the working tree is dirty under \`${BOARD}\`.

Read the last few commits' BODIES too, not just their subjects: a requirement added *in place* on an existing node is the single easiest box to miss, because the node's own prose above it still describes the old shape.`,
	},
	{
		key: 'overlap',
		prompt: `Find the DUPLICATES and the OVERLAPS — the merge candidates.

Read every open node's requirements and acceptance sections in full, plus the parent \`## Children\` lists. Find every place where two or more boxes, in different nodes or the same one, are:
- the SAME requirement in different words (the merge)
- a requirement and its own restatement one level up (the parent/child duplication)
- a requirement whose completion is implied by another's (the subsumption)
- two halves of one thing that was split when it should not have been

For each cluster give every member's \`id\` in \`notes\`, put the text that should SURVIVE in \`text\`, and set \`truth\` to your read of the cluster's real state.

Two structural signals to hunt deliberately, in any board:
- **A parent with more open boxes than any of its children.** That is the classic sign of a node that was never split properly: the work stayed in the parent and the children became labels. The census in the ground rules gives you every node's counts — find these first.
- **Two sibling nodes whose purpose paragraphs describe the same subject from different sides.** They are usually one node.`,
	},
	{
		key: 'dependency',
		prompt: `Derive the REAL dependency order of the remaining work — from the code and the specs, not from the priority numbers.

For each open node and each of its open boxes: what must exist before this can be done, and what does doing it unblock? Ground every edge in something concrete — a type that does not exist yet, a package that cannot reach another (check the dependency direction in the manifests, and in whatever gate this repo has that enforces it), a seam that is not wired, a format that has to settle before a consumer can read it.

Report each edge as an item: \`text\` = "A must precede B", \`notes\` = the concrete reason with the symbol or package that forces it, \`truth\` = \`genuinely-open\` if the edge is real and \`unknown\` if you are inferring it from prose.

Call out explicitly:
- any CYCLE the board currently implies, and where it breaks.
- any node whose stated priority contradicts the real order. Priorities on this board were assigned one node at a time and encode no global order; say where they mislead.
- **the hardest edge in the graph** — the one thing whose absence blocks the most other work. Verify it in the manifests rather than asserting it, because if it holds it decides the whole ordering.`,
	},
]

if (profile.memoDir || (profile.docs || []).length) {
	DIMS.push({
		key: 'unplaced',
		prompt: `Find the work that is SPECCED but not on the board, and the board work with no spec.

1. ${profile.memoDir ? `Read every design record in \`${profile.memoDir}\` — especially its declared status and every "what is not done" / "open" / "still open" section. Each thing a record names as decided-but-not-done is work. For each, check whether any board node carries it.` : 'This repo has no design-record layer, so skip to step 2.'} What is decided, recorded, and assigned to nobody is the most dangerous kind of work there is — law 3, a rule that cannot run is a wish.
2. The reverse: any open board box whose subject no record covers. A node with no spec has only its own requirements and nothing to be a wall against.
3. ${(profile.docs || []).length ? `These documents also carry per-item state: ${profile.docs.join(', ')}. Anything they call open that the board does not carry is unplaced too.` : 'No prose documents carry per-item state here.'}
4. And the direction nobody looks: work the CODE clearly implies is coming — a TODO with a ticket, a stub with a named successor, a feature flag with no second branch, an interface with one implementation where the record promises two. Report each with its file:line.

Report each as an item: \`node\` = the record or document it came from, \`text\` = the work, \`truth\` = what the code says about it, \`notes\` = where it is specced and whether any board node covers it.`,
	})
}

const inventory = await parallel(DIMS.map(d => () => agent(
	`${GROUND}${RECON}\n\nYou are the ${d.key.toUpperCase()} auditor. READ ONLY — never edit, never commit. Do not run the test suite or a full build (slow, and other sessions may be building); scoped greps, metadata commands, \`git log\` and reading files are all fine.\n\n${d.prompt}`,
	at('probe', { label: `inv:${d.key}`, phase: 'Inventory', schema: INVENTORY_SCHEMA }),
)))

const inv = inventory.filter(Boolean)
const invText = inv.map(r => `### ${r.dimension}\n_coverage: ${r.coverage}_\n\n` + (r.items || []).map(i => `- **${i.id}** [${i.node}] (${i.state} / code says: ${i.truth})\n  ${i.text}\n  → ${i.notes}`).join('\n')).join('\n\n')
const totalItems = inv.reduce((n, r) => n + (r.items || []).length, 0)
log(`inventory: ${totalItems} items across ${inv.length} dimensions`)

// ── Plan (three angles, independently) ───────────────────────────────────
phase('Plan')

const ANGLES = [
	{
		key: 'dependency-first',
		brief: `Order by what UNBLOCKS the most. The plan's spine is the dependency graph: the thing the largest number of other things wait on goes first, and a node exists exactly where the graph has a joint. Optimise for never being blocked — at every point in the sequence there should be parallel work available whose footprints do not collide. You are allowed to make a node BIGGER if splitting it would create a false boundary that forces two workers into one directory.`,
	},
	{
		key: 'risk-first',
		brief: `Order by what could INVALIDATE the rest. Somewhere in this repository's records is a decision that everything else is built on top of and that has been decided but not executed — a data shape, a protocol, a boundary, a storage format. Find it: read the design records and the root node's purpose, and identify the bet the whole tree rests on. If that bet is wrong, every piece of work built above it is wasted. So front-load whatever would prove or break the settled design earliest and cheapest, and defer anything whose cost is merely linear in how late it is done. Optimise for finding out you are wrong while it is still cheap, and name the bet explicitly in \`thesis\`.`,
	},
	{
		key: 'shipping-first',
		brief: `Order by what makes this thing USABLE end to end soonest. Read the root node's purpose and whatever document says what a user can actually do with this today. Find the shortest path to something a person can run start to finish — and make everything else wait behind it. A demo that is real beats four subsystems that are each 80% done. Be honest in \`risks\` about what this defers and what debt it takes on.`,
	},
]

const plans = await parallel(ANGLES.map(a => () => agent(
	`${GROUND}${RECON}

You are the ${a.key.toUpperCase()} planner. Two other planners are producing plans from different angles from the same inventory; you will be judged against them. Commit to your angle — a plan that hedges toward the middle loses to all three.

YOUR ANGLE: ${a.brief}

THE INVENTORY — every open box on the board, what the code says about each, the overlaps, the real dependency edges${profile.memoDir ? ', and the work that is specced but placed nowhere' : ''}:

${invText}

Produce THE PROPOSED BOARD. Not a critique, not a list of fixes — the actual tree of nodes as it should be, with every requirement written out. For each node give its path (reuse existing paths wherever the node survives), its disposition, and its full body: purpose, requirements, acceptance, out-of-scope.

Rules that decide whether your plan is any good:
- **\`absorbs\` is the ledger.** Every node lists the inventory ids it carries. Across your whole plan every id must appear exactly once — in some node's \`absorbs\`, in a \`merges\` entry, or in \`retired\` with evidence. This is checked arithmetically. A plan that loses requirements is rejected regardless of how good its ordering is.
- **Requirements say WHAT, verifiably.** No requirement that cannot be checked by something. A soft line becomes soft code.
- **\`verify:\` must be a command that exists today**, from the list in the ground rules. A \`verify:\` naming a recipe that was deleted, or one you wish existed, is a node that would close with no proof.
- **\`footprint\` is what makes the plan runnable.** Two nodes that are ready at the same time must not share a source directory, or the parallel runner serialises no matter how many agents it is given. Fewer, larger nodes beat more, smaller ones where the smaller ones would share a directory — but do not merge across a real contract boundary just to reduce the count.
- **Say what you are NOT doing.** \`## Out of scope\` is the line that stops drift, and a plan whose nodes have empty out-of-scope sections has not made any decisions.
- Do not touch closed nodes${PROTECT.length ? ' or the protected nodes named above' : ''}.`,
	at('judge', { label: `plan:${a.key}`, phase: 'Plan', schema: PLAN_SCHEMA }),
)))

const good = plans.filter(Boolean)
log(`${good.length} plan(s): ${good.map(p => `${p.angle} (${p.nodes.length} nodes, ${p.merges.length} merges, ${p.retired.length} retired)`).join(' · ')}`)

if (!good.length) return { error: 'no plan produced', inventory: inv }

// ── Judge ────────────────────────────────────────────────────────────────
phase('Judge')

const JUDGE_SCHEMA = {
	type: 'object', additionalProperties: false,
	required: ['winner', 'scores', 'grafts', 'reasoning'],
	properties: {
		winner: { type: 'string' },
		reasoning: { type: 'string' },
		scores: {
			type: 'array',
			items: {
				type: 'object', additionalProperties: false,
				required: ['angle', 'lossless', 'ordering', 'parallelism', 'honesty', 'total', 'why'],
				properties: {
					angle: { type: 'string' },
					lossless: { type: 'integer', description: '0-10: does every inventory id have exactly one home?' },
					ordering: { type: 'integer', description: '0-10: does the order respect the real dependency edges?' },
					parallelism: { type: 'integer', description: '0-10: can the first ready set be worked concurrently without two nodes sharing a directory?' },
					honesty: { type: 'integer', description: '0-10: verify commands that exist, no soft requirements, out-of-scope lines that decide something' },
					total: { type: 'integer' },
					why: { type: 'string' },
				},
			},
		},
		grafts: {
			type: 'array',
			items: { type: 'object', additionalProperties: false, required: ['from', 'what', 'why'], properties: { from: { type: 'string' }, what: { type: 'string' }, why: { type: 'string' } } },
		},
	},
}

const judged = await agent(
	`${GROUND}

You are the JUDGE. Three planners produced three full board proposals from one inventory, each committed to a different angle. Score them, pick a winner, and name what must be GRAFTED from the losers — a runner-up usually gets one or two things righter than the winner, and throwing those away is the cost of running a panel at all.

Score each on four axes, 0–10:
- **lossless** — every inventory id appears exactly once across \`absorbs\` + \`merges\` + \`retired\`. CHECK THIS ARITHMETICALLY against the inventory; do not take a plan's word. An id that appears nowhere is a lost requirement; an id in two places is a second home, which law 1 forbids.
- **ordering** — does the sequence respect the real dependency edges from the inventory, and does it break the cycles the board currently implies?
- **parallelism** — take each plan's first ready set and check their \`footprint\` lists for overlap. A plan whose ready set collides serialises the work no matter how many agents you throw at it.
- **honesty** — \`verify:\` commands drawn from the list of commands that exist, requirements naming a checkable artifact, out-of-scope lines that actually refuse something.

THE INVENTORY:
${invText}

THE PLANS:
${JSON.stringify(good, null, 1)}

Be a hard marker. A plan that reads well and loses three requirements scores below a blunt one that keeps them all.`,
	at('judge', { label: 'judge', phase: 'Judge', schema: JUDGE_SCHEMA }),
)

log(`winner: ${judged && judged.winner} · grafts: ${((judged && judged.grafts) || []).length}`)

// ── Draft ────────────────────────────────────────────────────────────────
phase('Draft')

const draft = await agent(
	`${GROUND}

You are the DRAFTER. Write the PROPOSAL — the streamlined plan a human will read and approve, and that a later applier will execute exactly.

Write it to \`${PROPOSAL}\`. That is the ONLY file you write. Do not touch \`${BOARD}\`, do not touch any source file, do not commit anything. It sits outside the repository on purpose: an unapproved proposal is not a fact worth a commit.

THE WINNER: ${judged && judged.winner}
${judged && judged.reasoning}

GRAFT THESE from the runners-up — the judge found them better than the winner's version, so they go in:
${JSON.stringify((judged && judged.grafts) || [], null, 1)}

THE PLANS (the winner is the base; take the grafts from the others):
${JSON.stringify(good, null, 1)}

THE INVENTORY, which is the losslessness ledger:
${invText}

The document, in this order and nothing else:

# The plan

## What changes, in one paragraph
The shape of the board before and after. A reader who stops here should know what they are approving.

## The plan
The forward sequence as a table: order | node | what it is | why here | what it unblocks. This is the streamlined plan — it is the point of the document.

## The board, node by node
For every node in the plan, in plan order, the COMPLETE file that would be written, in a fenced block, at its exact path:

\`\`\`markdown
--- ${BOARD}/<path>/prd.md ---
---
state: open
mode: afk
priority: <n>
verify: <a command from the list that exists>
---

# <Title>

Purpose: <one paragraph>

## Requirements
- [ ] <verifiable behaviour>

## Acceptance
- [ ] <end-to-end condition, as a box>

## Out of scope
- <the line that stops drift>
\`\`\`

Head each with its disposition — \`KEEP\` (unchanged), \`REWRITE\` (path survives, body replaced), \`NEW\`, \`ABSORB\` (folded into a parent, node retired), \`CLOSE-AS-MET\` (the code already does it — quote the evidence), \`REOPEN\` (quote the \`lie\` finding that justifies it).

**Six rules about REWRITE, and they are where every previous draft of this kind of document has failed.** A fenced \`--- path ---\` block reads to an applier as the file's WHOLE content, so anything the node currently holds that the block does not show is deleted. That is how a careful-looking instruction destroys the record.

1. **Never express preservation as a line range.** "PRESERVE VERBATIM lines 1-244" reads as careful and silently deletes whatever recorded decision sits below the cut. Enumerate what survives by **heading text** and, for boxes, by **number and first words**.
2. **A closed \`[x]\` box shown as a one-line summary means "copy this box's full body byte for byte out of the current file".** State that rule once in this section and restate it beside every such line. A closed box's body is often dozens of lines of close evidence — the check that would have proved the requirement — and a summary line is not a copy of it. This single rule covers most of what gets lost.
3. **Never reuse a retired requirement number.** A number is cited by commit messages in this repository's log, so reassigning it makes an old commit describe work it did not do. New boxes take the next free integer; a vacated number stays a **gap**. Run \`git log --format=%s%n%b | grep -nE 'requirement [0-9]'\` and check every citation still resolves to the same content after your rewrite.
4. **Enumerate the \`## Out of scope\` lines that survive.** These carry recorded user decisions — a reversal is the user's call, and an out-of-scope line dropped in a rewrite is that decision silently reversed.
5. **Carry \`[~]\` forward as \`[~]\`.** Downgrading a stub box to \`[ ]\` loses the honest record that a stub is load-bearing, even though both count as open.
6. **Every count you author must be measured at the moment you write it** — child counts, occurrence counts, package counts. A number written from the old tree is wrong the moment the plan lands, and it reads as authoritative the whole time.

And the check you ship for all of this must be **per file, never aggregate, and it must count all three box states**: record each rewritten file's \`[x]\`, \`[ ]\` and \`[~]\` counts before and after, and require that no file's count falls in any of the three. An aggregate \`- [x]\` count rises when bookkeeping boxes are added and hides closed boxes destroyed elsewhere — a green check over the exact defect it was written to catch. A check counting only \`[x]\` is the same failure one state over: it absorbs every deleted \`[ ]\` and \`[~]\`, which is where the *live* work is.

State that the inventory was taken at \`${profile.head}\`, and make the apply step's first instruction "verify HEAD is still that commit; if it moved, re-inventory before applying". A plan is a statement about a tree at a moment, and it goes stale in the one direction nobody checks.

## The migration map
A table with one row per inventory id: id | old node | where it goes | merged-with | verbatim / reworded / retired. **Every id in the inventory appears in this table exactly once.** Then the arithmetic spelled out: N ids in, N ids placed, 0 lost — and separately, the board's own count (${boardOpen} open + ${boardStub} stubbed = ${boardOpen + boardStub}) against the number of ids the inventory carries. If either does not come out, say so at the top of the document in bold. An unbalanced ledger is the one thing that must not be buried.

## What is deliberately not done
Closed nodes untouched, protected nodes untouched${profile.memoDir ? ', unplaced specced work you chose to leave unplaced and why' : ''}.

## The first ready set
The nodes that become ready the moment this is applied, and the source directories each one owns — this is what the parallel runner would pick up, so show that they do not collide.

## How to apply it
The exact sequence of \`git\` commits, one node per commit, in an order where the tree is never in a broken state. Name the commit messages.

Write in the tree's register: plain, specific, no salesmanship. Every claim about the code carries the symbol or path that proves it.`,
	at('judge', { label: 'draft', phase: 'Draft' }),
)

// ── Refute ───────────────────────────────────────────────────────────────
phase('Refute')

const audit = await agent(
	`${GROUND}

You are the ADVERSARY. A proposed board restructure has been written to \`${PROPOSAL}\`. Read it in full. Your job is to find what it BREAKS, not to confirm that it reads well. Default to "this is not safe to apply" and let the document talk you out of it.

Check, in this order, and stop being polite about it:

1. **Losslessness, against the BOARD — not against the map.** A map can balance perfectly against itself and still be short, because the inventory it was built from can be stale. So, in this order:
   a. Re-count the board on disk yourself, per file: every \`- [ ]\` and every \`- [~]\` under any heading. Get a total.
   b. Compare it to the census this run started from: **${boardOpen} open + ${boardStub} stubbed = ${boardOpen + boardStub}**. If the board has more open boxes than that, the plan is stale and the difference is exactly what it would silently delete. Find those boxes and name them.
   c. Check \`git rev-parse HEAD\` against \`${profile.head}\`. If HEAD moved, read every commit since — with bodies, not just subjects — hunting specifically for a requirement **added in place** on an existing node. That is the easiest box in the world to miss, because the node's own prose above it still describes the old shape, and no reader of the plan can tell.
   d. Only then check the map against itself: ids in, placed, missing, duplicated.
   Report all four counts. A missing box is a requirement this restructure deletes from the record, and if it is an open bug it deletes the only address anyone could claim to fix it.

2. **Retirements.** Every \`retired\` / \`CLOSE-AS-MET\` claim says the code already does it. Check each against the code yourself. A retirement that is wrong is worse than a lost box, because it closes with a false proof.

3. **Addresses.** Does the proposal rename or move any node id? A claim is a commit against a path. List every path that changes and every commit in \`git log\` that references the old one. Same one level down: any requirement RENUMBERED, against \`git log --format=%s%n%b | grep -nE 'requirement [0-9]'\`.

4. **Closed nodes.** Does it touch anything \`done\` or \`out-of-scope\`? ${SCOPE === 'open' ? 'Any such change is a violation unless it quotes a `lie` finding.' : 'Any such change must be a supersession, never an overwrite.'}

5. **Protected nodes.** ${PROTECT.length ? `Does it touch ${PROTECT.map(p => `\`${p}\``).join(', ')}? Those are under a live claim.` : 'Does it touch any node carrying a `claim:` field? Re-check every node yourself — one may have been claimed since this run started.'}

6. **The verify commands.** Every \`verify:\` in the proposal — does that command exist today? The commands that exist are: ${(profile.recipes || []).map(r => `\`${r}\``).join(', ') || '(no runner)'}. Check each against that list, against the manifests, and check that any file it names is on disk. Then the harder question: does it PROVE anything, or does it pass vacuously over an empty or fully-excluded set? A gate that finds nothing to check must fail, not pass.

7. **Parallelism, tested not asserted.** Take the proposal's own "first ready set", work out each node's real footprint yourself from the code, and check for overlap. If two ready nodes share a directory, the plan's central claim is false.

8. **Spec contradictions.** Does any new requirement contradict ${profile.memoDir ? 'the design record that specs its area' : 'another requirement in the same node, or the root node\'s purpose'}? That is a wall, and a plan that walks into one has not read its own spec.

THE INVENTORY:
${invText}

Return GitHub-flavoured markdown:
## Verdict
\`SAFE TO APPLY\` / \`SAFE WITH FIXES\` / \`DO NOT APPLY\`, then one paragraph.
## Lost or duplicated
the arithmetic, with ids.
## Wrong retirements
each one, with what the code actually shows.
## Address changes
every path and every requirement number that moves, and what references it.
## Broken verify commands
each one.
## Collisions in the first ready set
which nodes, which directory.
## Fixes required before applying
numbered, each one actionable in a sentence.`,
	at('judge', { label: 'refute-plan', phase: 'Refute' }),
)

return {
	proposal: PROPOSAL,
	plan: draft,
	audit,
	winner: judged && judged.winner,
	scores: judged && judged.scores,
	head: profile.head,
	boardBoxes: { open: boardOpen, stub: boardStub },
	inventoryItems: totalItems,
	protected: PROTECT,
	next: 'if the audit says DO NOT APPLY, the repair loop in /mi-repair takes it from here with { proposal, audit } — this workflow is normally called by it, not run alone',
}
