"""Build the Loot journal's small, original UI textures (Pillow, no game art copied)."""
from pathlib import Path
import math
import random
from PIL import Image, ImageDraw

OUT = Path(__file__).resolve().parents[1] / "media"


def build():
    OUT.mkdir(exist_ok=True)
    rng = random.Random(16301)
    paper = Image.new("RGBA", (128, 128))
    p = paper.load()
    for y in range(128):
        for x in range(128):
            n = 246 + rng.randrange(-4, 5) + 2 * math.sin(x * math.pi / 16) * math.sin(y * math.pi / 32)
            v = max(0, min(255, round(n)))
            p[x, y] = (v, v, v, 255)
    paper.save(OUT / "loot-paper.tga")

    stage = Image.new("RGBA", (256, 512))
    p = stage.load()
    for y in range(512):
        for x in range(256):
            glow = max(0, 1 - math.hypot((x - 128) / 150, (y - 209) / 305))
            n = rng.randrange(-2, 3)
            p[x, y] = (int(14 + glow * 14) + n, int(23 + glow * 29) + n, int(31 + glow * 31) + n, 255)
    overlay = Image.new("RGBA", stage.size)
    d = ImageDraw.Draw(overlay)
    for rx, ry, alpha in [(102, 191, 65), (108, 203, 38), (116, 218, 22)]:
        d.ellipse((128-rx, 217-ry, 128+rx, 217+ry), outline=(185, 159, 110, alpha), width=1)
    for x in (9, 246):
        d.line((x, 24, x, 487), fill=(185, 159, 110, 42), width=1)
    for yy in (17, 495):
        d.line((20, yy, 235, yy), fill=(185, 159, 110, 50), width=1)
    Image.alpha_composite(stage, overlay).save(OUT / "loot-stage.tga")

    ornament = Image.new("RGBA", (512, 64))
    d = ImageDraw.Draw(ornament)
    bronze = (134, 104, 57, 150)
    pale = (183, 152, 93, 125)
    for side in (-1, 1):
        for yy in (29, 34):
            d.line((256+side*27, yy, 256+side*236, yy), fill=bronze, width=1)
        for k in range(5):
            x = 256 + side * (37+k*17)
            d.arc((x-13, 14-k%2*4, x+13, 38), 180 if side<0 else 270, 350 if side<0 else 450, fill=pale, width=1)
        x = 256 + side*238
        d.polygon(((x, 26), (x+side*10, 32), (x, 38), (x-side*4, 32)), outline=bronze)
    d.polygon(((256, 18), (270, 32), (256, 46), (242, 32)), outline=bronze)
    d.polygon(((256, 24), (264, 32), (256, 40), (248, 32)), fill=pale)
    ornament.save(OUT / "loot-ornament.tga")

    ribbon = Image.new("RGBA", (1024, 128))
    p = ribbon.load()
    for y in range(128):
        for x in range(1024):
            sheen = 1 - abs(y - 44) / 92
            glow = max(0, 1 - abs(x - 245) / 540)
            grain = rng.randrange(-2, 3)
            p[x, y] = (16 + int(8*sheen) + grain, 28 + int(18*sheen + 9*glow) + grain,
                       33 + int(21*sheen + 11*glow) + grain, 255)
    ink = Image.new("RGBA", ribbon.size)
    d = ImageDraw.Draw(ink)
    for inset, alpha in [(5, 100), (10, 42)]:
        d.rounded_rectangle((inset, inset, 1023-inset, 127-inset), radius=12,
                            outline=(202, 167, 98, alpha), width=1)
    Image.alpha_composite(ribbon, ink).save(OUT / "loot-ribbon.tga")


if __name__ == "__main__":
    build()
    print("Built Loot journal paper, stage, ornament and banner textures")
