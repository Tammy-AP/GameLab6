"""
Builds Assets/Characters/player.glb - a low-poly cartoon character with a
Mixamo-style skeleton (bone names "mixamorig_*"), skinned mesh, a drawn face
texture and one "TPose" animation (Godot needs one to create an AnimationPlayer).

The bone names match "Mixamo BoneMap.tres" from Godot4-OpenAnimationLibraries,
so MeleeLib.res / ShooterLib.res can be retargeted onto it in Godot.

Run:  python Tools/build_character.py
"""
import json
import math
import os
import struct
from io import BytesIO

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT_GLB = os.path.join(ROOT, "Assets", "Characters", "player.glb")
OUT_FACE = os.path.join(ROOT, "Assets", "Characters", "face_texture.png")

P = "mixamorig_"

# ------------------------------------------------------------------ colours

def srgb(r, g, b, a=255):
    """sRGB 0-255 -> linear 0-1 (glTF baseColorFactor is linear)."""
    def lin(c):
        c /= 255.0
        return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4
    return [lin(r), lin(g), lin(b), a / 255.0]


SKIN_RGB = (244, 200, 162)
HAIR_RGB = (52, 38, 44)
MATERIALS = {
    "Skin":  dict(color=srgb(*SKIN_RGB), rough=0.75),
    "Face":  dict(color=[1, 1, 1, 1], rough=0.75, texture=True),
    "Hair":  dict(color=srgb(*HAIR_RGB), rough=0.6, double=True),
    "Shirt": dict(color=srgb(46, 184, 189), rough=0.85),
    "Scarf": dict(color=srgb(255, 107, 92), rough=0.85),
    "Pants": dict(color=srgb(44, 52, 78), rough=0.9),
    "Shoes": dict(color=srgb(250, 236, 208), rough=0.7),
    "Sole":  dict(color=srgb(255, 107, 92), rough=0.8),
    "Belt":  dict(color=srgb(34, 32, 40), rough=0.6),
    "Gold":  dict(color=srgb(255, 200, 70), rough=0.35, metal=0.6),
}

# ------------------------------------------------------------------ skeleton (T-pose, facing +Z, left = +X)

BONES = []          # [name, parent_name, global_pos]
BONE_INDEX = {}


def bone(name, parent, pos):
    BONE_INDEX[P + name] = len(BONES)
    BONES.append([P + name, (P + parent) if parent else None, np.array(pos, float)])


bone("Hips", None, (0, 0.93, 0))
bone("Spine", "Hips", (0, 1.01, 0))
bone("Spine1", "Spine", (0, 1.10, 0))
bone("Spine2", "Spine1", (0, 1.20, 0))
bone("Neck", "Spine2", (0, 1.36, -0.01))
bone("Head", "Neck", (0, 1.44, 0))
bone("HeadTop_End", "Head", (0, 1.80, 0))

FINGERS = {  # name: (z offset at knuckle, segment lengths)
    "Index": (0.027, (0.032, 0.022, 0.018)),
    "Middle": (0.009, (0.035, 0.024, 0.019)),
    "Ring": (-0.009, (0.032, 0.022, 0.018)),
    "Pinky": (-0.026, (0.026, 0.018, 0.015)),
}
THUMB = [(0.670, 1.302, 0.020), (0.695, 1.298, 0.045), (0.718, 1.297, 0.062), (0.738, 1.297, 0.074)]
KNUCKLE_X = 0.735
ARM_Y = 1.31
ARM_Z = -0.01

for side, s in (("Left", 1), ("Right", -1)):
    bone(side + "Shoulder", "Spine2", (s * 0.05, ARM_Y, ARM_Z))
    bone(side + "Arm", side + "Shoulder", (s * 0.185, ARM_Y, ARM_Z))
    bone(side + "ForeArm", side + "Arm", (s * 0.43, ARM_Y, ARM_Z))
    bone(side + "Hand", side + "ForeArm", (s * 0.655, ARM_Y, ARM_Z))
    for i, t in enumerate(THUMB):
        parent = side + "Hand" if i == 0 else side + "HandThumb%d" % i
        bone(side + "HandThumb%d" % (i + 1), parent, (s * t[0], t[1], t[2] + ARM_Z))
    for f, (z, lens) in FINGERS.items():
        x = KNUCKLE_X
        bone(side + "Hand%s1" % f, side + "Hand", (s * x, ARM_Y, z + ARM_Z))
        for i, ln in enumerate(lens):
            x += ln
            bone(side + "Hand%s%d" % (f, i + 2), side + "Hand%s%d" % (f, i + 1), (s * x, ARM_Y, z + ARM_Z))
    bone(side + "UpLeg", "Hips", (s * 0.095, 0.90, 0))
    bone(side + "Leg", side + "UpLeg", (s * 0.095, 0.50, 0.01))
    bone(side + "Foot", side + "Leg", (s * 0.095, 0.095, -0.01))
    bone(side + "ToeBase", side + "Foot", (s * 0.095, 0.02, 0.10))
    bone(side + "Toe_End", side + "ToeBase", (s * 0.095, 0.02, 0.18))


def bpos(name):
    return BONES[BONE_INDEX[P + name]][2]


# ------------------------------------------------------------------ mesh building

class Part:
    def __init__(self, mat):
        self.mat = mat
        self.pos, self.uv, self.w, self.ref, self.tri = [], [], [], [], []
        self.fixed_normals = None

    def add(self, p, weights, ref, uv=(0.0, 0.0)):
        self.pos.append(np.array(p, float))
        self.w.append(dict(weights))
        self.ref.append(np.array(ref, float))
        self.uv.append(uv)
        return len(self.pos) - 1

    def finish(self, smooth=True):
        """Make every triangle face outward (along ref), then compute normals."""
        P_ = np.array(self.pos)
        fixed = []
        for a, b, c in self.tri:
            n = np.cross(P_[b] - P_[a], P_[c] - P_[a])
            r = self.ref[a] + self.ref[b] + self.ref[c]
            fixed.append((a, c, b) if np.dot(n, r) < 0 else (a, b, c))
        self.tri = fixed
        if self.fixed_normals is not None:
            return
        N = np.zeros_like(P_)
        for a, b, c in self.tri:
            n = np.cross(P_[b] - P_[a], P_[c] - P_[a])
            N[a] += n
            N[b] += n
            N[c] += n
        ln = np.linalg.norm(N, axis=1, keepdims=True)
        ln[ln == 0] = 1
        self.normals = N / ln


PARTS = []


def W(*pairs):
    """W('Hips', 0.5, 'Spine', 0.5) -> {'mixamorig_Hips': .5, ...}"""
    return {P + pairs[i]: pairs[i + 1] for i in range(0, len(pairs), 2)}


def _unit(v):
    v = np.array(v, float)
    return v / np.linalg.norm(v)


def _basis(axis):
    a = _unit(axis)
    helper = np.array([0, 0, 1.0]) if abs(a[2]) < 0.9 else np.array([1.0, 0, 0])
    e1 = _unit(np.cross(a, helper))
    e2 = np.cross(a, e1)
    return e1, e2


def tube(mat, rings, nseg=10, cap0=0.7, cap1=0.7, capsteps=3, e1=None, e2=None, phase=0.0):
    """rings: list of (center, r1, r2, weights). cap = bulge of the rounded end (0 = flat)."""
    part = Part(mat)
    centers = [np.array(r[0], float) for r in rings]
    axis = centers[-1] - centers[0]
    if e1 is None:
        e1, e2 = _basis(axis)
    e1, e2 = np.array(e1, float), np.array(e2, float)

    def ring(c, r1, r2, w, push_dir=None, push=0.0):
        ids = []
        for k in range(nseg):
            t = 2 * math.pi * k / nseg + phase
            d = math.cos(t) * e1 * r1 + math.sin(t) * e2 * r2
            ref = d.copy()
            if push_dir is not None:
                ref = ref + push_dir * push
            ids.append(part.add(c + d, w, ref))
        return ids

    all_rings = [ring(c, r1, r2, w) for (c, r1, r2, w), c in zip(rings, centers)]

    def connect(ra, rb):
        for k in range(nseg):
            a, b = ra[k], ra[(k + 1) % nseg]
            c, d = rb[k], rb[(k + 1) % nseg]
            part.tri += [(a, b, d), (a, d, c)]

    for i in range(len(all_rings) - 1):
        connect(all_rings[i], all_rings[i + 1])

    def cap(end_idx, bulge, outward):
        c0, r1, r2, w = rings[end_idx]
        c0 = np.array(c0, float)
        prev = all_rings[end_idx]
        rmean = (r1 + r2) * 0.5
        if bulge <= 0:
            pole = part.add(c0, w, outward)
            for k in range(nseg):
                part.tri.append((pole, prev[k], prev[(k + 1) % nseg]))
            return
        for i in range(1, capsteps):
            ang = (math.pi / 2) * i / capsteps
            cc = c0 + outward * rmean * bulge * math.sin(ang)
            nr = ring(cc, r1 * math.cos(ang), r2 * math.cos(ang), w, outward, math.sin(ang) * rmean)
            connect(prev, nr)
            prev = nr
        pole = part.add(c0 + outward * rmean * bulge, w, outward)
        for k in range(nseg):
            part.tri.append((pole, prev[k], prev[(k + 1) % nseg]))

    a = _unit(centers[1] - centers[0])
    b = _unit(centers[-1] - centers[-2])
    if cap0 is not None:
        cap(0, cap0, -a)
    if cap1 is not None:
        cap(len(rings) - 1, cap1, b)
    part.finish()
    PARTS.append(part)
    return part


def ellipsoid(mat, center, radii, weights, nseg=16, nring=10, theta_max=None, uv=False, squash_bottom=None):
    """UV ellipsoid. theta_max(phi) limits the polar angle (for the hair cap).
    phi = 0 faces +Z (front)."""
    part = Part(mat)
    c = np.array(center, float)
    rx, ry, rz = radii
    cols = nseg + 1 if uv else nseg
    grid = []
    for j in range(nring + 1):
        row = []
        for i in range(cols):
            phi = 2 * math.pi * i / nseg - math.pi  # -pi..pi, seam at the back
            tmax = math.pi if theta_max is None else theta_max(phi)
            th = tmax * j / nring
            d = np.array([math.sin(th) * math.sin(phi), math.cos(th), math.sin(th) * math.cos(phi)])
            p = c + d * np.array([rx, ry, rz])
            if squash_bottom is not None and p[1] < c[1]:
                p[1] = c[1] + (p[1] - c[1]) * squash_bottom
            u = i / nseg
            v = th / math.pi
            row.append(part.add(p, weights, d, (u, v)))
        grid.append(row)
    for j in range(nring):
        for i in range(cols if not uv else nseg):
            i2 = (i + 1) % cols if not uv else i + 1
            a, b, cc, d = grid[j][i], grid[j][i2], grid[j + 1][i], grid[j + 1][i2]
            if j == 0:
                part.tri.append((a, cc, d))
            elif j == nring - 1 and theta_max is None:
                part.tri.append((a, cc, b))
            else:
                part.tri += [(a, cc, d), (a, d, b)]
    if theta_max is None or uv:
        # analytic ellipsoid normals look smoother than averaged ones
        part.finish()
        N = []
        for pidx in range(len(part.pos)):
            q = (part.pos[pidx] - c) / np.array([rx, ry, rz]) ** 2
            N.append(_unit(q) if np.linalg.norm(q) > 0 else np.array([0, 1.0, 0]))
        part.normals = np.array(N)
        part.fixed_normals = True
    else:
        part.finish()
    PARTS.append(part)
    return part


def cone(mat, base, direction, radius, height, weights, nseg=6):
    part = Part(mat)
    base = np.array(base, float)
    a = _unit(direction)
    e1, e2 = _basis(a)
    ids = []
    for k in range(nseg):
        t = 2 * math.pi * k / nseg
        d = math.cos(t) * e1 * radius + math.sin(t) * e2 * radius
        ids.append(part.add(base + d, weights, d + a * radius * 0.3))
    tip = part.add(base + a * height, weights, a)
    bottom = part.add(base - a * 0.01, weights, -a)
    for k in range(nseg):
        part.tri.append((ids[k], ids[(k + 1) % nseg], tip))
        part.tri.append((ids[k], ids[(k + 1) % nseg], bottom))
    part.finish()
    PARTS.append(part)
    return part


# ------------------------------------------------------------------ body parts

# torso (shirt): smooth weights across the spine bones
torso_rings = [
    ((0, 0.885, 0.005), 0.175, 0.125, W("Hips", 1.0)),
    ((0, 0.95, 0.005), 0.170, 0.122, W("Hips", 0.6, "Spine", 0.4)),
    ((0, 1.03, 0.0), 0.162, 0.118, W("Spine", 0.8, "Hips", 0.2)),
    ((0, 1.11, 0.0), 0.170, 0.120, W("Spine", 0.5, "Spine1", 0.5)),
    ((0, 1.19, 0.0), 0.182, 0.125, W("Spine1", 0.5, "Spine2", 0.5)),
    ((0, 1.27, -0.005), 0.180, 0.122, W("Spine2", 1.0)),
    ((0, 1.33, -0.01), 0.150, 0.105, W("Spine2", 1.0)),
]
tube("Shirt", torso_rings, nseg=14, cap0=None, cap1=0.35, e1=(1, 0, 0), e2=(0, 0, 1))

# shirt hem (a slightly wider ring so the shirt reads as clothing)
tube("Shirt", [((0, 0.875, 0.005), 0.183, 0.132, W("Hips", 1.0)),
               ((0, 0.915, 0.005), 0.181, 0.130, W("Hips", 0.8, "Spine", 0.2))],
     nseg=14, cap0=0, cap1=0, e1=(1, 0, 0), e2=(0, 0, 1))

# pelvis / pants top
tube("Pants", [((0, 0.96, 0.0), 0.160, 0.115, W("Hips", 1.0)),
               ((0, 0.87, 0.0), 0.176, 0.126, W("Hips", 1.0)),
               ((0, 0.81, 0.0), 0.165, 0.118, W("Hips", 1.0)),
               ((0, 0.77, 0.0), 0.120, 0.095, W("Hips", 1.0))],
     nseg=14, cap0=0, cap1=0.3, e1=(1, 0, 0), e2=(0, 0, 1))

# belt + buckle
tube("Belt", [((0, 0.835, 0.003), 0.178, 0.128, W("Hips", 1.0)),
              ((0, 0.865, 0.003), 0.179, 0.129, W("Hips", 1.0))],
     nseg=14, cap0=0, cap1=0, e1=(1, 0, 0), e2=(0, 0, 1))
tube("Gold", [((0, 0.85, 0.128), 0.026, 0.020, W("Hips", 1.0)),
              ((0, 0.85, 0.140), 0.026, 0.020, W("Hips", 1.0))],
     nseg=4, cap0=0, cap1=0, e1=(1, 0, 0), e2=(0, 1, 0), phase=math.pi / 4)

# neck
tube("Skin", [((0, 1.30, -0.01), 0.055, 0.052, W("Spine2", 1.0)),
              ((0, 1.38, -0.01), 0.052, 0.050, W("Neck", 1.0)),
              ((0, 1.47, 0.0), 0.050, 0.048, W("Head", 1.0))],
     nseg=8, cap0=0, cap1=0)

# scarf ring + tail
scarf_ring = []
for k in range(13):
    t = 2 * math.pi * k / 12
    scarf_ring.append(np.array([math.sin(t) * 0.098, 1.345 - 0.012 * math.cos(t), math.cos(t) * 0.085 - 0.01]))
for k in range(12):
    a, b = scarf_ring[k], scarf_ring[k + 1]
    tube("Scarf", [(a, 0.04, 0.034, W("Spine2", 0.6, "Neck", 0.4)),
                   (b, 0.04, 0.034, W("Spine2", 0.6, "Neck", 0.4))],
         nseg=6, cap0=0.9, cap1=0.9, capsteps=2,
         e1=(0, 1, 0), e2=_unit(np.cross(b - a, (0, 1, 0))))
tube("Scarf", [((-0.06, 1.33, -0.085), 0.045, 0.014, W("Spine2", 1.0)),
               ((-0.075, 1.22, -0.13), 0.042, 0.013, W("Spine2", 1.0)),
               ((-0.085, 1.11, -0.15), 0.040, 0.012, W("Spine2", 0.6, "Spine1", 0.4))],
     nseg=6, cap0=0.3, cap1=0.3, capsteps=2, e1=(1, 0, 0), e2=(0, 0, 1))

# head (face texture) + ears
HEAD_C = (0, 1.60, 0.012)
ellipsoid("Face", HEAD_C, (0.185, 0.20, 0.178), W("Head", 1.0), nseg=24, nring=16, uv=True, squash_bottom=0.92)
for s in (1, -1):
    ellipsoid("Skin", (s * 0.183, 1.585, 0.0), (0.028, 0.044, 0.034), W("Head", 1.0), nseg=8, nring=5)


# hair cap: front fringe zig-zag, covers sides and back
def hair_theta(phi):
    front = math.cos(phi)               # 1 front, -1 back
    base = math.radians(92) - math.radians(34) * max(front, 0) ** 1.5 + math.radians(22) * max(-front, 0)
    if front > 0.35:                    # fringe spikes over the forehead
        zig = abs(((phi / (2 * math.pi / 9)) % 1.0) - 0.5) * 2
        base += math.radians(13) * (1 - zig)
    return base


ellipsoid("Hair", (0, 1.612, 0.008), (0.198, 0.214, 0.192), W("Head", 1.0), nseg=36, nring=8, theta_max=hair_theta)
# spiky tufts
for (ax, ay, az), (dx, dy, dz), r, h in [
    ((0.00, 1.80, -0.02), (0.0, 1.0, -0.35), 0.075, 0.11),
    ((0.08, 1.78, -0.06), (0.55, 0.8, -0.45), 0.065, 0.10),
    ((-0.08, 1.78, -0.06), (-0.55, 0.8, -0.45), 0.065, 0.10),
    ((0.00, 1.72, -0.15), (0.0, 0.45, -1.0), 0.07, 0.10),
    ((0.11, 1.68, -0.12), (0.6, 0.2, -0.8), 0.06, 0.08),
    ((-0.11, 1.68, -0.12), (-0.6, 0.2, -0.8), 0.06, 0.08),
    ((0.06, 1.79, 0.07), (0.35, 1.0, 0.55), 0.06, 0.085),
    ((-0.07, 1.785, 0.06), (-0.4, 1.0, 0.4), 0.055, 0.08),
]:
    cone("Hair", (ax, ay, az), (dx, dy, dz), r, h, W("Head", 1.0), nseg=6)

for side, s in (("Left", 1), ("Right", -1)):
    X = lambda x: s * x  # noqa: E731
    sh, arm, fore, hand = side + "Shoulder", side + "Arm", side + "ForeArm", side + "Hand"

    # shoulder ball + sleeve
    ellipsoid("Shirt", (X(0.175), ARM_Y + 0.005, ARM_Z), (0.075, 0.072, 0.072), W(arm, 0.75, sh, 0.25), nseg=10, nring=6)
    tube("Shirt", [((X(0.16), ARM_Y, ARM_Z), 0.070, 0.068, W(arm, 1.0)),
                   ((X(0.26), ARM_Y, ARM_Z), 0.066, 0.064, W(arm, 1.0)),
                   ((X(0.315), ARM_Y, ARM_Z), 0.064, 0.062, W(arm, 1.0))],
         nseg=10, cap0=0.3, cap1=0, e1=(0, 1, 0), e2=(0, 0, 1))

    # arm (skin) - smooth elbow
    tube("Skin", [((X(0.17), ARM_Y, ARM_Z), 0.052, 0.050, W(arm, 1.0)),
                  ((X(0.30), ARM_Y, ARM_Z), 0.048, 0.046, W(arm, 1.0)),
                  ((X(0.40), ARM_Y, ARM_Z), 0.044, 0.043, W(arm, 0.85, fore, 0.15)),
                  ((X(0.43), ARM_Y, ARM_Z), 0.043, 0.042, W(arm, 0.5, fore, 0.5)),
                  ((X(0.46), ARM_Y, ARM_Z), 0.043, 0.042, W(fore, 0.85, arm, 0.15)),
                  ((X(0.56), ARM_Y, ARM_Z), 0.040, 0.038, W(fore, 1.0)),
                  ((X(0.64), ARM_Y, ARM_Z), 0.033, 0.031, W(fore, 0.7, hand, 0.3))],
         nseg=10, cap0=0.4, cap1=0, e1=(0, 1, 0), e2=(0, 0, 1))

    # palm
    tube("Skin", [((X(0.635), ARM_Y, ARM_Z), 0.026, 0.040, W(hand, 1.0)),
                  ((X(0.69), ARM_Y + 0.002, ARM_Z), 0.030, 0.050, W(hand, 1.0)),
                  ((X(0.735), ARM_Y + 0.002, ARM_Z), 0.026, 0.048, W(hand, 1.0))],
         nseg=8, cap0=0.3, cap1=0.25, e1=(0, 1, 0), e2=(0, 0, 1), phase=math.pi / 8)

    # fingers: segment n is weighted to finger bone n
    for f, (z, lens) in FINGERS.items():
        x0 = KNUCKLE_X - 0.008
        xs = [x0, KNUCKLE_X + lens[0], KNUCKLE_X + lens[0] + lens[1], KNUCKLE_X + sum(lens) + 0.006]
        r = 0.0105 if f != "Pinky" else 0.009
        for i in range(3):
            tube("Skin", [((X(xs[i]), ARM_Y, z + ARM_Z), r, r, W(side + "Hand%s%d" % (f, i + 1), 1.0)),
                          ((X(xs[i + 1]), ARM_Y, z + ARM_Z), r * 0.95, r * 0.95, W(side + "Hand%s%d" % (f, i + 1), 1.0))],
                 nseg=6, cap0=0.8, cap1=0.8, capsteps=2, e1=(0, 1, 0), e2=(0, 0, 1))
    th = [np.array((X(t[0]), t[1], t[2] + ARM_Z)) for t in THUMB]
    for i in range(3):
        tube("Skin", [(th[i], 0.0135, 0.0135, W(side + "HandThumb%d" % (i + 1), 1.0)),
                      (th[i + 1], 0.012, 0.012, W(side + "HandThumb%d" % (i + 1), 1.0))],
             nseg=6, cap0=0.8, cap1=0.8, capsteps=2)

    # leg (pants) - smooth knee
    up, leg, foot, toe = side + "UpLeg", side + "Leg", side + "Foot", side + "ToeBase"
    tube("Pants", [((X(0.095), 0.875, 0.0), 0.079, 0.084, W(up, 1.0)),
                   ((X(0.095), 0.72, 0.004), 0.080, 0.082, W(up, 1.0)),
                   ((X(0.095), 0.545, 0.009), 0.068, 0.070, W(up, 0.8, leg, 0.2)),
                   ((X(0.095), 0.50, 0.010), 0.066, 0.068, W(up, 0.5, leg, 0.5)),
                   ((X(0.095), 0.455, 0.008), 0.066, 0.068, W(leg, 0.8, up, 0.2)),
                   ((X(0.095), 0.30, 0.0), 0.064, 0.066, W(leg, 1.0)),
                   ((X(0.095), 0.15, -0.008), 0.060, 0.062, W(leg, 1.0)),
                   ((X(0.095), 0.12, -0.01), 0.064, 0.066, W(leg, 1.0))],
         nseg=10, cap0=0.4, cap1=0, e1=(1, 0, 0), e2=(0, 0, 1))

    # shoe: rings along +Z, heel weighted to Foot, front to ToeBase
    def fw(z):
        t = min(max((z - 0.06) / 0.05, 0.0), 1.0)
        return W(foot, 1 - t, toe, t) if 0 < t < 1 else (W(foot, 1.0) if t == 0 else W(toe, 1.0))
    shoe = []
    for z, half_w, half_h, cy in [(-0.06, 0.050, 0.060, 0.072), (-0.02, 0.056, 0.068, 0.070),
                                  (0.04, 0.058, 0.060, 0.062), (0.10, 0.058, 0.048, 0.050),
                                  (0.15, 0.052, 0.040, 0.042)]:
        shoe.append(((X(0.095), cy, z), half_w, half_h, fw(z)))
    tube("Shoes", shoe, nseg=10, cap0=0.5, cap1=0.9, e1=(1, 0, 0), e2=(0, 1, 0))
    tube("Sole", [((X(0.095), 0.012, -0.075), 0.054, 0.012, W(foot, 1.0)),
                  ((X(0.095), 0.012, 0.05), 0.060, 0.012, fw(0.05)),
                  ((X(0.095), 0.012, 0.17), 0.052, 0.012, W(toe, 1.0))],
         nseg=8, cap0=0.6, cap1=0.9, e1=(1, 0, 0), e2=(0, 1, 0))


# ------------------------------------------------------------------ face texture (drawn, 1024x512 equirect)

def draw_face(path):
    S = 2  # supersample
    w, h = 1024 * S, 512 * S
    img = Image.new("RGBA", (w, h), SKIN_RGB + (255,))
    d = ImageDraw.Draw(img)

    def E(cx, cy, rx, ry, **kw):
        d.ellipse([(cx - rx) * S, (cy - ry) * S, (cx + rx) * S, (cy + ry) * S], **kw)

    cx = 512  # u = 0.5 is the front of the head
    eye_y, eye_dx = 266, 64
    # blush
    blush = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    bd = ImageDraw.Draw(blush)
    for s in (-1, 1):
        x = cx + s * 104
        bd.ellipse([(x - 26) * S, (306 - 12) * S, (x + 26) * S, (306 + 12) * S], fill=(255, 120, 130, 120))
    blush = blush.filter(ImageFilter.GaussianBlur(6 * S))
    img = Image.alpha_composite(img, blush)
    d = ImageDraw.Draw(img)
    for s in (-1, 1):
        x = cx + s * eye_dx
        # eye white + dark eye + iris + highlights
        E(x, eye_y, 21, 29, fill=(255, 255, 255, 255))
        E(x, eye_y + 2, 18, 26, fill=(38, 28, 36, 255))
        E(x, eye_y + 9, 12, 15, fill=(70, 120, 150, 255))
        E(x, eye_y + 11, 7, 9, fill=(30, 22, 30, 255))
        E(x + 6, eye_y - 9, 7, 7, fill=(255, 255, 255, 255))
        E(x - 6, eye_y + 13, 3.5, 3.5, fill=(255, 255, 255, 230))
        # lash line
        d.arc([(x - 24) * S, (eye_y - 33) * S, (x + 24) * S, (eye_y + 25) * S], 200, 340,
              fill=(38, 28, 36, 255), width=6 * S)
        # eyebrow
        d.arc([(x - 26) * S, (eye_y - 64) * S, (x + 26) * S, (eye_y - 24) * S], 215 if s < 0 else 205,
              335 if s < 0 else 325, fill=HAIR_RGB + (255,), width=8 * S)
    # nose
    E(cx, 300, 5, 3.5, fill=(222, 160, 130, 255))
    # open smile
    d.chord([(cx - 22) * S, (304) * S, (cx + 22) * S, (346) * S], 0, 180, fill=(150, 45, 60, 255))
    d.chord([(cx - 13) * S, (322) * S, (cx + 13) * S, (348) * S], 200, 340, fill=(240, 120, 130, 255))
    d.line([(cx - 22) * S, 325 * S, (cx + 22) * S, 325 * S], fill=(150, 45, 60, 255), width=2 * S)
    img = img.resize((1024, 512), Image.LANCZOS).convert("RGB")
    img.save(path)
    buf = BytesIO()
    img.save(buf, "PNG")
    return buf.getvalue()


# ------------------------------------------------------------------ glTF writer

def build_glb():
    face_png = draw_face(OUT_FACE)
    bin_data = bytearray()
    buffer_views, accessors = [], []

    def add_view(data, target=None):
        while len(bin_data) % 4:
            bin_data.append(0)
        view = {"buffer": 0, "byteOffset": len(bin_data), "byteLength": len(data)}
        if target:
            view["target"] = target
        bin_data.extend(data)
        buffer_views.append(view)
        return len(buffer_views) - 1

    def add_accessor(arr, comp, typ, target=None, minmax=False):
        arr = np.ascontiguousarray(arr)
        view = add_view(arr.tobytes(), target)
        acc = {"bufferView": view, "componentType": comp, "count": int(arr.shape[0]), "type": typ}
        if minmax:
            acc["min"] = arr.min(axis=0).tolist()
            acc["max"] = arr.max(axis=0).tolist()
        accessors.append(acc)
        return len(accessors) - 1

    # materials
    mat_names = list(MATERIALS)
    materials = []
    for name in mat_names:
        m = MATERIALS[name]
        pbr = {"baseColorFactor": m["color"], "metallicFactor": m.get("metal", 0.0), "roughnessFactor": m["rough"]}
        if m.get("texture"):
            pbr["baseColorTexture"] = {"index": 0}
        mat = {"name": name, "pbrMetallicRoughness": pbr}
        if m.get("double"):
            mat["doubleSided"] = True
        materials.append(mat)

    # primitives: one per material
    primitives = []
    for mi, name in enumerate(mat_names):
        parts = [p for p in PARTS if p.mat == name]
        if not parts:
            continue
        pos, nrm, uv, jnt, wgt, idx = [], [], [], [], [], []
        base = 0
        for part in parts:
            for vi, p in enumerate(part.pos):
                pos.append(p)
                nrm.append(part.normals[vi])
                uv.append(part.uv[vi])
                items = sorted(part.w[vi].items(), key=lambda kv: -kv[1])[:4]
                total = sum(v for _, v in items)
                j4, w4 = [0, 0, 0, 0], [0.0, 0.0, 0.0, 0.0]
                for k, (bn, bw) in enumerate(items):
                    j4[k] = BONE_INDEX[bn]
                    w4[k] = bw / total
                jnt.append(j4)
                wgt.append(w4)
            for t in part.tri:
                idx.append([t[0] + base, t[1] + base, t[2] + base])
            base += len(part.pos)
        attrs = {
            "POSITION": add_accessor(np.array(pos, np.float32), 5126, "VEC3", 34962, True),
            "NORMAL": add_accessor(np.array(nrm, np.float32), 5126, "VEC3", 34962),
            "TEXCOORD_0": add_accessor(np.array(uv, np.float32), 5126, "VEC2", 34962),
            "JOINTS_0": add_accessor(np.array(jnt, np.uint16), 5123, "VEC4", 34962),
            "WEIGHTS_0": add_accessor(np.array(wgt, np.float32), 5126, "VEC4", 34962),
        }
        ind = add_accessor(np.array(idx, np.uint32).reshape(-1), 5125, "SCALAR", 34963)
        primitives.append({"attributes": attrs, "indices": ind, "material": mi})

    # nodes: 0 = Armature, 1..N = bones, N+1 = mesh
    nodes = [{"name": "Armature", "children": [1, len(BONES) + 1]}]
    for i, (name, parent, gpos) in enumerate(BONES):
        local = gpos - (BONES[BONE_INDEX[parent]][2] if parent else np.zeros(3))
        node = {"name": name, "translation": [round(float(v), 6) for v in local]}
        kids = [j + 1 for j, b in enumerate(BONES) if b[1] == name]
        if kids:
            node["children"] = kids
        nodes.append(node)
    nodes.append({"name": "Body", "mesh": 0, "skin": 0})

    ibm = []
    for _, _, g in BONES:
        m = np.identity(4, np.float32)
        m[:3, 3] = -g
        ibm.append(m.T.reshape(-1))  # column-major
    ibm_acc = add_accessor(np.array(ibm, np.float32), 5126, "MAT4")

    # one short "TPose" animation (rest pose) so Godot creates an AnimationPlayer
    t_acc = add_accessor(np.array([[0.0], [0.5]], np.float32), 5126, "SCALAR", minmax=True)
    hips = BONES[0][2]
    v_acc = add_accessor(np.array([hips, hips], np.float32), 5126, "VEC3")

    img_view = add_view(face_png)

    gltf = {
        "asset": {"version": "2.0", "generator": "GameLab6 build_character.py"},
        "scene": 0,
        "scenes": [{"name": "Scene", "nodes": [0]}],
        "nodes": nodes,
        "meshes": [{"name": "Body", "primitives": primitives}],
        "skins": [{"name": "Armature", "inverseBindMatrices": ibm_acc,
                   "joints": list(range(1, len(BONES) + 1)), "skeleton": 1}],
        "materials": materials,
        "textures": [{"source": 0, "sampler": 0}],
        "samplers": [{"magFilter": 9729, "minFilter": 9987, "wrapS": 10497, "wrapT": 33071}],
        "images": [{"name": "face_texture", "bufferView": img_view, "mimeType": "image/png"}],
        "animations": [{"name": "TPose",
                        "channels": [{"sampler": 0, "target": {"node": 1, "path": "translation"}}],
                        "samplers": [{"input": t_acc, "output": v_acc, "interpolation": "LINEAR"}]}],
        "accessors": accessors,
        "bufferViews": buffer_views,
        "buffers": [{"byteLength": len(bin_data)}],
    }
    js = json.dumps(gltf, separators=(",", ":")).encode()
    js += b" " * ((4 - len(js) % 4) % 4)
    while len(bin_data) % 4:
        bin_data.append(0)
    out = bytearray()
    out += struct.pack("<III", 0x46546C67, 2, 12 + 8 + len(js) + 8 + len(bin_data))
    out += struct.pack("<II", len(js), 0x4E4F534A) + js
    out += struct.pack("<II", len(bin_data), 0x004E4942) + bin_data
    os.makedirs(os.path.dirname(OUT_GLB), exist_ok=True)
    with open(OUT_GLB, "wb") as f:
        f.write(out)
    nv = sum(len(p.pos) for p in PARTS)
    nt = sum(len(p.tri) for p in PARTS)
    print("wrote", OUT_GLB, "bones=%d verts=%d tris=%d size=%.0fKB" % (len(BONES), nv, nt, len(out) / 1024))


if __name__ == "__main__":
    build_glb()
