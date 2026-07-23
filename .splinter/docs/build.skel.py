# §source docs/build.py
#!/usr/bin/env python3
"""Static documentation builder for the dotfiles + Claude machine setup.

Scans the repository's markdown documentation and renders a single
self-contained, searchable HTML file: docs/index.html.

Zero third-party dependencies. Fully offline. Deterministic output
(stable ordering) so re-running on unchanged sources yields identical bytes.

Sources (relative to repo root), in sidebar order:
  - README.md                  -> "Guide"
  - .proj/**/*.md              -> "Project layer"
  - .claude/rules/*.md         -> "Rules"
  - .claude/output-styles/*.md -> "Output styles"
  - .claude/agents/*.md        -> "Agents"
  - .claude/skills/**/*.md     -> "Skills"
  - docs/concepts/*.md         -> "Concepts"

Usage:
  python docs/build.py            # build into docs/index.html
  python docs/build.py --check    # build to a temp string, report counts only
"""
from __future__ import annotations

import html
import json
import re
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
OUT_FILE = REPO_ROOT / "docs" / "index.html"

# (glob, category, sort-weight) — weight orders categories in the sidebar.
SOURCES = [
    ("README.md", "Guide", 0),
    (".proj/**/*.md", "Project layer", 1),
    (".claude/rules/*.md", "Rules", 2),
    (".claude/output-styles/*.md", "Output styles", 3),
    (".claude/agents/*.md", "Agents", 4),
    (".claude/skills/**/*.md", "Skills", 5),
    ("docs/concepts/*.md", "Concepts", 6),
]

CATEGORY_ORDER = ["Guide", "Project layer", "Rules", "Output styles", "Agents", "Skills", "Concepts"]


# --------------------------------------------------------------------------
# Frontmatter
# --------------------------------------------------------------------------
def split_frontmatter(text: str) -> tuple[dict, str]:
    
# §.splinter/docs/build/split_frontmatter.fs



# --------------------------------------------------------------------------
# Minimal but robust Markdown -> HTML renderer (CommonMark-ish subset).
# Handles: ATX headings, fenced code, tables (GFM), blockquotes, ordered &
# unordered lists (nested by indent), hr, inline (code, bold, italic, links,
# images, autolinks), paragraphs. Good enough for technical docs.
# --------------------------------------------------------------------------
_INLINE_CODE = re.compile(r"`([^`]+)`")
_BOLD = re.compile(r"\*\*([^*]+)\*\*|__([^_]+)__")
_ITALIC = re.compile(r"(?<![\*_])\*([^*\n]+)\*(?!\*)|(?<![\w])_([^_\n]+)_(?![\w])")
_IMAGE = re.compile(r"!\[([^\]]*)\]\(([^)\s]+)(?:\s+\"[^\"]*\")?\)")
_LINK = re.compile(r"\[([^\]]+)\]\(([^)\s]+)(?:\s+\"[^\"]*\")?\)")
_AUTOLINK = re.compile(r"<(https?://[^>]+)>")
_HEADING_ID = re.compile(r"[^a-z0-9]+")


def _slug(text: str) -> str:
    
# §.splinter/docs/build/_slug.fs



def render_inline(text: str) -> str:
    # Protect code spans first by extracting them.
    
# §.splinter/docs/build/render_inline.fs



def render_markdown(md: str) -> str:
    
# §.splinter/docs/build/render_markdown.fs



def _render_list(lines: list[str], i_holder: list[int]) -> str:
    
# §.splinter/docs/build/_render_list.fs



def cur_text(parts: list[str]) -> str:
    
# §.splinter/docs/build/cur_text.fs



# --------------------------------------------------------------------------
# Collection
# --------------------------------------------------------------------------
def collect() -> list[dict]:
    
# §.splinter/docs/build/collect.fs



# --------------------------------------------------------------------------
# HTML shell (Gruvbox Dark Hard, matches the repo theme)
# --------------------------------------------------------------------------
def build_html(docs: list[dict]) -> str:
    
# §.splinter/docs/build/build_html.fs



TEMPLATE = r"""<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Setup Docs — Dotfiles &amp; Claude Machine</title>
<style>
:root{
  --bg0h:#1d2021; --bg0:#282828; --bg1:#3c3836; --bg2:#504945; --bg3:#665c54;
  --fg:#ebdbb2; --fg2:#d5c4a1; --fg4:#a89984; --gray:#928374;
  --red:#fb4934; --green:#b8bb26; --yellow:#fabd2f; --blue:#83a598;
  --purple:#d3869b; --aqua:#8ec07c; --orange:#fe8019;
}
*{box-sizing:border-box}
html,body{margin:0;height:100%}
body{
  background:var(--bg0h); color:var(--fg);
  font:15px/1.6 -apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,Helvetica,Arial,sans-serif;
  display:grid; grid-template-columns:300px 1fr; height:100vh; overflow:hidden;
}
aside{
  background:var(--bg0); border-right:1px solid var(--bg2);
  display:flex; flex-direction:column; min-height:0;
}
.brand{padding:16px 18px 12px;border-bottom:1px solid var(--bg2)}
.brand h1{margin:0;font-size:16px;color:var(--yellow);letter-spacing:.3px}
.brand .sub{font-size:11px;color:var(--gray);margin-top:3px}
.searchwrap{padding:12px 14px;border-bottom:1px solid var(--bg2)}
#q{
  width:100%;padding:9px 11px;background:var(--bg0h);color:var(--fg);
  border:1px solid var(--bg3);border-radius:7px;outline:none;font-size:13px;
}
#q:focus{border-color:var(--yellow)}
.hint{font-size:10.5px;color:var(--gray);margin-top:6px}
nav{overflow-y:auto;padding:8px 0 24px;flex:1;min-height:0}
.cat{padding:12px 18px 4px;font-size:10.5px;letter-spacing:.12em;text-transform:uppercase;color:var(--orange)}
a.item{
  display:block;padding:5px 18px;color:var(--fg2);text-decoration:none;
  font-size:13px;border-left:2px solid transparent;cursor:pointer;
}
a.item:hover{background:var(--bg1);color:var(--fg)}
a.item.active{background:var(--bg1);border-left-color:var(--yellow);color:var(--yellow)}
a.item .d{display:block;font-size:10.5px;color:var(--gray);white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
a.item mark{background:var(--yellow);color:var(--bg0h);border-radius:2px}
main{overflow-y:auto;padding:0;min-height:0}
.doc{max-width:860px;margin:0 auto;padding:38px 48px 120px}
.crumb{font-size:11.5px;color:var(--gray);margin-bottom:6px;font-family:ui-monospace,monospace}
.doc h1,.doc h2,.doc h3,.doc h4{color:var(--yellow);line-height:1.25;margin:1.5em 0 .5em}
.doc h1{font-size:1.9em;margin-top:.2em;border-bottom:1px solid var(--bg2);padding-bottom:.3em}
.doc h2{font-size:1.4em;color:var(--aqua)}
.doc h3{font-size:1.15em;color:var(--blue)}
.doc h4{font-size:1em;color:var(--fg2)}
.doc a{color:var(--blue)}
.doc code{background:var(--bg1);color:var(--orange);padding:1.5px 5px;border-radius:4px;font-family:ui-monospace,SFMono-Regular,Menlo,monospace;font-size:.88em}
.doc pre{background:var(--bg0);border:1px solid var(--bg2);border-radius:8px;padding:14px 16px;overflow-x:auto}
.doc pre code{background:none;color:var(--fg);padding:0;font-size:.85em;line-height:1.55}
.doc blockquote{border-left:3px solid var(--bg3);margin:1em 0;padding:.2em 1em;color:var(--fg4);background:var(--bg0)}
.doc table{border-collapse:collapse;width:100%;margin:1em 0;font-size:.9em}
.doc th,.doc td{border:1px solid var(--bg2);padding:7px 11px;text-align:left}
.doc th{background:var(--bg1);color:var(--yellow)}
.doc tr:nth-child(even) td{background:var(--bg0)}
.doc ul,.doc ol{padding-left:1.5em}
.doc li{margin:.2em 0}
.doc hr{border:none;border-top:1px solid var(--bg2);margin:1.6em 0}
.doc img{max-width:100%}
.empty{color:var(--gray);text-align:center;margin-top:80px;font-size:14px}
.results-mode .cat{display:none}
mark.hit{background:var(--yellow);color:var(--bg0h)}
::-webkit-scrollbar{width:11px;height:11px}
::-webkit-scrollbar-thumb{background:var(--bg2);border-radius:6px;border:2px solid var(--bg0)}
::-webkit-scrollbar-track{background:transparent}
@media(max-width:760px){body{grid-template-columns:1fr}aside{position:fixed;z-index:5;width:280px;height:100%;transform:translateX(-100%);transition:.2s}aside.open{transform:none}.doc{padding:24px}}
</style>
</head>
<body>
<aside>
  <div class="brand">
    <h1>Setup Docs</h1>
    <div class="sub"><span id="stat"></span></div>
  </div>
  <div class="searchwrap">
    <input id="q" type="search" placeholder="Search docs…  ( / to focus )" autocomplete="off" spellcheck="false">
    <div class="hint">Full-text across all docs · ↑↓ to move · Enter to open</div>
  </div>
  <nav id="nav"></nav>
</aside>
<main><div id="content"><div class="empty">Loading…</div></div></main>
<script>
const DOCS = /*__DATA__*/;
const N = /*__DOC_COUNT__*/, CATS = /*__CAT_COUNT__*/;
const nav = document.getElementById('nav');
const content = document.getElementById('content');
const q = document.getElementById('q');
document.getElementById('stat').textContent = N + ' documents · ' + CATS + ' sections';

let active = null;
let filtered = DOCS.slice();
let sel = -1;

function esc(s){return s.replace(/[&<>]/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;'}[c]));}

function highlight(text, terms){
  let out = esc(text);
  for(const t of terms){
    if(!t) continue;
    const re = new RegExp('('+t.replace(/[.*+?^${}()|[\]\\]/g,'\\$&')+')','ig');
    out = out.replace(re,'<mark>$1</mark>');
  }
  return out;
}

function score(doc, terms){
  const hay = (doc.title+' '+doc.desc+' '+doc.text).toLowerCase();
  let s = 0;
  for(const t of terms){
    if(!t) continue;
    if(doc.title.toLowerCase().includes(t)) s += 50;
    if(doc.desc.toLowerCase().includes(t)) s += 20;
    const m = hay.split(t).length - 1;
    if(m===0) return -1; // every term must appear
    s += Math.min(m,8);
  }
  return s;
}

function snippet(doc, terms){
  const text = doc.text;
  const low = text.toLowerCase();
  let idx = -1;
  for(const t of terms){ const k=low.indexOf(t); if(k>=0 && (idx<0||k<idx)) idx=k; }
  if(idx<0) return doc.desc || text.slice(0,90);
  const start = Math.max(0, idx-40);
  return (start>0?'…':'') + text.slice(start, start+120) + '…';
}

function renderNav(){
  const terms = q.value.toLowerCase().split(/\s+/).filter(Boolean);
  let html = '';
  if(terms.length){
    nav.classList.add('results-mode');
    const scored = DOCS.map(d=>({d,s:score(d,terms)})).filter(x=>x.s>=0)
                       .sort((a,b)=>b.s-a.s);
    filtered = scored.map(x=>x.d);
    if(!filtered.length){
      nav.innerHTML = '<div class="cat" style="display:block;color:var(--gray)">No matches</div>';
      return;
    }
    for(const {d} of scored){
      html += `<a class="item" data-id="${esc(d.id)}">`
            + highlight(d.title, terms)
            + `<span class="d">`+highlight(snippet(d,terms),terms)+`</span></a>`;
    }
  } else {
    nav.classList.remove('results-mode');
    filtered = DOCS.slice();
    let cat = null;
    for(const d of DOCS){
      if(d.category!==cat){ cat=d.category; html += `<div class="cat">${esc(cat)}</div>`; }
      const sub = d.desc ? `<span class="d">${esc(d.desc)}</span>` : '';
      html += `<a class="item" data-id="${esc(d.id)}">${esc(d.title)}${sub}</a>`;
    }
  }
  nav.innerHTML = html;
  sel = -1;
  markActive();
}

function markActive(){
  for(const a of nav.querySelectorAll('a.item'))
    a.classList.toggle('active', a.dataset.id===active);
}

function open(id, push){
  const doc = DOCS.find(d=>d.id===id);
  if(!doc) return;
  active = id;
  const terms = q.value.toLowerCase().split(/\s+/).filter(Boolean);
  let body = doc.html;
  content.innerHTML = `<article class="doc"><div class="crumb">${esc(doc.category)} · ${esc(doc.path)}</div>${body}</article>`;
  content.parentElement.scrollTop = 0;
  markActive();
  if(push!==false) location.hash = encodeURIComponent(id);
  document.querySelector('aside').classList.remove('open');
}

nav.addEventListener('click', e=>{
  const a = e.target.closest('a.item');
  if(a){ e.preventDefault(); open(a.dataset.id); }
});

let t=null;
q.addEventListener('input', ()=>{ clearTimeout(t); t=setTimeout(renderNav, 80); });

q.addEventListener('keydown', e=>{
  const items = [...nav.querySelectorAll('a.item')];
  if(e.key==='ArrowDown'){ e.preventDefault(); sel=Math.min(sel+1,items.length-1); items[sel]?.scrollIntoView({block:'nearest'}); items.forEach((it,i)=>it.classList.toggle('active',i===sel)); }
  else if(e.key==='ArrowUp'){ e.preventDefault(); sel=Math.max(sel-1,0); items[sel]?.scrollIntoView({block:'nearest'}); items.forEach((it,i)=>it.classList.toggle('active',i===sel)); }
  else if(e.key==='Enter'){ e.preventDefault(); (items[sel]||items[0])?.click(); }
});

document.addEventListener('keydown', e=>{
  if(e.key==='/' && document.activeElement!==q){ e.preventDefault(); q.focus(); q.select(); }
  if(e.key==='Escape' && document.activeElement===q){ q.value=''; renderNav(); }
});

window.addEventListener('hashchange', ()=>{
  const id = decodeURIComponent(location.hash.slice(1));
  if(id && id!==active) open(id, false);
});

renderNav();
const initial = decodeURIComponent(location.hash.slice(1));
open(DOCS.find(d=>d.id===initial) ? initial : DOCS[0].id, false);
</script>
</body>
</html>"""


def main(argv: list[str]) -> int:
    
# §.splinter/docs/build/main.fs



if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
