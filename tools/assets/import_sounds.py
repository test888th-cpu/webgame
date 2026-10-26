#!/usr/bin/env python3
"""Imports recorded sound effects listed in art/sounds/sounds.json.

  python3 tools/assets/import_sounds.py

Each entry names a 16-bit PCM WAV in art/sounds/, its authors, licence and
source page. The sound is cut to `start` + `length` seconds, mixed to mono,
given a short fade in and out (no clicks), normalised to -1 dBFS and written
to client/assets/audio/<id>.wav. The manifest's "audio" section lists it with
its credits under "recorded", next to the sounds gen_sfx.py synthesises.
"""

from __future__ import annotations

import array
import io
import json
import sys
import wave
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "art" / "sounds"
OUT = ROOT / "client" / "assets" / "audio"
MANIFEST = ROOT / "client" / "assets" / "manifest.json"
FADE_IN = 0.002
FADE_OUT = 0.06
PEAK = 0.89  # -1 dBFS


def render(spec: dict) -> bytes:
    with wave.open(str(SOURCE / spec["file"])) as source:
        if source.getsampwidth() != 2:
            raise ValueError(f"{spec['file']}: expected 16-bit PCM")
        rate, channels = source.getframerate(), source.getnchannels()
        frames = array.array("h", source.readframes(source.getnframes()))
    mono = [sum(frames[i:i + channels]) / channels for i in range(0, len(frames), channels)]
    first = int(spec.get("start", 0.0) * rate)
    count = int(spec["length"] * rate) if "length" in spec else len(mono) - first
    cut = mono[first:first + count]
    if not cut:
        raise ValueError(f"{spec['file']}: the cut is empty")
    fade_in, fade_out = max(1, int(FADE_IN * rate)), max(1, int(FADE_OUT * rate))
    for i in range(min(fade_in, len(cut))):
        cut[i] *= i / fade_in
    for i in range(min(fade_out, len(cut))):
        cut[-1 - i] *= i / fade_out
    peak = max(1.0, max(abs(v) for v in cut))
    scale = PEAK * 32767 / peak
    out = array.array("h", (int(round(v * scale)) for v in cut))
    buffer = io.BytesIO()
    with wave.open(buffer, "wb") as target:
        target.setnchannels(1)
        target.setsampwidth(2)
        target.setframerate(rate)
        target.writeframes(out.tobytes())
    return buffer.getvalue()


def recorded() -> dict:
    return json.loads((SOURCE / "sounds.json").read_text())["sounds"]


def main() -> int:
    OUT.mkdir(parents=True, exist_ok=True)
    manifest = json.loads(MANIFEST.read_text())
    audio = manifest.setdefault("audio", {})
    sounds = audio.setdefault("sounds", {})
    credits = {}
    for sound_id, spec in recorded().items():
        (OUT / f"{sound_id}.wav").write_bytes(render(spec))
        sounds[sound_id] = f"res://assets/audio/{sound_id}.wav"
        credits[sound_id] = {key: spec[key] for key in ("title", "authors", "license", "url", "attribution", "notes") if key in spec}
    audio["recorded"] = credits
    MANIFEST.write_text(json.dumps(manifest, indent=2, sort_keys=True) + "\n")
    print(f"imported {len(credits)} recorded sound(s)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
