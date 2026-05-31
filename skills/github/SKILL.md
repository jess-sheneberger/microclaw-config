---
name: github
description: "Work with GitHub repositories using git-mcp tools. Use when users ask to clone repos, push/pull changes, create branches, commit work, or interact with GitHub remotes. Triggers on mentions of GitHub, clone, push, pull, branch, commit, or remote."
---

# GitHub Skill

GitHub repository operations go through the **git-mcp** MCP server. Use git-mcp tools for all git operations — do NOT use bash for git commands, as the sandbox does not have credentials.

Repos are cloned into `/home/jess/.microclaw/working_dir/repos/<repo-name>/` and are accessible at `/repos/<repo-name>/` from git-mcp's perspective.

## Common operations

Clone a repo:
- Tool: `git_clone`
- `url`: the GitHub HTTPS URL (e.g. `https://github.com/owner/repo`)
- `path`: `/repos/repo-name`

Check status:
- Tool: `git_status`, `path`: `/repos/repo-name`

Stage and commit:
- Tool: `git_add`, then `git_commit`

Push / pull:
- Tool: `git_push` / `git_pull`

Create or switch branches:
- Tool: `git_branch` / `git_checkout`

View history or diffs:
- Tool: `git_log` / `git_diff`

## Reading and finding files

After cloning, use **native file tools** (read_file, glob, search_files) to read or search repo contents — not bash. Bash runs in a sandboxed container that does not have access to repo paths.

## GitHub API (issues, PRs, CI)

Not available — there is no GitHub API MCP server configured. For issue and PR management, ask the user to handle it via the GitHub web UI or their local `gh` CLI.
