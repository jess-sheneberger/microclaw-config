---
name: test
description: "Run tests for the classified repo (firmware tests, Flutter tests). Use when verifying a fix, checking for regressions, or running CI locally."
---

# Test Skill — classified repo

## Firmware tests (primary test surface)

The real test suite lives in the firmware. Flutter tests are placeholder-only.

**Run locally** (requires PlatformIO):
```bash
cd /repos/classified/firmware
make tests-single-local         # build with MARLIN_TEST_BUILD and run
make tests-all-local            # run all test variants
```

**Run in Docker** (no local toolchain needed — preferred):
```bash
cd /repos/classified/firmware
make tests-single-local-docker
make tests-all-local-docker
```

**How tests work:**
- Tests are conditionally compiled via `#if ENABLED(MARLIN_TEST_BUILD)`
- Entry points: `runStartupTests()` and `runPeriodicTests()` in `Marlin/src/tests/`
- Test runner: `buildroot/bin/run_tests`
- CTest integration available for CI

**Adding a test:**
- Edit `Marlin/src/tests/marlin_tests.cpp`
- Add assertions guarded by `#if ENABLED(MARLIN_TEST_BUILD)`
- Run `make tests-single-local` to verify

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

## After making firmware changes

Always run `make tests-single-local-docker` before opening a PR. Firmware changes that break the build on ATmega2560 (8-bit, limited RAM/flash) are common — the Docker build catches them without needing hardware.
