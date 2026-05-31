---
name: repos
description: "Work with code repositories in the local repos directory. Use when users ask to read, search, or edit files in a cloned repo, or need to understand a codebase. Triggers on mentions of repo, codebase, source code, read file, find file, or search code."
---

# Repos Skill

Cloned repositories live at `/home/jess/.microclaw/working_dir/repos/<repo-name>/`.

## Reading and finding files

Always use **native file tools** — never bash — for file operations in repos:

- **Read a file**: `read_file` with the full path
- **Find files by name or pattern**: `glob` (e.g. `glob /home/jess/.microclaw/working_dir/repos/myrepo/**/*.ts`)
- **Search file contents**: `search_files` with a query

Bash runs in a sandboxed container that cannot see repo paths. File tools work directly without the sandbox.

## Git operations

Use **git-mcp tools** for all git operations (clone, commit, push, pull, branch, diff, log, etc.). See the `github` skill for details.

## Typical workflow

1. Clone via git-mcp `git_clone` → path `/repos/repo-name`
2. Read and edit files using native file tools at `/home/jess/.microclaw/working_dir/repos/repo-name/`
3. Stage and commit via git-mcp `git_add` + `git_commit`
4. Push via git-mcp `git_push`
