#!/usr/bin/env python3
"""Replay real scrolling in one process: expanded -> collapsed -> expanded."""
import json
import os
from pathlib import Path
import signal
import subprocess
import time

root = Path(__file__).resolve().parents[1]
out = root / 'docs/settings-title-validation'
out.mkdir(parents=True, exist_ok=True)
env = dict(os.environ)
env.setdefault('DEVELOPER_DIR', '/Volumes/homex/Applications/Xcode-beta.app/Contents/Developer')
device = env.get('CAPWORDS_SIMULATOR_ID', '4607AA88-3821-4245-91AA-A1E6B8E407E4')
bundle = 'cn.a2px.wordrove.dev.f89luflt5b.c9e48b12'

def sim(*args, check=True):
    return subprocess.run(['/usr/bin/xcrun', 'simctl', *args], env=env, check=check,
                          capture_output=True, text=True)

original = sim('ui', device, 'appearance').stdout.strip()
sim('install', device, str(root / '.build/Build/Products/Debug-iphonesimulator/CapWordsSwift.app'))
records = []
try:
    for mode in ['light', 'dark']:
        sim('terminate', device, bundle, check=False)
        recording = subprocess.Popen(['/usr/bin/xcrun', 'simctl', 'io', device, 'recordVideo',
            '--codec=h264', '--force', str(out / (mode + '-scroll.mp4'))], env=env,
            stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        try:
            sim('launch', device, bundle, '--uitesting', '--seed-library', '--preview-settings',
                '--preview-settings-title-motion', '--appearance=' + mode,
                '-AppleLanguages', '(zh-Hans)', '-AppleLocale', 'zh_CN')
            start = time.monotonic()
            for seconds, state in [(3, 'expanded'), (9, 'collapsed'), (15, 'restored')]:
                time.sleep(max(0, start + seconds - time.monotonic()))
                name = mode + '-' + state + '.png'
                sim('io', device, 'screenshot', str(out / name))
                records.append(name)
                print(name, flush=True)
        finally:
            recording.send_signal(signal.SIGINT)
            recording.communicate(timeout=20)
            if recording.returncode != 0:
                raise RuntimeError('Simulator video recording failed')
finally:
    if original in ['light', 'dark']:
        sim('ui', device, 'appearance', original)
    (out / 'metadata.json').write_text(json.dumps({'device': device, 'captures': records,
        'method': 'One process per appearance. Debug ScrollViewReader replay, not synthesized touches.',
        'sequence': 'Expanded, scroll to App section, scroll back to top.'}, indent=2))
