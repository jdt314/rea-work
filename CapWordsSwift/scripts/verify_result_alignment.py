#!/usr/bin/env python3
"""Measure the three white action circles against video 4's normalized geometry."""
from collections import deque
import json
from pathlib import Path
import sys
from PIL import Image

path = Path(sys.argv[1])
im = Image.open(path).convert('RGB')
w, h = im.size
mask = im.point(lambda value: 255 if value >= 253 else 0)
p = mask.load()
seen = set()
components = []
for y in range(int(h * .45), int(h * .64)):
    for x in range(int(w * .08), int(w * .92)):
        if (x,y) in seen or p[x,y] != (255,255,255): continue
        queue = deque([(x,y)])
        seen.add((x,y))
        pts = []
        while queue:
            a,b = queue.popleft()
            pts.append((a,b))
            for c,d in [(a-1,b),(a+1,b),(a,b-1),(a,b+1)]:
                if 0 <= c < w and int(h*.45) <= d < int(h*.64) and (c,d) not in seen and p[c,d] == (255,255,255):
                    seen.add((c,d)); queue.append((c,d))
        if len(pts) > w*w*.006:
            xs,ys = zip(*pts)
            components.append({'x': (min(xs)+max(xs))/2/w, 'y': (min(ys)+max(ys))/2/h, 'diameter': (max(xs)-min(xs)+1)/w})
components.sort(key=lambda c:c['x'])
print(json.dumps({'image':str(path), 'circles':components}, indent=2))
assert len(components) == 3, 'Expected three distinct white action circles'
for actual, target_x, diameter in zip(components, [.226,.5,.774], [.15,.2,.15]):
    assert abs(actual['x']-target_x) < .012, f'button x drift: {actual}'
    assert abs(actual['y']-.537) < .012, f'button y drift: {actual}'
    assert abs(actual['diameter']-diameter) < .012, f'button diameter drift: {actual}'
print('PASS: video 4 action geometry')
