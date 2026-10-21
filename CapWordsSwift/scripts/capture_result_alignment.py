#!/usr/bin/env python3
"""Capture isolated deterministic result fixtures, without real API calls."""
import argparse
import json
import os
from pathlib import Path
import subprocess
import time

parser = argparse.ArgumentParser()
parser.add_argument('stage', choices=['before', 'after'])
args = parser.parse_args()
root = Path(__file__).resolve().parents[1]
out = root / 'docs/result-alignment-validation' / args.stage
out.mkdir(parents=True, exist_ok=True)
env = dict(os.environ)
env.setdefault('DEVELOPER_DIR', '/Volumes/homex/Applications/Xcode-beta.app/Contents/Developer')
device = env.get('CAPWORDS_SIMULATOR_ID', '4607AA88-3821-4245-91AA-A1E6B8E407E4')
app = 'cn.a2px.wordrove.dev.f89luflt5b.c9e48b12'

def sim(*parts, check=True):
    return subprocess.run(['/usr/bin/xcrun', 'simctl', *parts], env=env, check=check, capture_output=True, text=True)

sim('install', device, str(root / '.build/Build/Products/Debug-iphonesimulator/CapWordsSwift.app'))
scenarios = [('donut', ['--preview-result']), ('camera', ['--preview-camera', '--camera-layout-reference'])]
if args.stage == 'after':
    scenarios += [(name, ['--preview-result', '--result-fixture-' + name]) for name in ['key', 'long', 'missing']]
    scenarios += [('cutout', ['--preview-cutout', '--preview-camera']), ('slow', ['--preview-result', '--recognition-slow'])]
try:
    sim('status_bar', device, 'override', '--time', '17:28', '--dataNetwork', 'wifi', '--wifiMode', 'active', '--wifiBars', '3', '--batteryState', 'discharging', '--batteryLevel', '53')
    for name, extra in scenarios:
        sim('terminate', device, app, check=False)
        sim('launch', device, app, '--uitesting', *extra)
        time.sleep(10 if name == 'slow' else 3)
        sim('io', device, 'screenshot', str(out / (name + '.png')))
        print(name, flush=True)
finally:
    sim('status_bar', device, 'clear')
(out / 'metadata.json').write_text(json.dumps({'device': device, 'recognition': 'Debug fixtures, no real API', 'scenarios': scenarios}, indent=2))
