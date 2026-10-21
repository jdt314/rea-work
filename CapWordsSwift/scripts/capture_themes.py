#!/usr/bin/env python3
"""Capture theme coverage, live preference changes, system changes and persistence.
This is a programmatic rendering check, not a replacement for tap UI tests.
"""
import json
import os
from pathlib import Path
import subprocess
import sys
import time
from collections import Counter
from PIL import Image

root = Path(__file__).resolve().parents[1]
out = root / 'docs/theme-validation'
out.mkdir(parents=True, exist_ok=True)
env = dict(os.environ)
env.setdefault('DEVELOPER_DIR', '/Volumes/homex/Applications/Xcode-beta.app/Contents/Developer')
device = env.get('CAPWORDS_SIMULATOR_ID', '4607AA88-3821-4245-91AA-A1E6B8E407E4')
app = 'cn.a2px.wordrove.dev.f89luflt5b.c9e48b12'
records = []
only = sys.argv[2] if len(sys.argv) == 3 and sys.argv[1] == '--only' else None

def background(mode, scene):
    if mode == 'dark':
        return (27, 27, 27)
    if scene in ['home', 'home-bottom', 'conversation']:
        return (244, 245, 246)
    return (246, 246, 246) if scene in ['library', 'settings'] else (249, 247, 250)

def sim(*parts, check=True):
    return subprocess.run(['/usr/bin/xcrun', 'simctl', *parts], env=env, check=check,
                          capture_output=True, text=True)

def launch(*args):
    sim('terminate', device, app, check=False)
    sim('launch', device, app, '--uitesting', '--seed-library', *args, '-AppleLanguages', '(zh-Hans)', '-AppleLocale', 'zh_CN')

def shot(name, wait=4, expected=None):
    time.sleep(wait)
    path = out / (name + '.png')
    deadline = time.monotonic() + 20
    while True:
        sim('io', device, 'screenshot', str(path))
        if expected is None:
            break
        with Image.open(path) as image:
            coverage = Counter(image.convert('RGB').getdata())[expected] / (image.width * image.height)
        if coverage > .05:
            break
        if time.monotonic() >= deadline:
            raise RuntimeError(f'{name}: target background did not appear; inspect {path}')
        time.sleep(2)
    records.append(name)
    print(name, flush=True)

original = sim('ui', device, 'appearance').stdout.strip()
sim('install', device, str(root / '.build/Build/Products/Debug-iphonesimulator/CapWordsSwift.app'))
try:
    sim('ui', device, 'appearance', 'light')
    for mode in ['light', 'dark']:
        for scene, flags in [
            ('home', ['--preview-home', '--preview-home-dates']),
            ('home-bottom', ['--preview-home', '--preview-home-bottom']),
            ('settings', ['--preview-settings']),
            ('library', ['--preview-library']),
            ('review', ['--preview-home-review']),
            ('conversation', ['--preview-conversation']),
            ('detail', ['--preview-detail']),
            ('result', ['--preview-result']),
        ]:
            if only is not None and only != mode + '-' + scene and not (only == 'settings' and scene == 'settings'):
                continue
            launch('--appearance=' + mode, *flags)
            shot(mode + '-' + scene, wait=8 if scene in ['home', 'home-bottom'] else 4,
                 expected=background(mode, scene))
    if only is not None and only != 'settings':
        if not records:
            raise ValueError('Unknown scene: ' + only)
        sys.exit(0)
    # Change the same AppStorage binding used by settings while it stays on screen.
    launch('--appearance=light', '--preview-settings', '--preview-theme-cycle')
    started = time.monotonic()
    for seconds, name in [(3, 'live-light'), (9, 'live-dark'), (15, 'live-light-again'), (21, 'live-system')]:
        shot(name, max(0, started + seconds - time.monotonic()))
    # No relaunch: follow system changes in both directions.
    sim('ui', device, 'appearance', 'dark')
    shot('system-dark')
    sim('ui', device, 'appearance', 'light')
    shot('system-light')
    # Explicit override must survive a conflicting system mode, then a new process.
    launch('--appearance=dark', '--preview-settings')
    shot('explicit-dark-on-light')
    launch('--preserve-test-preferences', '--preview-settings')
    shot('persisted-dark')
    sim('ui', device, 'appearance', 'dark')
    launch('--appearance=light', '--preview-settings')
    shot('explicit-light-on-dark')
    launch('--appearance=light', '--preview-camera')
    shot('camera-in-light')
finally:
    if original in ['light', 'dark']:
        sim('ui', device, 'appearance', original)
    if only is not None and (out / 'metadata.json').exists():
        previous = json.loads((out / 'metadata.json').read_text())
        records = list(dict.fromkeys(previous.get('captures', []) + records))
    (out / 'metadata.json').write_text(json.dumps({'device': device, 'originalSystemAppearance': original,
        'captures': records, 'input': 'debug programmatic routes and AppStorage replay; not simulated taps'}, indent=2))
