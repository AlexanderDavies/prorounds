#!/usr/bin/env python3
"""Generate the coach voice clips from docs/coaching/phrases.json via the ElevenLabs API.

    export ELEVENLABS_API_KEY=...        # same key the elevenlabs MCP server uses
    # COACH_VOICE_ID is baked in (Coach Stokes); export it only to re-audition another voice
    scripts/gen-coach-clips.py --dry-run # what would be generated, and the character cost
    scripts/gen-coach-clips.py           # generate what is missing
    scripts/gen-coach-clips.py --force   # regenerate everything (after a wording change)
    scripts/gen-coach-clips.py --measure # no API calls: just rewrite estMs from the clips on disk

Layout, per docs/coaching/README.md — a phrase forks only when it names punches by number:

    clips/numbers/<id>.m4a   clips/names/<id>.m4a     (clip: "forked")
    clips/shared/<id>.m4a                             (clip: "shared")

Every clip is trimmed to speech + 80ms before encoding — ElevenLabs pads ~330ms of silence onto
the end, which would otherwise be reserved as cadence space by the scheduler.

`estMs` in the catalog starts as a hand estimate. Generation measures each clip with `afinfo` and
writes the real duration back, because the end-of-round guard depends on it being true.

Both conventions must come from the SAME voice, or the app sounds like two different coaches.
"""
from __future__ import annotations

import argparse
import array
import json
import os
import re
import subprocess
import sys
import tempfile
import urllib.error
import urllib.request
import wave
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CATALOG = ROOT / "docs" / "coaching" / "phrases.json"
DEFAULT_OUT = ROOT / "Sources" / "ProRoundsFoundationCoaching" / "Resources" / "clips"
API = "https://api.elevenlabs.io/v1/text-to-speech/{voice}?output_format=mp3_44100_128"

# Deliberate: a corner is clear and consistent, not theatrical. Low style keeps the read flat
# enough that 115 clips sound like one session rather than 115 takes.
VOICE_SETTINGS = {"stability": 0.45, "similarity_boost": 0.75, "style": 0.0, "use_speaker_boost": True}
MODEL = "eleven_multilingual_v2"

# Chosen at audition, 2026-09-07: "Coach Stokes" from the ElevenLabs voice library, picked over
# 29 other candidates. ONE voice speaks every clip in both conventions, or the app sounds like two
# different coaches. $COACH_VOICE_ID overrides it for a re-audition.
COACH_VOICE_ID = "YifVBvyYTdmecR2h3t20"

# ElevenLabs pads roughly 330ms of silence onto the end of every clip — measured across the
# audition set, 28% of the returned audio was silence. That padding is dead cadence space the
# scheduler would otherwise reserve, so it is cut here rather than modelled downstream. 80ms of
# tail keeps the natural decay on plosive endings ("Work!", "Hands up!") from sounding clipped.
LEAD_PAD_MS = 20
TAIL_PAD_MS = 80
SILENCE_FLOOR = 0.02   # of the clip's own peak, i.e. about -34 dBFS relative to it


def targets(catalog: dict, out: Path) -> list[tuple[str, str, Path]]:
    """[(phraseId, textToSpeak, outputPath)] for every clip the catalog implies."""
    jobs = []
    for p in catalog["phrases"]:
        if p["clip"] == "forked":
            for convention in ("numbers", "names"):
                jobs.append((p["id"], p["text"][convention], out / convention / f"{p['id']}.m4a"))
        else:
            jobs.append((p["id"], p["text"], out / "shared" / f"{p['id']}.m4a"))
    return jobs


def synthesize(text: str, dest: Path, key: str, voice: str) -> None:
    body = json.dumps({"text": text, "model_id": MODEL, "voice_settings": VOICE_SETTINGS}).encode()
    req = urllib.request.Request(
        API.format(voice=voice),
        data=body,
        headers={"xi-api-key": key, "Content-Type": "application/json", "Accept": "audio/mpeg"},
    )
    try:
        with urllib.request.urlopen(req, timeout=60) as r:
            audio = r.read()
    except urllib.error.HTTPError as e:
        detail = e.read().decode("utf-8", "replace")[:400]
        raise SystemExit(f"ElevenLabs {e.code} for {dest.name}: {detail}") from e

    dest.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(suffix=".mp3", delete=False) as tmp:
        tmp.write(audio)
        mp3 = Path(tmp.name)
    wav = mp3.with_suffix(".wav")
    try:
        # afconvert ships with macOS; no ffmpeg dependency. Decode to mono PCM first so the
        # silence trim can work on samples, then encode the trimmed result to AAC.
        subprocess.run(
            ["afconvert", "-f", "WAVE", "-d", "LEI16@44100", "-c", "1", str(mp3), str(wav)],
            check=True, capture_output=True,
        )
        trim_silence(wav)
        subprocess.run(
            ["afconvert", "-f", "m4af", "-d", "aac", "-b", "96000", str(wav), str(dest)],
            check=True, capture_output=True,
        )
    except subprocess.CalledProcessError as e:
        raise SystemExit(f"afconvert failed for {dest.name}: {e.stderr.decode()[:300]}") from e
    finally:
        mp3.unlink(missing_ok=True)
        wav.unlink(missing_ok=True)


def trim_silence(wav: Path) -> None:
    """Strip the lead-in and cut the tail to TAIL_PAD_MS, in place.

    Scans 10ms windows against a floor set relative to the clip's own peak, so a quiet
    phrase is not mistaken for silence. A clip with no window above the floor is left alone.
    """
    with wave.open(str(wav)) as r:
        params, frames = r.getparams(), r.readframes(r.getnframes())
    samples = array.array("h", frames)
    if not samples:
        return
    sr = params.framerate
    floor = (max(abs(s) for s in samples) or 1) * SILENCE_FLOOR
    win = max(1, sr // 100)
    loud = [i for i in range(0, len(samples) - win, win)
            if max(abs(s) for s in samples[i:i + win]) > floor]
    if not loud:
        return
    start = max(0, loud[0] - int(sr * LEAD_PAD_MS / 1000))
    end = min(len(samples), loud[-1] + win + int(sr * TAIL_PAD_MS / 1000))
    with wave.open(str(wav), "wb") as w:
        w.setparams(params)
        w.writeframes(samples[start:end].tobytes())


def show(path: Path) -> str:
    """Display path: repo-relative when it lives there, absolute otherwise (--out can point anywhere)."""
    try:
        return str(path.relative_to(ROOT))
    except ValueError:
        return str(path)


def duration_ms(path: Path) -> int | None:
    try:
        out = subprocess.run(["afinfo", str(path)], check=True, capture_output=True, text=True).stdout
    except (subprocess.CalledProcessError, FileNotFoundError):
        return None
    m = re.search(r"estimated duration:\s*([0-9.]+)\s*sec", out)
    return int(round(float(m.group(1)) * 1000)) if m else None


def remeasure(catalog: dict, out: Path) -> int:
    """Replace estMs with the measured length of the longest clip for that phrase."""
    changed = 0
    for p in catalog["phrases"]:
        paths = ([out / c / f"{p['id']}.m4a" for c in ("numbers", "names")]
                 if p["clip"] == "forked" else [out / "shared" / f"{p['id']}.m4a"])
        lengths = [d for d in (duration_ms(x) for x in paths if x.exists()) if d]
        if not lengths:
            continue
        measured = max(lengths)
        if measured != p.get("estMs"):
            p["estMs"] = measured
            changed += 1
    return changed


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--out", type=Path, default=DEFAULT_OUT)
    ap.add_argument("--force", action="store_true", help="regenerate clips that already exist")
    ap.add_argument("--only", help="one phrase id — for auditioning a voice on a real line")
    ap.add_argument("--dry-run", action="store_true")
    ap.add_argument("--measure", action="store_true", help="no API calls; rewrite estMs from disk")
    a = ap.parse_args()

    catalog = json.loads(CATALOG.read_text())

    if a.measure:
        changed = remeasure(catalog, a.out)
        CATALOG.write_text(json.dumps(catalog, indent=2, ensure_ascii=False) + "\n")
        print(f"estMs updated for {changed} phrases from clips in {a.out}")
        return 0

    jobs = targets(catalog, a.out)
    if a.only:
        jobs = [j for j in jobs if j[0] == a.only]
        if not jobs:
            raise SystemExit(f"no phrase with id {a.only!r}")
    todo = [j for j in jobs if a.force or not j[2].exists()]

    chars = sum(len(t) for _, t, _ in todo)
    print(f"{len(todo)} of {len(jobs)} clips to generate · {chars:,} characters · voice "
          f"{os.environ.get('COACH_VOICE_ID') or COACH_VOICE_ID}")
    if a.dry_run:
        for pid, text, dest in todo[:10]:
            print(f"  {show(dest)}  ← {text!r}")
        if len(todo) > 10:
            print(f"  … and {len(todo) - 10} more")
        return 0
    if not todo:
        print("nothing to do — pass --force to regenerate")
        return 0

    key, voice = os.environ.get("ELEVENLABS_API_KEY"), os.environ.get("COACH_VOICE_ID") or COACH_VOICE_ID
    if not key:
        raise SystemExit("set ELEVENLABS_API_KEY")

    for n, (pid, text, dest) in enumerate(todo, 1):
        synthesize(text, dest, key, voice)
        print(f"  [{n}/{len(todo)}] {show(dest)}  {duration_ms(dest)}ms")

    changed = remeasure(catalog, a.out)
    CATALOG.write_text(json.dumps(catalog, indent=2, ensure_ascii=False) + "\n")
    print(f"\ndone — estMs updated for {changed} phrases")
    print("re-run scripts/coach-script.py validate: real durations can breach a cadence ceiling")
    return 0


if __name__ == "__main__":
    sys.exit(main())
