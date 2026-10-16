"""Read-only Mach-O metadata and focused evidence extraction; does not execute target."""
import json, re, struct
from pathlib import Path

B = Path(__file__).resolve().parent / 'evidence' / 'ipa'
O = B / 'capture-flow'
O.mkdir(exist_ok=True)
b = (B / 'SnapWords').read_bytes()
sections = json.loads((B / 'sections.json').read_text())
base = 0x100000000

def off(a):
    for s in sections:
        if s['address'] <= a < s['address'] + s['size']:
            return s['offset'] + a - s['address']
    if base <= a < base + len(b):
        return a-base
    raise ValueError(hex(a))

def zerofill(a):
    return any(s['offset']==0 and s['address']<=a<s['address']+s['size'] for s in sections)
def u32(a): return 0 if zerofill(a) else struct.unpack_from('<I', b, off(a))[0]
def i32(a): return struct.unpack_from('<i', b, off(a))[0]
def u64(a): return 0 if zerofill(a) else struct.unpack_from('<Q', b, off(a))[0]
def rel(a): return a + i32(a) if i32(a) else 0
def ptr(a):
    x = u64(a)
    if x == 0: return 0
    if x >> 63: return 0  # imported binding, not an in-image pointer
    return base + (x & ((1 << 36)-1))
def string(a):
    p = off(a)
    return b[p:b.index(b'\0', p)].decode('utf-8', errors='replace')
def save(n,x): (O/n).write_text(json.dumps(x,ensure_ascii=False,indent=2),encoding='utf-8')

pattern = re.compile(r'Camera|StickerLayer|StickerCutout|StickerDust|StickerOutline|RecognitionPipeline|VisionManager|DustEffect|MetalEngine|DisplayLink|SimpleLayer|Ripple|RecognitionResult|RecognitionImage|StickerResult|ContainerBar|CameraBar|CarmeraBar|SoundEffect|Haptic', re.I)
def context_name(a, depth=0):
    if not a or depth>8: return ''
    try:
        kind=u32(a)&31
        if kind not in (0,1,2,3,4,16,17,18): return ''
        parent=rel(a+4)&~1
        name=string(rel(a+8))
        prefix=context_name(parent,depth+1)
        return (prefix+'.' if prefix else '')+name
    except (ValueError,struct.error): return ''
types=[]
for s in sections:
    if s['name'] not in ('__swift5_types','__swift5_types2'): continue
    for p in range(s['address'],s['address']+s['size'],4):
        try:
            a=rel(p); name=context_name(a)
            if not pattern.search(name): continue
            fields=[]; f=rel(a+16)
            if f:
                size=struct.unpack_from('<H',b,off(f+10))[0]; count=u32(f+12)
                if size>=12 and count<3000:
                    for j in range(count):
                        r=f+16+j*size
                        fields.append({'name': string(rel(r+8)), 'record':hex(r), 'flags':u32(r)})
            types.append({'name':name,'descriptor':hex(a),'kind':u32(a)&31,'accessor':hex(rel(a+12)), 'fields':fields})
        except (ValueError,struct.error,IndexError): pass
save('swift-types.json',types)

classes=[]
s=next(s for s in sections if s['name']=='__objc_classlist')
for p in range(s['address'],s['address']+s['size'],8):
    try:
        a=ptr(p); ro=ptr(a+32)&~7; name=string(ptr(ro+24))
        if not pattern.search(name): continue
        methods=[]; ivars=[]
        il=ptr(ro+48)
        if il:
            size=u32(il); count=u32(il+4)
            if size>=32 and count<3000:
                for j in range(count):
                    r=il+8+j*size
                    ivars.append({'name':string(ptr(r+8)), 'initial_offset_before_runtime':u32(ptr(r)), 'size':u32(r+28)})
        for kind,cls in [('instance',a),('class',ptr(a))]:
            cro=ptr(cls+32)&~7; ml=ptr(cro+32)
            if not ml: continue
            flags=u32(ml); count=u32(ml+4); size=flags&0xfffc
            for j in range(count):
                r=ml+8+j*size
                if flags&0x80000000:
                    sel=rel(r)
                    if not flags&0x40000000: sel=ptr(sel)
                    imp=rel(r+8)
                else: sel=ptr(r); imp=ptr(r+16)
                methods.append({'kind':kind,'selector':string(sel),'imp':hex(imp)})
        classes.append({'name':name,'class':hex(a),'ro':hex(ro),'methods':methods,'ivars':ivars})
    except (ValueError,struct.error,IndexError): pass
save('objc-classes.json',classes)

strings=json.loads((B/'strings.json').read_text(encoding='utf-8'))
selected=[x for x in strings if pattern.search(x['text']) or re.search(r'dustEffect|camera\.|recognition\.pipeline|sticker\.recognition|visionSubjectExtraction|visionEdgeExtraction|outlineRendering',x['text'])]
save('selected-strings.json',selected)
inventory=json.loads((B/'inventory.json').read_text())
save('animation-resources.json',[x for x in inventory if re.search(r'metal|shader|dust|capture|shutter|camera|sticker|\.wav|\.mp3|\.aiff|\.caf|\.riv|\.json$',x['path'],re.I)])
print(json.dumps({'types':len(types),'classes':len(classes),'strings':len(selected)}))
