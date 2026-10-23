"""Poora mark: a P whose bowl is a completion ring that has just closed.

Coral stem (the action) + sage ring (the day) whose last segment is ice
(the moment it closes). Rendered at 4x and downsampled.
"""
import math
import sys
from PIL import Image, ImageDraw

OUT = sys.argv[1]
BG = (21, 21, 23)
SAGE = (198, 218, 210)
CORAL = (239, 120, 103)
ICE = (195, 231, 239)
SS = 4

STEM = (300, 190, 420, 850)
RING_C = (566, 420)
RING_R = 176
RING_W = 104
# Mark bounding box on the 1024 grid.
BOX = (STEM[0], STEM[1], RING_C[0] + RING_R + RING_W / 2, STEM[3])


def arc(d, cx, cy, r, w, start, end, color):
    """Arc with round caps; angles in degrees, 0 = 3 o'clock, clockwise."""
    box = [cx - r - w / 2, cy - r - w / 2, cx + r + w / 2, cy + r + w / 2]
    d.arc(box, start, end, fill=color, width=int(round(w)))
    for a in (start, end):
        x = cx + r * math.cos(math.radians(a))
        y = cy + r * math.sin(math.radians(a))
        d.ellipse([x - w / 2, y - w / 2, x + w / 2, y + w / 2], fill=color)


def mark_layer(big, scale, ox, oy, mono=None):
    layer = Image.new('RGBA', (big, big), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    c = lambda col: (mono or col) + (255,)
    cx, cy = ox + RING_C[0] * scale, oy + RING_C[1] * scale
    r, w = RING_R * scale, RING_W * scale
    # Ring starts where it leaves the stem (top-left), runs clockwise; the
    # final segment returning to the stem is ice.
    arc(d, cx, cy, r, w, 180, 480, c(SAGE))
    arc(d, cx, cy, r, w, 470, 540, c(ICE))
    x0, y0, x1, y1 = (v * scale for v in STEM)
    d.rounded_rectangle([ox + x0, oy + y0, ox + x1, oy + y1], radius=(x1 - x0) / 2, fill=c(CORAL))
    return layer


def render(size, *, bg, mark_scale, name, mono=None):
    big = size * SS
    scale = big / 1024 * mark_scale
    bw, bh = (BOX[2] - BOX[0]) * scale, (BOX[3] - BOX[1]) * scale
    ox = (big - bw) / 2 - BOX[0] * scale
    oy = (big - bh) / 2 - BOX[1] * scale
    base = Image.new('RGBA', (big, big), (bg + (255,)) if bg else (0, 0, 0, 0))
    base.alpha_composite(mark_layer(big, scale, ox, oy, mono))
    img = base.resize((size, size), Image.LANCZOS)
    if bg:
        img = img.convert('RGB')  # store icons must not carry alpha
    img.save(f'{OUT}/{name}.png', optimize=True)


render(1024, bg=BG, mark_scale=0.92, name='icon_1024')
render(1024, bg=None, mark_scale=1.0, name='icon_foreground')
render(1024, bg=None, mark_scale=1.0, mono=(255, 255, 255), name='icon_monochrome')
render(1152, bg=None, mark_scale=0.52, name='splash_android12')
render(768, bg=None, mark_scale=0.9, name='splash_logo')
render(512, bg=BG, mark_scale=0.92, name='play_store_512')


# Web (apps/web reads these via scripts/sync-assets.mjs).
render(192, bg=BG, mark_scale=0.92, name='web_192')
render(512, bg=BG, mark_scale=0.92, name='web_512')
render(512, bg=BG, mark_scale=0.62, name='web_maskable_512')  # 80% safe zone
render(180, bg=BG, mark_scale=0.84, name='apple_touch_180')
print('ok')
