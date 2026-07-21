#!/usr/bin/env bash
set -euo pipefail
#
# Generate placeholder workout sound assets (mono 16-bit PCM WAV) into
# Sources/ProRoundsFoundationAudio/Resources/. These are deliberately simple synthesized tones —
# swap them for real audio later (DESIGN.md §10/§11). Committed output; re-run only to regenerate.

OUT="$(cd "$(dirname "$0")/.." && pwd)/Sources/ProRoundsFoundationAudio/Resources"
mkdir -p "$OUT"

python3 - "$OUT" <<'PY'
import math, os, struct, sys, wave

OUT = sys.argv[1]
RATE = 44100

def write_wav(name, samples):
    path = os.path.join(OUT, name + ".wav")
    with wave.open(path, "w") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        frames = bytearray()
        for s in samples:
            v = max(-1.0, min(1.0, s))
            frames += struct.pack("<h", int(v * 32767))
        w.writeframes(bytes(frames))
    print("wrote", path)

def env(i, n, attack=0.005, release=0.4):
    t = i / RATE
    dur = n / RATE
    a = min(1.0, t / attack) if attack > 0 else 1.0
    r = min(1.0, (dur - t) / release) if release > 0 else 1.0
    return max(0.0, a * r)

def tone(freq, dur, kind="sine", harmonics=(), decay=0.0, amp=0.6):
    n = int(RATE * dur)
    out = []
    for i in range(n):
        t = i / RATE
        if kind == "square":
            base = 1.0 if math.sin(2*math.pi*freq*t) >= 0 else -1.0
        else:
            base = math.sin(2*math.pi*freq*t)
        for hf, ha in harmonics:
            base += ha * math.sin(2*math.pi*freq*hf*t)
        e = env(i, n, release=0.5 if decay else 0.1)
        if decay:
            e *= math.exp(-decay * t)
        out.append(amp * e * base / (1 + sum(a for _, a in harmonics)))
    return out

def noise_click(dur=0.06, amp=0.7):
    import random
    random.seed(7)
    n = int(RATE * dur)
    return [amp * (2*random.random()-1) * math.exp(-40*(i/RATE)) for i in range(n)]

# Bell — bright decaying tone with a harmonic (round start/end/rest).
write_wav("bell", tone(880, 0.5, harmonics=[(2.0, 0.4), (3.0, 0.15)], decay=6.0, amp=0.7))
# Wooden clap — a short percussive click.
write_wav("wooden_clap", noise_click())
# Electronic horn — a sustained square tone.
write_wav("electronic_horn", tone(466, 0.35, kind="square", amp=0.45))
# Buzzer — a harsh low square.
write_wav("buzzer", tone(200, 0.4, kind="square", harmonics=[(2.0, 0.5)], amp=0.4))
# Complete — a short rising three-note arpeggio.
comp = tone(660, 0.16, decay=5) + tone(880, 0.16, decay=5) + tone(1175, 0.34, decay=4)
write_wav("complete", comp)
PY

echo "Done. Assets in $OUT"
