#!/usr/bin/env python3
"""仅从已提供的官网录像帧制作本地 UI 对照素材，不从 IPA 提取资源。需要 Pillow。"""
from collections import deque
from pathlib import Path
import json
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT.parent / 'capwords-analysis/evidence/video/m2'
ASSETS = ROOT / 'App/Resources/Assets.xcassets'


def save_asset(name, image):
    folder = ASSETS / f'{name}.imageset'
    folder.mkdir(parents=True, exist_ok=True)
    image.save(folder / f'{name}.png')
    (folder / 'Contents.json').write_text(json.dumps({
        'images': [{'filename': f'{name}.png', 'idiom': 'universal'}],
        'info': {'author': 'xcode', 'version': 1}
    }, indent=2) + '\n')


def cutout(frame, box):
    im = Image.open(SOURCE / frame).crop(box).convert('RGBA')
    pixels = im.load()
    w, h = im.size
    seen = set()
    todo = deque([(x, 0) for x in range(w)] + [(x, h-1) for x in range(w)]
                 + [(0, y) for y in range(h)] + [(w-1, y) for y in range(h)])
    while todo:
        x, y = todo.popleft()
        if not (0 <= x < w and 0 <= y < h) or (x, y) in seen:
            continue
        seen.add((x, y))
        r, g, b, _ = pixels[x, y]
        # 边界泛洪保留物体内部的白色，浅灰网点与投影归入背景。
        if min(r, g, b) > 177 and max(r, g, b) - min(r, g, b) < 35:
            pixels[x, y] = (r, g, b, 0)
            todo.extend([(x-1, y), (x+1, y), (x, y-1), (x, y+1)])
    return im.crop(im.getbbox())


specs = {
    'sample-monstera': ('t0023000.jpg', (40, 179, 158, 290)),
    'sample-tape': ('t0023000.jpg', (204, 177, 318, 291)),
    'sample-clip': ('t0023000.jpg', (42, 375, 150, 487)),
    'sample-switch': ('t0023000.jpg', (203, 373, 323, 488)),
    'sample-toast': ('t0016500.jpg', (35, 200, 156, 278)),
    'sample-bread': ('t0016500.jpg', (201, 180, 321, 305)),
    'sample-donut': ('t0008500.jpg', (32, 188, 160, 269)),
    'sample-forest': ('t0008500.jpg', (36, 461, 155, 565)),
    'sample-tea': ('t0008500.jpg', (234, 461, 299, 574)),
}
for name, (frame, box) in specs.items():
    save_asset(name, cutout(frame, box))
from prepare_camera_reference import prepare_camera_assets
prepare_camera_assets()
(ASSETS / 'Contents.json').write_text('{"info":{"author":"xcode","version":1}}\n')
# 本地代码绘制的独立应用图标，不使用原版商标图集。
from PIL import ImageDraw
icon = Image.new('RGB', (1024, 1024), '#f8f6fa')
draw = ImageDraw.Draw(icon)
colors = ['#efff72', '#b2e8cf', '#b4a0df', '#b9e2f4', '#f3c6ec']
for i, color in enumerate(colors):
    draw.pieslice((170, 170, 854, 854), start=i*72-90, end=i*72-24, fill=color)
draw.ellipse((323, 323, 701, 701), fill='white')
folder = ASSETS / 'AppIcon.appiconset'
folder.mkdir(exist_ok=True)
icon.save(folder / 'AppIcon.png')
(folder / 'Contents.json').write_text(json.dumps({'images': [{'filename':'AppIcon.png', 'idiom':'universal', 'platform':'ios', 'size':'1024x1024'}], 'info':{'author':'xcode','version':1}}, indent=2)+'\n')
print(f'Prepared {len(specs)} stickers, camera reference and app icon.')
