cwd := justfile_directory()

# `just` with no args = push (the first recipe is just's default — keep push here so
# bare `just` keeps meaning "apply + commit + push" as it always has).
push:
  @chezmoi init --source "{{cwd}}" --force
  @chezmoi apply --force
  @git add --all
  @git diff --cached --quiet || git commit -m "intermediate"
  @git pull --rebase --autostash
  @git push
  @sleep 5
  @chezmoi update --force

# Headless unit tests for the nushell config (pure functions only; tty parts excluded).
test:
  @nu tests/nushell/run.nu

# Local quality gate: parse the nushell libs (load-check), then run every test suite.
# Run before pushing to catch regressions; `just gate && just`.
gate:
  @nu -c 'source home/dot_config/nushell/finder.nu; source home/dot_config/nushell/quicklist.nu'
  @nu tests/nushell/run.nu
