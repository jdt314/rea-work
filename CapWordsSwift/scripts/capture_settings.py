#!/usr/bin/env python3
"""Capture video-6 settings routes. Routes render real views, not simulated taps."""
import argparse
import json
import os
from pathlib import Path
import subprocess
import time

root = Path(__file__).resolve().parents[1]
out = root / 'docs/settings-validation'
out.mkdir(parents=True, exist_ok=True)
parser = argparse.ArgumentParser()
parser.add_argument('--only', nargs='+')
parser.add_argument('--interface-language', choices=['zh-Hans', 'en'], default='zh-Hans')
args = parser.parse_args()
env = dict(os.environ)
env.setdefault('DEVELOPER_DIR', '/Volumes/homex/Applications/Xcode-beta.app/Contents/Developer')
device = env.get('CAPWORDS_SIMULATOR_ID', '4607AA88-3821-4245-91AA-A1E6B8E407E4')
bundle = 'cn.a2px.wordrove.dev.f89luflt5b.c9e48b12'

def sim(*parts, check=True):
    return subprocess.run(['/usr/bin/xcrun', 'simctl', *parts], env=env, check=check,
                          capture_output=True, text=True)

scenes = {'header': [], 'general': ['--preview-settings-general'],
          'footer': ['--preview-settings-footer'],
          **{name: ['--preview-settings-' + name] for name in
             ['profile', 'language', 'reminder', 'voice', 'widgets', 'health', 'faq', 'about']},
          'native-language': ['--preview-settings-language', '--preview-settings-native-language']}
original = sim('ui', device, 'appearance').stdout.strip()
records = []
sim('install', device, str(root / '.build/Build/Products/Debug-iphonesimulator/CapWordsSwift.app'))
try:
    sim('ui', device, 'appearance', 'light')
    for mode in ['light', 'dark']:
        for scene, flags in scenes.items():
            name = ('en-' if args.interface_language == 'en' else '') + mode + '-' + scene
            if args.only and name not in args.only:
                continue
            sim('terminate', device, bundle, check=False)
            sim('launch', device, bundle, '--uitesting', '--seed-library', '--preview-settings',
                '--appearance=' + mode, *flags, '-AppleLanguages', '(' + args.interface_language + ')',
                '-AppleLocale', 'zh_CN' if args.interface_language == 'zh-Hans' else 'en_US')
            time.sleep(7)
            path = out / (name + '.png')
            sim('io', device, 'screenshot', str(path))
            records.append(name)
            print(name, flush=True)
finally:
    if original in ['light', 'dark']:
        sim('ui', device, 'appearance', original)
    old = out / 'metadata.json'
    previous = json.loads(old.read_text()).get('captures', []) if old.exists() else []
    old.write_text(json.dumps({'device': device, 'captures': list(dict.fromkeys(previous + records)),
        'method': 'Debug routes render real SwiftUI views; no touch or system permission requests.'}, indent=2))
