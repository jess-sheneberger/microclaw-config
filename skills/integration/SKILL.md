---
name: integration
description: "Understand the full system integration of the classified repo: Flutter app → Python API → Marlin firmware via serial. Use when debugging cross-layer issues, adding new commands, or understanding data flow between components."
---

# Integration Skill — classified repo

## System architecture

```
Flutter app (Linux desktop)
    ↓ HTTP REST (JSON)
Python FastAPI backend  (/api/)
    ↓ Serial 250000 baud  (/dev/ttyUSB0 or /tmp/marlin-sim)
Marlin firmware (ATmega2560)
    ↓ physical motion
3D printer hardware (probe, axes)
```

## HTTP API contract (Flutter ↔ Python)

Flutter calls these via `app/lib/api_client.dart`:

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/printer/home` | Home all axes (G28) |
| GET | `/printer/position` | Get current XYZ position |
| POST | `/scan/start` | Start scan with params: `x_min`, `x_max`, `y_min`, `y_max`, `step`, `zhop` |
| POST | `/scan/stop` | Abort active scan |
| GET | `/scan/status` | Scan progress |
| GET | `/scan/result` | Completed scan as `.dat` point cloud file |

All request/response bodies are JSON. Errors return standard HTTP status codes.

## Serial / G-code contract (Python ↔ Marlin)

Python (`api/scanner.py`) sends standard Marlin G-code at 250000 baud:

| G-code | Purpose |
|--------|---------|
| `G28` | Home all axes |
| `G0`/`G1 X Y Z F` | Move to position |
| `G38.2 Z F` | Probe toward surface (used for scan points) |
| `G90` | Absolute positioning mode |
| `G91` | Relative positioning mode |

Marlin responds with `ok`, `error`, or position reports. The Python layer parses these responses.

## Simulator

`simulator/sim.py` creates a pseudo-TTY at `/tmp/marlin-sim` that responds to the same G-code commands with synthetic data. Use it for all development and testing that doesn't require hardware validation.

When debugging serial issues, diff the simulator response against expected Marlin output — the simulator may not implement all edge cases.

## State management (Flutter)

The app uses `provider` with `ChangeNotifier`:
- `ScanNotifier` — scan state (idle/running/complete), results
- `SettingsNotifier` — API endpoint config, scan parameters

When adding a new API call: add the method to `api_client.dart`, update the relevant notifier, call `notifyListeners()` after state changes.

## Adding a new scan command end-to-end

1. Add G-code handling in `firmware/Marlin/src/` (follow existing command patterns)
2. Add serial send/receive in `api/scanner.py`
3. Add HTTP endpoint in `api/main.py`
4. Add method to `app/lib/api_client.dart`
5. Update the relevant notifier in `app/lib/`
6. Test with simulator first, then hardware

## Common cross-layer bugs

- **Serial timeout**: Python waits for Marlin `ok` — if firmware doesn't send it, API hangs. Always ensure new G-code handlers send `ok`.
- **Coordinate system mismatch**: Flutter sends scan bounds in mm; Marlin works in mm but verify G90/G91 mode is set before moves.
- **Scan result parsing**: `.dat` format is a raw point cloud — if the probe sequence changes in firmware, the Python parser in `scanner.py` must match.
