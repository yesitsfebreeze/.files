// Generates BOTH halves of the site from the .nuon files that `help` itself
// reads, so neither can drift from the shell:
//
//   content/docs/guide/<task>.mdx       task order, from tasks.nuon + `task`/`step`
//   content/docs/reference/<topic>.mdx  subject order, from topics.nuon + `topic`
//
// Entries sharing a `does` id are two routes to one capability (a key and a
// command) and render as ONE block on the guide, which is what stops the same
// thing being listed twice.
//
// Run: npm run generate
import { execFileSync } from 'node:child_process'
import { mkdirSync, writeFileSync, rmSync } from 'node:fs'
import { dirname, join, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..')
const HELP = resolve(root, '../home/dot_config/nushell/help')
const SURFACES = ['shell', 'nvim', 'terminal', 'capsule']

const nuon = (f) =>
  JSON.parse(
    execFileSync('nu', ['-c', `open "${join(HELP, f)}" | to json`], {
      encoding: 'utf8',
      maxBuffer: 64 * 1024 * 1024,
    }),
  )

// MDX reads `<` as JSX and `{` as an expression. Escape them, but only outside
// code spans — inside backticks MDX interprets nothing, and the entries lean
// on that for `<leader>`, `<S-h>` and friends.
const esc = (s) =>
  String(s ?? '')
    .split(/(`+[^`]*`+)/g)
    .map((p, i) => (i % 2 ? p : p.replace(/</g, '&lt;').replace(/\{/g, '&#123;')))
    .join('')

const slug = (s) =>
  String(s).toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '')

const inv = (e) => e.cmd ?? e.key ?? e.title
const isConcept = (e) => e.kind === 'concept'

// A `|` inside a table cell ends the cell, even within a code span, and the
// rest of the invocation then reaches MDX as JSX — `<leader>| and <leader>-`
// is the entry that finds this. GFM takes `\|` as a literal pipe in a cell.
const cell = (s) => String(s ?? '').replace(/\|/g, '\\|')

const MODE = { shell: 'shell', terminal: 'terminal', container: 'container' }
const modeLabel = (m) =>
  !m ? null : MODE[m] ? MODE[m] : m.startsWith('nvim:') ? `nvim ${m.slice(5)}` : m

const tasks = nuon('tasks.nuon')
const topics = nuon('topics.nuon')
const entries = SURFACES.flatMap((s) => nuon(`${s}.nuon`).map((e) => ({ ...e, surface: s })))

// --- where each invocation lives on the GUIDE, so `also` links land there ---
const groupKey = (e) => e.does ?? inv(e)
const anchorFor = new Map()
for (const e of entries) {
  const t = tasks.find((t) => t.id === e.task)
  if (!t) continue
  anchorFor.set(inv(e), `/docs/guide/${t.id}#${slug(groupKey(e))}`)
}
const alsoLinks = (e) =>
  (e.also ?? [])
    .map((a) => (anchorFor.has(a) ? `[\`${a}\`](${anchorFor.get(a)})` : `\`${a}\``))
    .join(' · ')

// --- one entry, or a `does` group, as a guide block ---
function block(group) {
  const [first] = group
  const out = []

  if (group.length > 1) {
    out.push(`## ${group.map((e) => `\`${inv(e)}\``).join(' &nbsp;·&nbsp; ')}`, '')
    out.push(`**${esc(first.title)}**`, '')
    out.push('Two routes to the same thing:', '')
    for (const e of group) {
      out.push(`- \`${inv(e)}\` *(${modeLabel(e.mode) ?? '—'})* — ${esc(e.use)}`)
    }
    out.push('')
  } else if (isConcept(first)) {
    out.push(`## ${esc(first.title)}`, '')
    const label = modeLabel(first.mode)
    if (label) out.push(`*${label}*`, '')
    if (first.use) out.push(esc(first.use), '')
  } else {
    out.push(`## \`${inv(first)}\``, '')
    out.push(`**${esc(first.title)}**`, '')
    const label = modeLabel(first.mode)
    if (label) out.push(`*${label}*`, '')
    if (first.use) out.push(esc(first.use), '')
  }

  const why = group.map((e) => e.why).find(Boolean)
  if (why) out.push('<Callout title="Why it is this way">', esc(why), '</Callout>', '')

  const also = [...new Set(group.flatMap((e) => (e.also ?? [])))]
    .filter((a) => !group.some((g) => inv(g) === a))
    .map((a) => (anchorFor.has(a) ? `[\`${a}\`](${anchorFor.get(a)})` : `\`${a}\``))
    .join(' · ')
  const src = [...new Set(group.map((e) => e.source).filter(Boolean))]
  const meta = []
  if (also) meta.push(`See also: ${also}`)
  if (src.length) meta.push(`Spec: ${src.map((s) => `\`${s}\``).join(', ')}`)
  if (meta.length) out.push(meta.join('  \n'), '')

  return out.join('\n')
}

// ------------------------------------------------------------------ guide ---
const GUIDE = join(root, 'content/docs/guide')
rmSync(GUIDE, { recursive: true, force: true })
mkdirSync(GUIDE, { recursive: true })

const guidePages = []
for (const task of tasks) {
  const mine = entries.filter((e) => e.task === task.id)

  // group the two-route pairs, keep step order
  const groups = []
  const takenBy = new Map()
  for (const e of [...mine].sort((a, b) => (a.step ?? 99) - (b.step ?? 99))) {
    const k = groupKey(e)
    if (takenBy.has(k)) takenBy.get(k).push(e)
    else {
      const g = [e]
      takenBy.set(k, g)
      groups.push(g)
    }
  }

  const parts = [
    '---',
    `title: ${JSON.stringify(task.title)}`,
    `description: ${JSON.stringify(task.summary)}`,
    '---',
    '',
    '{/* GENERATED by scripts/generate-manual.mjs — edit the .nuon surfaces, not this file. */}',
    '',
    esc(task.intro),
    '',
  ]

  if (groups.length === 0) {
    // a task with no entries is a landing page: point at the rest
    parts.push('<Cards>')
    for (const t of tasks.filter((t) => t.id !== task.id)) {
      parts.push(
        `  <Card title=${JSON.stringify(t.title)} href="/docs/guide/${t.id}" description=${JSON.stringify(t.summary)} />`,
      )
    }
    parts.push('</Cards>', '')
  } else {
    parts.push(groups.map(block).join('\n'))
  }

  writeFileSync(join(GUIDE, `${task.id}.mdx`), parts.join('\n'))
  guidePages.push({ id: task.id, n: groups.length, entries: mine.length })
}
writeFileSync(
  join(GUIDE, 'meta.json'),
  JSON.stringify({ title: 'Guide', pages: tasks.map((t) => t.id) }, null, 2) + '\n',
)

// -------------------------------------------------------------- reference ---
const REF = join(root, 'content/docs/reference')
rmSync(REF, { recursive: true, force: true })
mkdirSync(REF, { recursive: true })

const refPages = []
for (const topic of topics) {
  const mine = entries.filter((e) => e.topic === topic.id)
  if (!mine.length) continue
  const rows = mine
    .map((e) => {
      const t = tasks.find((t) => t.id === e.task)
      const where = t ? `[${t.title}](/docs/guide/${t.id}#${slug(groupKey(e))})` : '—'
      return `| \`${cell(inv(e))}\` | ${cell(esc(e.title))} | ${modeLabel(e.mode) ?? '—'} | ${where} |`
    })
    .join('\n')
  const page = [
    '---',
    `title: ${JSON.stringify(topic.title)}`,
    `description: ${JSON.stringify(topic.summary)}`,
    '---',
    '',
    '{/* GENERATED by scripts/generate-manual.mjs — edit the .nuon surfaces, not this file. */}',
    '',
    `${esc(topic.summary)} Every entry links to where the guide explains it.`,
    '',
    '| | what it does | where | guide |',
    '|---|---|---|---|',
    rows,
    '',
  ].join('\n')
  writeFileSync(join(REF, `${topic.id}.mdx`), page)
  refPages.push({ id: topic.id, n: mine.length })
}
writeFileSync(
  join(REF, 'meta.json'),
  JSON.stringify({ title: 'Reference', pages: topics.map((t) => t.id) }, null, 2) + '\n',
)

// ----------------------------------------------------------------- report ---
const unmapped = entries.filter((e) => !tasks.some((t) => t.id === e.task))
console.log(`guide:     ${guidePages.length} pages`)
for (const p of guidePages)
  console.log(`  ${p.id.padEnd(13)} ${String(p.n).padStart(2)} blocks  (${p.entries} entries)`)
console.log(`reference: ${refPages.length} pages, ${entries.length} entries`)
if (unmapped.length) {
  console.error(`\n!! ${unmapped.length} entries carry no valid task:`)
  for (const e of unmapped) console.error(`   ${inv(e)}  (task: ${e.task ?? 'none'})`)
  process.exit(1)
}
