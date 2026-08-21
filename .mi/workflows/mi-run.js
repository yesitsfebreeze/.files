export const meta = {
	name: 'mi-run',
	description: 'One session on the board: claim whatever is free within the global worker cap IMMEDIATELY, then work each node in a parallel worktree lane — the lane reconciles its own node as it works — and land behind one gate run. Safe to launch as many times as you like, concurrently.',
	whenToUse: 'The entry point for a working session. Start as many as you want: each grabs different free nodes, because the claim commit is the lock. Use mi-replan separately for a whole-board restructure, which is exclusive, and mi-repair only when work is actually blocked.',
	phases: [
		{ model: 'haiku', title: 'Scout', detail: 'profile the repo and census the board — two scans, run in parallel; each is skipped when the caller hands its answer in (mi-gantt passes both)' },
		{ model: 'sonnet', title: 'Grab', detail: 'claim node by node, immediately — the commit is the lock, and nothing slower runs before it' },
		{ model: 'sonnet', title: 'Survey', detail: 'footprint the same candidates while the grab commits, to lay the lanes out disjoint — skipped when tickets carry their footprints' },
		{ model: 'opus', title: 'Work', detail: 'one agent per lane, each in its own git worktree — each reconciles its own node as it works it' },
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
// So the ordering rule is: **nothing slower than the claim runs before the
// claim.** A claim commit is milliseconds; every sweep, survey and reconcile
// is minutes; a session that sweeps first is reaching for a board that has
// moved. Concretely:
//
//   - **Scout** is two cheap scans (repo profile, board census) run in
//     PARALLEL — and each is skipped when the caller already has its answer:
//     `args.profile` replaces the profile scan, `args.tickets` replaces the
//     census AND the survey. mi-gantt passes both, so a dispatched session
//     spawns ZERO scan agents and goes straight to the grab — the plan record
//     already holds every task's node, spec, verify and footprint, and
//     re-deriving them per session would be the same work twice.
//   - **Grab** fires the moment the ready set is known. It is never skipped,
//     ticket or not: the claim is the LOCK, not a search — other sessions may
//     be running outside any schedule — and its per-node re-read from disk is
//     also the freshness check (a node that closed, escalated or got claimed
//     since the caller looked is skipped there, at the last possible moment,
//     instead of being pre-verified minutes earlier).
//   - The footprint **Survey runs CONCURRENTLY with the grab**, not before
//     it, and only when tickets did not already carry the footprints.
//   - **Reconciling is not a phase.** A lane worker reads its node and its
//     spec anyway; it reconciles as it works — an already-met box is claimed
//     [x] with the check (and the adversary still tries to kill it), a stale
//     address is corrected in the report, a contradiction with the spec is a
//     wall. The old standalone Reconcile+Amend pass was two extra serial
//     agents in front of every round for findings the worker re-derives in
//     its first ten minutes.
//   - **Checking is deferred to where it is needed.** Other sessions' held
//     directories are not pre-surveyed; if a merge actually conflicts, the
//     Lander refuses to paper over it, attributes it, and leaves that lane
//     unmerged — repair when blocked, not insurance up front.
//   - **A whole-board replan is NOT safe** at any number of sessions above
//     one. It lives in `mi-replan`, called via `/mi-repair`. A session never
//     replans.
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
//   { repo, board, profile, tickets, lanes, nodes, take, rounds, dryRun,
//     gate, fullGate, seeds, models, effort }
//   `profile` — a pre-computed repo profile (the PROFILE_SCHEMA shape);
//     handing one in skips the Profile scan.
//   `tickets` — the work, already known: [{ path, title, memo, verify, dirs,
//     exclusive, first, summary, priority }] (only `path` required; `spec`
//     and `files` are accepted as aliases for `memo` and `dirs`). Handing
//     them in skips the census and the survey — the grab still runs, because
//     the claim is the lock, and its re-read from disk is the staleness check.
//   mi-gantt passes profile AND tickets, one per task it dispatches — and it
//   dispatches several of these sessions CONCURRENTLY off its ready frontier,
//   which is exactly the concurrent-sessions case this script is built for.
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

// Tickets: the caller already knows the work. Normalise once; missing fields
// degrade to the same "unknown" the census path uses.
const TICKETS = Array.isArray(A.tickets) && A.tickets.length
	? A.tickets.filter(t => t && t.path).map(t => ({
		path: t.path, title: t.title || t.path,
		memo: t.memo || t.spec || '', verify: t.verify || '',
		dirs: t.dirs || t.files || [], exclusive: t.exclusive === true,
		first: t.first || t.notes || '', summary: t.summary || t.title || '',
		priority: t.priority != null ? t.priority : -1,
		open: t.open != null ? t.open : -1, stub: t.stub != null ? t.stub : 0,
	}))
	: null

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
// Scout — the two scans, in parallel, each skippable. The gate commands are
// the field the profile exists for: a lane told to run a recipe that does not
// exist in THIS repo will invent one, and a lane that invents a build recipe
// collides with every other lane in the tree. The census is pure board
// arithmetic and needs none of the profile, which is why the two can overlap —
// and tickets replace the census outright.
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

// The census is deliberately independent of the profile so the two scans can
// run in parallel — it is board arithmetic, and the board's shape is fixed by
// the protocol, not by the repo.
const CENSUS_PROMPT = `Repository: ${REPO}. The board is \`${BOARD}\` — every \`<dir>/prd.md\` under it is a node. Other sessions may be committing to this tree right now; read what is on disk and report it VERBATIM.

You are the CENSUS TAKER. Mechanical work: parse and count, judge nothing, claim nothing, edit nothing. READ ONLY.

1. \`git rev-parse HEAD\` and \`git status --porcelain -- ${BOARD} | head -20\` into \`notes\`.
2. \`find ${BOARD} -name prd.md | sort\`. Every one is a node; its \`path\` is its DIRECTORY relative to \`${BOARD}\`, and the root node's path is \`.\`.
3. Parse each node's \`---\` frontmatter and report every field **verbatim**. An illegal \`state\` value is reported as written, not repaired. Missing \`priority\` is \`-1\`; every other missing field is \`""\`.
4. \`maxWorkers\` — the \`max-workers\` field on the ROOT node. If there is no such field, report \`0\`; the default is applied by the caller, not by you.
5. Count boxes across the WHOLE file under any heading: \`- [ ]\` → \`open\`, \`- [~]\` → \`stub\`, \`- [x]\` → \`closed\`. Counting only under \`## Requirements\` is exactly what lets an unmet acceptance clause hide.
6. \`escalation\` is true iff the file contains an \`## Escalation\` heading.
7. \`children\` — the node directories one level below that themselves contain a \`prd.md\`.
8. For every node carrying a \`claim:\`, find its claim commit — \`git log -1 --format=%ct --grep="claim <path>"\` — and give the age in hours as \`claimAgeHours\`. Unclaimed, or no such commit: \`-1\`.
9. \`summary\` — one line quoted from the node's own purpose paragraph. Do not invent one.

Completeness is the whole job: a node you skip is a slot this session miscounts.`

phase('Scout')

// A caller that already profiled hands the profile in; a caller that already
// planned hands the tickets in. mi-gantt does both, so a wave's Scout spawns
// zero agents. Otherwise the two scans run at once — neither needs the other.
const havePassedProfile = A.profile && A.profile.gate && A.profile.fullGate
const [profileRaw, census1] = await parallel([
	() => havePassedProfile
		? Promise.resolve(A.profile)
		: agent(
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
			at('scan', { label: 'profile', phase: 'Scout', schema: PROFILE_SCHEMA }),
		),
	() => TICKETS
		? Promise.resolve(null)
		: agent(CENSUS_PROMPT, at('scan', { label: 'census-r1', phase: 'Scout', schema: CENSUS_SCHEMA })),
])

if (!profileRaw) return { error: 'profile failed — a lane without a real gate command invents one, so this run stops here' }

// A passed-in profile may be missing optional fields; fill what GROUND reads.
const profile = Object.assign(
	{ upstream: '', packages: [], sourceRoots: [], sharedFiles: [], memoDir: '', contextFile: '', testLayout: 'no stated convention', notes: '', branch: '(unknown)', head: '(unknown)' },
	profileRaw,
)

log(`${profile.ecosystem} · ${profile.packages.length} package(s) · lane gate: ${profile.gate} · full gate: ${profile.fullGate}${profile.upstream ? ` · upstream ${profile.upstream}` : ' · NO upstream (the claim race is local-only)'}${havePassedProfile ? ' · profile handed in' : ''}${TICKETS ? ` · ${TICKETS.length} ticket(s) handed in — no census, no survey` : ''}`)

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

const WORK_SCHEMA = {
	type: 'object', additionalProperties: false,
	required: ['node', 'branch', 'boxes', 'gateRun', 'wall', 'narrative'],
	properties: {
		node: { type: 'string' },
		branch: { type: 'string', description: 'the branch your worktree left the work on, or "" if nothing landed' },
		gateRun: { type: 'string', description: 'the exact gate invocation you ran and its verdict — name the command, not the recipe you wished existed' },
		wall: { type: 'string', description: 'empty, or the escalation text. A wall is escalated, never redefined away.' },
		narrative: { type: 'string', description: 'what you did — and every board amendment you want applied to your node: a sharpened box text, a corrected stale address, a note worth recording. The Lander transcribes these; you cannot write the board yourself.' },
		boxes: {
			type: 'array',
			items: {
				type: 'object', additionalProperties: false,
				required: ['text', 'intended', 'evidence', 'wouldHaveDone'],
				properties: {
					text: { type: 'string' },
					intended: { type: 'string', enum: ['x', '~', ' '] },
					evidence: { type: 'string', description: 'for [x] the exact command and result; for [~] the load-bearing stub and where it lives; for [ ] why it is still open. A box the code ALREADY satisfied before you started is still claimed [x] here, with the check you ran to establish that.' },
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
const esc = s => String(s).replace(/[.*+?^${}()|[\]\\]/g, '\\$&')

const allRounds = []

// With tickets, the pool drains across rounds: a worked ticket leaves it, a
// ticket dropped for a footprint collision stays and gets a later round —
// which is exactly what the caller's `rounds` exists for.
let pool = TICKETS

for (let round = 1; round <= ROUNDS; round++) {
	// ── Ready set (deterministic, no agent) ────────────────────────────────
	// The census is arithmetic; the ready set is a six-clause predicate, so it
	// is computed HERE in JavaScript rather than asked of a model — it is the
	// thing every session acts on and it must not be a coin-flip. With
	// tickets, the caller already computed it: the grab's per-node re-read
	// from disk is the only freshness check left, and it is the right one.
	let readyNodes, maxWorkers = null, liveClaims = [], remaining = null

	if (pool) {
		if (!pool.length) { log(`round ${round}: ticket pool drained`); break }
		readyNodes = A.nodes ? pool.filter(n => A.nodes.indexOf(n.path) !== -1) : pool
		if (!readyNodes.length) { log('no ticket matches the `nodes` filter'); break }
		log(`round ${round}: ${readyNodes.length} ticket(s) in the pool — cap checked at claim time`)
	} else {
		const census = round === 1
			? census1
			: await agent(CENSUS_PROMPT, at('scan', { label: `census-r${round}`, phase: 'Scout', schema: CENSUS_SCHEMA }))

		if (!census || !census.nodes || !census.nodes.length) { log(`no board found at ${BOARD}`); break }

		// The ready predicate, from worker.md §2, in code.
		const byPath = new Map(census.nodes.map(n => [n.path, n]))
		const owes = n => n.open + n.stub + (n.escalation ? 1 : 0)
		const resolvedN = n => n.state === 'out-of-scope' || (n.state === 'done' && owes(n) === 0)
		const reopened = n => n.state === 'done' && n.open + n.stub > 0 && !n.escalation
		const covered = n => resolvedN(n) && (n.children || []).every(c => { const k = byPath.get(c); return !k || covered(k) })

		liveClaims = census.nodes.filter(n => n.claim)
		maxWorkers = census.maxWorkers > 0 ? census.maxWorkers : DEFAULT_MAX_WORKERS
		remaining = Math.max(0, maxWorkers - liveClaims.length)

		// Stale claims are SURFACED, never taken — law 1's rung. Clearing one is
		// the user's call, not a workflow's.
		const stale = liveClaims.filter(n => n.claimAgeHours > 12)

		readyNodes = census.nodes.filter(n =>
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
	}

	const limit = Math.max(1, Math.min(A.take || 99, A.lanes || 99, remaining == null ? 99 : remaining))
	// Two spares beyond the limit: a race lost on a top candidate falls through
	// to the next instead of ending the round short.
	const candidates = readyNodes.slice(0, limit + 2)

	if (DRY) {
		allRounds.push({ round, dryRun: true, maxWorkers, remaining, wouldClaim: readyNodes.slice(0, limit).map(n => n.path), spares: candidates.slice(limit).map(n => n.path) })
		break
	}

	// ── Grab ∥ Survey ──────────────────────────────────────────────────────
	// The claim commit is milliseconds and the footprint survey is minutes, so
	// the survey runs BESIDE the grab, not in front of it — and not at all
	// when the tickets already carry their footprints. Nothing the survey
	// finds changes what to claim — priority already decided that — it decides
	// how the claimed nodes are laid out into disjoint worktree lanes.
	phase('Grab')

	const capIntro = pool
		? `The global cap is \`max-workers\` on the ROOT node (\`${BOARD}/prd.md\`); if the field is absent it is ${DEFAULT_MAX_WORKERS}. BEFORE your first claim, read it and count live \`claim:\` fields across \`${BOARD}/**/prd.md\` — the free slots are the cap minus that count, and **other sessions may be racing you for them.** Never hold more than the smaller of ${limit} and the free slots.`
		: `The global cap is \`max-workers: ${maxWorkers}\` and the census saw ${liveClaims.length} live claim(s), so ${remaining} slot(s) were free. **Other sessions are racing you for them.**`

	const [grabbed, fp] = await parallel([
		() => agent(
			`${GROUND}

You are the CLAIMER for this session, and the ONLY agent in this run permitted to write \`${BOARD}\`. Work in the MAIN checkout at ${REPO}.

Take a session id once: \`cc-$(date +%s)\`. Use it for every claim.

${capIntro} Claim the nodes below IN ORDER, one commit per node, per worker.md §3, and **stop once you hold ${limit}** — the extras at the bottom of the list are spares for races you lose, not additional slots:

1. **Re-read the node's \`prd.md\` from disk first.** This is the freshness check — the caller's picture may be minutes old. If the node is no longer \`open\`/unclaimed, or it carries \`mode: hitl\` or an \`## Escalation\` heading, SKIP it and say why — losing a race is normal and is not an error.
2. **Re-check the cap before each claim**: count \`claim:\` fields across \`${BOARD}/**/prd.md\`. If that count has already reached the cap, stop claiming and report how many you took.
3. Rewrite only that node's frontmatter: \`state: claimed\`, add \`claim: <session>\`. Keep the fences and field order byte-for-byte otherwise.
4. \`git add\` and commit that ONE file: \`git commit -m "claim <path>: <session>" -- ${BOARD}/<path>/prd.md\`
5. ${profile.upstream ? `\`git push\` — this branch tracks \`${profile.upstream}\`, so **the push decides the race**. Rejected → \`git pull --rebase\`, push again. A conflict on your node file means someone claimed first: \`git rebase --abort\`, \`git reset --hard @{upstream}\`, skip that node.` : 'This branch has NO upstream, so the commit is the whole lock and there is no push to arbitrate. Do not add a remote.'}
6. If a commit refuses, restore the file byte-for-byte and report it. Never leave a half-written frontmatter behind.

**Then verify the cap held, and fix it if it did not.** Re-count live claims. The cap is eventually consistent, not instantaneous — two sessions can each see one free slot and each claim a different node. If the total now EXCEEDS the cap, release **your own** most recently claimed nodes (drop the \`claim:\` line, \`state: open\`, commit as \`release <path>: <session> — over the global cap\`) until the total is within it. Release yours, never anyone else's, and say what you released.

Candidates, in priority order (stop once you hold ${limit}):
${candidates.map((n, i) => `  ${i + 1}. ${n.path}${i >= limit ? '  (spare)' : ''}`).join('\n')}

Return plain text: the session id on the first line, then one line per node — \`<path> :: CLAIMED\` or \`<path> :: SKIPPED, <reason>\` or \`<path> :: RELEASED, over cap\` — then \`git log --oneline -${candidates.length + 2}\`.`,
			at('probe', { label: `grab-r${round}`, phase: 'Grab' }),
		),
		() => pool
			// Tickets carry their footprints — synthesise the survey result
			// instead of paying an agent to re-derive what the plan recorded.
			? Promise.resolve({ footprints: candidates.map(n => ({ path: n.path, dirs: n.dirs || [], exclusive: n.exclusive === true, first: n.first || n.summary, evidence: 'from the caller\'s ticket' })) })
			: agent(
				`${GROUND}

You are the SURVEYOR. READ ONLY — claim nothing, edit nothing, run no tests. A claimer is committing claims on these same nodes RIGHT NOW in the main checkout; that is expected, and none of it changes what you read.

For each node below, work out the **footprint** of its REMAINING work: which source directories a worker would have to write. Read the node's open \`- [ ]\` and \`- [~]\` boxes, read its spec, and grep for every symbol, path, file and command they name. Ground each directory in something you found — put the greps in \`evidence\`.

This decides which of these nodes can be worked concurrently in one session, so err toward including a directory you are unsure about: a missed directory is a merge conflict, a spurious one only costs parallelism.

Mark \`exclusive: true\` where the work is tree-wide and cannot share a tree with anything — a rename sweep, a gate that reads every file, a change to the workspace member list, or any edit to a shared file (${SHARED}).

THE NODES:
${candidates.map(n => `- \`${n.path}\` — ${n.title} · ${n.open} open, ${n.stub} stubbed${n.memo ? ` · spec: ${n.memo}` : ''}\n  ${n.summary}`).join('\n')}`,
				at('probe', { label: `survey-r${round}`, phase: 'Survey', schema: FOOTPRINT_SCHEMA }),
			),
	])

	const grabText = String(grabbed || '')
	const held = candidates.filter(n => new RegExp(`${esc(n.path)}\\s*::\\s*CLAIMED`).test(grabText))

	log(`claimed ${held.length} of up to ${limit} (from ${candidates.length} candidate(s))`)
	if (!held.length) {
		log('lost every race — another session took them first. Nothing to work.')
		allRounds.push({ round, tookNothing: 'lost every race', grab: grabText })
		// A ticket the grab explicitly skipped (claimed elsewhere, closed,
		// escalated) will not come back next round; drop it from the pool.
		if (pool) pool = pool.filter(t => !new RegExp(`${esc(t.path)}\\s*::\\s*SKIPPED`).test(grabText))
		continue
	}

	// ── Partition (deterministic, no agent) ────────────────────────────────
	// Lay the held nodes out into footprint-disjoint lanes, in priority order.
	// A held node that cannot share the round — it collides with a
	// higher-priority lane, or it is tree-wide while others run — is handed to
	// the Lander to RELEASE, not worked into a guaranteed conflict. That is
	// the only repair this needs, and it happens only when actually blocked.
	const fpBy = new Map(((fp && fp.footprints) || []).map(f => [f.path, f]))
	if (!fp) log('  survey returned nothing — lanes run with unknown footprints; the Lander arbitrates any conflict at merge')

	const lanes = []
	const releaseUnworked = []
	let exclusiveTaken = false
	for (const n of held) {
		const f = fpBy.get(n.path)
		const dirs = new Set(((f && f.dirs) || []).map(norm))
		const excl = !!(f && f.exclusive === true)
		if (lanes.length >= limit) { releaseUnworked.push({ node: n, why: `over this session's lane limit (${limit})` }); continue }
		if (exclusiveTaken) { releaseUnworked.push({ node: n, why: 'an exclusive (tree-wide) lane holds the whole tree this round' }); continue }
		if (excl && lanes.length) { releaseUnworked.push({ node: n, why: 'tree-wide (exclusive) work — needs a session of its own' }); continue }
		const clashLane = lanes.find(l => [...dirs].some(d => [...l.dirs].some(o => collides(o, d))))
		if (clashLane) { releaseUnworked.push({ node: n, why: `footprint collides with \`${clashLane.node.path}\`` }); continue }
		if (excl) exclusiveTaken = true
		lanes.push({ node: n, dirs, first: (f && f.first) || n.summary, surveyed: !!f })
	}

	log(`working ${lanes.length} lane(s): ${lanes.map(l => l.node.path).join(', ')}`)
	for (const r of releaseUnworked) log(`  claimed but NOT worked this round — ${r.node.path}: ${r.why} (released by the Lander)`)

	// ── Work, then Refute ──────────────────────────────────────────────────
	// The lane worker reconciles its own node AS IT WORKS — there is no
	// standalone reconcile pass. Its already-met claims meet the same
	// adversary as its fresh work, so nothing vouches for itself.
	phase('Work')

	const worked = await pipeline(
		lanes.map((l, i) => ({ lane: i + 1, node: l.node, dirs: [...l.dirs], first: l.first, surveyed: l.surveyed })),

		lane => agent(
			`${GROUND}

You are LANE ${lane.lane} of this session, running in **your own git worktree** — a private checkout. Other lanes of this session, and other sessions entirely, are working other nodes in their own worktrees at the same time. ${lane.dirs.length ? `Your lane owns these directories: ${lane.dirs.join(', ')}. Touch nothing outside them without saying so loudly in \`narrative\`.` : 'Your lane\'s footprint was not pre-surveyed: stay narrowly inside what your node actually requires, and name every directory you touched in `narrative`.'}

YOUR NODE — claimed by this session moments ago, exactly as it sits on the board:
  ${lane.node.path}
  title:  ${lane.node.title}
  spec:   ${lane.node.memo || '(none — the node\'s own Requirements / Acceptance / Out of scope is the spec)'}
  verify: ${lane.node.verify || '(none)'}
  ${lane.node.open >= 0 ? `${lane.node.open} open, ${lane.node.stub} stubbed` : 'box counts unknown — the node file is the truth'}
  ${lane.first}

**RECONCILE AS YOU WORK.** Nobody pre-checked this node against the code — that is your first move, folded into the work itself. Read \`${BOARD}/${lane.node.path}/prd.md\` in full, then its spec in full, then for each open box:
- **Already met by the code as it stands?** Do not redo it. Claim it \`intended: "x"\` with the check you RAN to establish that (the adversary will try to kill it like any other box).
- **Names an address that moved?** Work against where it lives TODAY, and put the correction in \`narrative\` so the Lander records it on the node.
- **Too soft to verify?** State the tighter reading you worked to in \`narrative\`, and meet that.
- **Contradicts its spec?** That is a wall — stop, fill \`wall\`, and do not work around it. The spec governs; work against a node that contradicts it is escalated, never forked.

THE FOUR MOVES (worker.md §4):

1. **WORK the node.** Implement its open boxes. Requirements say WHAT; the how is yours — except that observable interfaces the node names (paths, flags, formats) ARE requirements.
2. **AMEND** — you cannot write \`${BOARD}\`; put every amendment you want into \`boxes\` and \`narrative\`. The Lander applies it.
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

Some boxes may be claimed \`x\` as **already met before this worker started** — those get no free pass: the check still has to be real and its counterfactual still has to bite.

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
	})).concat(releaseUnworked.map(r => ({
		node: r.node.path, branch: '', wall: '', gateRun: '(not worked)',
		narrative: `NOT WORKED this round: ${r.why}. Nothing to merge — release the claim so another session (or a later round) can take it.`,
		boxes: [],
	})))

	const demoted = settled.flatMap(s => s.boxes.filter(b => b.demoted))
	log(`${worked.filter(Boolean).length} lane(s) worked · ${demoted.length} box(es) demoted by the adversary`)

	// ── Land ───────────────────────────────────────────────────────────────
	phase('Land')

	const landed = await agent(
		`${GROUND}

You are the LANDER for this session, in the MAIN checkout at ${REPO}. This session holds the claims on the nodes below and is the only agent that writes their board files.

Session id: read it off this grab record.
${grabText.split('\n').slice(0, 3).join('\n')}

**1. Merge.** For each lane with a non-empty \`branch\`, \`git merge --no-ff <branch>\`. The lanes were laid out footprint-disjoint, so a conflict means the layout was wrong — do not paper over it: \`git merge --abort\`, leave that lane unmerged, and report exactly which files collided. A generated lockfile is the one legitimate shared file; resolve it by REGENERATING it with this repo's own command, never by hand-picking hunks. A lane with an EMPTY \`branch\` and no boxes was never worked — its \`narrative\` says why; there is nothing to merge for it, only a release in step 3.

Other sessions may have committed while you worked. ${profile.upstream ? `\`git pull --rebase\` first (this branch tracks \`${profile.upstream}\`).` : 'This branch has no upstream, so there is nothing to pull.'} If a pull brings in a change to a node file you hold, stop and report it — that should not happen, and it means something took your claim.

**2. Run the full gate ONCE.** \`${FULL_GATE}\`. This single run is why the lanes did not each run it. ${GATE_RULE}
   **If it fails, attribute the failure before you act.** Bisect by lane: reset to the pre-merge commit and re-merge one at a time, running only the failing target each time. A failure belongs to one lane, not to the run — do not release green lanes because a red neighbour failed. Report which lane owns it. If the failure predates your merges, say so and do not attribute it to a lane.

**3. Write the board**, per worker.md §6, for each node:
   - **DONE** — every box \`x\`, and if the node carries a \`verify:\`, **you ran it** and its output is the evidence. \`state: done\`, DELETE the \`claim:\` line, commit the node file together with the work it verifies: \`git commit -m "close <path>: <session>" -- <the work> ${BOARD}/<path>/prd.md\`
   - **Boxes still open?** Not done. \`state: open\`, write the honest boxes (\`[ ]\`/\`[~]\`, the stub named beside every \`[~]\`), DROP the \`claim:\` line, commit what landed as \`release <path>: <session>\`.
   - **Never worked (empty branch, no boxes)?** Just release: \`state: open\`, drop the \`claim:\` line, commit as \`release <path>: <session> — <the narrative's reason>\`. Change nothing else on the node.
   - **A wall?** \`## Escalation\` into that node (the \`wall\` text), release the claim, stop on it.
   - **Never leave a claim behind.** Closing and abandoning both clear the owner — and with other sessions running, a claim left behind blocks a node for everyone.
   - **The worker's \`narrative\` may carry amendments** — a corrected stale address, a sharpened requirement reading, a proposed child split. Record them on the node per worker.md move 2: sharpen in place keeping the requirement number, note corrections beneath the box, describe a proposed split under its own heading. Do not invent amendments the narrative does not state.

**4. The box states are settled — transcribe them, do not re-judge them.** Each carries \`final\`, the worker's intent after an adversary tried to kill it. A \`demoted\` box was killed: write the demoted state and put the refutation into the node body as the record of why. Do not restore a box the adversary killed.

**Never delete a closed \`[x]\` box, an \`## Out of scope\` line, or a recorded \`## Decisions\` / \`## Findings\` section, and never reuse a requirement number.**

LANES TO LAND:
${JSON.stringify(settled, null, 1)}

Return GitHub-flavoured markdown — an artifact, not a transcript:
## Landed
one line per node: closed / released / released unworked / escalated, with the session id.
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

	allRounds.push({ round, maxWorkers, remaining, grab: grabText, worked: lanes.map(l => l.node.path), releasedUnworked: releaseUnworked.map(r => ({ node: r.node.path, why: r.why })), demoted: demoted.length, report: landed })

	// Drain the ticket pool: worked tickets and explicitly-skipped tickets
	// leave it; collision-dropped tickets stay for the next round.
	if (pool) pool = pool.filter(t =>
		!lanes.some(l => l.node.path === t.path) &&
		!new RegExp(`${esc(t.path)}\\s*::\\s*SKIPPED`).test(grabText))

	if (round < ROUNDS) log(`round ${round} landed — going round again for more free work`)
}

return {
	rounds: allRounds.length,
	profile: { ecosystem: profile.ecosystem, head: profile.head, gate: LANE_GATE, fullGate: FULL_GATE },
	sessions: 'this is one session; launch mi-run again, concurrently, for another. If work is BLOCKED — escalations piling up, stale claims, a board that no longer matches the tree — that is /mi-repair, run deliberately, not more sessions.',
	detail: allRounds,
}
