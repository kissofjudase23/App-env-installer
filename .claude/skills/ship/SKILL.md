---
name: ship
description: Run make check, commit, push to origin, watch CI, open a PR and merge it once confirmed
disable-model-invocation: true
---
1. Run `git status`, `git diff --stat` and `git diff`. Stop if there is nothing to commit.
   Revert or flag machine-specific lines that installers appended under `assets/shell/`
   (see AGENTS.md "Critical gotchas"); ask before including untracked files.
2. Run `make check`; stop and report on failure.
3. Stage the intended files by path (no `git add -A`) and commit following
   `.github/instructions/copilot-commit-message-instructions.md`. If the diff spans
   unrelated scopes, propose splitting it first.
4. `git push origin HEAD`.
5. Find runs for the pushed commit: `gh run list --commit "$(git rev-parse HEAD)"
   --json databaseId,workflowName,status`; retry for up to ~30s until they appear.
   Watch each with `gh run watch <id> --exit-status` in the background
   (install-ubuntu can take 30 min). On failure, show `gh run view <id> --log-failed`
   and summarize the cause.
6. On `master`, stop here. Otherwise create a PR against `master` with `gh pr create`
   (branch pushes may start no runs; the PR triggers them).
7. Wait with `gh pr checks <number> --watch` in the background and confirm every check
   passed. On failure, show `gh run view <id> --log-failed`, summarize the cause and stop.
8. Ask the user whether to merge the PR and delete the remote branch. Only after they
   confirm, run `gh pr merge <number> --merge --delete-branch`.
