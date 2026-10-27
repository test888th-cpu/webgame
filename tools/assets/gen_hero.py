#!/usr/bin/env python3
"""Generates Riku, the boxer hero: an original character drawn by code.

  python3 tools/assets/gen_hero.py

A street boxer in a premium streetwear set: white snapback with a hot-pink
brim and a gold badge, an oversized hot-pink bomber over a white tee with a
gold chain, charcoal joggers with a white side stripe, chunky white sneakers
and fingerless gloves.

How it is drawn: a 2D skeleton (hips, torso, head, two arms, two legs) is
posed for every frame by joint angles; each body part and garment is then
rasterised from that pose at SS times the game's resolution with cel shading
(a light from the upper left), sampled down to one colour per pixel, and
given its face and a dark outline at the game's resolution. Every animation
is a list of poses, so the character stays the same in every frame and new
moves are a few numbers. Deterministic: the same script draws the same
pixels, and validate.py checks the committed sheet against it.

Writes client/assets/characters/hero_riku/ (sheet, hand sheet, credits) and
the manifest entry, with the weapon hand sockets taken straight from the
skeleton; make_spriteframes.py then builds the SpriteFrames.
"""

from __future__ import annotations

import json
import math
import sys
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).parent))
import custom_import  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
ASSET_ID = "hero_riku"
OUT = ROOT / "client" / "assets" / "characters" / ASSET_ID
MANIFEST = ROOT / "client" / "assets" / "manifest.json"

FRAME = (80, 80)
FEET = (40, 77)
SS = 4
PORTRAIT = 26

# Bone lengths and the body's proportions, in game pixels.
TORSO = 17.0
NECK = 6.6
UPPER_ARM = 8.0
FOREARM = 7.6
THIGH = 10.4
SHIN = 10.0
HEAD_RX, HEAD_RY = 6.2, 6.7

OUTLINE = (24, 20, 28, 255)


def ramp(*hexes: str) -> list[tuple[int, int, int, int]]:
    """Light, base, shadow, deep."""
    return [tuple(int(h[i : i + 2], 16) for i in (1, 3, 5)) + (255,) for h in hexes]


SKIN = ramp("#f4c69c", "#d9986b", "#b0704c", "#7e4a34")
HAIR = ramp("#3a3448", "#26222f", "#1a1722", "#120f18")
PINK = ramp("#ff7ab8", "#f2337f", "#bf1f63", "#86144a")
RIB = ramp("#ffffff", "#ece8f0", "#c4bfcc", "#8e8898")
TEE = ramp("#ffffff", "#eeeef2", "#c9c9d3", "#9898a6")
PANTS = ramp("#5c6072", "#40434f", "#2d2f39", "#1f2028")
SHOE = ramp("#ffffff", "#ececf2", "#c4c4d0", "#8a8a9a")
SOLE = ramp("#d8d8e2", "#b6b6c4", "#8e8e9e", "#62626e")
CAP = ramp("#ffffff", "#ecebf2", "#c6c3d2", "#8c889c")
GLOVE = ramp("#4a4458", "#2c2836", "#1e1b26", "#141119")
GOLD = ramp("#fff1a0", "#f2c14a", "#c48a24", "#8a5a14")
EYE = (24, 20, 28, 255)
WHITE = (250, 250, 252, 255)
LIGHT = (-0.55, -0.62, 0.56)


def darker(colors: list) -> list:
    """The far-side limbs: one step into the shade."""
    return [colors[min(i + 1, 3)] for i in range(4)]


class Canvas:
    """A supersampled painter's buffer of colours (None = empty)."""

    def __init__(self) -> None:
        self.w, self.h = FRAME[0] * SS, FRAME[1] * SS
        self.px: list = [None] * (self.w * self.h)

    def paint(self, box, inside, color) -> None:
        """For every hi-res pixel in `box` (game px), `inside(x, y)` returns
        (signed depth into the shape 0..1+, normal) or None; `color(depth,
        normal, x, y, under)` picks the colour."""
        x0 = max(0, int(box[0] * SS) - 1)
        y0 = max(0, int(box[1] * SS) - 1)
        x1 = min(self.w, int(box[2] * SS) + 2)
        y1 = min(self.h, int(box[3] * SS) + 2)
        for sy in range(y0, y1):
            y = (sy + 0.5) / SS
            row = sy * self.w
            for sx in range(x0, x1):
                x = (sx + 0.5) / SS
                hit = inside(x, y)
                if hit is None:
                    continue
                c = color(hit[0], hit[1], x, y, self.px[row + sx])
                if c is not None:
                    self.px[row + sx] = c

    def downsample(self) -> Image.Image:
        """One colour per game pixel: the most common, if the shape covers
        at least half of it."""
        image = Image.new("RGBA", FRAME, (0, 0, 0, 0))
        out = image.load()
        half = SS * SS // 2
        for y in range(FRAME[1]):
            for x in range(FRAME[0]):
                counts: dict = {}
                for sy in range(y * SS, y * SS + SS):
                    row = sy * self.w
                    for sx in range(x * SS, x * SS + SS):
                        c = self.px[row + sx]
                        if c is not None:
                            counts[c] = counts.get(c, 0) + 1
                if sum(counts.values()) >= half:
                    out[x, y] = max(counts.items(), key=lambda kv: (kv[1], -sum(kv[0][:3])))[0]
        return image


def shade(colors: list, normal: tuple[float, float, float], edge: bool) -> tuple:
    if edge:
        return colors[3]
    light = normal[0] * LIGHT[0] + normal[1] * LIGHT[1] + normal[2] * LIGHT[2]
    if light > 0.78:
        return colors[0]
    if light > 0.3:
        return colors[1]
    return colors[2]


# Game px of darker rim where a part lies over another.
EDGE = 0.9


def capsule(cv: Canvas, a, b, ra: float, rb: float, colors: list) -> None:
    """A tapered limb from a (radius ra) to b (radius rb), shaded as a
    cylinder; its rim darkens where it lies over something drawn before."""
    dx, dy = b[0] - a[0], b[1] - a[1]
    length2 = dx * dx + dy * dy or 1e-6
    r = max(ra, rb)
    box = (min(a[0], b[0]) - r, min(a[1], b[1]) - r, max(a[0], b[0]) + r, max(a[1], b[1]) + r)

    def inside(x, y):
        t = max(0.0, min(1.0, ((x - a[0]) * dx + (y - a[1]) * dy) / length2))
        rad = ra + (rb - ra) * t
        ox, oy = x - a[0] - dx * t, y - a[1] - dy * t
        d = math.hypot(ox, oy)
        if d > rad:
            return None
        nx, ny = ox / rad, oy / rad
        return (t, ((nx, ny, math.sqrt(max(0.0, 1 - nx * nx - ny * ny))), d > rad - EDGE))

    def color(t, hit, x, y, under):
        normal, rim = hit
        return shade(colors, normal, rim and under is not None)

    cv.paint(box, inside, color)


def ellipse(cv: Canvas, c, rx: float, ry: float, colors: list, keep=None, rim=True) -> None:
    """A shaded ellipse; `keep(x, y)` may clip it (False drops the pixel)."""

    def inside(x, y):
        ox, oy = (x - c[0]) / rx, (y - c[1]) / ry
        d2 = ox * ox + oy * oy
        if d2 > 1 or (keep and not keep(x, y)):
            return None
        nz = math.sqrt(max(0.0, 1 - d2))
        edge = math.sqrt(d2) > 1 - EDGE / max(rx, ry)
        return (0.0, ((ox, oy, nz), edge))

    def color(t, hit, x, y, under):
        normal, edge = hit
        return shade(colors, normal, edge and rim and under is not None)

    cv.paint((c[0] - rx, c[1] - ry, c[0] + rx, c[1] + ry), inside, color)


def polygon(cv: Canvas, points: list, colors_at) -> None:
    """A filled polygon; `colors_at(x, y, edge)` returns its colour."""
    xs = [p[0] for p in points]
    ys = [p[1] for p in points]
    segs = list(zip(points, points[1:] + points[:1]))

    def inside(x, y):
        hit = False
        for (x1, y1), (x2, y2) in segs:
            if (y1 > y) != (y2 > y) and x < (x2 - x1) * (y - y1) / (y2 - y1) + x1:
                hit = not hit
        if not hit:
            return None
        near = min(_seg_dist(x, y, s) for s in segs)
        return (near, None)

    def color(near, _n, x, y, under):
        return colors_at(x, y, near < EDGE and under is not None)

    cv.paint((min(xs), min(ys), max(xs), max(ys)), inside, color)


def _seg_dist(x, y, seg) -> float:
    (x1, y1), (x2, y2) = seg
    dx, dy = x2 - x1, y2 - y1
    t = max(0.0, min(1.0, ((x - x1) * dx + (y - y1) * dy) / ((dx * dx + dy * dy) or 1e-6)))
    return math.hypot(x - x1 - dx * t, y - y1 - dy * t)


# --- The skeleton -----------------------------------------------------------


def direction(degrees: float) -> tuple[float, float]:
    """0 points straight down, positive turns towards the front (right)."""
    a = math.radians(degrees)
    return (math.sin(a), math.cos(a))


def add(p, v, k=1.0):
    return (p[0] + v[0] * k, p[1] + v[1] * k)


STANCE = {
    "x": 0.0,
    "y": 0.0,
    "lean": 6.0,
    "head": 0.0,
    "front_arm": (40.0, 118.0),
    "back_arm": (22.0, 132.0),
    "front_leg": (20.0, -20.0, 0.0),
    "back_leg": (-16.0, -6.0, 0.0),
    "rot": 0.0,
    "lift": 0.0,
    # The back arm swings in front of the body (a cross).
    "cross": False,
}


def pose(**changes) -> dict:
    p = dict(STANCE)
    p.update(changes)
    return p


def skeleton(p: dict) -> dict:
    """Joint positions for pose `p`, standing on the ground line."""
    hip = (FEET[0] + p["x"], 52.0)
    up = (math.sin(math.radians(p["lean"])), -math.cos(math.radians(p["lean"])))
    front = (-up[1], up[0])
    neck = add(hip, up, TORSO)
    j = {"hip": hip, "neck": neck, "up": up, "front": front}
    tilt = p["lean"] + p["head"]
    hup = (math.sin(math.radians(tilt)), -math.cos(math.radians(tilt)))
    j["head"] = add(neck, hup, NECK)
    j["head_up"] = hup
    for side, k in (("front", 1.4), ("back", -1.6)):
        shoulder = add(add(neck, front, k), up, -1.8)
        sa, el = p[side + "_arm"]
        elbow = add(shoulder, direction(p["lean"] + sa), UPPER_ARM)
        fist = add(elbow, direction(p["lean"] + sa + el), FOREARM)
        j[side + "_arm"] = (shoulder, elbow, fist, p["lean"] + sa + el)
        hp = add(hip, front, k * 1.1)
        ha, kn, ft = p[side + "_leg"]
        knee = add(hp, direction(ha), THIGH)
        ankle = add(knee, direction(ha + kn), SHIN)
        j[side + "_leg"] = (hp, knee, ankle, ft)
    turn = p["rot"]
    if turn:
        pivot = FEET
        for key in ("hip", "neck", "head"):
            j[key] = rotate(j[key], pivot, turn)
        for key in ("front_arm", "back_arm"):
            s, e, f, a = j[key]
            j[key] = (rotate(s, pivot, turn), rotate(e, pivot, turn), rotate(f, pivot, turn), a - turn)
        for key in ("front_leg", "back_leg"):
            h, k_, a_, ft = j[key]
            j[key] = (rotate(h, pivot, turn), rotate(k_, pivot, turn), rotate(a_, pivot, turn), ft - turn)
        for key in ("up", "front", "head_up"):
            j[key] = rotate(j[key], (0, 0), turn)
        # Falling, the body turns about its middle, so it stays in the frame.
        mid = (j["head"][0] + j["front_leg"][2][0]) / 2
        j = move(j, (FEET[0] + p["x"] - mid, 0.0))
    # Stand on the ground: the lowest sole (or body, lying down) on the line.
    low = max(
        [j["front_leg"][2][1] + 2.6, j["back_leg"][2][1] + 2.6]
        + ([j["head"][1] + HEAD_RY, j["hip"][1] + 4, j["neck"][1] + 4] if turn else [])
    )
    shift = FEET[1] - low - p["lift"]
    return move(j, (0.0, shift))


def rotate(p, c, degrees):
    """Turn point p about c; positive tips the figure back (to the left)."""
    a = math.radians(-degrees)
    x, y = p[0] - c[0], p[1] - c[1]
    return (c[0] + x * math.cos(a) - y * math.sin(a), c[1] + x * math.sin(a) + y * math.cos(a))


def move(j: dict, v) -> dict:
    out = {}
    for key, value in j.items():
        if key in ("up", "front", "head_up"):
            out[key] = value
        elif key.endswith("_arm"):
            out[key] = tuple(add(q, v) for q in value[:3]) + (value[3],)
        elif key.endswith("_leg"):
            out[key] = tuple(add(q, v) for q in value[:3]) + (value[3],)
        else:
            out[key] = add(value, v)
    return out


# --- Drawing the character --------------------------------------------------


def draw_leg(cv: Canvas, leg, far: bool) -> None:
    hip, knee, ankle, foot = leg
    pants = darker(PANTS) if far else PANTS
    stripe = darker(RIB) if far else RIB
    capsule(cv, hip, knee, 3.6, 3.1, pants)
    capsule(cv, knee, ankle, 3.1, 2.5, pants)
    # The white side stripe down the outside of the leg.
    capsule(cv, add(hip, (0, 1)), knee, 0.55, 0.55, stripe)
    capsule(cv, knee, add(ankle, (0, -1.6)), 0.55, 0.5, stripe)
    draw_shoe(cv, ankle, foot, far)


def draw_shoe(cv: Canvas, ankle, foot_deg: float, far: bool) -> None:
    fwd = (math.cos(math.radians(foot_deg)), -math.sin(math.radians(foot_deg)))
    down = (-fwd[1], fwd[0])

    def at(f, d):
        return (ankle[0] + fwd[0] * f + down[0] * d, ankle[1] + fwd[1] * f + down[1] * d)

    upper = darker(SHOE) if far else SHOE
    sole = darker(SOLE) if far else SOLE
    accent = darker(PINK) if far else PINK
    body = [at(-2.6, -1.8), at(1.0, -2.2), at(3.8, -0.9), at(6.4, 0.6), at(6.6, 2.6), at(-3.4, 2.6), at(-3.5, 0.0)]

    def colour(x, y, edge):
        f = (x - ankle[0]) * fwd[0] + (y - ankle[1]) * fwd[1]
        d = (x - ankle[0]) * down[0] + (y - ankle[1]) * down[1]
        if edge:
            return upper[3]
        if d > 1.5:
            return sole[2] if d > 2.1 else sole[1]
        if -1.0 < f < 4.5 and 0.1 < d - f * 0.12 < 1.2:
            return accent[1]
        return upper[1] if d > -1.0 else upper[0]

    polygon(cv, body, colour)


def draw_arm(cv: Canvas, arm, far: bool) -> None:
    shoulder, elbow, fist, angle = arm
    sleeve = darker(PINK) if far else PINK
    rib = darker(RIB) if far else RIB
    to = (fist[0] - elbow[0], fist[1] - elbow[1])
    length = math.hypot(*to) or 1
    cuff = add(fist, to, -2.6 / length)
    capsule(cv, shoulder, elbow, 3.7, 3.3, sleeve)
    capsule(cv, elbow, cuff, 3.3, 3.0, sleeve)
    capsule(cv, cuff, add(cuff, to, 1.1 / length), 2.9, 2.8, rib)
    draw_fist(cv, fist, (to[0] / length, to[1] / length), far)


def draw_fist(cv: Canvas, fist, aim, far: bool) -> None:
    skin = darker(SKIN) if far else SKIN
    glove = GLOVE

    def inside(x, y):
        ox, oy = (x - fist[0]) / 2.6, (y - fist[1]) / 2.6
        d2 = ox * ox + oy * oy
        if d2 > 1:
            return None
        return (0.0, ((ox, oy, math.sqrt(1 - d2)), math.sqrt(d2) > 1 - EDGE / 2.6))

    def color(t, hit, x, y, under):
        normal, edge = hit
        knuckles = normal[0] * aim[0] + normal[1] * aim[1] > 0.3
        strap = abs(normal[0] * aim[0] + normal[1] * aim[1] + 0.15) < 0.12
        use = skin if knuckles else (PINK if strap else glove)
        return shade(use, normal, edge and under is not None)

    cv.paint((fist[0] - 2.6, fist[1] - 2.6, fist[0] + 2.6, fist[1] + 2.6), inside, color)


def draw_torso(cv: Canvas, j: dict) -> None:
    hip, neck, up, front = j["hip"], j["neck"], j["up"], j["front"]

    def at(base, f, u):
        return (base[0] + front[0] * f + up[0] * u, base[1] + front[1] * f + up[1] * u)

    outline = [
        at(hip, -7.2, -3.2),
        at(hip, 6.6, -3.2),
        at(hip, 7.6, 4.0),
        at(hip, 7.2, 12.0),
        at(neck, 5.6, -1.4),
        at(neck, 2.6, 0.9),
        at(neck, -3.2, 0.9),
        at(neck, -6.6, -1.6),
        at(hip, -8.0, 10.0),
    ]

    def colour(x, y, edge):
        f = (x - hip[0]) * front[0] + (y - hip[1]) * front[1]
        u = (x - hip[0]) * up[0] + (y - hip[1]) * up[1]
        s = max(-1.0, min(1.0, (f + 0.4) / 7.4))
        normal = (front[0] * s, front[1] * s, math.sqrt(max(0.0, 1 - s * s)))
        if u < -1.2:
            # Ribbed hem: white with a pink stripe.
            return shade(PINK if -2.6 < u < -1.9 else RIB, normal, edge)
        if u > TORSO - 1.6:
            return shade(RIB if u < TORSO - 0.6 else PINK, normal, edge)
        if f > 4.6 and u < TORSO - 2.4:
            # The open front shows the white tee.
            return shade(TEE, normal, edge)
        if 4.0 < f <= 4.6:
            return GOLD[1] if int(u * 2) % 2 == 0 else GOLD[2]
        return shade(PINK, normal, edge)

    polygon(cv, outline, colour)


def draw_head(cv: Canvas, j: dict) -> None:
    c, hup = j["head"], j["head_up"]
    hfront = (-hup[1], hup[0])
    neck_top = add(c, hup, -3.5)
    capsule(cv, j["neck"], neck_top, 2.3, 2.3, SKIN)

    def local(x, y):
        ox, oy = x - c[0], y - c[1]
        return (ox * hfront[0] + oy * hfront[1], ox * hup[0] + oy * hup[1])

    # Hair: the back of the head and the nape, under the cap.
    ellipse(cv, c, HEAD_RX, HEAD_RY, HAIR, keep=lambda x, y: local(x, y)[0] < -1.2)
    ellipse(cv, c, HEAD_RX, HEAD_RY, SKIN, keep=lambda x, y: local(x, y)[0] >= -1.2)
    # Sideburn.
    ellipse(cv, add(add(c, hfront, -0.6), hup, 0.4), 1.3, 2.4, HAIR, rim=False)
    # The cap's crown, a little larger than the head, above the brim line.
    ellipse(cv, add(c, hup, 0.4), HEAD_RX + 0.7, HEAD_RY + 0.4, CAP, keep=lambda x, y: local(x, y)[1] > 1.6)

    def at(f, u):
        return (c[0] + hfront[0] * f + hup[0] * u, c[1] + hfront[1] * f + hup[1] * u)

    brim = [at(HEAD_RX - 1.4, 2.4), at(HEAD_RX + 4.4, 1.9), at(HEAD_RX + 4.6, 1.0), at(HEAD_RX - 1.4, 1.0)]
    polygon(cv, brim, lambda x, y, edge: PINK[3] if edge else (PINK[0] if local(x, y)[1] > 1.9 else PINK[1]))
    # Gold badge on the crown.
    ellipse(cv, at(2.6, 4.0), 1.0, 1.0, GOLD, rim=False)


def draw_face(image: Image.Image, j: dict) -> None:
    """Eye, brow, nose, mouth and ear, at the game's resolution."""
    c, hup = j["head"], j["head_up"]
    hfront = (-hup[1], hup[0])
    px = image.load()

    def put(f, u, color, only_on=None):
        x = round(c[0] + hfront[0] * f + hup[0] * u - 0.5)
        y = round(c[1] + hfront[1] * f + hup[1] * u - 0.5)
        if 0 <= x < FRAME[0] and 0 <= y < FRAME[1] and px[x, y][3]:
            if only_on is None or px[x, y] in only_on:
                px[x, y] = color

    skin = set(SKIN)
    # Shadow of the brim across the brow.
    for f in (0.5, 1.5, 2.5, 3.5, 4.5):
        put(f, 0.6, SKIN[2], skin)
    put(2.6, -0.6, WHITE, skin)
    put(3.6, -0.6, EYE, skin)
    put(3.6, -1.6, EYE, skin)
    put(3.6, 0.5, HAIR[1], skin)
    put(2.6, 0.5, HAIR[1], skin)
    put(5.9, -2.0, SKIN[1])
    put(3.9, -3.7, SKIN[3], skin)
    put(-0.4, -1.0, SKIN[2], skin)
    put(-0.4, -2.0, SKIN[3], skin)


def outlined(image: Image.Image) -> Image.Image:
    return custom_import.outlined(image)


def draw(p: dict) -> tuple[Image.Image, tuple[int, int]]:
    """One frame for pose `p`, and where its front fist is."""
    j = skeleton(p)
    cv = Canvas()
    if not p["cross"]:
        draw_arm(cv, j["back_arm"], True)
    draw_leg(cv, j["back_leg"], True)
    draw_leg(cv, j["front_leg"], False)
    draw_torso(cv, j)
    draw_head(cv, j)
    draw_arm(cv, j["front_arm"], False)
    if p["cross"]:
        draw_arm(cv, j["back_arm"], False)
    image = cv.downsample()
    draw_face(image, j)
    fist = j["front_arm"][2]
    return outlined(image), (round(fist[0] - 0.5), round(fist[1] - 0.5))


# --- Animations -------------------------------------------------------------


def idle() -> list[dict]:
    frames = []
    for i in range(6):
        b = (1 - math.cos(i / 6 * math.tau)) / 2
        frames.append(
            pose(
                lift=-b * 0.8,
                lean=6 + b,
                front_arm=(40 - b * 3, 118 + b * 4),
                back_arm=(22 - b * 2, 132 + b * 3),
                front_leg=(20, -20 - b * 4, 0),
                back_leg=(-16, -6 - b * 4, 0),
            )
        )
    return frames


def walk() -> list[dict]:
    frames = []
    for i in range(8):
        a = i / 8 * math.tau
        s = math.sin(a)
        lift_front = max(0.0, math.cos(a))
        lift_back = max(0.0, -math.cos(a))
        frames.append(
            pose(
                lift=abs(math.cos(a)) * 0.8,
                lean=8,
                front_arm=(40 - s * 6, 118 + s * 4),
                back_arm=(22 + s * 6, 132 - s * 4),
                front_leg=(4 + 22 * s, -6 - 30 * lift_front, 0),
                back_leg=(4 - 22 * s, -6 - 30 * lift_back, 0),
            )
        )
    return frames


def light() -> list[dict]:
    return [
        pose(front_arm=(55, 95), lean=8),
        pose(front_arm=(78, 35), lean=11, x=1),
        pose(front_arm=(92, 4), lean=13, x=2, back_arm=(16, 140)),
        pose(front_arm=(93, 0), lean=13, x=2, back_arm=(16, 140)),
        pose(front_arm=(68, 60), lean=10, x=1),
        pose(front_arm=(45, 110), lean=7),
    ]


def heavy() -> list[dict]:
    return [
        pose(lean=-2, back_arm=(-10, 150), front_arm=(35, 120), back_leg=(-22, -8, 0)),
        pose(lean=0, back_arm=(-6, 150), front_arm=(30, 125), back_leg=(-24, -8, 0)),
        pose(lean=14, x=2, back_arm=(55, 50), front_arm=(20, 125), back_leg=(-30, 0, 0), cross=True),
        pose(lean=18, x=3, back_arm=(66, 6), front_arm=(14, 128), back_leg=(-34, 2, -10), cross=True),
        pose(lean=18, x=3, back_arm=(67, 0), front_arm=(14, 128), back_leg=(-34, 2, -10), cross=True),
        pose(lean=12, x=2, back_arm=(45, 80), front_arm=(30, 120), back_leg=(-26, -4, 0), cross=True),
        pose(lean=7, x=1),
    ]


def stab() -> list[dict]:
    return [
        pose(front_arm=(40, 70), lean=6),
        pose(front_arm=(55, 40), lean=9, x=1),
        pose(front_arm=(78, 6), lean=13, x=2),
        pose(front_arm=(80, 2), lean=13, x=2),
        pose(front_arm=(55, 50), lean=8, x=1),
    ]


def hurt() -> list[dict]:
    return [
        pose(lean=-14, head=-14, front_arm=(30, 70), back_arm=(-20, 60), x=-1),
        pose(lean=-10, head=-10, front_arm=(28, 80), back_arm=(-14, 80), x=-2),
        pose(lean=-4, head=-4, front_arm=(34, 100), back_arm=(8, 110), x=-2),
    ]


def down() -> list[dict]:
    lying = dict(front_arm=(150, 20), back_arm=(170, 10), front_leg=(20, -30, 0), back_leg=(8, -10, 0))
    return [
        pose(lean=-20, head=-16, front_arm=(40, 60), back_arm=(-30, 50), x=-2),
        pose(rot=40, head=-10, front_arm=(80, 40), back_arm=(30, 40), x=-3),
        pose(rot=78, head=-6, x=-4, **lying),
        pose(rot=90, x=-5, lift=1.5, **lying),
        pose(rot=90, x=-5, **lying),
        pose(rot=90, x=-5, **lying),
    ]


def dodge() -> list[dict]:
    duck = dict(front_leg=(34, -58, 0), back_leg=(-14, -52, 0), front_arm=(30, 140), back_arm=(14, 146))
    return [
        pose(lean=18, head=8, x=-1, **duck),
        pose(lean=30, head=10, x=-3, **duck),
        pose(lean=32, head=10, x=-4, **duck),
        pose(lean=22, head=6, x=-3, **duck),
        pose(lean=10, x=-1),
    ]


# Name -> (poses, fps, loop, weapon angle per frame or for all).
ANIMATIONS = {
    "idle": (idle, 8, True, 50),
    "walk": (walk, 12, True, 55),
    "light": (light, 16, False, [-30, 20, 80, 95, 60, 50]),
    "heavy": (heavy, 12, False, 30),
    "stab": (stab, 14, False, [60, 80, 90, 90, 80]),
    "hurt": (hurt, 10, False, 40),
    "down": (down, 10, False, 45),
    "dodge": (dodge, 12, False, 40),
}


def render() -> tuple[Image.Image, Image.Image, dict, dict, list[int]]:
    rows = [(name, [draw(p) for p in spec[0]()]) for name, spec in ANIMATIONS.items()]
    columns = max(len(frames) for _, frames in rows)
    sheet = Image.new("RGBA", (FRAME[0] * columns, FRAME[1] * len(rows)), (0, 0, 0, 0))
    hands_sheet = Image.new("RGBA", sheet.size, (0, 0, 0, 0))
    animations, hands = {}, {}
    for row, (name, frames) in enumerate(rows):
        _, fps, loop, angle = ANIMATIONS[name]
        angles = angle if isinstance(angle, list) else [angle] * len(frames)
        sockets = []
        for column, (image, fist) in enumerate(frames):
            at = (column * FRAME[0], row * FRAME[1])
            sheet.alpha_composite(image, at)
            for x, y in custom_import.fist_pixels(image, fist):
                hands_sheet.putpixel((at[0] + x, at[1] + y), image.getpixel((x, y)))
            sockets.append([fist[0], fist[1], angles[column]])
        hands[name] = sockets
        animations[name] = {"row": row, "frames": len(frames), "fps": fps, "loop": loop}
    portrait = custom_import.head_and_shoulders(rows[0][1][0][0], PORTRAIT)
    return sheet, hands_sheet, animations, hands, portrait


def manifest_entry(animations: dict, hands: dict, portrait: list[int]) -> dict:
    return {
        "animations": animations,
        "credits": f"res://assets/characters/{ASSET_ID}/credits.json",
        "facing": "right",
        "frame_size": list(FRAME),
        "generator": {"script": "tools/assets/gen_hero.py"},
        "hand_sheet": f"res://assets/characters/{ASSET_ID}/hands.png",
        "hands": hands,
        "licenses": ["MIT"],
        "origin": list(FEET),
        "portrait": portrait,
        "role": "hero",
        "sheet": f"res://assets/characters/{ASSET_ID}/sheet.png",
        "source": "original",
        "status": "imported",
    }


CREDITS = [
    {
        "file": "tools/assets/gen_hero.py",
        "authors": ["Ironbound Streets contributors"],
        "license": "MIT",
        "urls": [],
    }
]


def main() -> int:
    OUT.mkdir(parents=True, exist_ok=True)
    sheet, hands_sheet, animations, hands, portrait = render()
    sheet.save(OUT / "sheet.png", optimize=True)
    hands_sheet.save(OUT / "hands.png", optimize=True)
    (OUT / "credits.json").write_text(json.dumps(CREDITS, indent=2) + "\n")
    manifest = json.loads(MANIFEST.read_text())
    manifest["assets"][ASSET_ID] = manifest_entry(animations, hands, portrait)
    MANIFEST.write_text(json.dumps(manifest, indent=2, sort_keys=True) + "\n")
    print(f"wrote {ASSET_ID}: {', '.join(animations)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
