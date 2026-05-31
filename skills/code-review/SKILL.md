---
name: code-review
description: "Review a pull request for correctness, safety, and quality issues. Use when the user asks to review a PR, check a diff, or give feedback on code changes. Covers Flutter/Dart and C++ embedded (classified repo)."
---

# Code Review Skill

## Step 1: Get the diff

Use gh-mcp to fetch the PR:
```
get_pull_request         owner=<owner>  repo=<repo>  pullNumber=<n>
list_pull_request_files  owner=<owner>  repo=<repo>  pullNumber=<n>
```

For file contents, use gh-mcp `get_file_contents` or git-mcp `git_show` / `git_diff` on the branch.

## Step 2: Read changed files

Use **native file tools** (read_file, glob) to read full context around changes — not bash. A diff alone misses surrounding invariants.

## Step 3: Review by language

### Flutter / Dart

**Correctness:**
- `BuildContext` used across an `async` gap without `mounted` check → crash
- `StreamSubscription`, `AnimationController`, `TextEditingController` not disposed in `dispose()` → memory leak
- `setState` called after `dispose()` → crash
- `late` fields accessed before assignment
- Null coercion (`!`) without a guaranteed non-null invariant

**Performance:**
- Missing `const` constructors on stateless widgets → unnecessary rebuilds
- Heavy work in `build()` — should be in `initState` or a provider
- `ListView` without `itemExtent` or `ListView.builder` for long lists

**Patterns:**
- Platform channel calls not wrapped in try/catch (can throw on platform errors)
- `Future` returned but not awaited at call site
- `Stream` listened to without error handler

### C++ Embedded

**Memory & safety:**
- Heap allocation (`new`, `malloc`) in interrupt handlers or tight loops — prefer stack or static pools
- Stack-allocated arrays larger than a few hundred bytes — risk of stack overflow
- `memcpy`/`memset` size mismatches
- Integer promotions on 8/16-bit types producing unexpected results
- Signed/unsigned comparison warnings suppressed with casts

**Hardware / concurrency:**
- Hardware registers not declared `volatile`
- Shared state accessed from both ISR and main context without atomic or critical section
- ISR doing too much work (should set a flag, not process)
- Blocking calls (`delay()`, `while(!ready)`) inside ISRs

**C++ specifics (embedded constraints):**
- Exceptions likely disabled — no `try/catch`, constructors shouldn't throw
- RTTI likely disabled — no `dynamic_cast`
- Virtual functions in hot paths or ISR context — vtable dispatch overhead
- Static initialization order issues across translation units
- Destructors in global/static objects — order-of-destruction surprises at shutdown

**General:**
- Magic numbers without named constants
- Missing `override` on derived virtual functions
- `#pragma pack` or alignment attributes — verify intent and portability

## Step 4: Post findings

Use gh-mcp to post an inline review:
```
create_pull_request_review
  owner=<owner>  repo=<repo>  pullNumber=<n>
  event=COMMENT   (or REQUEST_CHANGES / APPROVE)
  body="<summary>"
  comments=[{path, position, body}, ...]
```

**Comment tone:** be specific and constructive. Lead with what the issue is and why it matters, then suggest a fix. Don't flag style unless it's a real readability problem.

## What NOT to flag

- Formatting / whitespace (that's for the linter)
- Naming that's consistent with the surrounding code
- Speculative "what if" scenarios without evidence in the diff
