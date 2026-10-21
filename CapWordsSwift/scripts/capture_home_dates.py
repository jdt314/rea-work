#!/usr/bin/env python3
"""Capture real rendering and a programmatic zoom replay; does not simulate taps."""
import os
from pathlib import Path
import signal
import subprocess
import time

root = Path(__file__).resolve().parents[1]
out = root / 'docs/home-date-validation'
out.mkdir(parents=True, exist_ok=True)
env = dict(os.environ)
env.setdefault('DEVELOPER_DIR', '/Volumes/homex/Applications/Xcode-beta.app/Contents/Developer')
device = env.get('CAPWORDS_SIMULATOR_ID', '4607AA88-3821-4245-91AA-A1E6B8E407E4')
app = 'cn.a2px.wordrove.dev.f89luflt5b.c9e48b12'

def sim(*parts, check=True):
    return subprocess.run(['/usr/bin/xcrun', 'simctl', *parts], env=env, check=check,
                          capture_output=True, text=True)

sim('install', device, str(root / '.build/Build/Products/Debug-iphonesimulator/CapWordsSwift.app'))
sim('terminate', device, app, check=False)
recorder = subprocess.Popen(['/usr/bin/xcrun', 'simctl', 'io', device, 'recordVideo',
                             '--codec=h264', '--force', str(out / 'date-zoom.mov')], env=env,
                            stdout=subprocess.DEVNULL, stderr=subprocess.PIPE)
try:
    time.sleep(1)
    sim('launch', device, app, '--uitesting', '--seed-library', '--preview-home',
        '--preview-home-dates', '--preview-home-motion')
    started = time.monotonic()
    for seconds, name in [(5, 'collapsed'), (14, 'expanded'), (24, 'returned')]:
        time.sleep(max(0, started + seconds - time.monotonic()))
        sim('io', device, 'screenshot', str(out / (name + '.png')))
        print(name, flush=True)
finally:
    recorder.send_signal(signal.SIGINT)
    recorder.communicate(timeout=20)
