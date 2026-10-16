"""Query retained annotated instructions without invoking target code."""
import argparse,json,re,sys
from pathlib import Path
sys.stdout.reconfigure(encoding='utf-8')
P=Path(__file__).resolve().parent/'evidence'/'ipa'/'capture-flow'
ap=argparse.ArgumentParser()
ap.add_argument('lo');ap.add_argument('hi',nargs='?')
ap.add_argument('--filter',default='')
a=ap.parse_args();lo=int(a.lo,16);hi=int(a.hi,16) if a.hi else None
active=False
for line in (P/'annotated-capture-disassembly.txt').open(encoding='utf-8'):
    if line.startswith('FUNCTION '):
        address=int(line.split()[1],16)
        if hi is None: active=address==lo
    m=re.match(r'([0-9a-f]+):',line)
    if m and hi is not None:active=lo<=int(m[1],16)<hi
    if active and (not a.filter or re.search(a.filter,line)):print(line.rstrip())
