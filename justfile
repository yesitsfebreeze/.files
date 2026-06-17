cwd := justfile_directory()

push:
  @chezmoi init --source "{{cwd}}" --force
  @chezmoi apply --force
  @git add --all
  @git commit -m "intermediate"
  @git push
  @sleep 5
  @chezmoi update --force
