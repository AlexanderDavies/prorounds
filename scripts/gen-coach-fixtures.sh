#!/usr/bin/env bash
set -euo pipefail
#
# Regenerate every coaching test fixture from the Python reference in one command.
#
# scripts/coach-script.py is normative for the Swift port: where it and the prose in
# docs/coaching/README.md disagree, the Python wins. These fixtures are how that is enforced —
# ProRoundsFoundationCoachingTests asserts byte-identity against them.
#
# Run after ANY change to coach-script.py, phrases.json, or a script file, then review the diff:
# a fixture change means the coach's behaviour changed, which is either intended or a bug.

cd "$(dirname "$0")/.."
OUT="Tests/ProRoundsFoundationCoachingTests/Fixtures"
mkdir -p "$OUT/schedules"

# RNG ground truth. Covers several config IDs and round indices, including a non-zero index, so a
# port that ignores roundIndex or treats it as one-based fails immediately.
scripts/coach-script.py seed-vectors \
  --pairs "demo:0,demo:1,demo:2,bag-cfg:0,bag-cfg:3,x:7,:0" --count 12 \
  > "$OUT/seed_vectors.json"

# Schedule fixtures. Round lengths span the short end (where guards dominate and schedules can come
# back empty) to the long end (where every segment gets real time).
for script in beginner_shadow beginner_bag; do
  # 4s and 5s sit either side of the guard boundary: at 4s the start delay plus the end-of-round
  # guard leave no room and the schedule comes back empty, at 5s exactly one call fits. Both are
  # fixtures so the empty path is covered by byte-identity, not only by the property tests.
  for round_s in 4 5 45 60 120 180 240 300; do
    for idx in 0 1 2; do
      scripts/coach-script.py preview "$script" \
        --round "$round_s" --round-index "$idx" --config demo --json \
        > "$OUT/schedules/${script}_r${round_s}_i${idx}.json"
    done
  done
done

# Edge cases found by the property tests, pinned so they cannot regress unnoticed.
#
# The 255s round below contains two calls at the SAME offset (140250ms) — a segment-boundary tie.
# No round in the matrix above has one, so without this fixture the (offset, id, kind) sort
# tie-break is untested, and a port that sorted by offset alone would pass every other check.
scripts/coach-script.py preview beginner_shadow \
  --round 255 --round-index 1 --config a-longer-config-id --json \
  > "$OUT/schedules/edge_offset_tie.json"

echo "fixtures written to $OUT"
find "$OUT" -name '*.json' | wc -l | xargs echo "files:"
