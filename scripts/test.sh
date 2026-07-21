#!/usr/bin/env bash
set -euo pipefail
#
# Run the ProRounds test suite (Swift Testing).
#
# Prefers a full Xcode toolchain — it ships both XCTest (needed by swift-snapshot-testing) and
# Swift Testing, so the suite runs with no special flags. Falls back to Command Line Tools with the
# framework/rpath shims Swift Testing needs there (note: CLT lacks XCTest, so any target linking the
# snapshot library will not build under the fallback — use full Xcode for the whole suite).
#
# Extra args are forwarded, e.g. `scripts/test.sh --enable-code-coverage`.

XCODE_DEV="/Applications/Xcode.app/Contents/Developer"
CURRENT="$(xcode-select -p 2>/dev/null || true)"

if [[ "$CURRENT" == *"Xcode.app"* ]]; then
  exec swift test "$@"
elif [[ -d "$XCODE_DEV" ]]; then
  exec env DEVELOPER_DIR="$XCODE_DEV" xcrun swift test "$@"
fi

# Command Line Tools fallback.
CLT_ROOT="${CURRENT:-/Library/Developer/CommandLineTools}"
FW="$CLT_ROOT/Library/Developer/Frameworks"
INTEROP="$CLT_ROOT/Library/Developer/usr/lib"
if [[ ! -d "$FW/Testing.framework" ]]; then
  echo "error: no full Xcode found and no Swift Testing framework at $FW." >&2
  echo "Install Xcode to run the full suite (incl. snapshot tests)." >&2
  exit 1
fi
exec swift test --disable-xctest \
  -Xswiftc -F -Xswiftc "$FW" \
  -Xlinker -rpath -Xlinker "$FW" \
  -Xlinker -rpath -Xlinker "$INTEROP" \
  "$@"
