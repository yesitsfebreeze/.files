export const meta = {
	name: 'mi-run',
	description: 'One session on the board: take whatever is free within the global worker cap, reconcile each node you took against its spec and the code, then work them in parallel worktree lanes and land behind one gate run. Safe to launch as many times as you like, concurrently.',
	whenToUse: 'The entry point for a working session. Start as many as you want: each grabs different free nodes, because the claim commit is the lock. Use mi-replan separately for a whole-board restructure, which is exclusive.',
	phases: [
		{ model: 'haiku', title: 'Profile', detail: 'discover the repo and census the board — cheap, and every later prompt reads it' },
		{ model: 'sonnet', title: 'Capacity', detail: 'the footprint of what is free and of what other sessions hold' },
		{ model: 'sonnet', title: 'Grab', detail: 'claim node by node — the commit is the lock, the push decides the race' },
		{ model: 'sonnet', title: 'Reconcile', detail: 'each node you hold, against its spec and the code' },
		{ model: 'sonnet', title: 'Amend', detail: 'write the corrections into the nodes you hold' },
		{ model: 'opus', title: 'Work', detail: 'one agent per lane, each in its own git worktree' },
		{ model: 'opus', title: 'Refute', detail: 'an adversary tries to kill every [x] before it is written' },
		{ model: 'opus', title: 'Land', detail: 'merge, one gate run, close or release honestly' },
	],
}

// ─────────────────────────────────────────────────────────────────────────
// mi-run — one session, and N of them can run at once.
//
// The whole design follows from one fact: **the only cross-session lock is the
// per-node claim commit.** `<board>/<path>/prd.md` gets `claim: <session>`,
// committed alone, and with a remote the push decides the race.
//
// So everything a session does must be SCOPED TO WHAT IT HOLDS:
//
//   - **Grabbing** is safe: one commit per node, losing a race is normal.
//   - **Reconciling a node you hold** is safe, and not a special dispensation
//     — worker.md move 2 says amending your own node is free. That is exactly
//     why the reconcile here is per-node and not board-wide.
//   - **Working** is safe: one git worktree per lane, footprint-disjoint.
//   - **A whole-board replan is NOT safe** at any number of sessions above
//     one, because it rewrites the addresses every other session's claims are
//     committed against. It lives in `mi-replan`. A session never replans.
//
// Grab BEFORE reconciling, which is the opposite of the single-session order.
// With one session the sweep tells you what to take; with N sessions the race
// window is what matters, and a claim commit is milliseconds while a sweep is
// minutes. What a worker needs is its OWN node reconciled, not the board.
//
// The global cap (`max-workers` on the root node) is shared across sessions,
// so it is re-read before every claim and re-verified after. It is eventually
// consistent, not instantaneous: two sessions can both see one free slot and
// both claim a different node. The Grab phase detects that and releases its
// own excess rather than pretending the cap held.
//
// Nothing below the args block names a language, a build tool or a package.
// See `_lib.md`.
//
// args (all optional):
//   { repo, board, lanes, nodes, take, rounds, reconcile, dryRun,
//     gate, fullGate, seeds, models, effort }
// ─────────────────────────────────────────────────────────────────────────

const A = (typeof args === 'object' && args) || {}
const REPO = (typeof args === 'string' && args) || A.repo || 'the repo rooted at your cwd (`git rev-parse --show-toplevel`)'
const BOARD = A.board || '.mi/prd'
// The protocol reference files. They live beside these scripts, so a repo that
// symlinks `.mi/workflows` at the shared home gets them for free — the refs
// travel with the workflows instead of being installed per repo. They are read
// on demand by the agents that need them, not registered as a skill.
const REFS = A.refs || '.mi/workflows/refs'
const DRY = A.dryRun === true
const ROUNDS = A.rounds || 1
const SEEDS = A.seeds || []

// ── model policy ─────────────────────────────────────────────────────────
// Tiered by the KIND of thinking, not by how important the step feels.
//   scan  — enumerate, parse, count. Reproducible by re-running the command.
//   probe — establish what is TRUE, and a later step can falsify it.
//   judge — the adversary. Nothing downstream checks it, so it pays for itself.
//   build — writes the code and closes the record. Mistakes are durable.
// The global cap used when the board root carries no `max-workers`. 3 is enough
// that a wave of independent files actually overlaps, and few enough that a bad
// plan costs three worktrees rather than twelve. `/mi-max <N>` writes the board
// value, which is authoritative whenever it is present.
const DEFAULT_MAX_WORKERS = 3

const MODELS = Object.assign({ scan: 'haiku', probe: 'sonnet', judge: 'opus', build: 'opus' }, A.models || {})
const EFFORTS = Object.assign({ scan: 'low', probe: 'medium', judge: 'high', build: 'high' }, A.effort || {})
const at = (tier, o) => Object.assign({ model: MODELS[tier], effort: EFFORTS[tier] }, o || {})

// ─────────────────────────────────────────────────────────────────────────
// Profile — once, before the rounds. The gate commands are the field this
// exists for: a lane told to run a recipe that does not exist in THIS repo
// will invent one, and a lane that invents a build recipe collides with every
// other lane in the tree.
// ─────────────────────────────────────────────────────────────────────────
const PROFILE_SCHEMA = {
	type: 'object', additionalProperties: false,
	required: ['head', 'dirty', 'branch', 'upstream', 'ecosystem', 'packages', 'sourceRoots', 'sharedFiles', 'gate', 'fullGate', 'gateEvidence', 'memoDir', 'contextFile', 'testLayout', 'notes'],
	properties: {
		head: { type: 'string' },
		branch: { type: 'string' },
		upstream: { type: 'string', description: 'the upstream ref if the branch has one, else "" — this decides whether a push arbitrates the claim race' },
		dirty: { type: 'string', description: 'one-line summary of `git status --porcelain`, or "clean"' },
		ecosystem: { type: 'string', description: 'the build system actually on disk — read the manifests, do not guess from the language' },
		sourceRoots: { type: 'array', items: { type: 'string' }, description: 'directories implementations live in, relative to the repo root' },
		sharedFiles: { type: 'array', items: { type: 'string' }, description: 'files that belong to NO lane because every lane would collide on them — the workspace manifest, the lockfile, the task runner file, the formatter and linter configs, CI definitions' },
		gate: { type: 'string', description: 'the SCOPED check one lane runs on its own change: the fastest command in this repo that would actually fail on a broken change. Must exist today.' },
		fullGate: { type: 'string', description: 'the whole-tree check, run ONCE after all lanes merge. Must exist today.' },
		gateEvidence: { type: 'string', description: 'the recipe list, script block or manifest target you actually read to establish both commands exist' },
		memoDir: { type: 'string', description: 'the design-record directory if this repo has one, else ""' },
		contextFile: { type: 'string', description: 'CLAUDE.md / AGENTS.md / equivalent, or ""' },
		testLayout: { type: 'string', description: 'where this repo puts tests and what it forbids, quoted from its own context file — or "no stated convention"' },
		notes: { type: 'string' },
		packages: {
			type: 'array',
			items: { type: 'object', additionalProperties: false, required: ['name', 'dir'], properties: { name: { type: 'string' }, dir: { type: 'string' } } },
		},
	},
}

const CENSUS_SCHEMA = {
	type: 'object', additionalProperties: false,
	required: ['maxWorkers', 'nodes', 'notes'],
	properties: {
		maxWorkers: { type: 'integer', description: 'max-workers from the ROOT node, or 0 if there is no such field — do NOT substitute a default, the caller applies one' },
		notes: { type: 'string', description: 'HEAD sha and whether the tree is dirty under the board or the source roots' },
		nodes: {
			type: 'array',
			items: {
				type: 'object', additionalProperties: false,
				required: ['path', 'title', 'state', 'mode', 'priority', 'verify', 'claim', 'claimAgeHours', 'open', 'stub', 'closed', 'escalation', 'children', 'memo', 'summary'],
				properties: {
					path: { type: 'string', description: 'node directory relative to the board root; the root node is "."' },
					title: { type: 'string' },
					state: { type: 'string', description: 'verbatim — report an illegal value as written, do not repair it' },
					mode: { type: 'string' },
					priority: { type: 'integer', description: '-1 if absent' },
					verify: { type: 'string' },
					claim: { type: 'string', description: 'the claim: field verbatim, or ""' },
					claimAgeHours: { type: 'number', description: 'hours since the `claim <path>` commit, or -1 if unclaimed or no such commit' },
					open: { type: 'integer', description: 'count of `- [ ]` under ANY heading' },
					stub: { type: 'integer', description: 'count of `- [~]` under ANY heading' },
					closed: { type: 'integer', description: 'count of `- [x]` under ANY heading' },
					escalation: { type: 'boolean' },
					children: { type: 'array', items: { type: 'string' } },
					memo: { type: 'string', description: 'the design record this node names as its spec, or ""' },
					summary: { type: 'string', description: 'one line, from the node\'s own purpose paragraph — quoted, not invented' },
				},
			},
		},
	},
}

const FOOTPRINT_SCHEMA = {
	type: 'object', additionalProperties: false,
	required: ['footprints'],
	properties: {
		footprints: {
			type: 'array',
			items: {
				type: 'object', additionalProperties: false,
				required: ['path', 'dirs', 'exclusive', 'first', 'evidence'],
				properties: {
					path: { type: 'string' },
					dirs: { type: 'array', items: { type: 'string' }, description: 'every source directory this node\'s REMAINING work would touch, relative to the repo root. Err toward including one you are unsure about: a missed directory is a merge conflict between lanes, a spurious one only costs parallelism.' },
					exclusive: { type: 'boolean', description: 'true if the work is tree-wide — a rename, a gate that reads every file, a change to the workspace member list or a shared config — and cannot share a tree with anything' },
					first: { type: 'string', description: 'two sentences: what remains, and the first thing a worker should do' },
					evidence: { type: 'string', description: 'the greps and files that gave you the directory list' },
				},
			},
		},
	},
}

phase('Profile')

const profile = await agent(
	`Repository: ${REPO}. READ ONLY — never edit, never commit, and do NOT run the test suite or a full build (slow, and other sessions are building this tree right now). Reading files, \`git\`, \`grep\`, \`find\`, \`ls\` and metadata-printing commands are fine.

Profile this repository for the workers that come after you. Every field is established by running something, not guessed from the language.

1. \`git rev-parse HEAD\`, \`git branch --show-current\`, \`git rev-parse --abbrev-ref '@{upstream}' 2>/dev/null\` (empty if none), \`git status --porcelain | head -20\`.
2. **The build system.** Which manifests are on disk — \`Cargo.toml\`, \`package.json\`, \`go.mod\`, \`pyproject.toml\`, \`pom.xml\`, \`build.gradle\`, \`Gemfile\`, \`mix.exs\`, \`CMakeLists.txt\`, \`Makefile\`, \`justfile\`, \`Taskfile.yml\`? Name what is there.
3. **The packages**, from the build system's own metadata command where one exists, not from directory names.
4. **THE TWO GATES. This is the field this whole step exists for.**
   - \`gate\` — the fastest check ONE lane can run against its own change that would really fail on a broken one.
   - \`fullGate\` — the whole-tree check, run once at the end.
   List the runner's actual recipes first — \`just --list\`, \`make -qp | grep '^[a-z]'\`, the \`scripts\` block of \`package.json\`, the CI workflow files — and quote what you read into \`gateEvidence\`. **Never invent a recipe.** If this repo has no task runner, fall back to the ecosystem's plain command and say so in \`gateEvidence\`. A lane handed a command that does not exist will invent one and commit it, which collides with every other lane.
5. **\`sharedFiles\`** — the files that belong to no lane: the workspace manifest, the lockfile, the task runner file, formatter and linter configs, CI definitions. Any lane editing one of these collides with all the others.
6. **The conventions.** Is there a \`CLAUDE.md\` / \`AGENTS.md\`? Quote what it says about where tests go and what it forbids. Is there a design-record directory?`,
	at('scan', { label: 'profile', phase: 'Profile', schema: PROFILE_SCHEMA }),
)

if (!profile) return { error: 'profile failed — a lane without a real gate command invents one, so this run stops here' }

log(`${profile.ecosystem} · ${profile.packages.length} package(s) · lane gate: ${profile.gate} · full gate: ${profile.fullGate}${profile.upstream ? ` · upstream ${profile.upstream}` : ' · NO upstream (the claim race is local-only)'}`)

const LANE_GATE = A.gate || profile.gate
const FULL_GATE = A.fullGate || profile.fullGate
const SHARED = (profile.sharedFiles || []).map(f => `\`${f}\``).join(', ') || 'the workspace manifest, the lockfile, the task-runner file and any formatter/linter config'

const GATE_RULE = `Confirm the command exists before you rely on it — the profile established it from ${profile.gateEvidence || 'this repo\'s own runner'}, but check again in your own tree. If it is missing, fall back to the ecosystem's plain equivalent and SAY SO in your report. **Never invent a task-runner recipe, and never edit a shared build file** (${SHARED}): those belong to no lane, and a lane that edits one collides with every other lane. If you believe the gate itself is wrong, that is a wall — escalate it, do not patch it.`

const GROUND = `Repository: ${REPO}. Work only there.

THE PROTOCOL — read it before you act, it beats your instincts:
- \`${REFS}/laws.md\` — the four laws.
- \`${REFS}/worker.md\` — the board protocol. A node is \`<dir>/prd.md\` under \`${BOARD}\`. Boxes are the only evidence: \`- [ ]\` not met · \`- [~]\` met against a STUB standing in for the real dependency · \`- [x]\` met against the real thing, with the check run.
${profile.contextFile ? `- \`${profile.contextFile}\` — the tree, the conventions, the tests law.` : ''}
- ${profile.memoDir ? `This repo has a design-record layer at \`${profile.memoDir}\`. Where a node names a record, that record is the SPEC and the node is only where work against it is claimed.` : 'This repo has no design-record layer: a node\'s own Requirements / Acceptance / Out of scope IS its spec.'} Either way, work that contradicts the spec is a wall — escalate it, never fork it.

THE REPOSITORY, profiled at \`${profile.head}\` on branch \`${profile.branch}\`:
- build system: ${profile.ecosystem}
- packages: ${profile.packages.map(p => `\`${p.name}\` (${p.dir})`).join(', ') || '(one, unnamed)'}
- implementations under: ${(profile.sourceRoots || []).join(', ') || '(unknown)'}
- lane gate: \`${LANE_GATE}\` · full gate: \`${FULL_GATE}\`
- shared files, owned by no lane: ${SHARED}
- tests law: ${profile.testLayout}
${profile.notes ? `- ${profile.notes}` : ''}
${SEEDS.length ? `\nTHE CALLER'S NOTES for this run:\n${SEEDS.map(s => `- ${s}`).join('\n')}` : ''}

**THIS IS ONE OF SEVERAL SESSIONS THAT MAY BE RUNNING RIGHT NOW.** Others hold their own claims and are editing their own worktrees. Therefore:
- A node carrying a \`claim:\` that is not this session's is **not yours**. Surface a stale one; never take it (law 1: a lock is a durable commit, surfaced when stale, never taken).
- Never edit a board node this session does not hold. A needed change to someone else's node is an escalation, not an edit (law 2).
- \`max-workers\` on the root node is a **global** cap across all sessions, not this session's allowance.`

const RECON_SCHEMA = {
	type: 'object', additionalProperties: false,
	required: ['node', 'wall', 'amendments', 'assessment'],
	properties: {
		node: { type: 'string' },
		assessment: { type: 'string', description: 'two or three sentences: is this node an accurate description of the work that remains?' },
		wall: { type: 'string', description: 'empty, or: the requirement contradicts its spec / the node\'s contract with the system must change. What you hit, what change is needed, why.' },
		amendments: {
			type: 'array',
			items: {
				type: 'object', additionalProperties: false,
				required: ['box', 'kind', 'newText', 'evidence'],
				properties: {
					box: { type: 'string', description: 'the box line verbatim, enough to locate it uniquely' },
					kind: { type: 'string', enum: ['already-met', 'sharpen', 'stale-address', 'note-only'], description: 'already-met = the code already does it, propose [x] with the check; sharpen = too soft to verify, propose tighter text; stale-address = names a path/symbol that moved; note-only = add evidence, leave the box' },
					newText: { type: 'string', description: 'the replacement box line, or the note to add beneath it' },
					evidence: { type: 'string', description: 'the symbol, path, test or command that establishes this, and for already-met what the check would have done had the requirement been unmet' },
				},
			},
		},
	},
}

const WORK_SCHEMA = {
	type: 'object', additionalProperties: false,
	required: ['node', 'branch', 'boxes', 'gateRun', 'wall', 'narrative'],
	properties: {
		node: { type: 'string' },
		branch: { type: 'string', description: 'the branch your worktree left the work on, or "" if nothing landed' },
		gateRun: { type: 'string', description: 'the exact gate invocation you ran and its verdict — name the command, not the recipe you wished existed' },
		wall: { type: 'string', description: 'empty, or the escalation text. A wall is escalated, never redefined away.' },
		narrative: { type: 'string' },
		boxes: {
			type: 'array',
			items: {
				type: 'object', additionalProperties: false,
				required: ['text', 'intended', 'evidence', 'wouldHaveDone'],
				properties: {
					text: { type: 'string' },
					intended: { type: 'string', enum: ['x', '~', ' '] },
					evidence: { type: 'string', description: 'for [x] the exact command and result; for [~] the load-bearing stub and where it lives; for [ ] why it is still open' },
					wouldHaveDone: { type: 'string', description: 'what would your check have done if the requirement were UNMET? No answer, no [x].' },
				},
			},
		},
	},
}

const REFUTE_SCHEMA = {
	type: 'object', additionalProperties: false,
	required: ['node', 'verdicts'],
	properties: {
		node: { type: 'string' },
		verdicts: {
			type: 'array',
			items: {
				type: 'object', additionalProperties: false, required: ['text', 'survives', 'why', 'shouldBe'],
				properties: {
					text: { type: 'string' }, survives: { type: 'boolean' }, why: { type: 'string' },
					shouldBe: { type: 'string', enum: ['x', '~', ' '] },
				},
			},
		},
	},
}

// Two directory paths collide when one contains the other, compared
// segment-wise: `engine/graph` contains `engine/graph/x` but NOT
// `engine/graph_ops`, which a bare startsWith would join by accident.
const norm = p => String(p).replace(/^\.?\/*/, '').replace(/\/+$/, '')
const collides = (a, b) => { a = norm(a); b = norm(b); return a === b || a.startsWith(b + '/') || b.startsWith(a + '/') }

const allRounds = []

for (let round = 1; round <= ROUNDS; round++) {
	// ── Capacity ───────────────────────────────────────────────────────────
	// Two steps, and the split is the point. The census is arithmetic: parse
	// frontmatter, count boxes. The ready set is a six-clause predicate, so it
	// is computed HERE in JavaScript rather than asked of a model — it is the
	// thing every session acts on and it must not be a coin-flip. Only the
	// footprint, which needs real reading of the code, costs a probe.
	phase('Capacity')

	const census = await agent(
		`${GROUND}

You are the CENSUS TAKER. Mechanical work: parse and count, judge nothing, claim nothing, edit nothing.

1. \`git rev-parse HEAD\` and \`git status --porcelain -- ${BOARD} | head -20\` into \`notes\`.
2. \`find ${BOARD} -name prd.md | sort\`. Every one is a node; its \`path\` is its DIRECTORY relative to \`${BOARD}\`, and the root node's path is \`.\`.
3. Parse each node's \`---\` frontmatter and report every field **verbatim**. An illegal \`state\` value is reported as written, not repaired. Missing \`priority\` is \`-1\`; every other missing field is \`""\`.
4. \`maxWorkers\` — the \`max-workers\` field on the ROOT node. If there is no such field, report \`0\`; the default is applied by the caller, not by you.
5. Count boxes across the WHOLE file under any heading: \`- [ ]\` → \`open\`, \`- [~]\` → \`stub\`, \`- [x]\` → \`closed\`. Counting only under \`## Requirements\` is exactly what lets an unmet acceptance clause hide.
6. \`escalation\` is true iff the file contains an \`## Escalation\` heading.
7. \`children\` — the node directories one level below that themselves contain a \`prd.md\`.
8. For every node carrying a \`claim:\`, find its claim commit — \`git log -1 --format=%ct --grep="claim <path>"\` — and give the age in hours as \`claimAgeHours\`. Unclaimed, or no such commit: \`-1\`.
9. \`summary\` — one line quoted from the node's own purpose paragraph. Do not invent one.

Completeness is the whole job: a node you skip is a slot this session miscounts.`,
		at('scan', { label: `census-r${round}`, phase: 'Capacity', schema: CENSUS_SCHEMA }),
	)

	if (!census || !census.nodes || !census.nodes.length) { log(`no board found at ${BOARD}`); break }

	// The ready predicate, from worker.md §2, in code.
	const byPath = new Map(census.nodes.map(n => [n.path, n]))
	const owes = n => n.open + n.stub + (n.escalation ? 1 : 0)
	const resolvedN = n => n.state === 'out-of-scope' || (n.state === 'done' && owes(n) === 0)
	const reopened = n => n.state === 'done' && n.open + n.stub > 0 && !n.escalation
	const covered = n => resolvedN(n) && (n.children || []).every(c => { const k = byPath.get(c); return !k || covered(k) })

	const liveClaims = census.nodes.filter(n => n.claim)
	const maxWorkers = census.maxWorkers > 0 ? census.maxWorkers : DEFAULT_MAX_WORKERS
	const remaining = Math.max(0, maxWorkers - liveClaims.length)

	// Stale claims are SURFACED, never taken — law 1's rung. Clearing one is
	// the user's call, not a workflow's.
	const stale = liveClaims.filter(n => n.claimAgeHours > 12)

	let readyNodes = census.nodes.filter(n =>
		(n.state === 'open' || reopened(n)) && !n.claim && n.mode !== 'hitl' && !n.escalation &&
		(n.children || []).every(c => { const k = byPath.get(c); return !k || covered(k) }))

	if (A.nodes) readyNodes = readyNodes.filter(n => A.nodes.indexOf(n.path) !== -1)

	readyNodes.sort((a, b) => (b.priority - a.priority) || (b.path.split('/').length - a.path.split('/').length) || a.path.localeCompare(b.path))

	log(`round ${round}: max-workers ${maxWorkers}, ${liveClaims.length} live claim(s), ${remaining} slot(s) free, ${readyNodes.length} ready`)
	for (const c of liveClaims) log(`  held: ${c.path} by ${c.claim}${c.claimAgeHours >= 0 ? ` (${Math.round(c.claimAgeHours)}h)` : ''}`)
	for (const s of stale) log(`  STALE, surfaced not taken: ${s.path} by ${s.claim} — claimed ${Math.round(s.claimAgeHours)}h ago`)

	if (remaining <= 0) {
		log(`no free slot — ${liveClaims.length} of ${maxWorkers} taken. Nothing to do.`)
		allRounds.push({ round, tookNothing: 'cap full', maxWorkers, liveClaims: liveClaims.map(c => c.path) })
		break
	}
	if (!readyNodes.length) {
		log('nothing ready — every open node is claimed, hitl, escalated, or waiting on children')
		allRounds.push({ round, tookNothing: 'nothing ready', maxWorkers, liveClaims: liveClaims.map(c => c.path) })
		break
	}

	// Footprints, for the ready nodes AND for what other sessions hold. The
	// held nodes matter as much as the free ones: another session is writing
	// those directories right now, and a lane that overlaps them collides at
	// merge — or worse, agrees textually and disagrees semantically.
	const needFootprint = readyNodes.concat(liveClaims)
	const fp = await agent(
		`${GROUND}

You are the SURVEYOR. READ ONLY — claim nothing, edit nothing, run no tests.

For each node below, work out the **footprint** of its REMAINING work: which source directories a worker would have to write. Read the node's open \`- [ ]\` and \`- [~]\` boxes, read its spec, and grep for every symbol, path, file and command they name. Ground each directory in something you found — put the greps in \`evidence\`.

This decides which nodes can be worked concurrently, so err toward including a directory you are unsure about: a missed directory is a merge conflict, a spurious one only costs parallelism.

Mark \`exclusive: true\` where the work is tree-wide and cannot share a tree with anything — a rename sweep, a gate that reads every file, a change to the workspace member list, or any edit to a shared file (${SHARED}).

THE NODES:
${needFootprint.map(n => `- \`${n.path}\` — ${n.title} · ${n.open} open, ${n.stub} stubbed${n.memo ? ` · spec: ${n.memo}` : ''}${n.claim ? ` · HELD by ${n.claim}, another session is writing this now` : ''}\n  ${n.summary}`).join('\n')}`,
		at('probe', { label: `footprint-r${round}`, phase: 'Capacity', schema: FOOTPRINT_SCHEMA }),
	)

	const fpBy = new Map(((fp && fp.footprints) || []).map(f => [f.path, f]))
	const dirsOf = n => (fpBy.get(n.path) || {}).dirs || []
	const isExclusive = n => ((fpBy.get(n.path) || {}).exclusive === true)

	// ── Partition (deterministic, no agent) ────────────────────────────────
	// Spread, do not pack: a fresh lane cannot collide with anything, so while
	// under the cap the answer is always "open one". Bounded by BOTH this
	// session's own limit and the global remaining slots.
	const limit = Math.max(1, Math.min(A.take || 99, A.lanes || 99, remaining))
	const exclusive = readyNodes.filter(isExclusive)
	const shareable = readyNodes.filter(n => !isExclusive(n))

	const occupied = liveClaims.flatMap(c => dirsOf(c).map(norm))
	const heldBy = new Map()
	for (const c of liveClaims) for (const d of dirsOf(c)) heldBy.set(norm(d), c.claim)

	const lanes = []
	const blocked = []
	for (const n of shareable) {
		if (lanes.length >= limit) break
		const set = new Set(dirsOf(n).map(norm))
		const clash = [...set].find(s => occupied.some(o => collides(o, s)))
		if (clash) { blocked.push({ node: n.path, dir: clash, session: heldBy.get(norm(clash)) || 'another session' }); continue }
		if ([...set].some(s => lanes.some(l => [...l.dirs].some(d => collides(d, s))))) continue
		lanes.push({ node: n, dirs: set, first: (fpBy.get(n.path) || {}).first || n.summary })
	}
	const skipped = shareable.filter(n => !lanes.some(l => l.node === n) && !blocked.some(b => b.node === n.path))

	for (const b of blocked) log(`  NOT taken — ${b.dir} is being written by ${b.session} (${b.node})`)
	log(`taking ${lanes.length} lane(s) (limit ${limit}): ${lanes.map(l => l.node.path).join(', ') || 'none'}`)
	if (exclusive.length) log(`  NOT taken — tree-wide, needs a session of its own: ${exclusive.map(n => n.path).join(', ')}`)
	if (skipped.length) log(`  NOT taken — collides with a lane this session took, or over the cap: ${skipped.map(n => n.path).join(', ')}`)

	if (DRY) {
		allRounds.push({ round, dryRun: true, maxWorkers, remaining, would: lanes.map(l => ({ node: l.node.path, dirs: [...l.dirs] })), exclusive: exclusive.map(n => n.path), blocked, skipped: skipped.map(n => n.path), stale: stale.map(s => s.path) })
		break
	}
	if (!lanes.length) {
		// Free slots and nothing takeable is a real, reportable state — the
		// board is not full, it is entangled. "Nothing ready" here would be a
		// lie a reader would act on.
		const why = blocked.length
			? `${remaining} slot(s) free, but every ready node overlaps a directory another session is writing: ${blocked.map(b => `${b.node} (${b.dir})`).join(', ')}`
			: 'every ready node is exclusive or collides'
		log(why)
		allRounds.push({ round, tookNothing: why, blocked })
		break
	}

	// ── Grab ───────────────────────────────────────────────────────────────
	phase('Grab')

	const grabbed = await agent(
		`${GROUND}

You are the CLAIMER for this session, and the ONLY agent in this run permitted to write \`${BOARD}\`. Work in the MAIN checkout at ${REPO}.

Take a session id once: \`cc-$(date +%s)\`. Use it for every claim.

The global cap is \`max-workers: ${maxWorkers}\` and the census saw ${liveClaims.length} live claim(s), so ${remaining} slot(s) were free. **Other sessions are racing you for them.** Follow worker.md §3 exactly, once per node below, IN ORDER, one commit per node:

1. **Re-read the node's \`prd.md\` from disk first.** If it is no longer \`open\`/unclaimed, SKIP it and say so — losing a race is normal and is not an error.
2. **Re-check the cap before each claim**: count \`claim:\` fields across \`${BOARD}/**/prd.md\`. If that count has already reached ${maxWorkers}, stop claiming and report how many you took.
3. Rewrite only that node's frontmatter: \`state: claimed\`, add \`claim: <session>\`. Keep the fences and field order byte-for-byte otherwise.
4. \`git add\` and commit that ONE file: \`git commit -m "claim <path>: <session>" -- ${BOARD}/<path>/prd.md\`
5. ${profile.upstream ? `\`git push\` — this branch tracks \`${profile.upstream}\`, so **the push decides the race**. Rejected → \`git pull --rebase\`, push again. A conflict on your node file means someone claimed first: \`git rebase --abort\`, \`git reset --hard @{upstream}\`, skip that node.` : 'This branch has NO upstream, so the commit is the whole lock and there is no push to arbitrate. Do not add a remote.'}
6. If a commit refuses, restore the file byte-for-byte and report it. Never leave a half-written frontmatter behind.

**Then verify the cap held, and fix it if it did not.** Re-count live claims. The cap is eventually consistent, not instantaneous — two sessions can each see one free slot and each claim a different node. If the total now EXCEEDS ${maxWorkers}, release **your own** most recently claimed nodes (drop the \`claim:\` line, \`state: open\`, commit as \`release <path>: <session> — over the global cap\`) until the total is within it. Release yours, never anyone else's, and say what you released.

Nodes to claim, in order:
${lanes.map((l, i) => `  lane ${i + 1}: ${l.node.path}`).join('\n')}

Return plain text: the session id on the first line, then one line per node — \`<path> :: CLAIMED\` or \`<path> :: SKIPPED, <reason>\` or \`<path> :: RELEASED, over cap\` — then \`git log --oneline -${lanes.length + 2}\`.`,
		at('probe', { label: `grab-r${round}`, phase: 'Grab' }),
	)

	const grabText = String(grabbed || '')
	const held = lanes.filter(l => new RegExp(`${l.node.path.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}\\s*::\\s*CLAIMED`).test(grabText))

	log(`claimed ${held.length} of ${lanes.length} attempted`)
	if (!held.length) {
		log('lost every race — another session took them first. Nothing to work.')
		allRounds.push({ round, tookNothing: 'lost every race', grab: grabText })
		continue
	}

	// ── Reconcile, scoped to what this session holds ───────────────────────
	// Board-wide reconciliation is not safe with other sessions running. A node
	// THIS session holds is safe, because the claim is the lock and worker.md
	// move 2 makes amending your own node free. Read-only in parallel; one
	// serial writer applies the result.
	let recons = []
	if (A.reconcile !== false) {
		phase('Reconcile')
		recons = (await parallel(held.map(l => () => agent(
			`${GROUND}

You are the RECONCILER for **one node this session now holds**: \`${l.node.path}\`.

READ ONLY. Do not edit the board — a single serial writer applies your findings. Do not run the full gate (\`${FULL_GATE}\`) or the test suite; scoped greps, metadata commands, \`git log\` and reading files are all fine.

Your question: **is this node an accurate description of the work that actually remains?** A worker is about to implement it, and a requirement that is already met, too soft to verify, or pointing at an address that moved costs them the whole node.

  node:   \`${BOARD}/${l.node.path}/prd.md\`
  spec:   ${l.node.memo || '(none — the node\'s own Requirements / Acceptance / Out of scope is the spec)'}
  verify: ${l.node.verify || '(none)'}
  ${l.node.open} open, ${l.node.stub} stubbed · footprint: ${[...l.dirs].join(', ') || '(unknown)'}

Read the node in full, then its spec in full. For every open \`- [ ]\` and stubbed \`- [~]\` box:

1. **Is it already met?** Grep for every symbol, path, test and command it names. If the code already does what the box asks, that is an \`already-met\` amendment — and give the check you ran plus **what that check would have done had the requirement been unmet**. Without that second half it is not evidence, it is a coincidence.
2. **Does it name an address that moved?** Check every path and symbol against the tree TODAY (\`git log --diff-filter=R\`, the metadata command, \`find\`). A box naming an address that no longer resolves is pre-move — give the current address.
3. **Is it too soft to verify?** Then \`sharpen\` it. Vagueness left in the line ends up in the code, and sharpening a requirement on a node you hold is worker.md move 2 — free.
4. **Does it contradict its spec?** That is a **wall**, not an amendment: put it in \`wall\` and propose no text. The spec governs, and work against a node that contradicts it is escalated, never forked.

Be conservative. An amendment that turns out to be wrong is worse than a box left as written, because the next reader trusts it. If you are unsure, use \`note-only\` and record what you found.`,
			at('probe', { label: `recon:${l.node.path.split('/').pop()}`, phase: 'Reconcile', schema: RECON_SCHEMA }),
		)))).filter(Boolean)

		const nAmend = recons.reduce((n, r) => n + (r.amendments || []).length, 0)
		const walls = recons.filter(r => r.wall && r.wall.trim())
		log(`reconcile: ${nAmend} amendment(s) across ${recons.length} node(s), ${walls.length} wall(s)`)

		if (nAmend > 0 || walls.length > 0) {
			phase('Amend')
			await agent(
				`${GROUND}

You are the AMENDER for this session. You hold these nodes, so you may write them — and **only** these:
${held.map(l => `  ${BOARD}/${l.node.path}/prd.md`).join('\n')}

Session id: read it off the first line of this grab record.
${grabText.split('\n').slice(0, 3).join('\n')}

Reconcilers examined each node against its spec and the code. Apply their findings, per worker.md move 2 (amend only your own node — sharpening, recording a decision, noting evidence is free) and move 3 (a wall is escalated, never redefined away).

For each amendment:
- \`already-met\` — mark the box \`[x]\` ONLY if the evidence includes both the check run and what it would have done had the requirement been unmet. Write that evidence into the node beneath the box. If either half is missing, add it as a note and leave the box open.
- \`sharpen\` — replace the box text with the tighter version. Keep the requirement number.
- \`stale-address\` — correct the address in place and note the old one, so a reader of an older commit can still follow it.
- \`note-only\` — add the note beneath the box, change no state.

For each wall: write an \`## Escalation\` section into that node (what was hit, what change is needed, why), then **release that node** — drop the \`claim:\` line, set \`state: open\`, commit as \`release <path>: <session> — escalated\`. An escalated node leaves the work surface, so it must not go on to a lane.

**Never reuse a requirement number, and never delete a closed \`[x]\` box or an \`## Out of scope\` line.** Those are the record; corrections are appended and shadow.

Commit per node: \`git commit -m "amend <path>: <session> — <what changed>" -- ${BOARD}/<path>/prd.md\`

THE FINDINGS:
${JSON.stringify(recons, null, 1)}

Return: one line per node — what you amended, what you escalated and released, and the commit hash. Name any finding you did NOT apply and why.`,
				at('probe', { label: `amend-r${round}`, phase: 'Amend' }),
			)
		}
	}

	const escalated = new Set(recons.filter(r => r.wall && r.wall.trim()).map(r => r.node))
	const working = held.filter(l => !escalated.has(l.node.path))
	if (escalated.size) log(`${escalated.size} node(s) escalated and released — not worked`)
	if (!working.length) { allRounds.push({ round, tookNothing: 'every node escalated', grab: grabText, recons }); continue }

	// ── Work, then Refute ──────────────────────────────────────────────────
	phase('Work')

	const worked = await pipeline(
		working.map((l, i) => ({ lane: i + 1, node: l.node, dirs: [...l.dirs], first: l.first })),

		lane => agent(
			`${GROUND}

You are LANE ${lane.lane} of this session, running in **your own git worktree** — a private checkout. Other lanes of this session, and other sessions entirely, are working other nodes in their own worktrees at the same time. Your lane owns these directories: ${lane.dirs.join(', ') || '(none identified — be conservative and say what you touched)'}. Touch nothing outside them without saying so loudly in \`narrative\`.

YOUR NODE — claimed by this session, and reconciled against its spec before you started:
  ${lane.node.path}
  title:  ${lane.node.title}
  spec:   ${lane.node.memo || '(none — the node\'s own Requirements / Acceptance / Out of scope is the spec)'}
  verify: ${lane.node.verify || '(none)'}
  ${lane.node.open} open, ${lane.node.stub} stubbed
  ${lane.first}

Read \`${BOARD}/${lane.node.path}/prd.md\` in full — it may have been amended since the census — then its spec in full.

THE FOUR MOVES (worker.md §4):

1. **WORK the node.** Implement its open boxes. Requirements say WHAT; the how is yours — except that observable interfaces the node names (paths, flags, formats) ARE requirements.
2. **AMEND** — you cannot write \`${BOARD}\`; put every amendment you want into \`boxes\` and \`narrative\`. The session's serial writer applies it.
3. **ESCALATE a wall.** A requirement is wrong, or the node's contract with the system must change → stop, put the escalation text in \`wall\`, do not redefine it away, do not narrow the node's scope. Narrowing is not yours.
4. **SPLIT.** A coherent sub-area with its own contract → describe the child in \`narrative\`. Do not work it.

Before you mark any box \`intended: "x"\`, answer in \`wouldHaveDone\`: **what did I run, and what would it have done if the requirement were unmet?** No answer, no \`x\`. If the real dependency is not there yet the box is \`~\` and you NAME the stub — \`~\` is not a lesser failure, it is the honest record that a stub is load-bearing.

GATE: run \`${LANE_GATE}\` in your worktree when you are done writing. It is the scoped gate for what you changed, and it falls open: it can say "not yet", it can never say "done". Do **NOT** run the full gate (\`${FULL_GATE}\`) — one agent runs that once, after all lanes merge. ${GATE_RULE}

COMMIT on a branch named \`lane/${lane.lane}-${lane.node.path.split('/').pop()}\` (\`git switch -c\`). Commit the CODE together with whatever doc or record explains it — they land in the same commit. Do **NOT** commit anything under \`${BOARD}\`; if git shows changes there, revert them. Report the branch in \`branch\`.

TESTS: ${profile.testLayout}. Hold that convention whether or not a gate enforces it${profile.contextFile ? ` — and re-read \`${profile.contextFile}\` before you place a new test file` : ''}.`,
			at('build', { label: `lane-${lane.lane}`, phase: 'Work', isolation: 'worktree', schema: WORK_SCHEMA }),
		),

		(work, lane) => {
			if (!work) return null
			const toKill = (work.boxes || []).filter(b => b.intended === 'x')
			if (!toKill.length) return { work, verdicts: [] }
			return agent(
				`${GROUND}

You are the ADVERSARY for node \`${work.node}\`. A worker just did the work and intends to mark the boxes below \`[x]\`. **Refute each one.** Law 2: nothing vouches for itself, and the author does not get to say it is done.

The work is on branch \`${work.branch || '(uncommitted)'}\`. Read it with \`git show\`, \`git diff ${profile.branch}...${work.branch || 'HEAD'}\`, and by reading the files. You may run SCOPED tests; do NOT run the full gate (\`${FULL_GATE}\`). ${GATE_RULE}

A box survives only if you fail to kill it:
- Does the code do what the box says, or something adjacent? Read the diff; do not trust the evidence line.
- Is the evidence a real check or a restatement? "It compiles", "the test passes" without naming it, "I verified it" — all refuted.
- Would the check have FAILED had the requirement been unmet? Their \`wouldHaveDone\` is a claim; test it. A check that passes either way proves nothing (law 3: a gate that finds nothing to check must fail, not pass).
- Is it met against the REAL dependency, or against a stub, fixture or in-process fake? A load-bearing stub anywhere on the path makes it \`~\`, not \`x\` — and name the stub.
- Does the change contradict the node's spec? That is a wall, not a pass.
- Is there a new test, and does it live where this repo's tests law puts it (${profile.testLayout})?

BOXES CLAIMED \`[x]\`:
${toKill.map((b, i) => `${i + 1}. ${b.text}\n   EVIDENCE: ${b.evidence}\n   WOULD-HAVE-DONE: ${b.wouldHaveDone}`).join('\n\n')}

One verdict per box, same \`text\`. \`shouldBe\` is what the box should actually carry — \`x\` only if it survived you.`,
				at('judge', { label: `refute-${lane.lane}`, phase: 'Refute', schema: REFUTE_SCHEMA }),
			).then(v => ({ work, verdicts: (v && v.verdicts) || [] }))
		},
	)

	const settled = worked.filter(Boolean).map(w => ({
		node: w.work.node, branch: w.work.branch, wall: w.work.wall, narrative: w.work.narrative, gateRun: w.work.gateRun,
		boxes: (w.work.boxes || []).map(b => {
			const v = w.verdicts.find(x => x.text === b.text)
			const final = b.intended === 'x' && v && !v.survives ? v.shouldBe : b.intended
			return { text: b.text, final, demoted: final !== b.intended, evidence: b.evidence, refutation: v ? v.why : (b.intended === 'x' ? 'NO VERDICT RETURNED — treat as unproven' : '') }
		}),
	}))

	const demoted = settled.flatMap(s => s.boxes.filter(b => b.demoted))
	log(`${settled.length} lane(s) worked · ${demoted.length} box(es) demoted by the adversary`)

	// ── Land ───────────────────────────────────────────────────────────────
	phase('Land')

	const landed = await agent(
		`${GROUND}

You are the LANDER for this session, in the MAIN checkout at ${REPO}. This session holds the claims on the nodes below and is the only agent that writes their board files.

Session id: read it off this grab record.
${grabText.split('\n').slice(0, 3).join('\n')}

**1. Merge.** For each branch, \`git merge --no-ff <branch>\`. The directory sets were computed disjoint, so a conflict means the partition was wrong — do not paper over it: \`git merge --abort\`, leave that lane unmerged, and report exactly which files collided. A generated lockfile is the one legitimate shared file; resolve it by REGENERATING it with this repo's own command, never by hand-picking hunks.

Other sessions may have committed while you worked. ${profile.upstream ? `\`git pull --rebase\` first (this branch tracks \`${profile.upstream}\`).` : 'This branch has no upstream, so there is nothing to pull.'} If a pull brings in a change to a node file you hold, stop and report it — that should not happen, and it means something took your claim.

**2. Run the full gate ONCE.** \`${FULL_GATE}\`. This single run is why the lanes did not each run it. ${GATE_RULE}
   **If it fails, attribute the failure before you act.** Bisect by lane: reset to the pre-merge commit and re-merge one at a time, running only the failing target each time. A failure belongs to one lane, not to the run — do not release green lanes because a red neighbour failed. Report which lane owns it. If the failure predates your merges, say so and do not attribute it to a lane.

**3. Write the board**, per worker.md §6, for each node:
   - **DONE** — every box \`x\`, and if the node carries a \`verify:\`, **you ran it** and its output is the evidence. \`state: done\`, DELETE the \`claim:\` line, commit the node file together with the work it verifies: \`git commit -m "close <path>: <session>" -- <the work> ${BOARD}/<path>/prd.md\`
   - **Boxes still open?** Not done. \`state: open\`, write the honest boxes (\`[ ]\`/\`[~]\`, the stub named beside every \`[~]\`), DROP the \`claim:\` line, commit what landed as \`release <path>: <session>\`.
   - **A wall?** \`## Escalation\` into that node, release the claim, stop on it.
   - **Never leave a claim behind.** Closing and abandoning both clear the owner — and with other sessions running, a claim left behind blocks a node for everyone.

**4. The box states are settled — transcribe them, do not re-judge them.** Each carries \`final\`, the worker's intent after an adversary tried to kill it. A \`demoted\` box was killed: write the demoted state and put the refutation into the node body as the record of why. Do not restore a box the adversary killed.

**Never delete a closed \`[x]\` box, an \`## Out of scope\` line, or a recorded \`## Decisions\` / \`## Findings\` section, and never reuse a requirement number.**

LANES TO LAND:
${JSON.stringify(settled, null, 1)}

Return GitHub-flavoured markdown — an artifact, not a transcript:
## Landed
one line per node: closed / released / escalated, with the session id.
## The gate
the exact commands and exit status. If red, which lane owns it.
## Box-by-box
per node, each box and its final state, and for every \`[x]\` the check that proves it.
## Still open
what is left on each released node and why.
## Commits
the merge and close/release commits, by hash.`,
		at('build', { label: `land-r${round}`, phase: 'Land' }),
	)

	allRounds.push({ round, maxWorkers, remaining, grab: grabText, reconciled: recons.length, escalated: [...escalated], nodes: settled.map(s => s.node), demoted: demoted.length, report: landed })

	if (round < ROUNDS) log(`round ${round} landed — going round again for more free work`)
}

return {
	rounds: allRounds.length,
	profile: { ecosystem: profile.ecosystem, head: profile.head, gate: LANE_GATE, fullGate: FULL_GATE },
	sessions: 'this is one session; launch mi-run again, concurrently, for another',
	detail: allRounds,
}
