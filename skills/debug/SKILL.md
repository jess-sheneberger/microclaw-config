---
name: debug
description: "Systematically debug a problem in code. Use when the user reports a bug, unexpected behavior, test failure, or error and wants it investigated and fixed."
---

# Debug Skill

Structured debugging workflow. Follow these steps in order — don't jump to fixes before you understand the problem.

## Step 1: Reproduce

Confirm you can observe the failure before touching anything.

- Read the error message or stack trace carefully with **read_file** / native file tools
- Identify: what was expected vs. what actually happened
- Find the relevant entry point (test file, endpoint, function)

Do NOT run bash speculatively. Only use the sandbox when you have a specific command to run (e.g. run the failing test).

## Step 2: Isolate

Narrow down *where* the problem is.

- Use **glob** and **read_file** to read relevant source files — not bash grep
- Trace the call path from the failure point upward
- Look for: wrong assumptions, missing nil checks, off-by-one, wrong types, stale state

## Step 3: Hypothesize

Form one specific hypothesis before making any change:
> "The bug is in `foo.rs:42` because X is Y when it should be Z"

If you can't form a hypothesis yet, go back to Step 2.

## Step 4: Verify

Test your hypothesis with the minimum change possible:
- Add a log line or assertion using native file tools
- Run the specific failing test in the sandbox: `cargo test test_name` / `npm test -- <pattern>`
- Confirm the hypothesis is correct before proceeding to fix

## Step 5: Fix

- Make the targeted fix using native file tools
- Re-run the test to confirm it passes
- Check for related call sites with **glob** / **search_files** that may have the same bug
- If the fix is non-obvious, note the *why* in a comment

## Step 6: Verify nothing else broke

Run the full test suite in the sandbox if feasible. If it's too slow, run the tests for the affected module.

## Key rules

- **Never use bash to read or find files** — use native file tools
- **Don't fix without understanding** — a fix that passes tests but doesn't address the root cause will recur
- **One hypothesis at a time** — don't make multiple speculative changes simultaneously
- **Sandbox bash is for running code, not reading it**
