export const meta = {
	name: 'mi-rating',
	description: 'Rate every implementation module on complexity, usefulness and board mandate (1-100), verdict its placement against the architecture the board states, and write the scored inventory',
	whenToUse: 'When you want a fresh rating page — the scored inventory sorted for low complexity and high usefulness, counter-checked against the .mi/prd board, with a placement verdict per unit.',
	phases: [
		{ model: 'haiku', title: 'Profile', detail: 'discover the repo: build system, packages, source roots, live claims' },
		{ model: 'haiku', title: 'Inventory', detail: 'enumerate every implementation module — find, wc, and the header comment' },
		{ model: 'sonnet', title: 'Doctrine', detail: 'what the board commits to, and the one architectural seam it states' },
		{ model: 'sonnet', title: 'Rate', detail: 'raters in chunks against the doctrine brief, plus one gap-finder' },
		{ model: 'opus', title: 'Publish', detail: 'calibrate, score, verdict placement, write the page' },
	],
}

// ─────────────────────────────────────────────────────────────────────────
// mi-rating — the scored inventory, and the counter-check against the board.
//
// Three scales, and the third is the whole point. `complexity` and
// `usefulness` are properties of the code. `mandate` is a property of the
// BOARD: how strongly the record calls for this thing to exist at all. The
// interesting rows are the ones where they diverge — machinery nothing asks
// for, and requirements nothing implements.
//
// The sort is `usefulness - complexity`. `mandate` is deliberately NOT in the
// sort: it is the counter-check, and folding it in would hide exactly the
// disagreement this page exists to surface.
//
// Nothing below the args block names a language, a build tool, a package or an
// architectural seam. The seam is DISCOVERED from the board by the Doctrine
// step, because every repo has a different one and a hardcoded seam turns this
// workflow into a lecture about somebody else's codebase. See `_lib.md`.
//
// args: { repo, board, out, chunk, seeds, models, effort }
// ─────────────────────────────────────────────────────────────────────────

const A = (typeof args === 'object' && args) || {}
const REPO = (typeof args === 'string' && args) || A.repo || 'the repo rooted at your cwd (`git rev-parse --show-toplevel`)'
const BOARD = A.board || '.mi/prd'
const OUT = A.out || '.mi/rating.md'
const CHUNK = A.chunk || 8
const SEEDS = A.seeds || []

// ── model policy ─────────────────────────────────────────────────────────
// The inventory is `scan` because it is `find` + `wc -l` + the first comment
// line — there is no judgment in it, and a cheap model runs the same commands.
// Rating is `probe`: every number is anchored to a measurement the note has to
// carry, so it is checkable. Only the final page is `judge`, because
// calibrating across raters and deciding what the headline finding is are the
// two things nothing downstream checks.
const MODELS = Object.assign({ scan: 'haiku', probe: 'sonnet', judge: 'opus', build: 'opus' }, A.models || {})
const EFFORTS = Object.assign({ scan: 'low', probe: 'medium', judge: 'high', build: 'high' }, A.effort || {})
const at = (tier, o) => Object.assign({ model: MODELS[tier], effort: EFFORTS[tier] }, o || {})

// ─────────────────────────────────────────────────────────────────────────
// Phase 1 — Profile. What used to be a paragraph of hardcoded facts about one
// repository is now four shell commands in the cheapest model available.
// ─────────────────────────────────────────────────────────────────────────
const PROFILE_SCHEMA = {
	type: 'object', additionalProperties: false,
	required: ['head', 'date', 'ecosystem', 'metadataCmd', 'packages', 'exts', 'testDirs', 'boardNodes', 'claimed', 'binaries', 'notes'],
	properties: {
		head: { type: 'string', description: 'git rev-parse --short HEAD' },
		date: { type: 'string', description: 'output of `date +%F` — pass it forward; the page must be dated and a workflow cannot read the clock itself' },
		ecosystem: { type: 'string', description: 'the build system actually on disk — read the manifests, do not guess from the language' },
		metadataCmd: { type: 'string', description: 'the command that lists this repo\'s packages, or "" if it has none' },
		exts: { type: 'array', items: { type: 'string' }, description: 'the source file extensions that hold implementations in this repo, e.g. [".rs"], [".ts",".tsx"] — from what is actually in the source roots, dominant first' },
		testDirs: { type: 'array', items: { type: 'string' }, description: 'the directory names or path patterns that hold tests rather than implementations, so the inventory can exclude them' },
		boardNodes: { type: 'array', items: { type: 'string' }, description: 'every board node path relative to the board root, the root node first' },
		claimed: { type: 'array', items: { type: 'string' }, description: 'one line per node carrying a `claim:` or `state: claimed`: `<path> — <session>`. Another session is changing those areas right now, so their rows are a snapshot.' },
		binaries: { type: 'array', items: { type: 'string' }, description: 'the entry points this repo actually produces — the binary/bin targets, the main files, the published entry — and where each starts' },
		notes: { type: 'string' },
		packages: {
			type: 'array',
			items: {
				type: 'object', additionalProperties: false, required: ['name', 'dir', 'sourceRoot'],
				properties: {
					name: { type: 'string' },
					dir: { type: 'string', description: 'the package directory relative to the repo root' },
					sourceRoot: { type: 'string', description: 'the directory inside it that holds implementations, relative to the repo root' },
				},
			},
		},
	},
}

phase('Profile')

const profile = await agent(
	`Repository: ${REPO}. Work only there, in the MAIN checkout — ignore any git worktrees (\`git worktree list\` shows them). READ ONLY — never edit, never commit, and never run a build or a test suite (slow, and other sessions may be building this tree). Reading files, \`git\`, \`grep\`, \`find\`, \`ls\`, \`wc\`, \`sed -n\` and metadata-printing commands are all fine.

Profile this repository for the raters that come after you. Every field is established by running something.

1. \`git rev-parse --short HEAD\` and \`date +%F\`. Both go on the finished page, and nothing later in this run can read the clock, so \`date\` matters.
2. **The build system**, from the manifests on disk: \`Cargo.toml\`, \`package.json\`, \`go.mod\`, \`pyproject.toml\`, \`pom.xml\`, \`build.gradle\`, \`Gemfile\`, \`mix.exs\`, \`CMakeLists.txt\`. Name what is there, and the command that lists this repo's packages (a workspace listing, a members query, a module list) if it has one.
3. **The packages.** One entry per manifest, from that metadata command rather than from directory names. For each, the \`sourceRoot\` — the directory inside it that actually holds implementations. A single-package repo has exactly one entry.
4. **\`exts\`** — which source extensions hold implementations here. Count them under the source roots (\`find <root> -type f | sed 's/.*\\.//' | sort | uniq -c | sort -rn\`) and list the dominant ones. Do not list a language the repo does not contain.
5. **\`testDirs\`** — the directory names or path patterns holding tests rather than implementations, so the inventory can exclude them. Look at what this repo actually does; do not assume a convention.
6. **The board** at \`${BOARD}\`: \`find ${BOARD} -name prd.md | sort\`, each node's path relative to \`${BOARD}\` (the root node is \`.\`), and which nodes carry a \`claim:\` field or \`state: claimed\`, with the session id. Another session is changing those areas right now and their rows will be a snapshot.
7. **\`binaries\`** — what this repo actually produces, and the file each entry point starts at. This is what \`usefulness\` gets measured against, so get it from the manifests, not from a guess.`,
	at('scan', { label: 'profile', phase: 'Profile', schema: PROFILE_SCHEMA }),
)

if (!profile) return { error: 'profile failed — every later phase reads it' }
if (!profile.packages || !profile.packages.length) return { error: 'no packages found', profile }

log(`${profile.ecosystem} · ${profile.packages.length} package(s) · ${profile.exts.join(' ')} · ${profile.boardNodes.length} board node(s)${profile.claimed.length ? ` · ${profile.claimed.length} claimed` : ''}`)

const CLAIM_NOTE = profile.claimed.length
	? `IN FLIGHT: ${profile.claimed.join(' · ')}. Another session holds those nodes and is changing that code in its own worktrees. Rate what is at HEAD in the main checkout and treat those rows as a snapshot.`
	: 'No board node is under a live claim, so HEAD is a stable subject.'

const GROUND = `You are working in the repository at ${REPO}. Work only there, in the MAIN checkout — ignore any git worktrees. READ ONLY — never edit, never commit, and never run a build or a test suite (too slow, and other sessions may be building this tree). Reading files, \`git\`, \`grep\`, \`find\`, \`ls\`, \`wc\`, \`sed -n\`, \`head\` and metadata-printing commands are all fine.

THE REPOSITORY, profiled at \`${profile.head}\` on ${profile.date}:
- build system: ${profile.ecosystem}
- packages: ${profile.packages.map(p => `\`${p.name}\` (${p.sourceRoot})`).join(', ')}
- source extensions: ${profile.exts.join(', ')}
- what it produces: ${profile.binaries.join(' · ') || '(no entry point identified)'}
${profile.notes ? `- ${profile.notes}` : ''}

THE SPEC IS THE BOARD at \`${BOARD}\`. \`${BOARD}/prd.md\` is the root; each node's own Requirements / Acceptance / Out of scope is that area's contract. Board nodes: ${profile.boardNodes.map(n => `\`${n}\``).join(', ')}. A checkbox is a CLAIM by the board — \`[ ]\` unstarted, \`[~]\` partial, \`[x]\` claimed done — and not necessarily a fact about the tree.

${CLAIM_NOTE}
${SEEDS.length ? `\nTHE CALLER'S SEEDS — specific things to check first. Leads, not conclusions:\n${SEEDS.map(s => `- ${s}`).join('\n')}` : ''}`

// ─────────────────────────────────────────────────────────────────────────
// Phase 2 — Inventory. Units are MODULES, not packages: a handful of packages
// is too coarse to sort, and the interesting placement questions live inside
// the oversized files.
// ─────────────────────────────────────────────────────────────────────────
const UNIT_SCHEMA = {
	type: 'object', additionalProperties: false,
	required: ['units', 'crosscheck'],
	properties: {
		crosscheck: { type: 'string', description: 'the file count you got from `find`, per source root, and whether it equals the number of units you returned' },
		units: {
			type: 'array',
			items: {
				type: 'object', additionalProperties: false,
				required: ['id', 'family', 'path', 'lines', 'what'],
				properties: {
					id: { type: 'string', description: '<package>/<path inside the source root, without the extension>' },
					family: { type: 'string', description: 'the package name, exactly as the metadata command reports it' },
					path: { type: 'string', description: 'file path relative to the repo root' },
					lines: { type: 'integer', description: 'wc -l of that file' },
					what: { type: 'string', description: 'one line: what it is, taken from the file\'s own header/doc comment. If it has none, say so plainly — do not invent a purpose.' },
				},
			},
		},
	},
}

phase('Inventory')

const inv = await agent(
	`${GROUND}

Enumerate every implementation module in this tree. One unit per source FILE.

1. The source roots are: ${profile.packages.map(p => `\`${p.sourceRoot}\` (package \`${p.name}\`)`).join(', ')}.
2. For each, \`find <sourceRoot> -type f \\( ${profile.exts.map(e => `-name '*${e}'`).join(' -o ')} \\)\`. Every file found is one unit. \`family\` is the package name; \`id\` is \`<package>/<path inside the source root, extension stripped>\`.
3. \`lines\` is \`wc -l\` on that file.
4. **EXCLUDE tests.** Skip anything under ${profile.testDirs.map(d => `\`${d}\``).join(', ') || 'this repo\'s test directories'} — an integration test is not an implementation to place. Also skip generated files (a header saying "do not edit", a vendored directory, a lockfile) and say in \`crosscheck\` how many you skipped and why.
5. **INCLUDE thin re-export shims.** Some files are twenty lines of re-exports. They are legitimately tiny units: do not skip them and do not merge them into their siblings — whether they should exist at all is a verdict a later phase makes, not one you make by omission.
6. \`what\` comes from the file's OWN header or doc comment, one line. If there is none, say so plainly.

Completeness matters more than speed. In \`crosscheck\`, give the \`find\` count per source root and confirm it equals the number of units you returned. State nothing beyond what the schema asks.`,
	at('scan', { label: 'inventory', phase: 'Inventory', schema: UNIT_SCHEMA }),
)

if (!inv || !inv.units || !inv.units.length) return { error: 'inventory came back empty — nothing to rate', profile }
log(`${inv.units.length} module(s) inventoried — ${inv.crosscheck}`)

// ─────────────────────────────────────────────────────────────────────────
// Phase 3 — Doctrine. What the board commits to, so the raters measure
// against the spec instead of against their own taste. And, critically, the
// SEAM: the one architectural boundary this repo's board actually states.
// Every placement verdict is relative to that, and it is different in every
// repository, which is why it is read rather than assumed.
// ─────────────────────────────────────────────────────────────────────────
const DOCTRINE_SCHEMA = {
	type: 'object', additionalProperties: false,
	required: ['brief', 'seam', 'mandates', 'contract', 'tensions', 'recordDrift'],
	properties: {
		brief: { type: 'string', description: 'what this project is, in <=200 words, in the board\'s own words, carrying the root node\'s purpose line' },
		seam: {
			type: 'object', additionalProperties: false,
			required: ['stated', 'quote', 'source', 'sharedSide', 'behindSide'],
			properties: {
				stated: { type: 'boolean', description: 'false if the board states no architectural boundary at all — then placement is judged on cohesion alone' },
				quote: { type: 'string', description: 'the board sentence that states the boundary, quoted' },
				source: { type: 'string', description: 'file:line' },
				sharedSide: { type: 'string', description: 'the package or layer that must stay generic, and what the board forbids it (e.g. "must compile without platform X", "no dependency on Y")' },
				behindSide: { type: 'string', description: 'where the specific implementations belong instead' },
			},
		},
		mandates: {
			type: 'array',
			description: 'the capabilities the board commits to, each quoted and addressed',
			items: {
				type: 'object', additionalProperties: false, required: ['capability', 'source', 'quote', 'state'],
				properties: {
					capability: { type: 'string' },
					source: { type: 'string', description: 'file:line' },
					quote: { type: 'string', description: 'the committing sentence, quoted' },
					state: { type: 'string', enum: ['[ ]', '[~]', '[x]'], description: 'the checkbox the board carries for it' },
				},
			},
		},
		contract: {
			type: 'array',
			description: 'the per-package boundary the board draws — from the root node\'s children table and each node\'s own requirements',
			items: {
				type: 'object', additionalProperties: false, required: ['package', 'owns', 'source'],
				properties: {
					package: { type: 'string' },
					owns: { type: 'string', description: 'what the board says this package is responsible for, and anything it is forbidden' },
					source: { type: 'string', description: 'file:line plus the quoted sentence' },
				},
			},
		},
		tensions: {
			type: 'array',
			description: 'places where the board contradicts ITSELF — two lines that cannot both be honoured',
			items: {
				type: 'object', additionalProperties: false, required: ['subject', 'sideA', 'sideB', 'current'],
				properties: {
					subject: { type: 'string' },
					sideA: { type: 'string', description: 'file:line plus quote' },
					sideB: { type: 'string', description: 'file:line plus quote' },
					current: { type: 'string', description: 'which governs and on what evidence — or "unresolved" if the board gives no way to tell' },
				},
			},
		},
		recordDrift: {
			type: 'array',
			description: 'board claims its own text does not support — a [x] whose evidence does not meet its own acceptance bar, or a reference to something that does not exist',
			items: {
				type: 'object', additionalProperties: false, required: ['file', 'line', 'says', 'reality'],
				properties: { file: { type: 'string' }, line: { type: 'integer' }, says: { type: 'string' }, reality: { type: 'string' } },
			},
		},
	},
}

phase('Doctrine')

const doctrine = await agent(
	`${GROUND}

Extract what this repository's own board COMMITS to. Read \`${BOARD}/prd.md\` first — its Requirements, Acceptance, Out of scope and its children table are the top-level spec — then every node: ${profile.boardNodes.filter(n => n !== '.').map(n => `\`${BOARD}/${n}/prd.md\``).join(', ')}. Note each node's \`state:\` and each requirement's checkbox.

**\`seam\` is the field this brief exists for, and it is different in every repository, so read it rather than assuming it.** Most boards state exactly one architectural boundary and then repeat it as a constraint: a package that must stay generic while the specifics live behind an interface; a layer forbidden a particular dependency; a core that must build without a platform. Find that sentence and quote it with its file:line — a requirement of the form "this must compile without X", "no Y-specific dependencies here", "everything Z-specific goes behind the W trait/interface/port" is the one you want. It is the test every placement verdict is measured against. If the board genuinely states no such boundary, set \`stated: false\` and say so; placement will then be judged on cohesion alone, which is a weaker but honest basis.

For \`mandates\`, take every capability the board commits to, quoted, with its file:line and its checkbox. For \`contract\`, what the board says each package owns and what it forbids it.

For \`tensions\`, hunt the board contradicting ITSELF, and it does this in two reliable places:
- **A Requirement against an Out of scope line.** A board that commits to a capability in one section and refuses it in another has two readings and no way to choose. Record both sides with file:line and say which governs.
- **A capability marked done in one node and open in another.** Where one node claims \`[x]\` and another carries the same subject as \`[ ]\`, often marked as folded or moved, somebody owes the capability and the board does not say who. Record what it means for who owes it.

For \`recordDrift\`, the pattern to hunt is a box marked \`[x]\` on evidence that does not meet its own acceptance text, or a reference to something absent. Three shapes that recur in any board:
- an Acceptance box marked \`[x]\` whose own parenthetical concedes it was met against a mock, a stub or a simulation rather than the real thing
- a box marked \`[x]\` whose text says it depends on a node, a host or an environment that does not exist — check the root children table for whether a node it names exists at all
- a node marked \`state: done\` carrying a requirement its own text admits could not be executed here
Report each with file:line. Do not stop at these shapes; they are where to start.`,
	at('probe', { label: 'doctrine', phase: 'Doctrine', schema: DOCTRINE_SCHEMA }),
)

if (!doctrine) return { error: 'doctrine came back empty — raters would have nothing to measure against', profile }
log(`doctrine: ${doctrine.mandates.length} mandate(s), ${doctrine.contract.length} package contract(s), ${doctrine.tensions.length} self-contradiction(s), ${doctrine.recordDrift.length} drift site(s) · seam ${doctrine.seam.stated ? 'stated' : 'NOT stated'}`)

const SEAM = doctrine.seam
const SEAM_BRIEF = SEAM.stated
	? `**THE SEAM — the one architectural boundary this board states, and the test every placement verdict is measured against:**
> ${SEAM.quote}
> — ${SEAM.source}

The generic side is **${SEAM.sharedSide}**. The specific implementations belong **${SEAM.behindSide}**. A module on the wrong side of that line is a CONTRACT VIOLATION, not a matter of taste — but you must name the dependency, import, conditional compilation flag or platform call that makes it so. "It feels platform-specific" is not a finding.`
	: `**THE SEAM: this board states no architectural boundary.** Placement is therefore judged on cohesion alone — does this module hold one concern, and is it in the package that concern belongs to — and you may NOT invent a boundary the board does not state. Say so in \`placementWhy\` where it matters.`

const DOCTRINE_BRIEF = `## The doctrine you are measuring against

${doctrine.brief}

${SEAM_BRIEF}

**Capabilities the board commits to:**
${doctrine.mandates.map(m => `- ${m.state} ${m.capability} — ${m.source}: "${m.quote}"`).join('\n')}

**The boundary the board draws per package:**
${doctrine.contract.map(c => `- ${c.package} owns ${c.owns} — ${c.source}`).join('\n')}

**Where the board contradicts itself:**
${doctrine.tensions.map(t => `- ${t.subject}: ${t.sideA} VS ${t.sideB} → ${t.current}`).join('\n') || '- (none found)'}`

// ─────────────────────────────────────────────────────────────────────────
// Phase 4 — Rate against the doctrine, plus one gap-finder.
// ─────────────────────────────────────────────────────────────────────────
const RATINGS_SCHEMA = {
	type: 'object', additionalProperties: false,
	required: ['ratings'],
	properties: {
		ratings: {
			type: 'array',
			items: {
				type: 'object', additionalProperties: false,
				required: ['id', 'complexity', 'usefulness', 'mandate', 'placement', 'placementWhy', 'note'],
				properties: {
					id: { type: 'string' },
					complexity: { type: 'integer', minimum: 1, maximum: 100 },
					usefulness: { type: 'integer', minimum: 1, maximum: 100 },
					mandate: { type: 'integer', minimum: 1, maximum: 100 },
					placement: { type: 'string', enum: ['keep', 'shared', 'behind-seam', 'split', 'merge', 'delete'] },
					placementWhy: { type: 'string', description: 'one line, citing the board contract or the reverse-dependency evidence that decides it' },
					note: { type: 'string', description: 'one line of evidence: the measurements behind the three numbers' },
				},
			},
		},
	},
}

const RUBRIC = `Rate each unit on three 1-100 scales and give it one placement verdict. Anchor on MEASUREMENTS you actually take, not vibes, and put the measurements in \`note\`. A number with no measurement behind it is worse than no number, because the page it lands on reads as authoritative.

**complexity** — how hard this module is to understand and safely change, as it stands today.
Measure: its \`lines\` (given); the number of exported/public items; its package's dependency count from the manifest; the count of whatever this language's escape hatches are (raw memory, unchecked casts, reflection, dynamic evaluation, foreign-function calls, global mutable state); and read its header comment for declared invariants. Weigh upward: parsers, protocol state machines, concurrency, foreign or ABI boundaries, process lifetime and timeout management, and shelling out to an external binary whose output must be parsed. Anchors: **1-15** a re-export shim or a plain data/type module with no invariants; **40-60** a typical module with real invariants; **85+** the hardest thing in THIS tree — find it first and calibrate the rest against it, rather than against an absolute idea of hard.

**usefulness** — how load-bearing it is TODAY, not aspirationally.
Measure, in this order, because the first one caps the rest:
(a) **package-level wiring** — is this module's package actually a dependency of another package? Grep every manifest in the tree for its name. A package nothing depends on, and that no entry point links (${profile.binaries.join(' · ') || 'the entry points named in the ground rules'}), caps every one of its modules low no matter how good the code is.
(b) **module-level use** — grep for its import path within its own package and across the others.
(c) **the boot path** — does it sit on the path from an entry point to doing anything at all?
Anchors: **90+** the product does not function without it; **40-60** a real feature some flow uses; **1-25** not wired, stub-grade, or removable without anyone noticing. Rate what is WIRED, not what a board checkbox promises. A module whose own header calls itself a stub is stub-grade however many signatures it sketches.

**mandate** — how strongly the BOARD (the doctrine brief above) calls for this thing to exist at all. This is the counter-check, and it is deliberately independent of \`usefulness\`: a module a root Requirement names is high-mandate even if nothing imports it yet, and a module no requirement asks for is low-mandate even if four packages depend on it. Anchors: **90+** named in a root or node Requirement; **50-70** machinery a mandated capability plainly needs; **20-40** supporting infrastructure no requirement asks for by name; **1-15** nothing in the board calls for it, or an Out of scope line argues against it.
**When mandate and usefulness diverge by more than ~30, that gap IS the finding** — say which way, and why, in \`note\`.

**placement** — one verdict, measured against the seam in the doctrine brief:
- \`keep\` — correctly placed and correctly sized as it stands.
- \`shared\` — it sits in one specific implementation but is a shared type, interface or error surface that belongs on the generic side of the seam. Cite what else needs it.
- \`behind-seam\` — it sits on the generic side but is specific to one platform, backend or vendor and belongs behind the boundary. **Cite the exact dependency, import, conditional-compilation flag or platform call that makes it non-portable.** Without that citation this verdict is a preference, and preferences do not move code.
- \`split\` — a grab-bag: one file carrying several unrelated concerns, usually an oversized entry or root module. Name the concerns you would separate and roughly how many lines each. Do not be shy with this verdict, but do not use it for a file that is merely long and coherent.
- \`merge\` — too thin to stand as its own module; fold it into the parent that is its only user. Cite the single user.
- \`delete\` — nothing depends on it, no requirement mandates it, or an Out of scope line argues against it. Say what makes it dead, and whether something that shipped supersedes it. **Not for a module that is merely unwired while a Requirement still mandates its capability** — that is a high-mandate/low-usefulness row, which is a finding, not a deletion.`

phase('Rate')

const units = inv.units.slice().sort((a, b) => (a.family + '/' + a.path).localeCompare(b.family + '/' + b.path))
const chunks = []
for (let i = 0; i < units.length; i += CHUNK) chunks.push(units.slice(i, i + CHUNK))

const GAP_SCHEMA = {
	type: 'object', additionalProperties: false,
	required: ['gaps', 'unmandated', 'orphans'],
	properties: {
		gaps: {
			type: 'array',
			description: 'capabilities the board mandates that NO unit in the inventory implements',
			items: {
				type: 'object', additionalProperties: false, required: ['capability', 'source', 'boardState', 'evidence', 'wouldBe'],
				properties: {
					capability: { type: 'string' },
					source: { type: 'string', description: 'the board file:line that mandates it, quoted' },
					boardState: { type: 'string', enum: ['[ ]', '[~]', '[x]'], description: 'the checkbox the board carries — an absent capability marked [x] is the worst case' },
					evidence: { type: 'string', description: 'the exact search you ran that establishes nothing implements it, and its result' },
					wouldBe: { type: 'string', description: 'which package should own it, under the seam in the doctrine brief' },
				},
			},
		},
		unmandated: {
			type: 'array',
			description: 'substantial machinery in the tree that no board line asks for',
			items: {
				type: 'object', additionalProperties: false, required: ['id', 'lines', 'why'],
				properties: { id: { type: 'string' }, lines: { type: 'integer' }, why: { type: 'string', description: 'what it does, and the search establishing that no board line mandates it' } },
			},
		},
		orphans: {
			type: 'array',
			description: 'whole packages no other package depends on and no entry point links',
			items: {
				type: 'object', additionalProperties: false, required: ['package', 'lines', 'boardState', 'evidence'],
				properties: {
					package: { type: 'string' },
					lines: { type: 'integer', description: 'total source lines in the package' },
					boardState: { type: 'string', description: 'the `state:` of its board node, if it has one' },
					evidence: { type: 'string', description: 'the grep over every manifest establishing zero reverse dependencies' },
				},
			},
		},
	},
}

// The barrier is deliberate: calibration in the Publish phase needs every
// chunk together to normalise one scale across raters, and the gap list is
// part of the same page.
const rateResults = await parallel([
	...chunks.map((chunk, i) => () => agent(
		`${GROUND}\n\n${DOCTRINE_BRIEF}\n\n${RUBRIC}\n\nYour units — rate ALL of them, exactly these ids:\n${JSON.stringify(chunk, null, 2)}`,
		at('probe', { label: `rate:${i + 1}/${chunks.length}`, phase: 'Rate', schema: RATINGS_SCHEMA }),
	)),

	() => agent(
		`${GROUND}

${DOCTRINE_BRIEF}

Three questions, all about the SPACE BETWEEN the board and the tree. This is the counter-check, and it is the part of the page a reader cannot get from the code alone. The full inventory of what exists is:
${JSON.stringify(units.map(u => ({ id: u.id, path: u.path, lines: u.lines })), null, 2)}

1. **gaps** — which mandated capabilities does NOTHING in that inventory implement? Take each mandate in the brief and actually grep for it: its name, its type names, its command names, its wire strings, case-insensitively, across every source root. Record the board's checkbox for each — **a capability absent from the tree but marked \`[x]\` is the most serious finding on this page.** Give the exact grep and its result; a gap claimed without a search is worthless. Two shapes to check deliberately:
   - a capability whose name appears NOWHERE in the tree. Report the count you got, including zero.
   - a capability whose name appears only inside a file whose own header calls itself a stub, a mock or a placeholder. Read that header before deciding it counts as implemented — a module full of signatures that return "unimplemented" implements nothing.

2. **unmandated** — which substantial units (say >250 lines) does no board line ask for? Give the line count and the search establishing it. **Be fair**: "the board does not name it" is not the same as "the board does not need it". Machinery a mandated capability plainly requires is mandated by implication and you should NOT list it. List only what is genuinely built beyond the board.

3. **orphans** — which whole packages does no other package depend on? Read EVERY manifest in the tree, list every internal dependency you find, and report any package that appears in none of them and is not itself an entry point (${profile.binaries.join(' · ') || 'see the ground rules'}). Give each orphan's total source line count and the \`state:\` of its board node. **A large package the board calls \`done\` that nothing links is the single most important row on the final page — do not soften it.**`,
		at('probe', { label: 'gaps', phase: 'Rate', schema: GAP_SCHEMA }),
	),
])

const gapFinding = rateResults[rateResults.length - 1] || { gaps: [], unmandated: [], orphans: [] }
const rated = rateResults.slice(0, -1).filter(Boolean).flatMap(r => r.ratings || [])

const ratedIds = new Set(rated.map(r => r.id))
const missing = units.filter(u => !ratedIds.has(u.id)).map(u => u.id)
if (missing.length) log(`WARNING: ${missing.length} unit(s) came back unrated: ${missing.join(', ')}`)
log(`${rated.length}/${units.length} rated · ${gapFinding.gaps.length} mandated-but-missing · ${gapFinding.unmandated.length} built-beyond-mandate · ${gapFinding.orphans.length} orphan package(s)`)

// ─────────────────────────────────────────────────────────────────────────
// Phase 5 — Calibrate across chunks, score, sort, write the page.
// ─────────────────────────────────────────────────────────────────────────
const merged = units.map(u => {
	const r = rated.find(x => x.id === u.id)
	return r
		? Object.assign({}, u, { complexity: r.complexity, usefulness: r.usefulness, mandate: r.mandate, placement: r.placement, placementWhy: r.placementWhy, note: r.note })
		: Object.assign({}, u, { complexity: null, usefulness: null, mandate: null, placement: null, placementWhy: null, note: 'UNRATED — the rater returned nothing for this id' })
})

phase('Publish')

const result = await agent(
	`${GROUND.replace('READ ONLY — never edit, never commit, and never run a build or a test suite', `You may write exactly ONE file: \`${OUT}\`. Never edit anything else, never commit, and never run a build or a test suite`)}

${DOCTRINE_BRIEF}

Below are ratings from ${chunks.length} independent raters over chunks of the inventory, plus one gap-finder's results. Their scales may disagree at the seams between chunks.

1. **Calibrate.** Scan for cross-chunk inconsistency — two units of visibly similar weight scored 30 apart. Adjust only where a note's own evidence contradicts its number, keep every adjustment small, and mention it in that row's note. Rate any UNRATED unit yourself now, in the same evidence style. Then sanity-check the \`placement\` verdicts against the board contract and fix any that contradict it. In particular: ${SEAM.stated ? `nothing on the generic side (${SEAM.sharedSide}) gets \`behind-seam\` unless the row names the specific dependency, import or conditional that makes it non-portable — that citation is the whole test` : 'no row gets `shared` or `behind-seam` at all, because this board states no boundary to move things across; convert any such verdict to `split`, `merge` or `keep` on cohesion grounds and say so'}. And no module gets \`delete\` for being unwired alone while a Requirement still mandates its capability — that is a high-mandate/low-usefulness row, not a deletion.
2. **Score.** \`score = usefulness − complexity\`. Higher is better: this deliberately rewards low complexity and high usefulness. Ties break toward higher usefulness.
3. **Write \`${OUT}\`** (overwrite). Plain markdown, no frontmatter, in this order:

   - **Title**, then the date **${profile.date}** and the commit rated **${profile.head}** — use those, do not try to read the clock. Then 3-4 sentences: what the three scales mean, that the sort is \`usefulness − complexity\`, and that \`mandate\` is the counter-check against the \`${BOARD}\` board rather than an input to the sort.${profile.claimed.length ? ` Add one sentence noting that ${profile.claimed.join(', ')} ${profile.claimed.length === 1 ? 'was' : 'were'} under a live claim and being changed by another session when this was generated, so those rows are a snapshot.` : ''}

   - **## The table** — ONE table sorted by score descending, every unit exactly once (${merged.length} rows), columns: Rank | Module | Package | Lines | Complexity | Usefulness | Mandate | Score | Placement | Note. Put the path into the Note where it is not obvious from the id.

   - **## Counter-check — where the tree and the board disagree**, four subsections, each a short table plus one line of prose:
     - \`### Orphan packages\` — the gap-finder's \`orphans\`: Package | Lines | Board state | Evidence of zero reverse deps. **Lead with this**: a large package the board calls \`done\` that nothing links is the headline finding.
     - \`### Mandated but missing\` — the gap-finder's \`gaps\`: Capability | Mandated by | Board box | Evidence it is absent | Should land in. Sort rows whose Board box is \`[x]\` FIRST, and say in the prose that those are the board claiming a capability the tree does not contain.
     - \`### Built beyond the mandate\` — the gap-finder's \`unmandated\`: Module | Lines | Why nothing asks for it. Plus every rated unit whose mandate is ≤25, and every unit where usefulness exceeds mandate by more than 30.
     - \`### Mandated in the board, unwired in the tree\` — every unit where mandate exceeds usefulness by more than 30. This is the board's own machinery that nothing currently runs; name what would have to wire each one.

   - **## Placement — what should move** — group rows by verdict: \`split\` first, then ${SEAM.stated ? '`behind-seam`, `shared`, ' : ''}\`merge\`, \`delete\`, and \`keep\` last as a bare count. Open with one sentence naming the standing goal${SEAM.stated ? ` — the seam this board states: "${SEAM.quote}"` : ' — and state plainly that this board declares no architectural boundary, so these verdicts rest on cohesion alone'}. For \`split\`, one row each naming the concerns to separate. For every other verdict, one row each carrying the dependency or reverse-dependency evidence from \`placementWhy\`.

   - **## Where the board is stale** — the doctrine pass's \`recordDrift\`: File:line | Says | Reality. Then \`### Self-contradictions\` from its \`tensions\`: Subject | One side | The other side | Which governs. One line of prose noting these are board defects to fix in \`${BOARD}\`, not code defects.

THE RATINGS:
${JSON.stringify(merged, null, 2)}

THE GAP-FINDER'S RESULTS:
${JSON.stringify(gapFinding, null, 2)}

THE BOARD-DRIFT SITES:
${JSON.stringify(doctrine.recordDrift, null, 2)}

THE BOARD SELF-CONTRADICTIONS:
${JSON.stringify(doctrine.tensions, null, 2)}

Return: the path written, the row count, the counts per placement verdict, and the full text of the four Counter-check subsections as you wrote them.`,
	at('judge', { label: 'publish', phase: 'Publish' }),
)

return {
	wrote: OUT,
	head: profile.head,
	date: profile.date,
	unitCount: merged.length,
	unrated: missing,
	seam: SEAM.stated ? `${SEAM.quote} (${SEAM.source})` : 'the board states no architectural seam',
	orphans: gapFinding.orphans.map(o => o.package),
	gaps: gapFinding.gaps.map(g => `${g.boardState} ${g.capability}`),
	unmandated: gapFinding.unmandated.map(u => u.id),
	boardDrift: doctrine.recordDrift.length,
	tensions: doctrine.tensions.length,
	summary: result,
}
