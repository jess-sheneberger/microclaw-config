---
name: pr-workflow
description: "Create a pull request from scratch: branch, edit, commit, push, open PR. Use when the user asks to implement a feature or fix and ship it as a PR, or when work is ready to submit for review."
---

# PR Workflow Skill

Full workflow from branch to open PR using git-mcp (local git) and gh-mcp (GitHub API).

## Step 1: Start from a clean branch

```
git_checkout  path=/repos/<repo>  branch=main
git_pull      path=/repos/<repo>
git_branch    path=/repos/<repo>  branch=<branch-name>  create=true
git_checkout  path=/repos/<repo>  branch=<branch-name>
```

**Branch naming:** `fix/<short-description>`, `feat/<short-description>`, `chore/<short-description>`

## Step 2: Make changes

Use **native file tools** (read_file, write_file, edit_file) to read and edit files — not bash.

## Step 3: Stage and commit

```
git_add     path=/repos/<repo>  files=[<file>, ...]
git_commit  path=/repos/<repo>  message="<message>"
```

**Commit message format:**
- First line: `<type>: <short summary>` (50 chars max) — types: `fix`, `feat`, `chore`, `refactor`, `test`, `docs`
- Blank line, then optional body explaining the *why*

## Step 4: Push

```
git_push  path=/repos/<repo>  remote=origin  branch=<branch-name>
```

## Step 5: Open PR via gh-mcp

```
create_pull_request
  owner=<owner>
  repo=<repo>
  title="<title>"
  body="<description>"
  head=<branch-name>
  base=main
```

**PR body should include:**
- What changed and why
- How to test it
- Any relevant issue numbers (`Closes #123`)

## Notes

- Always confirm the base branch with the user if unclear (may be `main`, `master`, or `develop`)
- If the repo isn't cloned yet, use the `github` skill to clone it first
- Never commit directly to main/master
