#!/usr/bin/env python3
"""Reproduce certificate signing on a temporary copy of the failing build file."""
import argparse
from pathlib import Path
import re
import shutil
import subprocess
import tempfile

parser = argparse.ArgumentParser()
parser.add_argument('--identity', required=True, help='SHA-1 of the public signing certificate')
args = parser.parse_args()
root = Path.home() / 'Library/Developer/Xcode/DerivedData'
files = list(root.glob('CapWordsSwift-*/Build/Products/Debug-iphoneos/WordroveWidget.appex/WordroveWidget.debug.dylib'))
if not files:
    raise SystemExit('No device Widget debug library found; build the iOS target first.')
source = max(files, key=lambda p: p.stat().st_mtime)

def report(result):
    message = result.stdout + result.stderr
    print(re.sub(r'[\w.+-]+@[\w.-]+', '<REDACTED>', message), end='', flush=True)

with tempfile.TemporaryDirectory(prefix='wordrove-signing-probe-', dir='/tmp') as folder:
    target = Path(folder) / source.name
    shutil.copy2(source, target)
    print('Signing a temporary copy of', source.name, flush=True)
    result = subprocess.run(['/usr/bin/codesign', '--force', '--sign', args.identity,
        '--timestamp=none', '--generate-entitlement-der', str(target)], capture_output=True, text=True)
    report(result)
    if result.returncode:
        raise SystemExit(result.returncode)
    result = subprocess.run(['/usr/bin/codesign', '--verify', '--strict', '--verbose=2', str(target)],
                            capture_output=True, text=True)
    report(result)
    raise SystemExit(result.returncode)
