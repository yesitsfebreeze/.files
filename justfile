push:
  @git add --all
  @git commit -m "intermediate"
  @git push
  @sleep 5
  @chezmoi update
