#!/usr/bin/env bash
set -euo pipefail
#
# Run SwiftLint in strict mode (any violation fails). Prefers a full Xcode toolchain for SourceKit;
# falls back to the Command Line Tools framework path. Extra args are forwarded.

XCODE_DEV="/Applications/Xcode.app/Contents/Developer"
CURRENT="$(xcode-select -p 2>/dev/null || true)"

if [[ "$CURRENT" == *"Xcode.app"* ]]; then
  exec swiftlint lint --strict "$@"
elif [[ -d "$XCODE_DEV" ]]; then
  exec env DEVELOPER_DIR="$XCODE_DEV" swiftlint lint --strict "$@"
fi

CLT_ROOT="${CURRENT:-/Library/Developer/CommandLineTools}"
export DYLD_FRAMEWORK_PATH="${DYLD_FRAMEWORK_PATH:-}:$CLT_ROOT/usr/lib"
exec swiftlint lint --strict "$@"
