#!/usr/bin/env python3
"""Check the actual captured page background, live updates and relaunch results."""
from collections import Counter
import json
import sys
from pathlib import Path
from PIL import Image

root = Path(__file__).resolve().parents[1]
folder = root / 'docs/theme-validation'
records = []
expected = {}
for mode in ['light', 'dark']:
    for scene in ['home', 'settings', 'library', 'review', 'conversation', 'detail', 'result']:
        light = (244, 245, 246) if scene in ['home', 'conversation'] else (246, 246, 246) if scene in ['library', 'settings'] else (249, 247, 250)
        expected[f'{mode}-{scene}'] = (27, 27, 27) if mode == 'dark' else light
for name in ['live-dark', 'system-dark', 'explicit-dark-on-light', 'persisted-dark']:
    expected[name] = (27, 27, 27)
for name in ['live-light', 'live-light-again', 'live-system', 'system-light', 'explicit-light-on-dark']:
    expected[name] = (246, 246, 246)
for name, color in expected.items():
    if '--settings-only' in sys.argv and name in [f'{mode}-{scene}' for mode in ['light', 'dark'] for scene in ['home', 'library', 'review', 'conversation', 'detail', 'result']]:
        continue
    image = Image.open(folder / (name + '.png')).convert('RGB')
    count = Counter(image.getdata())[color]
    coverage = count / (image.width * image.height)
    records.append({'capture': name, 'expectedBackgroundRGB': color, 'coverage': round(coverage, 4), 'pass': coverage > .05})
(folder / ('settings-checks.json' if '--settings-only' in sys.argv else 'checks.json')).write_text(json.dumps({'checks': records, 'limitations': 'Background rendering only; button selection and text reviewed separately, no tap simulation.'}, indent=2))
assert all(r['pass'] for r in records), [r for r in records if not r['pass']]
print(f'{len(records)} real screenshot background checks passed, including live system changes and persisted selection.')
