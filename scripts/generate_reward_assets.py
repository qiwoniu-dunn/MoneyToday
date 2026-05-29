#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path
from PIL import Image, ImageDraw
import sys


OUT = Path(sys.argv[1] if len(sys.argv) > 1 else "Sources/MoneyTodayApp/Resources/Rewards")
OUT.mkdir(parents=True, exist_ok=True)
SCALE = 4
SIZE = 128


def rgba(hex_value: str, alpha: int = 255):
    value = hex_value.strip("#")
    return tuple(int(value[i : i + 2], 16) for i in (0, 2, 4)) + (alpha,)


def draw_asset(name: str, palette: list[str], blocks: list[tuple[int, int, int, int, int]]):
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    draw.rounded_rectangle((4, 4, 124, 124), radius=18, fill=rgba(palette[0], 48))
    for x, y, w, h, idx in blocks:
        color = rgba(palette[min(idx, len(palette) - 1)])
        draw.rectangle((x * SCALE, y * SCALE, (x + w) * SCALE - 1, (y + h) * SCALE - 1), fill=color)
    img.save(OUT / f"{name}.png")


cup = [(8, 8, 13, 3, 2), (7, 11, 15, 4, 2), (8, 15, 13, 9, 2), (10, 15, 9, 3, 1), (21, 14, 4, 7, 2), (22, 16, 2, 4, 0), (10, 5, 2, 2, 3), (15, 4, 1, 3, 3), (19, 5, 1, 2, 3), (9, 24, 12, 1, 1), (11, 25, 8, 1, 1)]
meal = [(5, 17, 22, 3, 2), (6, 14, 20, 4, 0), (9, 11, 5, 4, 3), (15, 10, 6, 5, 1), (21, 12, 3, 3, 3), (7, 20, 18, 2, 2), (4, 22, 24, 1, 1), (5, 7, 1, 10, 2), (27, 7, 1, 10, 2)]
burger = [(6, 11, 20, 4, 2), (5, 15, 22, 4, 0), (6, 19, 20, 3, 1), (7, 22, 18, 3, 2), (9, 10, 2, 1, 3), (14, 10, 2, 1, 3), (20, 10, 2, 1, 3)]
car = [(5, 15, 22, 5, 0), (9, 10, 14, 6, 2), (10, 11, 5, 4, 2), (17, 11, 5, 4, 2), (7, 20, 5, 5, 1), (20, 20, 5, 5, 1), (8, 21, 3, 3, 2), (21, 21, 3, 3, 2), (5, 16, 3, 2, 3)]
ticket = [(5, 8, 22, 16, 0), (7, 10, 18, 12, 2), (11, 10, 1, 12, 0), (18, 10, 1, 12, 0), (5, 12, 2, 3, 2), (25, 19, 2, 3, 2)]
dumbbell = [(5, 14, 4, 8, 1), (9, 16, 14, 4, 0), (23, 14, 4, 8, 1), (4, 16, 1, 4, 2), (27, 16, 1, 4, 2)]
spa = [(8, 18, 16, 4, 2), (10, 14, 12, 5, 0), (13, 9, 6, 6, 3), (10, 6, 3, 3, 3), (20, 7, 3, 3, 3)]
keyboard = [(4, 11, 24, 14, 1), (6, 13, 20, 10, 2), (7, 14, 3, 2, 0), (12, 14, 3, 2, 0), (17, 14, 3, 2, 0), (22, 14, 3, 2, 0), (7, 18, 18, 2, 0)]
mouse = [(10, 7, 12, 20, 1), (12, 9, 8, 16, 2), (15, 7, 2, 7, 3), (13, 5, 6, 2, 1)]
bottle = [(12, 6, 8, 4, 1), (10, 10, 12, 18, 0), (12, 13, 8, 10, 2), (14, 4, 4, 2, 3)]
headphones = [(8, 9, 16, 4, 1), (6, 13, 4, 12, 1), (22, 13, 4, 12, 1), (8, 20, 4, 6, 0), (20, 20, 4, 6, 0)]
camera = [(6, 11, 20, 14, 1), (10, 8, 8, 4, 1), (12, 14, 8, 8, 2), (14, 16, 4, 4, 0), (22, 13, 3, 2, 3)]
hotel = [(5, 10, 22, 16, 2), (7, 15, 18, 7, 0), (8, 11, 4, 3, 1), (14, 11, 4, 3, 1), (20, 11, 4, 3, 1), (5, 24, 22, 2, 1)]
suitcase = [(8, 10, 16, 17, 0), (12, 7, 8, 4, 1), (10, 12, 12, 13, 2), (14, 12, 2, 13, 1), (9, 27, 3, 2, 1), (21, 27, 3, 2, 1)]
phone = [(10, 5, 12, 24, 1), (12, 8, 8, 17, 2), (15, 26, 2, 1, 3), (13, 6, 6, 1, 3)]
laptop = [(6, 8, 20, 14, 1), (8, 10, 16, 10, 2), (4, 22, 24, 4, 0), (9, 24, 14, 1, 3)]
spark = [(15, 5, 2, 6, 0), (13, 11, 6, 2, 0), (14, 14, 4, 4, 2), (7, 18, 2, 4, 3), (6, 20, 4, 2, 3), (24, 16, 1, 3, 1), (23, 17, 3, 1, 1)]


assets = [
    ("reward-coffee", ["f7f0da", "8b5a2b", "ffffff", "6fcf97"], cup),
    ("reward-latte", ["f8e7c8", "c58940", "fffaf1", "7ac7ff"], cup),
    ("reward-milk-tea", ["f3b6c8", "9a6a45", "fff3f7", "ffcf5a"], cup),
    ("reward-breakfast", ["f7c948", "db6b3d", "fff8df", "63b36f"], meal),
    ("reward-lunch", ["f58b45", "4b8f5a", "fff4d8", "cf3f3f"], meal),
    ("reward-fastfood", ["f6c343", "d9472f", "fff0c2", "4f8fdf"], burger),
    ("reward-ride", ["5aa9e6", "202733", "eaf8ff", "ffd24a"], car),
    ("reward-movie", ["8c6ff7", "202733", "fff8e8", "ffcf5a"], ticket),
    ("reward-gym", ["63d297", "202733", "eafff3", "ff7a7a"], dumbbell),
    ("reward-brunch", ["ffa85c", "7a4c26", "fff8e8", "6fcf97"], meal),
    ("reward-massage", ["83d6d0", "37616b", "f0fffb", "ffb6c8"], spa),
    ("reward-keycaps", ["d7dce7", "2b3440", "ffffff", "6fcf97"], keyboard),
    ("reward-mouse", ["d8e4ef", "2d3640", "ffffff", "5aa9e6"], mouse),
    ("reward-perfume", ["f3b6d0", "5b4a67", "fff3fb", "ffcf5a"], bottle),
    ("reward-dinner", ["ff8d6b", "62351f", "fff6ed", "63b36f"], meal),
    ("reward-headphones", ["8aa4ff", "202733", "eef2ff", "6fcf97"], headphones),
    ("reward-camera", ["7f8da3", "202733", "eaf1ff", "ffcf5a"], camera),
    ("reward-hotel", ["7ac7ff", "365778", "ffffff", "ffcf5a"], hotel),
    ("reward-travel", ["f2a65a", "3b4a66", "fff0d4", "6fcf97"], suitcase),
    ("reward-phone", ["2e3848", "0f1720", "e9f1ff", "72d8ff"], phone),
    ("reward-laptop", ["9aa7b7", "202733", "eff5ff", "6fcf97"], laptop),
    ("reward-spark", ["ffcf5a", "f7931e", "fff7d6", "6fcf97"], spark),
]

for item in assets:
    draw_asset(*item)

print(f"wrote {len(assets)} reward assets to {OUT}")
