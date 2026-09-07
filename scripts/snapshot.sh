#!/usr/bin/env bash
set -euo pipefail
#
# Run the design-system / feature snapshot tests on a pinned iOS simulator.
#
# Requires full Xcode. Reference images live beside the tests in __Snapshots__/ and are the visual
# regression guard. To (re)record references after an intentional design change:
#     RECORD=1 scripts/snapshot.sh
# Normal verification run:
#     scripts/snapshot.sh
#
# The generated ProRounds.xcodeproj shadows the package's aggregate test scheme
# (ProRoundsModules-Package — the only scheme with a test action). Rather than moving the real
# project (which disturbs an open Xcode), we run xcodebuild from a throwaway directory of *symlinks*
# to the package (Package.swift, Sources, Tests, Package.resolved) with no .xcodeproj present. The
# symlinked Tests dir means __Snapshots__ reads/writes still land on the real reference images. Both
# the symlink workspace and its DerivedData live under .build/ (git-ignored); DerivedData persists so
# builds cache across runs.

export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"

DEVICE="${SNAPSHOT_DEVICE:-iPhone 17 Pro}"
DESTINATION="platform=iOS Simulator,name=${DEVICE}"

# Recording is selected by a COMPILER FLAG, not an environment variable.
#
# xcodebuild does not forward an exported variable into the simulator's test process, so the
# library never saw SNAPSHOT_TESTING_RECORD and RECORD=1 silently did nothing — it only appeared to
# work because swift-snapshot-testing writes a reference that is entirely missing whatever the
# record mode is. Changed references were never re-recorded. Build settings do propagate, so the
# suites read `#if RECORD_SNAPSHOTS` instead.
# Always set, never an empty array: `set -u` on the bash that ships with macOS treats an empty
# array expansion as an unbound variable, which silently turned a verification run into a no-op.
SWIFT_FLAGS='$(inherited)'
if [[ "${RECORD:-0}" == "1" ]]; then
  SWIFT_FLAGS='$(inherited) -D RECORD_SNAPSHOTS'
  echo "Recording snapshot references on ${DEVICE}…"
fi

REPO="$(cd "$(dirname "$0")/.." && pwd)"
WORKSPACE="$REPO/.build/snapshot-workspace"
DERIVED="$REPO/.build/snapshot-deriveddata"

# Rebuild the symlink farm (cheap); keep DerivedData for caching.
rm -rf "$WORKSPACE"
mkdir -p "$WORKSPACE"
for item in Package.swift Package.resolved Sources Tests; do
  [[ -e "$REPO/$item" ]] && ln -s "$REPO/$item" "$WORKSPACE/$item"
done

cd "$WORKSPACE"
exec xcodebuild test \
  -scheme ProRoundsModules-Package \
  -destination "${DESTINATION}" \
  -only-testing:ProRoundsDesignSystemTests \
  -only-testing:ProRoundsFeatureConfigTests \
  -only-testing:ProRoundsFeatureTimerTests \
  -only-testing:ProRoundsFeaturePerformanceTests \
  -only-testing:ProRoundsFeatureSettingsTests \
  -derivedDataPath "$DERIVED" \
  CODE_SIGNING_ALLOWED=NO \
  "OTHER_SWIFT_FLAGS=${SWIFT_FLAGS}"
