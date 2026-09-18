"""Draw the app icon: a rainbow field with a white check mark."""

import colorsys
import math
import struct
import zlib

SIZE = 1024
OUT = "Resources/Assets.xcassets/AppIcon.appiconset/icon-1024.png"

PNG_SIGNATURE = bytes([137, 80, 78, 71, 13, 10, 26, 10])

# Check mark: a short down stroke into a long up stroke.
STROKES = [((300, 545), (455, 700)), ((455, 700), (745, 355))]
THICKNESS = 78


def distance_to_segment(px, py, a, b):
    ax, ay = a
    bx, by = b
    dx, dy = bx - ax, by - ay
    length = dx * dx + dy * dy
    t = 0.0 if length == 0 else max(0.0, min(1.0, ((px - ax) * dx + (py - ay) * dy) / length))
    cx, cy = ax + t * dx, ay + t * dy
    return math.hypot(px - cx, py - cy)


def chunk(tag, data):
    body = tag + data
    return struct.pack(">I", len(data)) + body + struct.pack(">I", zlib.crc32(body) & 0xFFFFFFFF)


rows = bytearray()
for y in range(SIZE):
    rows.append(0)
    for x in range(SIZE):
        hue = ((x + y) / (2 * SIZE)) % 1.0
        r, g, b = colorsys.hsv_to_rgb(hue, 0.72, 0.95)
        pixel = [r * 255, g * 255, b * 255]

        nearest = min(distance_to_segment(x, y, a, b) for a, b in STROKES)
        edge = THICKNESS / 2
        if nearest <= edge:
            # Feather the last pixel so the mark does not look jagged.
            blend = min(1.0, (edge - nearest) / 2.0)
            pixel = [value + (255 - value) * blend for value in pixel]

        rows.extend(int(max(0, min(255, value))) for value in pixel)

with open(OUT, "wb") as f:
    f.write(PNG_SIGNATURE)
    f.write(chunk(b"IHDR", struct.pack(">IIBBBBB", SIZE, SIZE, 8, 2, 0, 0, 0)))
    f.write(chunk(b"IDAT", zlib.compress(bytes(rows), 9)))
    f.write(chunk(b"IEND", b""))
