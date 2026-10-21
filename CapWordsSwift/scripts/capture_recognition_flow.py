#!/usr/bin/env python3
"""Record real simulator rendering with explicitly simulated recognition timing."""
import json
import os
from pathlib import Path
import signal
import subprocess
import time

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'docs/video-4-validation'
DEVICE = os.environ['CAPWORDS_SIMULATOR_ID']
ENV = dict(os.environ)
ENV.setdefault('DEVELOPER_DIR', '/Volumes/homex/Applications/Xcode-beta.app/Contents/Developer')
APP = 'cn.a2px.wordrove.dev.f89luflt5b.c9e48b12'


def simctl(*args, check=True):
    return subprocess.run(['/usr/bin/xcrun', 'simctl', *args], env=ENV, check=check,
                          capture_output=True, text=True)


OUT.mkdir(parents=True, exist_ok=True)
simctl('install', DEVICE, str(ROOT / '.build/Build/Products/Debug-iphonesimulator/CapWordsSwift.app'))
records = []
for name, extra, samples in [
    ('slow', ['--recognition-slow'], [0.6, 1.2, 2.1, 2.5, 3.2, 5.0, 8.8, 10.0, 13.0]),
    ('fast', [], [1.0, 3.8, 6.0]),
    ('failure', ['--recognition-error'], [6.0]),
    ('cancel', ['--recognition-slow', '--recognition-cancel'], [5.5, 14.0]),
]:
    simctl('terminate', DEVICE, APP, check=False)
    recording = None
    stream = None
    try:
        if name == 'slow':
            stream = (OUT / 'recording.log').open('w')
            recording = subprocess.Popen(['/usr/bin/xcrun', 'simctl', 'io', DEVICE, 'recordVideo',
                                          '--codec=h264', '--force', str(OUT / 'slow.mp4')],
                                         env=ENV, stdout=stream, stderr=stream)
            time.sleep(0.5)
        start = time.monotonic()
        simctl('launch', DEVICE, APP, '--uitesting', '--preview-camera', '--exercise-recognition', *extra)
        for seconds in samples:
            time.sleep(max(0, start + seconds - time.monotonic()))
            file = f'{name}-{seconds:.1f}.png'
            simctl('io', DEVICE, 'screenshot', str(OUT / file))
            records.append({'scenario': name, 'file': file, 'secondsAfterLaunchRequest': time.monotonic() - start})
    finally:
        if recording:
            recording.send_signal(signal.SIGINT)
            recording.wait(timeout=15)
        if stream:
            stream.close()
(OUT / 'metadata.json').write_text(json.dumps({'device': DEVICE, 'recognition': 'deterministic demo; no real API call',
                                               'frames': records}, indent=2))
simctl('terminate', DEVICE, APP, check=False)
simctl('launch', DEVICE, APP)
print(f'Captured {len(records)} real simulator frames and slow.mp4 in {OUT}')
