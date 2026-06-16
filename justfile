cwd := justfile_directory()

push:
  @chezmoi init --source "{{cwd}}"
  @chezmoi apply
  @git add --all
  @git commit -m "intermediate"
  @git push
  @sleep 5
  @chezmoi update
