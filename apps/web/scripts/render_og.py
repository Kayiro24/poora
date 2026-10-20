"""Renders the 1200x630 Open Graph cards in public/og/.

Run from apps/web:  python scripts/render_og.py
Uses the brand fonts from apps/mobile/assets/fonts and the logo geometry from
apps/mobile/tool/render_logo.py, so cards always match the app.
"""
import math
import os
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
FONTS = os.path.join(HERE, '../../mobile/assets/fonts')
OUT = os.path.join(HERE, '../public/og')
W, H, SS = 1200, 630, 2

BG = (22, 22, 22)
SURFACE = (34, 34, 34)
TEXT = (244, 241, 234)
TEXT2 = (163, 160, 154)
SAGE, CORAL, PERI, ICE = (201, 217, 207), (242, 112, 94), (110, 114, 246), (191, 234, 242)


def font(name, size):
    return ImageFont.truetype(os.path.join(FONTS, name), size * SS)


def mark(d, x, y, h):
    """Poora mark with its top-left at (x, y), height h (scaled 1024 grid)."""
    k = h / 660
    ox, oy = x - 300 * k, y - 190 * k
    cx, cy, r, w = ox + 566 * k, oy + 420 * k, 176 * k, 104 * k

    def arc(a0, a1, col):
        d.arc([cx - r - w / 2, cy - r - w / 2, cx + r + w / 2, cy + r + w / 2], a0, a1, fill=col, width=int(w))
        for a in (a0, a1):
            px, py = cx + r * math.cos(math.radians(a)), cy + r * math.sin(math.radians(a))
            d.ellipse([px - w / 2, py - w / 2, px + w / 2, py + w / 2], fill=col)

    arc(180, 480, SAGE)
    arc(470, 540, ICE)
    d.rounded_rectangle([ox + 300 * k, oy + 190 * k, ox + 420 * k, oy + 850 * k], radius=60 * k, fill=CORAL)


def card(name, eyebrow, title_lines, body):
    img = Image.new('RGB', (W * SS, H * SS), BG)
    d = ImageDraw.Draw(img)
    s = SS
    # Soft panel + accent stripes (the app's three rooms).
    d.rounded_rectangle([40 * s, 40 * s, (W - 40) * s, (H - 40) * s], radius=48 * s, fill=SURFACE)
    for i, col in enumerate((SAGE, CORAL, PERI)):
        d.rounded_rectangle([(80 + i * 76) * s, (H - 92) * s, (140 + i * 76) * s, (H - 80) * s], radius=6 * s, fill=col)
    mark(d, 860 * s, 150 * s, 330 * s)
    d.text((80 * s, 92 * s), eyebrow.upper(), font=font('Inter.ttf', 22), fill=TEXT2)
    y = 132
    for line in title_lines:
        d.text((80 * s, y * s), line.upper(), font=font('BarlowCondensed-SemiBold.ttf', 92), fill=TEXT)
        y += 92
    d.text((80 * s, (y + 22) * s), body, font=font('Inter.ttf', 28), fill=TEXT2)
    img.resize((W, H), Image.LANCZOS).save(os.path.join(OUT, f'{name}.png'), optimize=True)


os.makedirs(OUT, exist_ok=True)
card('og-home', 'Poora · focus timer & day planner', ['Make every', 'day whole.'], 'Focus fully. Finish fully. Free, offline, no account.')
card('og-privacy', 'Poora · privacy policy', ['Your data', 'stays yours.'], 'Everything on your device. No account, no tracking.')
card('og-contact', 'Poora · contact', ['Say hello.'], 'Feedback, bugs and ideas — every message is read.')
print('og cards written')
