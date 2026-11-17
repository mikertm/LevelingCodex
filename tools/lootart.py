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
            glow = max(0, 1 - math.hypot((x - 128) / 180, (y - 205) / 360))
            n = rng.randrange(-2, 3)
            p[x, y] = (int(19 + glow * 30) + n, int(27 + glow * 27) + n, int(29 + glow * 23) + n, 255)
    overlay = Image.new("RGBA", stage.size)
    d = ImageDraw.Draw(overlay)
    for inset, alpha in [(7, 150), (11, 55)]:
        d.rounded_rectangle((inset, inset, 255-inset, 511-inset), radius=38, outline=(177, 143, 82, alpha), width=1)
    d.ellipse((27, 437, 229, 484), fill=(5, 10, 13, 110), outline=(154, 129, 76, 90), width=1)
    for yy in (36, 419):
        d.line((30, yy, 226, yy), fill=(162, 135, 83, 65), width=1)
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
            glow = 1 - abs(x - 310) / 714
            grain = rng.randrange(-2, 3)
            p[x, y] = (20 + int(12*sheen) + grain, 36 + int(23*sheen + 9*glow) + grain,
                       38 + int(26*sheen + 13*glow) + grain, 255)
    ink = Image.new("RGBA", ribbon.size)
    d = ImageDraw.Draw(ink)
    for inset, alpha in [(5, 140), (10, 60)]:
        d.rounded_rectangle((inset, inset, 1023-inset, 127-inset), radius=12,
                            outline=(202, 167, 98, alpha), width=1)
    cx, cy = 952, 63
    d.ellipse((cx-39, cy-39, cx+39, cy+39), outline=(214, 184, 119, 105), width=2)
    d.ellipse((cx-32, cy-32, cx+32, cy+32), outline=(214, 184, 119, 45), width=1)
    d.polygon([(cx-18,cy-17),(cx+18,cy-17),(cx+15,cy+9),(cx,cy+22),(cx-15,cy+9)],
              fill=(210, 176, 104, 55), outline=(214, 184, 119, 165), width=2)
    d.line((cx,cy-11,cx,cy+12), fill=(214, 184, 119, 170), width=2)
    d.line((cx-9,cy-1,cx+9,cy-1), fill=(214, 184, 119, 170), width=2)
    Image.alpha_composite(ribbon, ink).save(OUT / "loot-ribbon.tga")


if __name__ == "__main__":
    build()
    print("Built Loot journal paper, stage, ornament and banner textures")
