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


if __name__ == "__main__":
    build()
    print("Built Loot journal paper, stage and ornament textures")
