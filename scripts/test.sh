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
#
# Runs SERIALLY (--no-parallel). The migration test in ProRoundsDataConfigTests writes its fixture
# with a legacy @Model that deliberately shares the shipped entity's class name — that name match is
# what makes the fixture a genuine pre-change store. SwiftData keys stored entities on that name, so
# two models claiming it must never be live at once; in parallel they intermittently drop the newer
# column, and can abort the whole run with an NSException. Swift Testing's `.serialized` only orders
# tests within one suite, so it does not close a cross-suite race. The suite runs in well under a
# second, so serial execution costs nothing worth keeping parallelism for.

XCODE_DEV="/Applications/Xcode.app/Contents/Developer"
CURRENT="$(xcode-select -p 2>/dev/null || true)"

if [[ "$CURRENT" == *"Xcode.app"* ]]; then
  exec swift test --no-parallel "$@"
elif [[ -d "$XCODE_DEV" ]]; then
  exec env DEVELOPER_DIR="$XCODE_DEV" xcrun swift test --no-parallel "$@"
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
exec swift test --no-parallel --disable-xctest \
  -Xswiftc -F -Xswiftc "$FW" \
  -Xlinker -rpath -Xlinker "$FW" \
  -Xlinker -rpath -Xlinker "$INTEROP" \
  "$@"
