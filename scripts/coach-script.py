#!/usr/bin/env python3
"""ProRounds coaching-script tool — validate the authored scripts, or preview a round.

    scripts/coach-script.py validate
    scripts/coach-script.py preview beginner_shadow --round 180 --warning 10 --round-index 0

`preview` is the reference implementation of the call-selection algorithm documented in
docs/coaching/README.md. The Swift `CoachCueScheduler` must reproduce these sequences exactly —
same seed, same order, same offsets — so this doubles as the fixture generator for its tests.
"""
from __future__ import annotations
import argparse, json, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
COACH = ROOT / "docs" / "coaching"
KINDS = ("combo", "defence", "movement", "technique", "effort")
MASK = (1 << 64) - 1


class SplitMix64:
    """Fixed, portable PRNG. Swift must implement this exactly (guide §7 determinism)."""

    def __init__(self, seed: int) -> None:
        self.state = seed & MASK

    def next_u64(self) -> int:
        self.state = (self.state + 0x9E3779B97F4A7C15) & MASK
        z = self.state
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
        return (z ^ (z >> 31)) & MASK

    def unit(self) -> float:
        """Uniform in [0,1) from the top 53 bits."""
        return (self.next_u64() >> 11) / float(1 << 53)


def seed_for(config_id: str, round_index: int) -> int:
    """FNV-1a 64 over "<configID>#<roundIndex>". Documented so Swift can match it byte for byte."""
    h = 0xCBF29CE484222325
    for b in f"{config_id}#{round_index}".encode("utf-8"):
        h = ((h ^ b) * 0x100000001B3) & MASK
    return h


def load(name: str) -> dict:
    return json.loads((COACH / f"{name}.json").read_text())


def catalog() -> dict:
    return {p["id"]: p for p in load("phrases")["phrases"]}


def weighted(rng: SplitMix64, items: list, weight) -> object:
    total = sum(weight(i) for i in items)
    x = rng.unit() * total
    acc = 0.0
    for i in items:
        acc += weight(i)
        if x < acc:
            return i
    return items[-1]


def schedule(script: dict, cat: dict, round_ms: int, warning_ms: int, config_id: str, round_index: int) -> list:
    """Return [(offsetMs, phraseId, kind)] for one round. Deterministic in (config_id, round_index)."""
    g = script["guards"]
    rng = SplitMix64(seed_for(config_id, round_index))
    warn_at = round_ms - warning_ms if warning_ms > 0 else None
    last_end = round_ms - g["roundEndGuardMs"]
    boost = g.get("followsBoost", 1)

    def nudge(start: float) -> float:
        """Push a call clear of the round-end warning cue."""
        if warn_at is not None and abs(start - warn_at) < g["warningGuardMs"]:
            return warn_at + g["warningGuardMs"]
        return start

    # Pinned calls are placed first; drawn calls flow around them.
    pinned: list[tuple[int, str, str]] = []
    reserved: list[tuple[float, float]] = []
    seg_start = 0.0
    for seg in script["segments"]:
        seg_end = seg_start + seg["share"] * round_ms
        for pin in seg.get("pinned", []):
            at = nudge(round_ms - pin["atFromRoundEndMs"])
            p = cat[pin["id"]]
            if at < seg_start or at + p["estMs"] > last_end:
                continue  # round too short for this cue to be honest — drop it
            pinned.append((int(round(at)), pin["id"], p["kind"]))
            reserved.append((at - g["minGapMs"], at + p["estMs"] + g["minGapMs"]))
        seg_start = seg_end

    calls: list[tuple[int, str, str]] = []
    # No-repeat history is kept PER KIND: a technique cue must wait for N other technique cues,
    # not N calls. Otherwise the same reminder lands three times a round, because technique slots
    # are far apart in the call sequence.
    recent: dict[str, list[str]] = {k: [] for k in KINDS}
    for _, pid, k in pinned:
        recent[k].append(pid)
    prev_tags: set[str] = set()
    prev_kind: str | None = None
    run_non_combo = 0
    seg_start = 0.0

    for seg in script["segments"]:
        seg_end = seg_start + seg["share"] * round_ms
        t = max(seg_start, g["roundStartDelayMs"]) if seg is script["segments"][0] else seg_start

        while t < seg_end:
            kinds = [(k, seg["mix"][k]) for k in KINDS if seg["mix"].get(k, 0) > 0 and seg["pools"].get(k)]
            if not kinds:
                break
            kind = weighted(rng, kinds, lambda kv: kv[1])[0]
            # Never the same non-combo kind twice running, and never a third non-combo in a row —
            # but defence → technique IS allowed, because that pairing is the point of `follows`.
            if kind != "combo" and seg["pools"].get("combo"):
                if kind == prev_kind or run_non_combo >= g["maxConsecutiveNonCombo"]:
                    kind = "combo"

            remaining = round_ms - t

            def eligible(entries, k):
                window = g["noRepeatWithinKind"].get(k, 0)
                seen = recent[k][-window:] if window else []
                out = []
                for e in entries:
                    p = cat[e["id"]]
                    if e["id"] in seen:
                        continue
                    w = p.get("windowFromRoundEndMs")
                    if w and not (w[0] <= remaining <= w[1]):
                        continue
                    if "follows" in p:
                        if not (set(p["follows"]) & prev_tags):
                            continue
                        out.append((e, e["w"] * boost))  # a cue that answers the last call is worth more
                    else:
                        out.append((e, e["w"]))
                return out

            pool = eligible(seg["pools"][kind], kind)
            # After a defence or movement call, a technique cue must *answer* it when one can:
            # "Roll under it" → "Roll from the legs, not the waist". This is what makes the coach
            # sound like it is watching you rather than reading a list.
            if kind == "technique" and prev_kind not in (None, "combo") and g.get("answerAfterNonCombo"):
                answering = [(e, w) for e, w in pool if "follows" in cat[e["id"]]]
                if answering:
                    pool = answering
            if not pool and kind != "combo":
                kind, pool = "combo", eligible(seg["pools"].get("combo", []), "combo")
            if not pool:
                pool = [(e, e["w"]) for e in seg["pools"][kind]]
            if not pool:
                break

            entry = weighted(rng, pool, lambda ew: ew[1])[0]
            phrase = cat[entry["id"]]

            start = nudge(t)
            for lo_r, hi_r in reserved:                       # keep clear of pinned calls
                if start < hi_r and start + phrase["estMs"] > lo_r:
                    start = hi_r
            if start + phrase["estMs"] > last_end:
                t = seg_end
                break

            calls.append((int(round(start)), entry["id"], kind))
            recent[kind].append(entry["id"])
            prev_tags = set(phrase.get("tags", []))
            prev_kind = kind
            run_non_combo = 0 if kind == "combo" else run_non_combo + 1

            lo, hi = seg["cadenceMs"]
            interval = lo + rng.unit() * (hi - lo)
            t = start + max(interval, phrase["estMs"] + g["minGapMs"])

        seg_start = seg_end

    return sorted(calls + pinned)


# ---------------------------------------------------------------- validate
def validate() -> int:
    cat = catalog()
    errs, warns = [], []

    for pid, p in cat.items():
        if p["kind"] not in KINDS:
            errs.append(f"{pid}: unknown kind {p['kind']!r}")
        if p["clip"] == "forked":
            if not isinstance(p.get("text"), dict) or set(p["text"]) != {"numbers", "names"}:
                errs.append(f"{pid}: forked clip needs text.numbers and text.names")
            if not {"numbers", "names"} <= set(p.get("ticker", {})):
                errs.append(f"{pid}: forked clip needs ticker.numbers and ticker.names")
        else:
            if not isinstance(p.get("text"), str):
                errs.append(f"{pid}: shared clip needs a plain-string text")
            if "line" not in p.get("ticker", {}):
                errs.append(f"{pid}: shared clip needs ticker.line")
        if p["kind"] == "combo" and "follows" in p:
            errs.append(f"{pid}: combos cannot declare follows")

    follow_tags = {t for p in cat.values() for t in p.get("follows", [])}
    all_tags = {t for p in cat.values() for t in p.get("tags", [])}
    for t in sorted(follow_tags - all_tags):
        errs.append(f"follows tag {t!r} is never produced by any phrase")

    # A cue whose `follows` tags no call in the same script ever produces can never play.
    for name in ("beginner_shadow", "beginner_bag"):
        s = load(name)
        used = {e["id"] for seg in s["segments"] for entries in seg["pools"].values() for e in entries}
        produced = {t for pid in used for t in cat[pid].get("tags", [])}
        for pid in sorted(used):
            f = cat[pid].get("follows")
            if f and not (set(f) & produced):
                errs.append(f"{name}: {pid} follows {f} — no call in this script produces those tags")

    for name in ("beginner_shadow", "beginner_bag"):
        s = load(name)
        if abs(sum(seg["share"] for seg in s["segments"]) - 1.0) > 1e-9:
            errs.append(f"{name}: segment shares must sum to 1.0")
        for seg in s["segments"]:
            where = f"{name}/{seg['id']}"
            if abs(sum(seg["mix"].values()) - 1.0) > 1e-9:
                errs.append(f"{where}: mix must sum to 1.0")
            for k, share in seg["mix"].items():
                if share > 0 and not seg["pools"].get(k):
                    errs.append(f"{where}: mix gives {k} {share} but its pool is empty")
            lo, hi = seg["cadenceMs"]
            if lo > hi:
                errs.append(f"{where}: cadence min exceeds max")
            for pin in seg.get("pinned", []):
                if pin["id"] not in cat:
                    errs.append(f"{where}: unknown pinned phrase {pin['id']!r}")
                elif any(pin["id"] == e["id"] for e in seg["pools"].get(cat[pin["id"]]["kind"], [])):
                    errs.append(f"{where}: {pin['id']} is both pinned and in the draw pool")
            for k, entries in seg["pools"].items():
                window = s["guards"]["noRepeatWithinKind"].get(k, 0)
                if entries and window >= len(entries):
                    errs.append(f"{where}: {k} pool has {len(entries)} phrases but the no-repeat "
                                f"window is {window} — every candidate can be blocked at once")
                for e in entries:
                    p = cat.get(e["id"])
                    if p is None:
                        errs.append(f"{where}: unknown phrase {e['id']!r}")
                        continue
                    if p["kind"] != k:
                        errs.append(f"{where}: {e['id']} is kind {p['kind']}, pooled under {k}")
                    if e["w"] <= 0:
                        errs.append(f"{where}: {e['id']} has non-positive weight")
                    floor = p["estMs"] + s["guards"]["minGapMs"]
                    _ = floor
                    if floor > hi:
                        warns.append(f"{where}: {e['id']} ({p['estMs']}ms) forces a gap of {floor}ms, "
                                     f"past the {hi}ms cadence ceiling")
        # a whole workout must be schedulable at the shortest supported round
        for round_ms in (60_000, 120_000, 180_000, 300_000):
            calls = schedule(s, cat, round_ms, 10_000, "validate", 0)
            if not calls:
                errs.append(f"{name}: no calls scheduled for a {round_ms // 1000}s round")

    for w in warns:
        print(f"  warn  {w}")
    for e in errs:
        print(f"  ERROR {e}")
    print(f"\n{len(cat)} phrases · 2 scripts · {len(errs)} errors, {len(warns)} warnings")
    return 1 if errs else 0


# ---------------------------------------------------------------- preview
def preview(name: str, round_ms: int, warning_ms: int, round_index: int, config_id: str, convention: str) -> int:
    cat = catalog()
    s = load(name)
    calls = schedule(s, cat, round_ms, warning_ms, config_id, round_index)

    bounds, acc = [], 0.0
    for seg in s["segments"]:
        acc += seg["share"] * round_ms
        bounds.append((seg["id"], acc))

    print(f"\n{s['title']} — round {round_index + 1}, {round_ms // 1000}s, "
          f"warning at {warning_ms // 1000}s, config {config_id!r}, {convention}")
    print(f"{len(calls)} calls\n")

    shown = 0
    for seg_id, end in bounds:
        seg = next(x for x in s["segments"] if x["id"] == seg_id)
        lo, hi = seg["cadenceMs"]
        print(f"  ── {seg_id.upper()}  (to {int(end) // 1000}s, cadence {lo // 1000}-{hi // 1000}s)")
        while shown < len(calls) and calls[shown][0] < end:
            off, pid, kind = calls[shown]
            p = cat[pid]
            text = p["text"] if isinstance(p["text"], str) else p["text"][convention]
            print(f"     {off // 60000:d}:{off // 1000 % 60:02d}.{off % 1000 // 100}  "
                  f"{kind:<9} {text}")
            shown += 1
    counts = {k: sum(1 for c in calls if c[2] == k) for k in KINDS}
    print("\n  mix: " + " · ".join(f"{k} {v}" for k, v in counts.items() if v))
    return 0


def stats(name: str, round_ms: int, rounds: int, config_id: str) -> int:
    """Delivered mix over N rounds. `mix` in a script is a DRAW weight — adjacency rules convert
    some draws to combos — so this is the number to tune against, not the declared mix."""
    import collections
    cat = catalog()
    s = load(name)
    kinds: collections.Counter = collections.Counter()
    ids: collections.Counter = collections.Counter()
    counts = []
    for ri in range(rounds):
        calls = schedule(s, cat, round_ms, 10_000, config_id, ri)
        counts.append(len(calls))
        for _, pid, k in calls:
            kinds[k] += 1
            ids[pid] += 1
    total = sum(kinds.values())
    print(f"\n{s['title']} — {rounds} × {round_ms // 1000}s rounds, config {config_id!r}")
    print(f"  {sum(counts) / len(counts):.1f} calls per round "
          f"(one every {round_ms / 1000 / (sum(counts) / len(counts)):.1f}s)")
    print("  delivered mix:")
    for k in KINDS:
        if kinds[k]:
            declared = sum(seg["mix"].get(k, 0) * seg["share"] for seg in s["segments"])
            print(f"    {k:<10} {kinds[k] / total:>5.1%}  (declared draw weight {declared:>5.1%})")
    pooled = {e["id"] for seg in s["segments"] for p in seg["pools"].values() for e in p}
    pooled |= {p["id"] for seg in s["segments"] for p in seg.get("pinned", [])}
    unused = sorted(pooled - set(ids))
    print(f"  {len(pooled) - len(unused)}/{len(pooled)} phrases heard")
    if unused:
        print("  not heard in this sample: " + ", ".join(unused))
    return 0


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)
    sub.add_parser("validate")
    pv = sub.add_parser("preview")
    pv.add_argument("script", choices=["beginner_shadow", "beginner_bag"])
    pv.add_argument("--round", type=int, default=180, help="round length in seconds (default 180)")
    pv.add_argument("--warning", type=int, default=10, help="warning lead in seconds, 0 for off")
    pv.add_argument("--round-index", type=int, default=0)
    pv.add_argument("--config", default="demo", help="config ID — half of the RNG seed")
    pv.add_argument("--convention", choices=["numbers", "names"], default="numbers")
    st = sub.add_parser("stats")
    st.add_argument("script", choices=["beginner_shadow", "beginner_bag"])
    st.add_argument("--round", type=int, default=180)
    st.add_argument("--rounds", type=int, default=24)
    st.add_argument("--config", default="demo")
    a = ap.parse_args()
    if a.cmd == "validate":
        return validate()
    if a.cmd == "stats":
        return stats(a.script, a.round * 1000, a.rounds, a.config)
    return preview(a.script, a.round * 1000, a.warning * 1000, a.round_index, a.config, a.convention)


if __name__ == "__main__":
    sys.exit(main())
