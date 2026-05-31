---
name: build
description: "Build any component of the classified repo (firmware, Flutter app, Python API, simulator). Use when verifying a change compiles, setting up the dev environment, or diagnosing build failures."
---

# Build Skill — classified repo

The repo has four components with separate build systems. Each lives in its own subdirectory under `/repos/classified/`.

## Firmware (Marlin / ATmega2560)

**Toolchain**: PlatformIO with Arduino framework. Target: `mega2560`.

```bash
cd /repos/classified/firmware
pio run                     # build firmware
pio run -t upload           # build + flash to connected board
make marlin                 # alias via Makefile (same as pio run)
```

**Common build failures:**
- PlatformIO not installed: `pip install platformio` or use the Docker path
- Config errors: check `platformio.ini` and the Marlin `Configuration.h` / `Configuration_adv.h`
- Missing preflight: the extra scripts in `platformio.ini` run preflight checks — read their output carefully

**Building in Docker** (no local PlatformIO needed):
```bash
cd /repos/classified/firmware
make tests-single-local-docker    # builds and runs tests in Docker
```

## Flutter App (Linux desktop)

**Toolchain**: Flutter SDK, CMake, GTK+ 3.0

```bash
cd /repos/classified/app
flutter pub get             # install dependencies (run first after clone)
flutter build linux         # release build → build/linux/x64/release/bundle/
flutter run -d linux        # debug run
```

**No codegen** — no `build_runner`, no `flutter pub run build_runner build` needed.

**Common failures:**
- GTK dev headers missing: `sudo apt install libgtk-3-dev`
- CMake too old: needs 3.13+
- Flutter version mismatch: check `pubspec.yaml` SDK constraint (`^3.11.5`)

## Python API

**Toolchain**: Python with `uv`

```bash
cd /repos/classified/api
uv run uvicorn main:app --reload    # dev server on :8000
uv run uvicorn main:app             # production
```

Requires a serial device (real printer or simulator) at `/dev/ttyUSB0`.

## Simulator

Fake Marlin serial device — use this instead of real hardware during development.

```bash
cd /repos/classified/simulator
uv run python sim.py                # creates pseudo-TTY at /tmp/marlin-sim
```

Then point the API at it: set the serial port to `/tmp/marlin-sim` in the API config.

## Full stack (dev)

1. Start simulator: `cd simulator && uv run python sim.py`
2. Start API: `cd api && uv run uvicorn main:app --reload`
3. Run app: `cd app && flutter run -d linux`
