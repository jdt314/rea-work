"""Recover enum dispatch and retain focused static evidence. Never executes IPA code."""
import json, re, struct, sys
from pathlib import Path
sys.stdout.reconfigure(encoding='utf-8')
import analyze_capture_flow as m

out = m.O / 'gaps'
out.mkdir(exist_ok=True)
types = {t['name']: t for t in m.types}
t = types['SnapWords.StickerLayerModel.Action']
d = int(t['descriptor'], 16)
payload_count = m.u32(d + 20) & 0xffffff
empty_count = m.u32(d + 24)
assert payload_count + empty_count == len(t['fields']) == 43
actions = []
for tag, field in enumerate(t['fields']):
    p = int(field['record'], 16) + 4
    assert bool(m.rel(p)) == (tag < payload_count)
    actions.append(dict(tag=tag, action=field['name'], payload_type_address=hex(m.rel(p)) if m.rel(p) else None,
                        reducer_branch=hex(0x1004c4b14 + m.i32(0x1004c61fc + tag * 4))))
assert all(0x1004c4980 <= int(x['reducer_branch'], 16) < 0x1004c61fc for x in actions)
(out / 'action-dispatch.json').write_text(json.dumps(dict(descriptor=hex(d), payload_count=payload_count,
    empty_count=empty_count, reducer='0x1004c4980', table='0x1004c61fc', actions=actions), ensure_ascii=False, indent=2), encoding='utf-8')

ranges = {
    'subject-selection.txt': [(0x100550a9c,0x100550d18),(0x100569408,0x10056b304),(0x10056c5c8,0x10056c604)],
    'outline-rendering.txt': [(0x1004d1b20,0x1004d221c),(0x100568bb4,0x100569408),(0x10056bce8,0x10056bed4),(0x10056c28c,0x10056c490)],
    'state-and-timing.txt': [(0x1004c4980,0x1004c87e0),(0x1004c885c,0x1004c9b10),(0x1004ce994,0x1004ced70),(0x1004ad09c,0x1004ad340),(0x1004b4cc0,0x1004b4ce8)],
    'dynamic-media.txt': [(0x100552000,0x1005522d0),(0x100552d74,0x1005539b0),(0x100554720,0x1005547f8),(0x100554b04,0x100554b60),(0x1005596d0,0x1005599c0),(0x10055aa00,0x10055aa54),(0x10055acf8,0x10055ad64),(0x10056bbc8,0x10056bce8)],
    'crop-coordinates.txt': [(0x10055ccf4,0x10055cf10),(0x10055f348,0x10055f480)],
}
streams = {name: [] for name in ranges}
for line in (m.O / 'annotated-capture-disassembly.txt').open(encoding='utf-8'):
    match = re.match(r'([0-9a-f]+):', line)
    if not match: continue
    addr = int(match[1],16)
    for name, spans in ranges.items():
        if any(lo <= addr < hi for lo,hi in spans): streams[name].append(line)
for name, lines in streams.items(): (out / name).write_text(''.join(lines),encoding='utf-8')
print(json.dumps({'actions':len(actions), 'evidence_lines':{n:len(v) for n,v in streams.items()},
    'one_second_duration_words':[hex(m.u64(0x1018599b0)),hex(m.u64(0x1018599b8))]},ensure_ascii=False))
