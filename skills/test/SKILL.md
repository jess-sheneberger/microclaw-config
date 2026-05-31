---
name: test
description: "Run tests for the classified repo (Flutter tests, Python API tests). Use when verifying a fix, checking for regressions, or running CI locally."
---

# Test Skill — classified repo

## Flutter tests

Minimal — the `test/widget_test.dart` is boilerplate placeholder. Running it is still useful as a smoke check that the widget tree builds without errors.

```bash
cd /repos/classified/app
flutter test
```

No integration tests or golden tests are configured.

## Python API tests

Check `/repos/classified/api/` for any test files before assuming there are none — the explorer may have missed them. If present, run with:
```bash
cd /repos/classified/api
uv run pytest
```

## CI

GitHub Actions workflows are in `.github/workflows/`. Check there to understand what the CI pipeline runs — mirror it locally when debugging a CI failure.

