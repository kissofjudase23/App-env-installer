---
name: ship
description: Run make check, commit, push to origin and watch CI for the pushed commit
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
