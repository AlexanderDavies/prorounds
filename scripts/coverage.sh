#!/usr/bin/env bash
set -euo pipefail
#
# Run the test suite with coverage and enforce the gate (default 90%).
#
# Coverage is measured over `Sources/`, EXCLUDING the declarative ProRoundsDesignSystem module
# (guide §14.4 — view code is guarded by snapshot tests, not line coverage). App views and the
# @main entry live outside the SwiftPM package and are excluded by construction. The timer engine
# is always included. Override the gate with COVERAGE_THRESHOLD.

THRESHOLD="${COVERAGE_THRESHOLD:-90}"

XCODE_DEV="/Applications/Xcode.app/Contents/Developer"
if [[ -d "$XCODE_DEV" && "$(xcode-select -p 2>/dev/null || true)" != *"Xcode.app"* ]]; then
  export DEVELOPER_DIR="$XCODE_DEV"
fi

./scripts/test.sh --enable-code-coverage

BIN="$(xcrun swift build --show-bin-path)"
PROF="$BIN/codecov/default.profdata"
XCTEST="$(find "$BIN" -name '*.xctest' -type d | head -1)"
BINEXE="$XCTEST/Contents/MacOS/$(basename "$XCTEST" .xctest)"

# Exclude the declarative design-system module and any *View.swift (guide §14.4). View models
# (*ViewModel.swift) and mappers stay counted; the engine is always included.
FILES="$(find Sources -name '*.swift' -not -path '*/ProRoundsDesignSystem/*' -not -name '*View.swift')"

# shellcheck disable=SC2086
PCT="$(xcrun llvm-cov export "$BINEXE" -instr-profile "$PROF" -summary-only $FILES \
  | python3 -c 'import json,sys; print(json.load(sys.stdin)["data"][0]["totals"]["lines"]["percent"])')"

printf 'Line coverage: %.2f%% (gate: %s%%, ProRoundsDesignSystem excluded)\n' "$PCT" "$THRESHOLD"

python3 - "$PCT" "$THRESHOLD" <<'PY'
import sys
pct, gate = float(sys.argv[1]), float(sys.argv[2])
if pct + 1e-9 < gate:
    print(f"error: coverage {pct:.2f}% is below the {gate:.0f}% gate", file=sys.stderr)
    sys.exit(1)
PY
