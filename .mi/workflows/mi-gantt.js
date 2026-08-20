export const meta = {
	name: 'mi-gantt',
	description: 'Run the whole schedule: derive a plan from the board if there is not one yet, store it under .mi/gantt as the record, then drive it wave by wave — one mi-run session per wave, the board re-read after each to record what actually closed.',
	whenToUse: 'When you want the schedule executed rather than one node. Creates the plan record on first run. Use mi-run for a single step, mi-repair when the board is too tangled to schedule, and mi-drill when the plan has holes in it.',
	phases: [
		{ model: 'haiku', title: 'Profile', detail: 'discover the repo, the board, and whether a plan already exists' },
		{ model: 'haiku', title: 'Load', detail: 'read the plan record and fold the append-only ledger into a status' },
		{ model: 'sonnet', title: 'Survey', detail: 'derive the tasks from the board and the schedule document — only when there is no plan' },
		{ model: 'opus', title: 'Audit', detail: 'an adversary hunts for work the derived plan lost' },
		{ model: 'opus', title: 'Record', detail: 'write the plan record and regenerate its human view' },
		{ model: 'opus', title: 'Wave', detail: 'one mi-run session per wave, scoped to that wave\'s nodes' },
		{ model: 'sonnet', title: 'Ledger', detail: 'observe the board, append what actually closed, run the wave gate' },
	],
}

// ─────────────────────────────────────────────────────────────────────────
// mi-gantt — the scheduler. It does not work nodes; `mi-run` does.
//
// The division of labour is the whole design:
//
//   mi-gantt  decides WHAT RUNS NEXT and records what happened.
//   mi-run    takes nodes, claims them, works them, refutes them, lands them.
//
// So every wave here is one `workflow('mi-run', { nodes: [...] })` call. mi-run
// already has everything a wave needs — the claim commit as the cross-session
// lock, footprint partitioning, the per-node reconcile, the adversary, the one
// gate run — and re-implementing any of it here would be a second copy that
// can disagree with the first. `rounds` is handed in so mi-run loops until the
// wave is drained, picking up whatever its own partition dropped.
//
// THE RECORD, and why it is shaped like this (law 1):
//
//   <planDir>/plan.json     the home. Tasks, their specs, footprints, deps.
//   <planDir>/ledger.jsonl  append-only. One line per observation.
//   <the schedule document>  a GENERATED view of the two above.
//
// Status is a **fold of the ledger**, recomputed on read, never stored beside
// it — so a correction is an appended line that shadows the old one and
// deletion is not expressible. The plan is regenerated only on `replan: true`;
// its previous version stays in git history, which is the actual record.
//
// AND WHAT CLOSED IS OBSERVED, NOT REPORTED (law 2). The Ledger phase re-reads
// the board nodes after mi-run returns and writes down what it SEES — state and
// box counts — rather than parsing mi-run's own account of its success. A
// scheduler that believes its workers cannot notice when they are wrong.
//
// Two kinds of task are never dispatched, and both are surfaced loudly rather
// than skipped quietly:
//   - `mode: hitl` — needs the human (naming, taste, money, a reversal). It
//     does not close, so everything downstream of it stays blocked.
//   - `node: ""` — specified somewhere but placed nowhere on the board. There
//     is nothing for mi-run to claim. That is a plan defect; mi-repair or
//     mi-drill places it.
//
// Nothing below the args block names a language, a build tool or a package.
// See `_lib.md`.
//
// args (all optional):
//   { repo, board, planDir, refs, schedule, lanes, rounds, waves, only,
//     fromWave, replan, planOnly, dryRun, gate, fullGate, sizeHours,
//     seeds, models, effort }
// ─────────────────────────────────────────────────────────────────────────

const A = (typeof args === 'object' && args) || {}
const REPO = (typeof args === 'string' && args) || A.repo || 'the repo rooted at your cwd (`git rev-parse --show-toplevel`)'
const BOARD = A.board || '.mi/prd'
const PLANDIR = A.planDir || '.mi/gantt'
const PLAN = PLANDIR + '/plan.json'
const LEDGER = PLANDIR + '/ledger.jsonl'
const REFS = A.refs || '.mi/workflows/refs'
const SEEDS = A.seeds || []
const DRY = A.dryRun === true
const PLAN_ONLY = A.planOnly === true
const REPLAN = A.replan === true
const MAX_WAVES = A.waves || 99
const FROM_WAVE = A.fromWave || 1

// The concurrency cap. Precedence: what the caller asked for, then the board's
// own `max-workers` on the root node (which is the GLOBAL cap across every
// running session, so it is authoritative when present), then 3.
//
// 3 is the default because it is the number that is nearly always right: enough
// that a wave of independent files actually overlaps, few enough that a bad
// plan costs three worktrees rather than twelve. `/mi-max <N>` writes the board
// value; this constant only covers a board that has not said.
const DEFAULT_MAX_WORKERS = 3

// Size letters → hours, for the critical path only. Advisory: nothing schedules
// on it, it exists so the report can name the fulcrum task.
const SIZE_HOURS = Object.assign({ S: 1, M: 2.5, L: 5, XL: 8 }, A.sizeHours || {})

const MODELS = Object.assign({ scan: 'haiku', probe: 'sonnet', judge: 'opus', build: 'opus' }, A.models || {})
const EFFORTS = Object.assign({ scan: 'low', probe: 'medium', judge: 'high', build: 'high' }, A.effort || {})
const at = (tier, o) => Object.assign({ model: MODELS[tier], effort: EFFORTS[tier] }, o || {})

const TASK_ITEM = {
	type: 'object', additionalProperties: false,
	required: ['id', 'title', 'node', 'spec', 'size', 'mode', 'files', 'deps', 'verify', 'manual', 'notes'],
	properties: {
		id: { type: 'string', description: 'the schedule label this task is known by — taken from the source document where it has one, never invented if it does' },
		title: { type: 'string' },
		node: { type: 'string', description: 'the board node directory this task lands in, relative to the board root. EMPTY STRING if the task is specified but placed nowhere — do not guess a path that does not exist on disk.' },
		spec: { type: 'string', description: 'the file that specifies this task: the node, the design record, or the feature document' },
		size: { type: 'string', description: 'S | M | L | XL, or a bare number of hours. Advisory.' },
		mode: { type: 'string', enum: ['afk', 'hitl'], description: 'hitl = only the human can settle it (naming, taste, money, a reversal). A hitl task is never dispatched and blocks everything downstream of it.' },
		files: { type: 'array', items: { type: 'string' }, description: 'the files and directories this task writes, relative to the repo root. This is what decides who may run beside whom, so err toward listing one you are unsure about.' },
		deps: { type: 'array', items: { type: 'string' }, description: 'task ids this cannot be WRITTEN AND VERIFIED without. Not "would be nicer afterwards" — that is ordering, and the schedule computes it. An edge to an id that is not a task is an invented edge and will be dropped.' },
		verify: { type: 'string', description: 'the command that proves this task, if its spec names one, else ""' },
		manual: { type: 'string', description: 'checks on this task that genuinely need a human at a terminal, else "". Surfaced, never automated away.' },
		notes: { type: 'string' },
	},
}

const PROFILE_SCHEMA = {
	type: 'object', additionalProperties: false,
	required: ['isGit', 'head', 'branch', 'dirty', 'ecosystem', 'gate', 'fullGate', 'gateEvidence', 'boardNodes', 'maxWorkers', 'havePlan', 'scheduleDoc', 'contextFile', 'sharedFiles', 'notes'],
	properties: {
		isGit: { type: 'boolean', description: 'does `git rev-parse --is-inside-work-tree` succeed? If false, say so — worktree isolation and the claim lock both need git.' },
		head: { type: 'string' }, branch: { type: 'string' },
		dirty: { type: 'string', description: 'one-line summary of `git status --porcelain`, or "clean", or "not a git repo"' },
		ecosystem: { type: 'string', description: 'the build system actually on disk — read the manifests, do not guess from the language' },
		gate: { type: 'string', description: 'the SCOPED check one lane runs on its own change. Must exist today.' },
		fullGate: { type: 'string', description: 'the whole-tree check. Must exist today.' },
		gateEvidence: { type: 'string', description: 'the recipe list, script block or manifest target you actually read. Never invent a recipe; if there is no runner, say so.' },
		boardNodes: { type: 'integer', description: 'how many `prd.md` files exist under the board root. 0 means the board is not in node form and nothing can be claimed.' },
		maxWorkers: { type: 'integer', description: '`max-workers` on the board ROOT node, or -1 if there is no root node or no such field' },
		havePlan: { type: 'boolean', description: 'does the plan record file exist and parse as JSON?' },
		scheduleDoc: { type: 'string', description: 'a human schedule document if the repo has one — a gantt chart, a wave layout, a delivery plan — else ""' },
		contextFile: { type: 'string', description: 'CLAUDE.md / AGENTS.md / equivalent, or ""' },
		sharedFiles: { type: 'array', items: { type: 'string' }, description: 'files belonging to no task because every task would collide on them' },
		notes: { type: 'string' },
	},
}

const LOAD_SCHEMA = {
	type: 'object', additionalProperties: false,
	required: ['tasks', 'entries', 'malformed'],
	properties: {
		tasks: { type: 'array', items: TASK_ITEM, description: 'the tasks array out of the plan record, verbatim. Empty if there is no plan.' },
		malformed: { type: 'string', description: 'empty, or what failed to parse and at which line. Do NOT repair it — an unparseable record stops the run rather than being guessed at.' },
		entries: {
			type: 'array',
			description: 'every line of the ledger, IN FILE ORDER. File order is the record order; do not sort it.',
			items: {
				type: 'object', additionalProperties: false,
				required: ['entry', 'id', 'state', 'wave', 'at', 'note'],
				properties: {
					entry: { type: 'string', description: 'task | gate | wave | lock | note' },
					id: { type: 'string', description: 'the task id, or "" for entries that are not about one task' },
					state: { type: 'string', description: 'for a task entry: done | open | stub | escalated | blocked. For a gate entry: green | red.' },
					wave: { type: 'integer', description: '-1 if absent' },
					at: { type: 'string' }, note: { type: 'string' },
				},
			},
		},
	},
}

const SURVEY_SCHEMA = {
	type: 'object', additionalProperties: false,
	required: ['tasks', 'sources', 'unplaced', 'notes'],
	properties: {
		tasks: { type: 'array', items: TASK_ITEM },
		sources: { type: 'array', items: { type: 'string' }, description: 'every file you read to build this, so the audit can check you against them' },
		unplaced: { type: 'string', description: 'work you found specified but could not place on the board, and where you found it' },
		notes: { type: 'string' },
	},
}

const AUDIT_SCHEMA = {
	type: 'object', additionalProperties: false,
	required: ['verdict', 'lost', 'invented', 'edges', 'collisions', 'summary'],
	properties: {
		verdict: { type: 'string', enum: ['SAFE', 'REPAIR FIRST'], description: 'REPAIR FIRST if any work is lost, any edge is invented, or any hitl task is mismarked' },
		lost: { type: 'array', items: { type: 'string' }, description: 'work specified in a source and present in NO task — quote the source line' },
		invented: { type: 'array', items: { type: 'string' }, description: 'tasks with no source, or requirements a task added that its spec does not ask for' },
		edges: { type: 'array', items: { type: 'string' }, description: 'dependency edges that are ordering preference rather than a real "cannot be written and verified without", and edges that are missing' },
		collisions: { type: 'array', items: { type: 'string' }, description: 'tasks whose file lists are wrong — a file the task must write that is not listed, which is what turns into a merge conflict' },
		summary: { type: 'string' },
	},
}

const OBSERVE_SCHEMA = {
	type: 'object', additionalProperties: false,
	required: ['observations', 'gateRun', 'notes'],
	properties: {
		gateRun: { type: 'string', description: 'the exact wave-gate invocation and its verdict, or "" if this wave named no gate of its own' },
		notes: { type: 'string' },
		observations: {
			type: 'array',
			items: {
				type: 'object', additionalProperties: false,
				required: ['id', 'node', 'state', 'open', 'stub', 'closed', 'escalation', 'claim', 'evidence'],
				properties: {
					id: { type: 'string' }, node: { type: 'string' },
					state: { type: 'string', description: 'the node\'s `state` field VERBATIM — report an illegal value as written' },
					open: { type: 'integer' }, stub: { type: 'integer' }, closed: { type: 'integer' },
					escalation: { type: 'boolean' }, claim: { type: 'string', description: 'a claim left behind, or ""' },
					evidence: { type: 'string', description: 'what you read to establish this — the frontmatter line and the box counts' },
				},
			},
		},
	},
}

phase('Profile')

const profile = await agent(
	`Repository: ${REPO}. READ ONLY — never edit, never commit, and do NOT run the test suite or a full build. Reading files, \`git\`, \`grep\`, \`find\`, \`ls\` and metadata commands are fine.

Profile this repository for the scheduler that comes after you. Every field is established by running something, not guessed.

1. \`git rev-parse --is-inside-work-tree\` — if that fails this is NOT a git repo, set \`isGit: false\` and say so in \`notes\`. Then \`git rev-parse HEAD\`, \`git branch --show-current\`, \`git status --porcelain | head -20\`.
2. **The build system**, from the manifests actually on disk.
3. **The two gates.** \`gate\` — the fastest scoped check one worker runs on its own change. \`fullGate\` — the whole-tree check. List the runner's real recipes first (\`just --list\`, \`make -qp\`, the \`scripts\` block, the CI files) and quote what you read into \`gateEvidence\`. **Never invent a recipe.** If there is no runner, say so — a worker handed a command that does not exist will invent one.
4. **The board.** \`find ${BOARD} -name prd.md | wc -l\` → \`boardNodes\`. Then read the ROOT node (\`${BOARD}/prd.md\`) and report its \`max-workers\` field, or \`-1\` if there is no root node or no such field. **If \`boardNodes\` is 0, say so plainly in \`notes\`** — it means the board is not in node form and there is nothing for a worker to claim, however much prose the tree holds.
5. **The plan.** Does \`${PLAN}\` exist and parse as JSON?
6. **The schedule document.** Is there a human-authored schedule anywhere — a gantt chart, a wave layout, a delivery plan, a work breakdown? Name the file. This is what the survey will read.
7. \`sharedFiles\` — the files belonging to no task, and the context file if there is one.`,
	at('scan', { label: 'profile', phase: 'Profile', schema: PROFILE_SCHEMA }),
)

if (!profile) return { error: 'profile failed — the run stops here rather than scheduling against guesses' }

const LANE_GATE = A.gate || profile.gate
const FULL_GATE = A.fullGate || profile.fullGate
const CAP = Math.max(1, A.lanes || (profile.maxWorkers > 0 ? profile.maxWorkers : DEFAULT_MAX_WORKERS))
const capSource = A.lanes ? 'the caller' : (profile.maxWorkers > 0 ? `the board root's max-workers` : `the default (no max-workers on the board root — set one with /mi-max)`)

log(`${profile.ecosystem} · ${profile.boardNodes} board node(s) · cap ${CAP} from ${capSource}${profile.isGit ? '' : ' · NOT A GIT REPO'}`)

const GROUND = `Repository: ${REPO}. Work only there.

THE PROTOCOL — read it before you act, it beats your instincts:
- \`${REFS}/laws.md\` — the four laws.
- \`${REFS}/worker.md\` — the board protocol. A node is \`<dir>/prd.md\` under \`${BOARD}\`; a child is a subdirectory holding its own. Appendix A is the node format. Boxes are the only evidence: \`- [ ]\` not met · \`- [~]\` met against a STUB standing in for the real dependency · \`- [x]\` met against the real thing, with the check run.
${profile.contextFile ? `- \`${profile.contextFile}\` — the tree and its conventions.` : ''}

THE PLAN RECORD:
- \`${PLAN}\` — the home. The tasks, their specs, their footprints, their real dependency edges.
- \`${LEDGER}\` — append-only. Status is a FOLD of it, recomputed on read. A correction is an appended line that shadows the old one; deletion is not expressible.
${profile.scheduleDoc ? `- \`${profile.scheduleDoc}\` — the human view. GENERATED from the two above, never authored beside them.` : ''}

THE REPOSITORY, profiled at \`${profile.head || '(no commit)'}\`:
- build system: ${profile.ecosystem}
- scoped gate: \`${LANE_GATE}\` · full gate: \`${FULL_GATE}\`
- shared files, owned by no task: ${(profile.sharedFiles || []).map(f => `\`${f}\``).join(', ') || '(none identified)'}
${profile.isGit ? '' : '- **THIS IS NOT A GIT REPO.** There is no claim lock, no worktree isolation and no rollback.'}
${profile.notes ? `- ${profile.notes}` : ''}
${SEEDS.length ? `\nTHE CALLER'S NOTES for this run:\n${SEEDS.map(s => `- ${s}`).join('\n')}` : ''}`

// ── Load ─────────────────────────────────────────────────────────────────
phase('Load')

const loaded = await agent(
	`${GROUND}

You are the RECORD READER. Mechanical: parse and report. Judge nothing, edit nothing, create nothing.

1. If \`${PLAN}\` exists, parse it and return its \`tasks\` array **verbatim** — every field as written. If it does not exist, return an empty array; that is not an error.
2. If \`${LEDGER}\` exists, return every line as an entry **in file order**. File order is the record order — do not sort, do not dedupe, do not drop a line that looks superseded. Shadowing is computed downstream, and a line you drop is a correction that silently vanishes.
3. If either file exists but does not parse, put what failed and its line number into \`malformed\` and **do not repair it**. An unparseable record stops the run; a guessed one corrupts it.`,
	at('scan', { label: 'load', phase: 'Load', schema: LOAD_SCHEMA }),
)

// `malformed` is a required schema field, which invites the reader to fill it
// even when nothing is wrong: a first run has no ledger.jsonl at all and the
// field has come back as `""` — the two-character string — aborting a record
// that parsed fine. Strip quoting and no-op sentinels before believing it.
const malformedReport = (loaded?.malformed ?? '').trim().replace(/^["'`]+|["'`]+$/g, '').trim()

if (malformedReport && !/^(none|n\/?a|null|nil|nothing|empty|no|ok)$/i.test(malformedReport)) {
	return { error: `the plan record does not parse: ${malformedReport}`, fix: 'repair it by hand, or re-derive with { replan: true } — this run refuses to guess at a corrupt record' }
}

// The fold. Last entry per task id wins, because corrections are appended and
// shadow. Computed here rather than asked of a model: it is the thing every
// later decision reads, and it must not be a coin-flip.
const ledger = (loaded && loaded.entries) || []
const folded = new Map()
for (const e of ledger) if (e.entry === 'task' && e.id) folded.set(e.id, e)
const doneIds = new Set([...folded.entries()].filter(([, e]) => e.state === 'done').map(([id]) => id))
const escalatedIds = new Set([...folded.entries()].filter(([, e]) => e.state === 'escalated').map(([id]) => id))

let tasks = (loaded && loaded.tasks) || []
const derived = !tasks.length || REPLAN

// ── Survey ───────────────────────────────────────────────────────────────
// Only when there is no plan, or the caller asked for a fresh one. The point of
// a record is that it is not re-derived every run.
let audit = null
if (derived) {
	phase('Survey')
	if (tasks.length) log(`replan requested — re-deriving over ${tasks.length} existing task(s); the old plan stays in git history`)

	const survey = await agent(
		`${GROUND}

You are the SURVEYOR. READ ONLY — write nothing, claim nothing, run no tests.

Build the task list this schedule will be driven from. ${profile.scheduleDoc ? `This repo already has a human schedule at \`${profile.scheduleDoc}\` — **start there**, and treat its task ids, sizes and dependency edges as the intent to be captured rather than re-invented. Then check every one of them against the board and the specs, because a schedule document drifts from the tree it describes.` : 'This repo has no schedule document, so derive the tasks from the board and the specs directly.'}

For each task:
- **\`id\`** — use the label the source document already gives it. Inventing a new id for work that is already called something is how a plan stops matching the conversation about it.
- **\`node\`** — the board node directory the work lands in. **Verify the path exists on disk** (\`ls ${BOARD}/<path>/prd.md\`). If the work is specified but placed on no node, set \`node: ""\` and record it in \`unplaced\`. **Do not invent a plausible path** — an id pointing at a node that does not exist is a task that can never be claimed, and it will look scheduled the whole time it is impossible.
- **\`spec\`** — the file a worker must read to do it.
- **\`deps\`** — only what the task cannot be **written and verified** without. "Would read better afterwards" is ordering, not a dependency; the schedule computes ordering itself. Every edge must point at an id that is also in your task list.
- **\`files\`** — what it writes. This decides who runs beside whom, so grep for the paths its spec names and err toward including a file you are unsure about: a missed file is a merge conflict, a spurious one only costs parallelism.
- **\`mode\`** — \`hitl\` when only the human can settle it: naming, taste, money, a reversal, or a fork between two designs where both are defensible. Read \`${REFS}/how.md\` on which decisions are the human's. A \`hitl\` task is never dispatched and blocks everything downstream, so marking one \`afk\` to keep the schedule moving is the most expensive mistake available here.
- **\`verify\`** — the command its spec names, if any. Never invent one.
- **\`manual\`** — checks that genuinely need a human at a terminal. Listed, never automated away.

Completeness is the job. Work you leave out will not be scheduled, and nothing downstream will notice it is missing.`,
		at('probe', { label: 'survey', phase: 'Survey', schema: SURVEY_SCHEMA }),
	)

	if (!survey || !survey.tasks || !survey.tasks.length) {
		return { error: 'the survey found no tasks — there is nothing to schedule', notes: (survey && survey.notes) || '', board: `${profile.boardNodes} node(s) under ${BOARD}` }
	}
	tasks = survey.tasks
	log(`surveyed ${tasks.length} task(s) from ${(survey.sources || []).length} source(s)${survey.unplaced ? ` · unplaced work reported` : ''}`)

	// ── Audit ────────────────────────────────────────────────────────────
	// Nothing downstream checks a planner. A survey that quietly loses a
	// requirement produces a plan that runs green and builds the wrong thing,
	// so this is where the strong model earns its price.
	phase('Audit')
	audit = await agent(
		`${GROUND}

You are the ADVERSARY for a freshly derived plan. Law 2: nothing vouches for itself, and the surveyor does not get to certify its own completeness. **Your job is to find what it lost**, not to agree with it.

READ ONLY. Read every source it claims to have read, then attack the plan:

1. **Lost work.** Walk each source and find work that appears in NO task. Quote the source line. This is the failure that matters most: unscheduled work is invisible, and the run will report success without it.
2. **Invented work.** A task with no source, or a task that added a requirement its spec does not ask for.
3. **Edges.** Two directions. An edge that is really ordering preference costs parallelism for nothing. A MISSING edge is worse: two tasks run concurrently, one needed the other, and it fails at merge or silently builds against something half-there.
4. **Footprints.** For each task, grep the paths its spec names. A file the task must write that is not in its \`files\` list is a merge conflict waiting for the wave that schedules them together.
5. **hitl.** Any task marked \`afk\` that is actually a decision only the human can make — a naming call, a scope fork, a reversal, a choice between two defensible designs. An agent handed one of those will pick one and commit it, and the choice will look settled forever.
6. **Placement.** Any \`node\` path that does not resolve on disk, and any task with \`node: ""\` — those cannot be claimed at all.

THE SOURCES IT CLAIMS: ${((survey.sources) || []).join(', ') || '(none named — that alone is a finding)'}
${survey.unplaced ? `\nIT REPORTED THIS WORK AS UNPLACED:\n${survey.unplaced}` : ''}

THE PLAN:
${JSON.stringify(tasks, null, 1)}

\`SAFE\` only if you failed to find anything in categories 1, 2, 5 or 6. Missing work, an invented task, a mismarked decision or an unplaceable node all mean \`REPAIR FIRST\`.`,
		at('judge', { label: 'audit', phase: 'Audit', schema: AUDIT_SCHEMA }),
	)

	if (audit) {
		log(`audit: ${audit.verdict} · ${(audit.lost || []).length} lost · ${(audit.invented || []).length} invented · ${(audit.edges || []).length} edge finding(s) · ${(audit.collisions || []).length} footprint finding(s)`)
		for (const l of (audit.lost || []).slice(0, 8)) log(`  LOST: ${l}`)
	}
}

// ─────────────────────────────────────────────────────────────────────────
// Schedule. Deterministic, no agent — an agent that can be replaced by a for
// loop is a paid coin-flip, and this is the arithmetic every wave acts on.
// ─────────────────────────────────────────────────────────────────────────
const byId = new Map(tasks.map(t => [t.id, t]))
const norm = p => String(p).replace(/^\.?\/*/, '').replace(/\/+$/, '')
const collides = (a, b) => { a = norm(a); b = norm(b); return a === b || a.startsWith(b + '/') || b.startsWith(a + '/') }
const hoursOf = t => SIZE_HOURS[String(t.size || '').toUpperCase()] || Number(t.size) || 1

// Invented edges are dropped, loudly. An edge to a task that does not exist
// would otherwise block its source forever with no visible cause.
const droppedEdges = []
for (const t of tasks) {
	t.deps = (t.deps || []).filter(d => {
		if (byId.has(d)) return true
		droppedEdges.push(`${t.id} → ${d} (no such task)`)
		return false
	})
}

// Longest path by hours. Guarded against a cycle so a malformed plan reports
// one instead of hanging.
const cost = new Map(); const from = new Map(); const walking = new Set()
const pathCost = id => {
	if (cost.has(id)) return cost.get(id)
	if (walking.has(id)) return 0
	walking.add(id)
	const t = byId.get(id); let best = 0; let bestFrom = ''
	for (const d of t.deps) { const c = pathCost(d); if (c > best) { best = c; bestFrom = d } }
	walking.delete(id)
	cost.set(id, best + hoursOf(t)); from.set(id, bestFrom)
	return cost.get(id)
}
for (const t of tasks) pathCost(t.id)

let tail = ''
for (const t of tasks) if (!tail || cost.get(t.id) > cost.get(tail)) tail = t.id
const critical = []
for (let c = tail; c; c = from.get(c)) { critical.unshift(c); if (critical.length > tasks.length) break }

// Waves, as successive ready-sets over what the ledger has not already closed.
// A hitl task is marked SEEN but never CLOSED, which is exactly what keeps its
// dependents blocked instead of silently promoting them.
const closed = new Set(doneIds)
const held = []
const waves = []
for (let guard = 0; guard <= tasks.length; guard++) {
	const layer = tasks.filter(t => !closed.has(t.id) && !held.some(h => h.id === t.id) && t.deps.every(d => closed.has(d)))
	if (!layer.length) break
	const stoppers = layer.filter(t => t.mode === 'hitl' || escalatedIds.has(t.id) || !t.node)
	for (const t of stoppers) held.push(t)
	const runnable = layer.filter(t => stoppers.indexOf(t) === -1)
	if (!runnable.length) break
	waves.push(runnable)
	for (const t of runnable) closed.add(t.id)
}
const blocked = tasks.filter(t => !closed.has(t.id) && !held.some(h => h.id === t.id))

const reason = t => escalatedIds.has(t.id) ? 'escalated' : (t.mode === 'hitl' ? 'needs the human' : 'placed on no board node')
const scheduled = waves.reduce((n, w) => n + w.length, 0)

log(`plan: ${tasks.length} task(s) · ${doneIds.size} already done · ${scheduled} scheduled across ${waves.length} wave(s) · ${held.length} held · ${blocked.length} blocked downstream`)
log(`critical path (${Math.round(cost.get(tail) || 0)}h): ${critical.join(' → ')}`)
for (const h of held) log(`  HELD — ${h.id} ${h.title}: ${reason(h)}`)
if (blocked.length) log(`  BLOCKED behind the above: ${blocked.map(t => t.id).join(', ')}`)
for (const d of droppedEdges) log(`  dropped invented edge: ${d}`)

// The generated view. Built here so the arithmetic in it is this script's, not
// a model's recollection of this script's.
let elapsed = 0
const waveSpans = waves.map(w => { const dur = Math.max(...w.map(hoursOf)); const span = { start: elapsed, dur }; elapsed += dur; return span })
const mermaid = [
	'```mermaid', 'gantt', '    title Schedule — parallel wall-clock (agent-hours)', '    dateFormat X', '    axisFormat %s', '    todayMarker off', '',
].concat(waves.flatMap((w, i) => ['    section Wave ' + (i + 1)].concat(w.map(t =>
	`    ${t.id} ${t.title.slice(0, 40).replace(/[:#]/g, ' ')} :${critical.indexOf(t.id) !== -1 ? 'crit, ' : ''}${t.id.replace(/[^A-Za-z0-9]/g, '_')}, ${waveSpans[i].start}, ${hoursOf(t)}`,
)))).concat(held.length ? ['    section Held'].concat(held.map(t => `    ${t.id} ${reason(t)} :done, held_${t.id.replace(/[^A-Za-z0-9]/g, '_')}, 0, 1`)) : []).concat(['```']).join('\n')

const view = [
	'# Schedule', '',
	'**Generated from `' + PLAN + '` and `' + LEDGER + '`. Do not edit by hand** — regenerate with `/mi-gantt`. Progress is a fold of the ledger, so the numbers here are true as of the last run and nowhere else.', '',
	'| | |', '|---|---|',
	`| Tasks | **${tasks.length}** (${doneIds.size} done, ${scheduled} scheduled, ${held.length} held, ${blocked.length} blocked) |`,
	`| Serial effort | **${Math.round(tasks.reduce((n, t) => n + hoursOf(t), 0))} agent-hours** |`,
	`| Parallel wall-clock | **≈ ${Math.round(elapsed)} hours** at cap ${CAP} |`,
	`| Critical path | \`${critical.join(' → ')}\` (≈ ${Math.round(cost.get(tail) || 0)}h) |`,
	held.length ? `| Hard blocker | ${held.map(h => `**${h.id}** — ${reason(h)}`).join(' · ')} |` : '| Hard blocker | none |',
	'', mermaid, '',
	'## Waves', '', '| Wave | Tasks | Agents | Gate |', '|---|---|---|---|',
].concat(waves.map((w, i) => `| ${i + 1} | ${w.map(t => t.id).join(', ')} | ${Math.min(CAP, w.length)} | \`${FULL_GATE}\` |`))
	.concat(held.length ? ['', '## Held — not scheduled, and blocking what follows', '', '| Task | Why | Blocks |', '|---|---|---|']
		.concat(held.map(h => `| ${h.id} ${h.title} | ${reason(h)} | ${blocked.filter(b => b.deps.indexOf(h.id) !== -1).map(b => b.id).join(', ') || '—'} |`)) : [])
	.concat(tasks.some(t => t.manual) ? ['', '## Checks that need a human at a terminal', ''].concat(tasks.filter(t => t.manual).map(t => `- **${t.id}** — ${t.manual}`)) : [])
	.join('\n')

// ── Record ───────────────────────────────────────────────────────────────
if (derived) {
	phase('Record')
	await agent(
		`${GROUND}

You are the RECORDER. Write the plan record and its generated view, and nothing else.

**1. \`${PLAN}\`** — create the directory if needed. Write exactly this JSON, pretty-printed:

${JSON.stringify({ maxWorkers: CAP, sizeHours: SIZE_HOURS, tasks }, null, 1)}

**2. \`${PLANDIR}/plan.md\`** — write this verbatim. It is generated; the arithmetic in it is already done and is not yours to recompute:

${view}

${profile.scheduleDoc ? `**3. \`${profile.scheduleDoc}\`** is the human schedule this was derived from. It is now a GENERATED view, so replace its body with the content above and put a line at the top saying it is generated and naming \`${PLAN}\` as its home. **Keep any prose section that carries a reason the generated view cannot express** — a rationale, a decision, a warning about a trap — and move it below the generated content under a heading that says it is hand-written. A generated file that silently eats the one paragraph explaining WHY is the exact loss law 1 exists to prevent.` : ''}

**4.** ${profile.isGit ? `Commit all of it together: \`git add\` those files and \`git commit -m "plan: <N> tasks, <M> waves"\`. The record of why lands in the same commit as the change it explains.` : 'This is not a git repo, so there is nothing to commit. Say so in your report — the plan has no history and no rollback until someone runs `git init`.'}

${audit && audit.verdict === 'REPAIR FIRST' ? `**The adversary returned REPAIR FIRST.** Write its findings into \`${PLANDIR}/plan.md\` under a \`## Audit findings — unrepaired\` heading, verbatim, so the next reader sees them before trusting the plan:\n${JSON.stringify({ lost: audit.lost, invented: audit.invented, edges: audit.edges, collisions: audit.collisions }, null, 1)}` : ''}

Return: the paths you wrote, the commit hash if there is one, and anything you preserved out of an existing document.`,
		at('build', { label: 'record', phase: 'Record' }),
	)
}

// ── Stop conditions, before any work is dispatched ────────────────────────
const stopReport = {
	plan: PLAN, cap: CAP, capSource,
	tasks: tasks.length, done: doneIds.size, scheduled, waves: waves.length,
	criticalPath: critical, criticalHours: Math.round(cost.get(tail) || 0),
	held: held.map(h => ({ id: h.id, title: h.title, why: reason(h), blocks: blocked.filter(b => b.deps.indexOf(h.id) !== -1).map(b => b.id) })),
	blocked: blocked.map(t => t.id),
	droppedEdges,
	audit: audit ? { verdict: audit.verdict, lost: audit.lost, invented: audit.invented } : 'not re-audited — the plan was loaded, not derived',
	waveLayout: waves.map((w, i) => ({ wave: i + 1, tasks: w.map(t => t.id) })),
}

if (audit && audit.verdict === 'REPAIR FIRST') {
	return Object.assign({ stopped: 'the audit says REPAIR FIRST — the plan is recorded but nothing was dispatched against it', next: 'fix the findings with /mi-drill or /mi-repair, then run /mi-gantt again' }, stopReport)
}
if (PLAN_ONLY) return Object.assign({ stopped: 'planOnly — the plan is recorded, nothing dispatched' }, stopReport)
if (DRY) return Object.assign({ stopped: 'dryRun — this is what would run' }, stopReport)
if (!profile.isGit) {
	return Object.assign({ stopped: 'not a git repo — the plan is recorded, but no work can be dispatched', why: 'mi-run claims a node with a commit and works it in a git worktree. Without git there is no lock, no isolation between lanes and no rollback when a gate fails.', next: 'git init && git add -A && git commit, then run /mi-gantt again' }, stopReport)
}
if (!profile.boardNodes) {
	return Object.assign({ stopped: 'the board has no nodes — the plan is recorded, but there is nothing to claim', why: `mi-run works \`${BOARD}/<path>/prd.md\` nodes: frontmatter for state and the claim, boxes for evidence. This tree has ${profile.boardNodes} of them, so however much the specs describe, no worker can take anything.`, next: 'run /mi-repair to bring the tree into node form, then /mi-gantt again' }, stopReport)
}
if (!waves.length) {
	return Object.assign({ stopped: held.length ? 'nothing runnable — every ready task is held' : 'nothing left to schedule', next: held.length ? 'settle the held tasks (/mi-drill for the decisions, /mi-max if the cap is the problem), then run again' : 'the plan is complete as far as the ledger knows' }, stopReport)
}

// ─────────────────────────────────────────────────────────────────────────
// Run the waves. Each is one mi-run session scoped to that wave's nodes, then
// one observation of what actually changed on the board.
// ─────────────────────────────────────────────────────────────────────────
const ran = []
for (let w = FROM_WAVE - 1; w < waves.length && w < FROM_WAVE - 1 + MAX_WAVES; w++) {
	let wave = waves[w]
	if (A.only) wave = wave.filter(t => A.only.indexOf(t.id) !== -1)
	if (!wave.length) continue

	const nodes = wave.map(t => t.node)
	const lanes = Math.min(CAP, wave.length)
	// Enough rounds for mi-run to drain the wave even when its own footprint
	// partition has to serialise some of it — plus one to mop up.
	const rounds = Math.ceil(wave.length / lanes) + 1

	phase('Wave')
	log(`wave ${w + 1}/${waves.length}: ${wave.map(t => t.id).join(', ')} → mi-run, ${lanes} lane(s), up to ${rounds} round(s)`)

	let runResult = null
	try {
		runResult = await workflow('mi-run', {
			repo: A.repo, board: BOARD, refs: A.refs,
			nodes, take: lanes, lanes, rounds,
			gate: LANE_GATE, fullGate: FULL_GATE,
			models: A.models, effort: A.effort,
			seeds: (SEEDS || []).concat([
				`You are being run as wave ${w + 1} of ${waves.length} of a recorded schedule (\`${PLAN}\`). Work only the nodes handed to you in \`nodes\`.`,
				`The scheduler observes the board itself afterwards and writes the ledger from what it sees, not from your report — so an honest \`[ ]\` costs you nothing and a hopeful \`[x]\` will be contradicted by the record.`,
			]),
		})
	} catch (e) {
		log(`wave ${w + 1}: mi-run failed — ${String(e && e.message || e)}`)
		ran.push({ wave: w + 1, tasks: wave.map(t => t.id), error: String(e && e.message || e) })
		break
	}

	// ── Ledger ───────────────────────────────────────────────────────────
	// Progress is computed from observed change, never from the actor's report
	// (law 2). This reads the board and writes down what is there.
	phase('Ledger')
	const observed = await agent(
		`${GROUND}

You are the LEDGER KEEPER for wave ${w + 1}. Two jobs, in order: **observe**, then **append**. You do not work nodes, you do not fix them, and you do not decide whether the wave succeeded.

**1. Observe.** For each task below, read its node file and report what is ACTUALLY THERE:
- the \`state\` field verbatim — an illegal value is reported as written, not repaired
- the box counts across the WHOLE file under any heading: \`- [ ]\` → open, \`- [~]\` → stub, \`- [x]\` → closed. Counting only under one heading is exactly what lets an acceptance clause close unmet.
- whether an \`## Escalation\` heading exists
- any \`claim:\` left behind — a claim on a node nobody is working blocks it for every session

A worker just reported on these nodes. **Do not read that report and do not look for it.** You are here because the actor's account of its own success is not evidence; the file is.

TASKS IN THIS WAVE:
${wave.map(t => `- \`${t.id}\` → \`${BOARD}/${t.node}/prd.md\` — ${t.title}`).join('\n')}

**2. The wave gate.** ${A.waveGate || FULL_GATE ? `Run \`${A.waveGate || FULL_GATE}\` once and record the exact invocation and verdict in \`gateRun\`. Confirm the command exists first — the profile established it from ${profile.gateEvidence || 'this repo\'s own runner'}. If it is missing, say so in \`gateRun\`; **never invent a recipe**, and never edit a shared build file to make a gate pass.` : 'This wave names no gate of its own. Leave `gateRun` empty.'}
   If it fails, that is a finding, not something for you to fix. Record it and stop.

**3. Append to \`${LEDGER}\`** — one JSON object per line, created if absent. **Append only.** Never rewrite or delete a line: corrections are appended and shadow the old value, which is what makes this file a record instead of a cache.

One line per task, with the state you OBSERVED — \`done\` only when the node says \`state: done\` and has zero open and zero stubbed boxes and no escalation; \`escalated\` when there is an \`## Escalation\`; \`stub\` when boxes are \`[~]\`; \`open\` otherwise:
    {"entry":"task","id":"<id>","state":"<observed>","wave":${w + 1},"at":"<date -u +%FT%TZ>","note":"<open>/<stub>/<closed> boxes, state: <verbatim>"}
Then one line for the wave:
    {"entry":"gate","id":"","state":"<green|red>","wave":${w + 1},"at":"<...>","note":"<the exact command and verdict, or 'no wave gate'>"}

Take the timestamp by running \`date -u +%FT%TZ\` — do not compose one from memory.

**4.** Commit the ledger alone: \`git add ${LEDGER} && git commit -m "ledger: wave ${w + 1}"\`. Commit nothing else; the work itself was already committed by the workers.`,
		at('probe', { label: `ledger-w${w + 1}`, phase: 'Ledger', schema: OBSERVE_SCHEMA }),
	)

	const obs = (observed && observed.observations) || []
	const closedNow = obs.filter(o => o.state === 'done' && o.open === 0 && o.stub === 0 && !o.escalation)
	const strays = obs.filter(o => o.claim)
	const esc = obs.filter(o => o.escalation)

	log(`wave ${w + 1}: ${closedNow.length}/${wave.length} closed · ${esc.length} escalated · ${strays.length} stray claim(s)${observed && observed.gateRun ? ` · gate: ${observed.gateRun}` : ''}`)
	for (const s of strays) log(`  STRAY CLAIM on ${s.node} by ${s.claim} — that node is blocked for every session until it is cleared`)

	for (const o of closedNow) doneIds.add(o.id)
	ran.push({
		wave: w + 1, dispatched: wave.map(t => t.id),
		closed: closedNow.map(o => o.id),
		stillOpen: obs.filter(o => closedNow.indexOf(o) === -1).map(o => ({ id: o.id, state: o.state, open: o.open, stub: o.stub })),
		escalated: esc.map(o => o.id), strayClaims: strays.map(o => ({ node: o.node, claim: o.claim })),
		gateRun: (observed && observed.gateRun) || '', miRun: runResult && runResult.detail ? runResult.detail.map(d => ({ round: d.round, nodes: d.nodes, tookNothing: d.tookNothing, demoted: d.demoted })) : runResult,
	})

	// A red gate stops the schedule. Advancing a wave over a failed gate is how
	// a build reports success on top of a broken tree.
	if (observed && /\bred\b|\bfail/i.test(observed.gateRun || '')) { log(`wave ${w + 1} gate is red — stopping rather than advancing`); break }
	if (esc.length) { log(`wave ${w + 1} left ${esc.length} escalation(s) — stopping; an escalation is the human's to clear`); break }
	if (!closedNow.length) { log(`wave ${w + 1} closed nothing — stopping rather than looping on a wave that does not move`); break }
}

return Object.assign({
	ran,
	closedThisRun: ran.flatMap(r => r.closed || []),
	remaining: tasks.filter(t => !doneIds.has(t.id)).map(t => t.id),
	next: ran.length && ran[ran.length - 1].closed && ran[ran.length - 1].closed.length === (ran[ran.length - 1].dispatched || []).length
		? 'run /mi-gantt again for the next wave'
		: 'a wave did not fully close — read `ran` for what is still open, then /mi-drill the specs or /mi-repair the board',
}, stopReport)
