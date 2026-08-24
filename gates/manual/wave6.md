# Wave 6 — interactive checklist, and the fresh-machine run

Automated half: `just gate 6`.

- [ ] **H.4** — the fresh-machine run, below. It is this wave's whole point.
- [ ] **H.4** — `help --check` exits 0. Run it on the fresh machine, not on this one.
      PASS: exit 0 — every binding that exists is documented and every
      documented binding exists. That is the closest thing this build has to a
      completeness proof.
      FAIL: any non-zero exit; read what it names before touching anything.
- [ ] **H.4** — `ls --help` still behaves. On the fresh machine, in the new shell.
      PASS: the real `ls` help, unmangled.
      FAIL: anything of ours in the output — a `--help` delegation regression
      breaks the whole shell, which is why H.2 needed an adversarial second
      agent.

## The fresh-machine run (R7, non-negotiable)

The last gate runs on a machine that has never seen this config. Everything
else can pass on a developer box that already has the tools installed and
prove nothing.

**Do not build an automated fresh-machine gate on this host, and do not
"improve" this file into a script.** A scratch `HOME` on this box still has
every tool on `PATH`, every brew formula installed and every cache warm, so
such a gate passes while proving exactly nothing — precisely the failure R7
warns about. The isolation has to be a real machine boundary: a container or a
VM. `docker` is installed here (`/usr/local/bin/docker`) and so is `lima`, so
this is a copy-paste procedure, not a hand-wave.

1. Start a clean Linux container with nothing but git and curl:
   `docker run --rm -it -v "$PWD":/repo:ro debian:bookworm bash`
   (or `limactl start --name=fresh template://default && limactl shell fresh`
   for a full VM, which is the closer analogue of a new laptop).
2. Inside it: `apt-get update && apt-get install -y git curl` — nothing else.
   Installing anything further by hand invalidates the run.
3. `git clone <this repo> ~/dotfiles && cd ~/dotfiles`.
4. Run the bootstrap exactly as a new user would, from the README, with no
   local knowledge and no shortcuts.
5. `chezmoi apply`, then `chezmoi apply` a second time.
   PASS: the second apply is a no-op.
6. Open a new shell and *work in it for ten minutes*: cd around, jump, use the
   finder, open the editor, run a container. Not a script — actual use.
7. Run `help --check` and `ls --help` there, and tick the two boxes above.

PASS: a working daily driver, from clone to prompt, with no step you had to
know in advance. FAIL: any step that needed a tool the container did not have,
a path only this Mac has, or a piece of knowledge that lives in nobody's
README. macOS-only steps are expected to be skipped in a Linux container;
record which ones, because on a fresh *Mac* they must all run.
- [ ] **H.5** — the reading test, and the only check that measures whether this
      whole epic worked. Start a **fresh** agent session that knows nothing
      about this repo. Give it the output of `help` and nothing else, plus an
      ordinary task that needs a search and a file-find — "find where X is
      configured", say.
      PASS: it reaches for the tools this environment installs — `rg` for
      search, `fd` for find, `tv` for picking — and names no tool that is not
      installed. `fzf` counts as a failure anywhere except inside `zi`/`cdi`,
      which are the one sanctioned exception.
      FAIL: it reaches for `grep`, `find`, `fzf`, or any tool this environment
      does not provide.
      Why a human sets it up: the subject is an agent's behaviour on first
      contact, so the session has to be uncontaminated — anyone who has read
      this repo cannot be the subject, and neither can a session that was told
      what the right answer is. That is also why the PASS line names the tools
      rather than describing them: a grader who has to interpret is a grader
      who can be argued with.
      Evidence already on file: the orchestrator ran this on 2026-08-24 with a
      deliberately uninformed agent. The result is recorded in
      [`06-help/05-agent-interface`](../../prds/06-help/05-agent-interface/prd.md)'s
      closing note. It is evidence for whoever ticks this box, not a tick.
