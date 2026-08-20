export const meta = {
	name: 'mi-reconcile',
	description: 'Reconcile the .mi/prd board, the design records and the actual tree; report every drift with file:line',
	whenToUse: 'When you suspect the record no longer describes the code — before a replan, after a big rename, or when a node claims something you cannot find.',
	phases: [
		{ model: 'haiku', title: 'Profile', detail: 'discover the repo: build system, gates, doc layers, board census' },
		{ model: 'sonnet', title: 'Reconcile', detail: 'one finder per drift dimension' },
		{ model: 'opus', title: 'Refute', detail: 'one adversary per dimension, prompted to kill findings' },
		{ model: 'opus', title: 'Synthesize', detail: 'merge survivors into one evidence report' },
	],
}

// ─────────────────────────────────────────────────────────────────────────
// args — see _lib.md. Nothing below names a language, a build tool, a package
// or a node id: what varies per repo is DISCOVERED by the Profile step.
// ─────────────────────────────────────────────────────────────────────────
const A = (typeof args === 'object' && args) || {}
const REPO = (typeof args === 'string' && args) || A.repo || 'the repo rooted at your cwd (`git rev-parse --show-toplevel`)'
const BOARD = A.board || '.mi/prd'
// The protocol reference files. They live beside these scripts, so a repo that
// symlinks `.mi/workflows` at the shared home gets them for free — the refs
// travel with the workflows instead of being installed per repo. They are read
// on demand by the agents that need them, not registered as a skill.
const REFS = A.refs || '.mi/workflows/refs'
// Plan artifacts live OUTSIDE the repository. They are transient evidence, not
// repo content, and `.mi/` is walked by tree-wide gates — a scratch file there
// makes every gate run depend on whatever a planner last wrote.
const PLAN_DIR = A.planDir || '/tmp/mi-plan'
const SEEDS = A.seeds || []
const RETIRED = A.retired || []

// ── model policy ─────────────────────────────────────────────────────────
// Tiered by the KIND of thinking a step does, not by how important it feels.
//   scan  — enumerate, parse, count. Reproducible by re-running the command.
//   probe — read the code and establish what is TRUE. Falsifiable downstream.
//   judge — adversaries and synthesisers. Nothing downstream checks these.
//   build — writes durable things.
const MODELS = Object.assign({ scan: 'haiku', probe: 'sonnet', judge: 'opus', build: 'opus' }, A.models || {})
const EFFORTS = Object.assign({ scan: 'low', probe: 'medium', judge: 'high', build: 'high' }, A.effort || {})
const at = (tier, o) => Object.assign({ model: MODELS[tier], effort: EFFORTS[tier] }, o || {})

// ─────────────────────────────────────────────────────────────────────────
// Phase 1 — Profile. One cheap agent replaces both the facts the old version
// of this file had hardcoded and the N expensive agents that would each
// re-derive them.
// ─────────────────────────────────────────────────────────────────────────
const PROFILE_SCHEMA = {
	type: 'object', additionalProperties: false,
	required: ['head', 'dirty', 'ecosystem', 'packages', 'sourceRoots', 'gate', 'fullGate', 'gateEvidence', 'memoDir', 'docs', 'contextFile', 'testLayout', 'renames', 'notes'],
	properties: {
		head: { type: 'string', description: 'git rev-parse HEAD' },
		dirty: { type: 'string', description: 'a one-line summary of `git status --porcelain`, or "clean"' },
		ecosystem: { type: 'string', description: 'the build system actually on disk — read the manifest files, do not guess from the language' },
		sourceRoots: { type: 'array', items: { type: 'string' }, description: 'the directories implementations live in, relative to the repo root' },
		gate: { type: 'string', description: 'the SCOPED check one worker runs against its own change: the fastest command in this repo that would actually fail on a broken change. Must exist today.' },
		fullGate: { type: 'string', description: 'the whole-tree check, run once after everything merges. Must exist today.' },
		gateEvidence: { type: 'string', description: 'how you established both commands exist — the recipe list, script list or manifest target you actually read' },
		memoDir: { type: 'string', description: 'the design-record directory if this repo has one (e.g. .mi/docs/memos), else ""' },
		docs: { type: 'array', items: { type: 'string' }, description: 'the prose documents that make CHECKABLE claims about the tree — counts, paths, symbols, states' },
		contextFile: { type: 'string', description: 'CLAUDE.md / AGENTS.md / equivalent, or ""' },
		testLayout: { type: 'string', description: 'where this repo puts tests and what it forbids, quoted from its own context file — or "no stated convention"' },
		notes: { type: 'string', description: 'anything an auditor of this repo must know that the fields above do not carry' },
		packages: {
			type: 'array',
			items: {
				type: 'object', additionalProperties: false, required: ['name', 'dir'],
				properties: { name: { type: 'string' }, dir: { type: 'string', description: 'directory relative to the repo root' } },
			},
			description: 'every buildable unit, one per manifest. A single-package repo has exactly one entry.',
		},
		renames: {
			type: 'array',
			description: 'the moves and renames in recent history — the main mechanical source of drift, because the record keeps the old address',
			items: {
				type: 'object', additionalProperties: false, required: ['from', 'to', 'when'],
				properties: { from: { type: 'string' }, to: { type: 'string' }, when: { type: 'string', description: 'the commit and date' } },
			},
		},
	},
}

const CENSUS_SCHEMA = {
	type: 'object', additionalProperties: false,
	required: ['nodes', 'totals'],
	properties: {
		totals: { type: 'string', description: 'nodes counted, and the tree-wide open / stub / closed box totals' },
		nodes: {
			type: 'array',
			items: {
				type: 'object', additionalProperties: false,
				required: ['path', 'title', 'state', 'mode', 'priority', 'verify', 'claim', 'open', 'stub', 'closed', 'escalation', 'children', 'memo'],
				properties: {
					path: { type: 'string', description: 'node directory relative to the board root' },
					title: { type: 'string' },
					state: { type: 'string', description: 'the state: field verbatim — do not normalise an illegal value, report it as written' },
					mode: { type: 'string' },
					priority: { type: 'integer', description: '-1 if absent or unparseable' },
					verify: { type: 'string', description: 'the verify: command verbatim, or ""' },
					claim: { type: 'string', description: 'the claim: field verbatim, or ""' },
					open: { type: 'integer', description: 'count of `- [ ]` boxes under ANY heading in this file' },
					stub: { type: 'integer', description: 'count of `- [~]` boxes under ANY heading' },
					closed: { type: 'integer', description: 'count of `- [x]` boxes under ANY heading' },
					escalation: { type: 'boolean', description: 'does the file carry an `## Escalation` section' },
					children: { type: 'array', items: { type: 'string' }, description: 'child node paths, relative to the board root' },
					memo: { type: 'string', description: 'the design record this node names as its spec, or ""' },
				},
			},
		},
	},
}

phase('Profile')

const [profile, census] = await parallel([
	() => agent(
		`Repository: ${REPO}. READ ONLY — never edit, never commit, and never run the test suite or a full build (slow, and other sessions may be building this tree). Reading files, \`git log\`, \`grep\`, \`find\`, \`ls\`, and any command that only PRINTS metadata are all fine.

Profile this repository for the auditors that come after you. Every field is a fact you establish by running something, not a guess from the language.

1. \`git rev-parse HEAD\`, and \`git status --porcelain | head -20\`.
2. **The build system.** Look for manifests on disk: \`Cargo.toml\`, \`package.json\`, \`go.mod\`, \`pyproject.toml\`, \`pom.xml\`, \`build.gradle\`, \`Gemfile\`, \`mix.exs\`, \`CMakeLists.txt\`, \`Makefile\`, \`justfile\`, \`Taskfile.yml\`. Name what is actually there. If several, say which one the repo's own context file treats as primary.
3. **The packages.** Enumerate them from the build system's own metadata command where one exists (a workspace listing, a members list, a module list) rather than by guessing from directory names. A single-package repo has exactly one entry.
4. **The two gates, and this is the field most likely to be wrong.** Find the commands this repo actually uses:
   - \`gate\` — the fastest check a single worker can run against its own change that would really fail on a broken one. Scoped tests, a type-check, a lint — whichever exists.
   - \`fullGate\` — the whole-tree check.
   Establish they exist: list the runner's recipes (\`just --list\`, \`make -qp\`, the \`scripts\` block of \`package.json\`, the CI workflow files), and quote what you found in \`gateEvidence\`. **Never invent a recipe.** If the repo has no runner, fall back to the ecosystem's plain command and say so.
5. **The record layers.** Is there a design-record / memo / ADR directory? Which prose documents make claims a reader could check — counts, paths, symbols, per-item states? Is there a \`CLAUDE.md\` or \`AGENTS.md\`, and what does it say about where tests go?
6. **The renames.** \`git log --diff-filter=R --name-status -M --since='6 months ago' | head -60\` and the last ~40 commit subjects. A rename or a directory move is the main mechanical source of drift, because the record keeps the old address long after the code moves. Report each as from → to, with the commit.`,
		at('scan', { label: 'profile', phase: 'Profile', schema: PROFILE_SCHEMA }),
	),
	() => agent(
		`Repository: ${REPO}. READ ONLY.

Take a complete census of the board at \`${BOARD}\`. This is mechanical: parse and count, judge nothing.

1. \`find ${BOARD} -name prd.md | sort\`. Every one is a node. Its \`path\` is its DIRECTORY relative to \`${BOARD}\` — the root node's path is \`.\`.
2. For each node, parse the \`---\` frontmatter. Report every field **verbatim**. If \`state\` holds something illegal, report the illegal value; do not repair it. Missing \`priority\` is \`-1\`; every other missing field is \`""\`.
3. Count boxes across the WHOLE file, under any heading: \`- [ ]\` → \`open\`, \`- [~]\` → \`stub\`, \`- [x]\` → \`closed\`. Scoping the count to \`## Requirements\` is exactly the mistake that lets an unmet acceptance clause hide, so count everything.
4. \`escalation\` is true iff the file contains an \`## Escalation\` heading.
5. \`children\` — the node directories one level below this one that themselves contain a \`prd.md\`.
6. \`memo\` — if the node names a design record as its spec, the path it names. Otherwise \`""\`.
7. \`title\` — the first \`#\` heading.

Completeness is the whole job: a node you skip is a node nobody audits.`,
		at('scan', { label: 'census', phase: 'Profile', schema: CENSUS_SCHEMA }),
	),
])

if (!profile) return { error: 'profile failed — every downstream prompt depends on it' }
if (!census || !census.nodes || !census.nodes.length) return { error: `no board found at ${BOARD}`, profile }

log(`${profile.ecosystem} · ${profile.packages.length} package(s) · gate: ${profile.gate} · ${census.nodes.length} board nodes`)
if (profile.memoDir) log(`design records: ${profile.memoDir}`)

// ── the ready set, computed here rather than by an agent ─────────────────
// Deterministic arithmetic over the census. An agent that can be replaced by a
// `for` loop is a paid coin-flip, and this predicate is the one every session
// acts on.
const byPath = new Map(census.nodes.map(n => [n.path, n]))
const owes = n => n.open + n.stub + (n.escalation ? 1 : 0)
const resolved = n => n.state === 'out-of-scope' || (n.state === 'done' && owes(n) === 0)
const reopened = n => n.state === 'done' && n.open + n.stub > 0 && !n.escalation
const covered = n => {
	if (!resolved(n)) return false
	return (n.children || []).every(c => { const k = byPath.get(c); return !k || covered(k) })
}
const ready = census.nodes
	.filter(n => (n.state === 'open' || reopened(n)) && !n.claim && n.mode !== 'hitl' && !n.escalation && (n.children || []).every(c => { const k = byPath.get(c); return !k || covered(k) }))
	.sort((a, b) => (b.priority - a.priority) || (b.path.split('/').length - a.path.split('/').length) || a.path.localeCompare(b.path))

const claimed = census.nodes.filter(n => n.claim)
log(`ready: ${ready.length ? ready.map(n => n.path).join(', ') : 'none'}${claimed.length ? ` · claimed: ${claimed.map(n => n.path).join(', ')}` : ''}`)

// ─────────────────────────────────────────────────────────────────────────
// Ground rules, built from what was discovered rather than from what somebody
// once knew about one repository.
// ─────────────────────────────────────────────────────────────────────────
const CENSUS_TEXT = census.nodes.map(n => `- \`${n.path}\` — ${n.title} · state:${n.state} mode:${n.mode} prio:${n.priority}${n.claim ? ` claim:${n.claim}` : ''} · ${n.open}open/${n.stub}stub/${n.closed}closed${n.escalation ? ' · ESCALATED' : ''}${n.verify ? ` · verify: \`${n.verify}\`` : ''}${n.memo ? ` · memo: ${n.memo}` : ''}`).join('\n')

const RENAME_TEXT = (profile.renames || []).length
	? profile.renames.map(r => `- \`${r.from}\` → \`${r.to}\` (${r.when})`).join('\n')
	: '(none found in recent history)'

const GROUND = `You are auditing the repository at ${REPO}. Work only there. READ ONLY — never edit, never commit, and never run the test suite or a full build (too slow, and other sessions may be building this tree). Reading files, \`git log\`, \`grep\`, \`find\`, \`ls\`, \`sed -n\`, and metadata-printing commands are all fine.

THE PROTOCOL, and it beats your instincts:
- \`${REFS}/laws.md\` — the four laws. Law 1: one record; where a copy must exist it is generated from its home, never authored beside it. Law 2: nothing vouches for itself. Law 3: a rule that cannot run is a wish. Law 4: one form at every scale, one vocabulary.
- \`${REFS}/worker.md\` — the board protocol. A node is \`<dir>/prd.md\`. Boxes: \`- [ ]\` unmet · \`- [~]\` met against a STUB standing in for the real dependency · \`- [x]\` met against the real thing with the check run.
${profile.contextFile ? `- \`${profile.contextFile}\` — the working context for this tree.` : '- (this repo has no context file; the board is the whole spec)'}

THE REPOSITORY, as profiled at \`${profile.head}\`:
- build system: ${profile.ecosystem}
- packages: ${profile.packages.map(p => `\`${p.name}\` (${p.dir})`).join(', ') || '(one, unnamed)'}
- implementations live under: ${(profile.sourceRoots || []).join(', ') || '(unknown)'}
- gates that exist: scoped \`${profile.gate}\`, full \`${profile.fullGate}\` — do NOT run either
- design records: ${profile.memoDir || '(this repo has no memo layer — a node\'s own Requirements / Acceptance / Out of scope IS its contract)'}
- checkable prose: ${(profile.docs || []).join(', ') || '(none)'}
- tests law: ${profile.testLayout}
${profile.notes ? `- ${profile.notes}` : ''}

RENAMES IN RECENT HISTORY — the main mechanical source of drift, because the record keeps the old address:
${RENAME_TEXT}
${RETIRED.length ? `\nVOCABULARY RETIREMENTS the caller supplied, to be swept for:\n${RETIRED.map(r => `- \`${r[0]}\` → \`${r[1]}\``).join('\n')}` : ''}

THE BOARD, censused at that commit:
${CENSUS_TEXT}

The ready set, computed from that census by the protocol's own predicate — \`(open ∨ reopened) ∧ unclaimed ∧ afk ∧ no escalation ∧ every child covered\`: ${ready.map(n => n.path).join(', ') || '(nothing ready)'}
${SEEDS.length ? `\nTHE CALLER'S SEEDS — specific suspicions about THIS repo, to check first. They are leads, not conclusions, and finding one false is a useful answer:\n${SEEDS.map(s => `- ${s}`).join('\n')}` : ''}

WHAT A FINDING IS. Every finding names file + line, quotes the exact wrong text, and gives the exact right text. A finding nobody can act on without redoing your search is a bad finding. Report only DRIFT — a place where the record disagrees with itself or with the code. Do NOT report style opinions, missing features, or work that is honestly marked open.

WHAT IS NOT DRIFT, in any repository:
- A **closed** node keeping vocabulary or an address from when it was closed. A claim is a commit against a path; the closed record is the record of what was true then.
- A **provenance note** that names an old thing on purpose, and says so.
- A stored identifier — a database name, a wire field, a serialized key — that costs a migration to change. Report it only if something in the record calls it already renamed.`

const FINDING_SCHEMA = {
	type: 'object', additionalProperties: false,
	required: ['dimension', 'findings', 'coverage'],
	properties: {
		dimension: { type: 'string' },
		coverage: { type: 'string', description: 'what you actually read and ran, and what you could not cover' },
		findings: {
			type: 'array',
			items: {
				type: 'object', additionalProperties: false,
				required: ['file', 'line', 'claim', 'reality', 'fix', 'severity'],
				properties: {
					file: { type: 'string' },
					line: { type: 'integer' },
					claim: { type: 'string', description: 'the exact text in the record that is wrong, quoted' },
					reality: { type: 'string', description: 'what is actually true, and the command or file that establishes it' },
					fix: { type: 'string', description: 'the exact replacement text or the exact edit' },
					severity: { type: 'string', enum: ['lie', 'stale', 'cosmetic'], description: 'lie = a reader would act wrongly on it; stale = an old address that still resolves by guesswork; cosmetic = spelling only' },
				},
			},
		},
	},
}

const VERDICT_SCHEMA = {
	type: 'object', additionalProperties: false,
	required: ['verdicts'],
	properties: {
		verdicts: {
			type: 'array',
			items: {
				type: 'object', additionalProperties: false, required: ['file', 'line', 'refuted', 'why'],
				properties: { file: { type: 'string' }, line: { type: 'integer' }, refuted: { type: 'boolean' }, why: { type: 'string' } },
			},
		},
	},
}

// ─────────────────────────────────────────────────────────────────────────
// The dimensions. Each is a question about the record that holds in ANY repo
// running this board; the repo-specific half arrives through GROUND.
// ─────────────────────────────────────────────────────────────────────────
const DIMENSIONS = [
	{
		key: 'board-integrity',
		prompt: `DIMENSION: the board against itself.

The census above already counted the boxes, so do not re-count them — audit what the counts MEAN.

1. **Frontmatter legality.** Every field one of state / mode / priority / verify / est / claim / max-workers, with a legal value (\`state: open|claimed|done|out-of-scope\`, \`mode: afk|hitl\`). Any other field, or an illegal value, is a finding. The census reports these verbatim, so start from the rows that look wrong there.
2. **Box arithmetic against \`state\`.** A node marked \`done\` still carrying open or stub boxes and no \`## Escalation\` is REOPENED by the protocol and is lying about being done. A node marked \`open\` with zero open boxes is drift the other way. A node marked \`claimed\` whose \`claim:\` field is missing is drift.
3. **\`verify:\` commands — law 3.** For every node carrying one, does that command exist TODAY? Check it against the runner's recipe list and the package metadata, and check that any file it names is on disk. **Do not run it.** A \`verify:\` that cannot run is a node that would close with no proof. Also flag one that would pass VACUOUSLY — a test selector matching nothing, a gate over an empty or fully-excluded set. A check that finds nothing must fail, not pass.
4. **\`claim:\` fields.** For each, find the claim commit (\`git log -1 --format='%ct %h' --grep='claim <path>'\`) and give its age in hours. A claim whose session id appears in no recent commit is stale — SURFACE it, and say so; taking it is not yours and not this workflow's.
5. **The children contract.** Where a parent carries a \`## Children\` checklist, does each line agree with that child's actual state in the census? A parent box saying a child is done when the child carries open boxes is a law-1 finding: the parent authored a copy beside the home instead of folding it.`,
	},
	{
		key: 'closed-vs-code',
		prompt: `DIMENSION: closed \`[x]\` boxes against the code that is supposed to prove them.

Scope: every node the census reports as \`done\` or \`out-of-scope\`, plus every \`[x]\` box inside a node that is still open. These are the claims nobody will re-examine, which is exactly why they rot.

For every \`- [x]\` box that names a CONCRETE artifact — a path, a symbol, a test name, a command, a file format, a flag — verify that artifact exists at that address today. Use grep, find, and the package metadata command; do not run tests.

Report a box when the named artifact:
- cannot be found under any name (the claim is unsupported), or
- was found at a DIFFERENT address (give both — this is the rename tax, and the renames listed in the ground rules are where to look first).

Do not report a box that names no artifact; that is a different dimension's problem. A closed box whose evidence moved is \`stale\`; a closed box whose evidence never existed is a \`lie\`.`,
	},
	{
		key: 'open-vs-code',
		prompt: `DIMENSION: open \`[ ]\` and stub \`[~]\` boxes against the code — drift in the other direction.

Scope: every node the census reports with open or stub boxes. Prioritise the ready set named in the ground rules: those are the nodes somebody is about to pick up, and a wrong box there costs a worker the whole node.

For each open box:
1. **Is it already met?** Grep for every symbol, path, test and command it names. If the code already does what the box asks, the box should be \`[x]\` and its being open is drift. Give the evidence AND what a check would have done had the requirement been unmet — without that second half you have a coincidence, not evidence.
2. **Does it name an address that moved?** Check every path and symbol against the tree today. Give the current address.
3. **Does it contradict its own spec** — the design record it names, or, where there is none, another box in the same node? Contradiction inside the record is the most expensive finding here, because both sides look authoritative.
4. For each \`[~]\`, name the load-bearing STUB and where it lives. A stub box with no identified stub is a box that has quietly become a \`[ ]\`.

CRITICAL EXTRA OUTPUT — the collision map. In \`coverage\`, give a compact \`node -> directories\` list: for each node with open work, which source directories its remaining work would have to touch. This decides whether nodes can be worked in parallel, so be concrete and err toward naming a directory you are unsure about.`,
	},
	{
		key: 'docs-vs-tree',
		prompt: `DIMENSION: the checkable claims in the prose against the actual tree.

Read the context file and every document listed as "checkable prose" in the ground rules. A prose document drifts silently because nothing gates it.

Check every claim that is COUNTABLE or CHECKABLE, and check each by running something:
- **Counts** — "N packages", "N plugins", "three families", "ten directories". Count them yourself from the package metadata and \`ls\`. Report the real number.
- **Paths and symbols** — every one named in prose. Does it resolve today?
- **Commands** — every command the docs tell a reader to run. Does it exist? (Do not run it.)
- **Negative claims** — "there are no X", "this never happens", "the tree contains no Y". These are the ones that rot invisibly. Run the search that would falsify each.
- **Per-item state** — where a document carries its own list of what is done and what is not, compare each item against the board's actual box counts in the census. The board is the claim surface and prose about it is a fold, so every disagreement is a law-1 finding.
- **Handoff / status / session documents** — is each still current, or does it describe work that has since landed or been superseded? Give its date and what it still asserts that is no longer true.

Report every claim that did NOT hold. Say in \`coverage\` how many you checked, so the ratio is visible.`,
	},
	{
		key: 'vocabulary',
		prompt: `DIMENSION: retired vocabulary and dead addresses still live in the record — law 4, one vocabulary.

You are NOT given a list of banned words to grep for. Derive the retirements yourself, because that is what makes this check survive the next rename:

1. Start from the renames in the ground rules (from \`git log --diff-filter=R\`) and from any retirement the record states explicitly — a memo, a decision section, a changelog entry saying "X is now Y".
2. Add the directory moves: any path prefix that no longer exists but is still written down.
3. Add anything the caller supplied under vocabulary retirements.
4. For each, sweep the record — \`${BOARD}/**\`, the design records, the context file, and package-level READMEs — for the old spelling.

Honour the "what is not drift" rules in the ground rules: closed nodes, deliberate provenance notes, and stored identifiers keep their old words on purpose.

GROUP your findings: one finding per file, with an occurrence count and the line numbers — not one per occurrence. But raise SEPARATELY, with severity \`lie\`, any occurrence where the old word would make a reader do the WRONG THING rather than merely read an old name: a command they would run, a path they would open, a field they would set.

Finally, law 3: is there a GATE that would catch a re-introduction of any retired word? Look wherever this repo keeps its checks. If there is not, say so — an unenforced retirement is a wish, and it will be undone by the next contributor who never read the memo.`,
	},
]

if (profile.memoDir) {
	DIMENSIONS.push({
		key: 'records-vs-code',
		prompt: `DIMENSION: the design records at \`${profile.memoDir}\` against the tree.

These are the specs. A node that names one is governed by it, so a record that has drifted misleads not one reader but every worker on that node.

For each record:
1. **Its frontmatter against the tree.** Every path it declares — the code it lands in, the gate that proves it, the references it cites — does that path exist today? A record's declared status against the reality of its own code: a record saying it is partial whose code is fully landed, or saying it is landed whose code does not exist, is a finding. Establish reality by READING THE CODE, not by trusting the record's body.
2. **Its own format rules.** If the directory contains a document defining the record format, read that FIRST and report every record whose frontmatter violates the format it declares.
3. **The index, if there is one.** A README or index that folds the records' own frontmatter into a table is a law-1 copy: it must be generated from the home, never authored beside it. Compare every column against the records' actual frontmatter and report each disagreement. Then check whether anything GENERATES or GATES that table, or whether it is hand-authored — if the index claims a gate keeps it honest, read the gate and verify it actually checks what the index says it does. A gate that does not check the thing it is cited for is a law-3 finding.
4. **Both directions of coverage.** A record whose subject no board node carries is decided work assigned to nobody. An open board node whose subject no record covers has no spec to be a wall against. Report both lists.`,
	})
}

phase('Reconcile')

const results = await pipeline(
	DIMENSIONS,
	d => agent(`${GROUND}\n\n${d.prompt}`, at('probe', { label: `find:${d.key}`, phase: 'Reconcile', schema: FINDING_SCHEMA })),
	(found, d) => {
		if (!found || !found.findings || !found.findings.length) return { d, found, verdicts: [] }
		const list = found.findings.map((f, i) => `${i + 1}. ${f.file}:${f.line} [${f.severity}]\n   CLAIM: ${f.claim}\n   REALITY: ${f.reality}\n   FIX: ${f.fix}`).join('\n')
		return agent(
			`${GROUND}

You are the ADVERSARY for the "${d.key}" dimension. Another agent produced the findings below. **Refute each one.** Not confirm it — refute it. Default to \`refuted: true\` whenever you cannot independently reproduce the claim from the tree yourself.

For each finding, go to the named file:line and check:
- Does the quoted CLAIM text actually appear there? A misquote or a wrong line number => refuted. A finding a reader cannot locate is worse than no finding.
- Is the REALITY true? Re-derive it from the tree. Do not reason from the finding's own explanation — that is the thing under test.
- Is it covered by "what is not drift" in the ground rules — a closed node, a deliberate provenance note, a stored identifier? => refuted.
- Is this actually drift, or honest open work correctly marked open? => refuted.
- Would the proposed FIX be correct if applied verbatim, by someone who does not know the codebase? If not => refuted, and say what the fix should have been.

FINDINGS:
${list}

One verdict per finding, keyed by the same file and line.`,
			at('judge', { label: `refute:${d.key}`, phase: 'Refute', schema: VERDICT_SCHEMA }),
		).then(v => ({ d, found, verdicts: (v && v.verdicts) || [] }))
	},
)

const surviving = []
const killed = []
const coverage = []
for (const r of results.filter(Boolean)) {
	if (!r.found) continue
	coverage.push(`### ${r.found.dimension || r.d.key}\n${r.found.coverage}`)
	for (const f of r.found.findings || []) {
		const v = r.verdicts.find(x => x.file === f.file && x.line === f.line)
		if (v && v.refuted) killed.push(Object.assign({}, f, { dimension: r.d.key, why: v.why }))
		else surviving.push(Object.assign({}, f, { dimension: r.d.key, verdict: v ? v.why : 'no verdict returned' }))
	}
}

log(`${surviving.length} finding(s) survived refutation, ${killed.length} killed`)

phase('Synthesize')

const synth = await agent(
	`${GROUND}

You are the SYNTHESIZER. ${DIMENSIONS.length} auditors swept this repository for drift between the board, the design records and the code. Every finding below survived an adversary prompted to refute it.

Your output is EVIDENCE for a later replanning step, not a worklist. Do not place findings on the board, do not propose node structure, and do not partition anything into lanes — other steps own those, and a second opinion here becomes a second home for the decision. Report what is true.

**Write your report to \`${PLAN_DIR}/plan.reconcile.md\`** — the only file you write. It sits OUTSIDE the repository on purpose: a sweep is evidence, not yet a fact worth a commit, and a scratch file inside \`.mi/\` is walked by the tree-wide gates, so every gate run would start depending on whatever a planner last wrote. Return the same text as your answer.

FINDINGS THAT SURVIVED:
${JSON.stringify(surviving, null, 1)}

COVERAGE NOTES FROM EACH AUDITOR:
${coverage.join('\n\n')}

GitHub-flavoured markdown, these sections and nothing else:

## The verdict
Two or three sentences: is the record honest about the code, and where is it not. State the commit (\`${profile.head}\`) this was taken at.

## Drift, by severity
A table: severity | file:line | what it claims | what is true | the fix. Lies first, then stale, then cosmetic. Group cosmetic vocabulary sweeps into one row per file with a count.

## What this means for the plan
Structural conclusions only — which nodes are lying about their own state, which requirements are already met in code, which are specced nowhere, which parent/child relationships the board gets wrong, and which \`verify:\` commands cannot run. This is what a replanner reads; keep it to conclusions a plan can be built on.

## What nobody checked
The honest gap: what these ${DIMENSIONS.length} sweeps did not cover. This section is not optional and "nothing" is not an answer.

Be concrete and short. No preamble, no restating the task.`,
	at('judge', { label: 'synthesize', phase: 'Synthesize' }),
)

return {
	report: synth,
	reportPath: `${PLAN_DIR}/plan.reconcile.md`,
	head: profile.head,
	profile: { ecosystem: profile.ecosystem, gate: profile.gate, fullGate: profile.fullGate, memoDir: profile.memoDir },
	board: { nodes: census.nodes.length, totals: census.totals, ready: ready.map(n => n.path), claimed: claimed.map(n => `${n.path} (${n.claim})`) },
	surviving: surviving.length,
	killed: killed.length,
	killedDetail: killed,
}
