#!/usr/bin/env python3
"""Generates the sound effects: original, synthesised in code (no samples).

  python3 tools/assets/gen_sfx.py

Effects built from oscillators, filtered noise and envelopes,
written as 16-bit mono WAV files to client/assets/audio/ and listed in the
manifest's "audio" section. Noise comes from a seeded generator, so the
output is reproducible; the validator compares it with a small tolerance
because floating-point sine may differ in the last bit between machines.
"""

from __future__ import annotations

import io
import json
import math
import random
import struct
import sys
import wave
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "client" / "assets" / "audio"
MANIFEST = ROOT / "client" / "assets" / "manifest.json"
RATE = 22050


class Sound:
    """A mono buffer that voices are mixed into."""

    def __init__(self, seconds: float, seed: int, level: float = 0.85) -> None:
        self.samples = [0.0] * int(seconds * RATE)
        self.rng = random.Random(seed)
        # The peak it is normalised to: small sounds heard often (a coin, a
        # pickup) sit well under the blows instead of matching them.
        self.level = level

    def tone(self, start: float, length: float, f0: float, f1: float, shape: str = "sine",
             volume: float = 0.5, attack: float = 0.004, decay: float = 6.0, vibrato: float = 0.0) -> None:
        """An oscillator sweeping exponentially from f0 to f1 Hz."""
        first, count = int(start * RATE), int(length * RATE)
        phase = 0.0
        for i in range(count):
            t = i / RATE
            k = i / max(1, count - 1)
            freq = f0 * (f1 / f0) ** k
            if vibrato:
                freq *= 1.0 + 0.03 * math.sin(2 * math.pi * vibrato * t)
            phase = (phase + freq / RATE) % 1.0
            if shape == "sine":
                value = math.sin(2 * math.pi * phase)
            elif shape == "square":
                value = 1.0 if phase < 0.5 else -1.0
            elif shape == "saw":
                value = 2.0 * phase - 1.0
            else:  # triangle
                value = 4.0 * abs(phase - 0.5) - 1.0
            self._add(first + i, value * volume * envelope(t, length, attack, decay))

    def noise(self, start: float, length: float, volume: float = 0.5, low: float = 1.0,
              high: float = 0.0, attack: float = 0.002, decay: float = 8.0,
              low_end: float | None = None, tremolo: float = 0.0) -> None:
        """White noise through a one-pole low-pass (`low`, 0..1, sweeping to
        `low_end`) and an optional high-pass (`high`, 0..1)."""
        first, count = int(start * RATE), int(length * RATE)
        lp = hp_in = hp_out = 0.0
        for i in range(count):
            t = i / RATE
            k = i / max(1, count - 1)
            cutoff = low if low_end is None else low + (low_end - low) * k
            lp += cutoff * (self.rng.uniform(-1.0, 1.0) - lp)
            value = lp
            if high:
                hp_out = high * (hp_out + value - hp_in)
                hp_in = value
                value = hp_out
            gain = envelope(t, length, attack, decay)
            if tremolo:
                gain *= 0.6 + 0.4 * math.sin(2 * math.pi * tremolo * t)
            self._add(first + i, value * volume * gain)

    def _add(self, index: int, value: float) -> None:
        if 0 <= index < len(self.samples):
            self.samples[index] += value

    def to_wav(self) -> bytes:
        peak = max(1e-9, max(abs(s) for s in self.samples))
        scale = min(1.0, self.level / peak)
        frames = bytearray()
        for s in self.samples:
            v = math.tanh(s * scale * 1.2) / math.tanh(1.2)
            frames += struct.pack("<h", int(round(v * 32000)))
        buffer = io.BytesIO()
        with wave.open(buffer, "wb") as out:
            out.setnchannels(1)
            out.setsampwidth(2)
            out.setframerate(RATE)
            out.writeframes(bytes(frames))
        return buffer.getvalue()


def envelope(t: float, length: float, attack: float, decay: float) -> float:
    if t < attack:
        return t / attack
    tail = min(1.0, (length - t) / 0.01)  # avoid clicks at the end
    return math.exp(-decay * (t - attack)) * max(0.0, tail)


def note(name: str) -> float:
    names = {"C": -9, "D": -7, "E": -5, "F": -4, "G": -2, "A": 0, "B": 2}
    semis = names[name[0]] + (1 if "#" in name else 0) + 12 * (int(name[-1]) - 4)
    return 440.0 * 2 ** (semis / 12)


def swing_light(s: Sound) -> None:
    s.noise(0, 0.12, 0.5, low=0.08, low_end=0.35, high=0.6, attack=0.03, decay=18)


def swing_heavy(s: Sound) -> None:
    s.noise(0, 0.24, 0.6, low=0.04, low_end=0.2, high=0.5, attack=0.06, decay=10)
    s.tone(0, 0.2, 180, 90, "sine", 0.15, attack=0.05, decay=10)


def hit_light(s: Sound) -> None:
    s.tone(0, 0.09, 160, 60, "sine", 0.9, attack=0.001, decay=30)
    s.noise(0, 0.04, 0.6, low=0.5, attack=0.0005, decay=60)


def hit_heavy(s: Sound) -> None:
    s.tone(0, 0.2, 120, 38, "sine", 1.0, attack=0.001, decay=14)
    s.noise(0, 0.1, 0.8, low=0.35, low_end=0.08, attack=0.0005, decay=25)
    s.tone(0, 0.05, 900, 300, "square", 0.15, attack=0.0005, decay=60)


def hit_block(s: Sound) -> None:
    s.tone(0, 0.18, 950, 900, "square", 0.25, attack=0.0005, decay=22)
    s.tone(0, 0.18, 1420, 1380, "triangle", 0.3, attack=0.0005, decay=26)
    s.noise(0, 0.03, 0.5, low=0.9, high=0.7, attack=0.0005, decay=80)


def guard_break(s: Sound) -> None:
    s.noise(0, 0.3, 0.7, low=0.9, high=0.4, attack=0.001, decay=10)
    s.tone(0, 0.3, 900, 180, "square", 0.25, attack=0.001, decay=8)
    s.tone(0.02, 0.2, 140, 50, "sine", 0.7, attack=0.001, decay=12)


def hero_hurt(s: Sound) -> None:
    s.tone(0, 0.2, 240, 150, "saw", 0.35, attack=0.01, decay=10, vibrato=30)
    s.noise(0, 0.2, 0.25, low=0.1, attack=0.01, decay=12)
    s.tone(0, 0.08, 130, 60, "sine", 0.7, attack=0.001, decay=30)


def knockdown(s: Sound) -> None:
    s.tone(0, 0.28, 90, 38, "sine", 1.0, attack=0.002, decay=12)
    s.noise(0, 0.25, 0.6, low=0.06, attack=0.002, decay=14)


def ko(s: Sound) -> None:
    s.tone(0, 0.4, 420, 70, "square", 0.3, attack=0.002, decay=6)
    s.tone(0.05, 0.3, 90, 35, "sine", 0.9, attack=0.002, decay=10)
    s.noise(0.05, 0.25, 0.4, low=0.08, attack=0.002, decay=12)


def dodge(s: Sound) -> None:
    s.noise(0, 0.14, 0.45, low=0.15, low_end=0.5, high=0.7, attack=0.02, decay=16)


def skill_uppercut(s: Sound) -> None:
    s.noise(0, 0.2, 0.5, low=0.05, low_end=0.5, high=0.5, attack=0.04, decay=10)
    s.tone(0.05, 0.25, 500, 1300, "triangle", 0.25, attack=0.01, decay=9)
    s.tone(0.1, 0.15, 140, 50, "sine", 0.8, attack=0.001, decay=18)


def skill_whirlwind(s: Sound) -> None:
    s.noise(0, 0.45, 0.6, low=0.1, low_end=0.4, high=0.5, attack=0.05, decay=4, tremolo=14)
    s.tone(0, 0.45, 300, 600, "sine", 0.12, attack=0.05, decay=4, vibrato=14)


def skill_rush(s: Sound) -> None:
    s.tone(0, 0.32, 110, 320, "saw", 0.3, attack=0.01, decay=5)
    s.noise(0, 0.32, 0.55, low=0.1, low_end=0.45, high=0.5, attack=0.02, decay=6)
    s.tone(0.22, 0.12, 120, 45, "sine", 0.8, attack=0.001, decay=20)


def skill_slam(s: Sound) -> None:
    s.noise(0, 0.12, 0.3, low=0.1, low_end=0.5, attack=0.08, decay=4)
    s.tone(0.12, 0.65, 75, 28, "sine", 1.0, attack=0.002, decay=5)
    s.noise(0.12, 0.6, 0.9, low=0.2, low_end=0.03, attack=0.002, decay=6)
    s.noise(0.14, 0.3, 0.3, low=0.9, high=0.6, attack=0.002, decay=14)


def level_up(s: Sound) -> None:
    # A warm rising chime (bell partials), not a chiptune fanfare.
    for i, name in enumerate(("C5", "E5", "G5", "C6")):
        s.tone(i * 0.09, 0.6 - i * 0.08, note(name), note(name), "sine", 0.3, attack=0.004, decay=5)
        s.tone(i * 0.09, 0.3, note(name) * 2.76, note(name) * 2.76, "sine", 0.06, attack=0.002, decay=14)
    s.tone(0.27, 0.55, note("C6") * 2, note("C6") * 2, "sine", 0.1, attack=0.01, decay=6, vibrato=5)


def coin(s: Sound) -> None:
    # A small, quiet metallic clink: two inharmonic partials that ring for a
    # moment, the way coins sound in most action games, not an arcade jingle.
    s.tone(0, 0.14, 2350, 2350, "sine", 0.4, attack=0.0008, decay=30)
    s.tone(0, 0.1, 3720, 3720, "sine", 0.22, attack=0.0008, decay=42)
    s.noise(0, 0.012, 0.12, low=0.9, high=0.8, attack=0.0005, decay=200)


def pickup(s: Sound) -> None:
    # A soft, short pop for an item into the bag.
    s.tone(0, 0.09, 520, 760, "sine", 0.5, attack=0.002, decay=26)
    s.noise(0, 0.02, 0.15, low=0.5, high=0.5, attack=0.001, decay=120)


def heal(s: Sound) -> None:
    for i, name in enumerate(("G5", "B5", "D6", "G6")):
        s.tone(i * 0.06, 0.3, note(name), note(name), "sine", 0.3, attack=0.01, decay=8, vibrato=8)


def quest(s: Sound) -> None:
    for i, (name, length) in enumerate((("C5", 0.12), ("G5", 0.12), ("E5", 0.12), ("C6", 0.45))):
        s.tone(i * 0.11, length, note(name), note(name), "triangle", 0.4, attack=0.004, decay=3)
        s.tone(i * 0.11, length, note(name) / 2, note(name) / 2, "sine", 0.12, attack=0.004, decay=5)


def ui_move(s: Sound) -> None:
    s.tone(0, 0.035, 1250, 1250, "triangle", 0.35, attack=0.001, decay=50)


def ui_select(s: Sound) -> None:
    s.tone(0, 0.08, 880, 1320, "square", 0.18, attack=0.001, decay=20)


def ui_back(s: Sound) -> None:
    s.tone(0, 0.08, 700, 440, "square", 0.18, attack=0.001, decay=20)


def denied(s: Sound) -> None:
    s.tone(0, 0.06, 150, 140, "square", 0.25, attack=0.001, decay=10)
    s.tone(0.08, 0.08, 120, 110, "square", 0.25, attack=0.001, decay=10)


def boss_roar(s: Sound) -> None:
    s.tone(0, 0.9, 85, 52, "saw", 0.5, attack=0.08, decay=2.5, vibrato=7)
    s.noise(0, 0.9, 0.5, low=0.08, attack=0.08, decay=2.5, tremolo=22)


def arena_lock(s: Sound) -> None:
    s.tone(0, 0.35, 220, 200, "square", 0.2, attack=0.001, decay=9)
    s.tone(0, 0.35, 330, 310, "triangle", 0.3, attack=0.001, decay=9)
    s.noise(0, 0.05, 0.5, low=0.6, attack=0.001, decay=50)


def weapon_grab(s: Sound) -> None:
    s.noise(0, 0.06, 0.4, low=0.5, high=0.5, attack=0.001, decay=40)
    s.tone(0.02, 0.12, 300, 520, "triangle", 0.4, attack=0.002, decay=16)


def weapon_drop(s: Sound) -> None:
    for i, start in enumerate((0.0, 0.07, 0.12)):
        s.tone(start, 0.08, 700 - i * 90, 640 - i * 90, "square", 0.18 - i * 0.04, attack=0.0005, decay=40)
        s.noise(start, 0.04, 0.35, low=0.6, high=0.5, attack=0.0005, decay=70)


def break_glass(s: Sound) -> None:
    s.noise(0, 0.35, 0.8, low=0.95, high=0.85, attack=0.0005, decay=10)
    for i, start in enumerate((0.0, 0.03, 0.08, 0.15)):
        s.tone(start, 0.12, 2600 + i * 420, 2300 + i * 400, "triangle", 0.18, attack=0.0005, decay=28)


def break_wood(s: Sound) -> None:
    s.noise(0, 0.25, 0.9, low=0.4, low_end=0.15, attack=0.0005, decay=14)
    s.tone(0, 0.12, 220, 90, "square", 0.3, attack=0.0005, decay=24)
    s.noise(0.08, 0.15, 0.5, low=0.6, high=0.4, attack=0.001, decay=20)


def break_metal(s: Sound) -> None:
    s.tone(0, 0.45, 1180, 1120, "triangle", 0.4, attack=0.0005, decay=7, vibrato=9)
    s.tone(0, 0.45, 1760, 1700, "sine", 0.3, attack=0.0005, decay=9)
    s.noise(0, 0.05, 0.6, low=0.9, high=0.6, attack=0.0005, decay=60)


def hazard_warn(s: Sound) -> None:
    # Two quick rising alert tones: something is coming, get clear.
    for start in (0.0, 0.13):
        s.tone(start, 0.1, 620, 880, "triangle", 0.35, attack=0.004, decay=12)


def steam_hiss(s: Sound) -> None:
    s.noise(0, 0.55, 0.8, low=0.95, high=0.75, attack=0.01, decay=4)
    s.noise(0, 0.2, 0.4, low=0.3, attack=0.002, decay=18)


def zap(s: Sound) -> None:
    s.noise(0, 0.4, 0.7, low=0.9, high=0.6, attack=0.001, decay=7, tremolo=45)
    s.tone(0, 0.35, 120, 95, "saw", 0.25, attack=0.001, decay=8, vibrato=30)


def laser_beam(s: Sound) -> None:
    s.tone(0, 0.45, 1400, 300, "saw", 0.3, attack=0.002, decay=5)
    s.tone(0, 0.45, 700, 150, "square", 0.12, attack=0.002, decay=6)
    s.noise(0, 0.08, 0.4, low=0.9, high=0.7, attack=0.001, decay=40)


def elite_arrive(s: Sound) -> None:
    # A bright shimmer with a low swell under it: a tougher foe has come.
    for i, f in enumerate((1320, 1760, 2200)):
        s.tone(i * 0.05, 0.4, f, f * 1.02, "sine", 0.15, attack=0.01, decay=6, vibrato=11)
    s.tone(0, 0.5, 110, 140, "triangle", 0.4, attack=0.06, decay=4)


def body_slam(s: Sound) -> None:
    # A whole person hitting the street: a chest-deep boom, the dull smack of
    # a body on concrete, a short bounce, then grit settling.
    s.tone(0, 0.5, 68, 30, "sine", 1.0, attack=0.001, decay=6)
    s.noise(0, 0.36, 0.9, low=0.12, low_end=0.03, attack=0.001, decay=9)
    s.noise(0, 0.05, 0.45, low=0.8, high=0.5, attack=0.0005, decay=60)
    s.tone(0.1, 0.12, 62, 40, "sine", 0.35, attack=0.002, decay=25)
    s.noise(0.06, 0.32, 0.22, low=0.45, high=0.3, attack=0.01, decay=10)


def _step(s: Sound, low: float, pitch: float) -> None:
    # A soft footfall: a muffled heel thump and a whisper of grit underfoot.
    s.tone(0, 0.06, pitch, pitch * 0.6, "sine", 0.5, attack=0.002, decay=45)
    s.noise(0, 0.07, 0.5, low=low, low_end=0.05, attack=0.002, decay=40)
    s.noise(0.008, 0.03, 0.12, low=0.7, high=0.5, attack=0.001, decay=90)


def step_1(s: Sound) -> None:
    _step(s, 0.18, 100)


def step_2(s: Sound) -> None:
    _step(s, 0.15, 88)


# id -> (painter, seconds[, level]): level is the peak each is normalised to
# (0.85 when left out).
SOUNDS = {
    "swing_light": (swing_light, 0.14),
    "swing_heavy": (swing_heavy, 0.26),
    "hit_light": (hit_light, 0.12),
    "hit_heavy": (hit_heavy, 0.24),
    "hit_block": (hit_block, 0.2),
    "guard_break": (guard_break, 0.34),
    "hero_hurt": (hero_hurt, 0.22),
    "knockdown": (knockdown, 0.3),
    "ko": (ko, 0.45),
    "dodge": (dodge, 0.16),
    "skill_uppercut": (skill_uppercut, 0.32),
    "skill_whirlwind": (skill_whirlwind, 0.48),
    "skill_rush": (skill_rush, 0.36),
    "skill_slam": (skill_slam, 0.8),
    "level_up": (level_up, 0.85, 0.6),
    "coin": (coin, 0.15, 0.35),
    "pickup": (pickup, 0.1, 0.4),
    "heal": (heal, 0.5),
    "quest": (quest, 0.8),
    "ui_move": (ui_move, 0.04),
    "ui_select": (ui_select, 0.09),
    "ui_back": (ui_back, 0.09),
    "denied": (denied, 0.18),
    "boss_roar": (boss_roar, 0.95),
    "arena_lock": (arena_lock, 0.38),
    "weapon_grab": (weapon_grab, 0.16),
    "weapon_drop": (weapon_drop, 0.22),
    "break_glass": (break_glass, 0.4),
    "break_wood": (break_wood, 0.32),
    "break_metal": (break_metal, 0.5),
    "hazard_warn": (hazard_warn, 0.25, 0.5),
    "steam_hiss": (steam_hiss, 0.56, 0.6),
    "zap": (zap, 0.42, 0.7),
    "laser_beam": (laser_beam, 0.46, 0.7),
    "elite_arrive": (elite_arrive, 0.52, 0.6),
    "body_slam": (body_slam, 0.55),
    "step_1": (step_1, 0.08, 0.3),
    "step_2": (step_2, 0.08, 0.3),
}


def render(sound_id: str) -> bytes:
    painter, seconds, *level = SOUNDS[sound_id]
    sound = Sound(seconds, seed=sum(map(ord, sound_id)), level=level[0] if level else 0.85)
    painter(sound)
    return sound.to_wav()


def main() -> int:
    OUT.mkdir(parents=True, exist_ok=True)
    files = {}
    for sound_id in SOUNDS:
        (OUT / f"{sound_id}.wav").write_bytes(render(sound_id))
        files[sound_id] = f"res://assets/audio/{sound_id}.wav"
    manifest = json.loads(MANIFEST.read_text())
    # Recorded sounds (tools/assets/import_sounds.py) keep their entries.
    old = manifest.get("audio", {})
    recorded = old.get("recorded", {})
    for sound_id in recorded:
        files[sound_id] = old["sounds"][sound_id]
    manifest["audio"] = {
        "license": "MIT (original sounds synthesised by tools/assets/gen_sfx.py)",
        "sounds": files,
        "recorded": recorded,
    }
    MANIFEST.write_text(json.dumps(manifest, indent=2, sort_keys=True) + "\n")
    print(f"wrote {len(files)} sounds")
    return 0


if __name__ == "__main__":
    sys.exit(main())
