"""Annotate retained LLVM instructions with decoded selector stubs and address candidates."""
import bisect,json,re,struct
from analyze_capture_flow import B,O,b,base,sections,off,ptr,string,save,u32

strings=json.loads((B/'strings.json').read_text(encoding='utf-8'))
stringmap={base+int(x['offset'],16):x['text'] for x in strings}
starts=sorted(int(x,16) for x in (B/'function-starts.txt').read_text().splitlines() if re.fullmatch('[0-9a-fA-F]{16}',x))
def function(a):
    i=bisect.bisect_right(starts,a)-1
    return starts[i] if i>=0 else a

def adrp(a,w):
    v=(((w>>5)&0x7ffff)<<2)|((w>>29)&3)
    if v&(1<<20): v-=1<<21
    return (a&~4095)+(v<<12)
stubmap={}
s=next(s for s in sections if s['name']=='__objc_stubs')
for a in range(s['address'],s['address']+s['size'],32):
    try:
        w=u32(a);v=u32(a+4)
        if w&0x9f000000==0x90000000 and v&0xffc00000==0xf9400000:
            address=adrp(a,w)+((v>>10)&4095)*8
            stubmap[a]=string(ptr(address))
    except (ValueError,struct.error): pass
save('objc-selector-stubs.json',[{'address':hex(a),'selector':v} for a,v in stubmap.items()])

xrefs=[];callers={}; registers={};linepat=re.compile(r'^([0-9a-f]+):\s+(\S+)\s*(.*)')
cur=None
with (O/'annotated-capture-disassembly.txt').open('w',encoding='utf-8') as out:
    for line in (B/'disassembly.txt').open(encoding='utf-8'):
        m=linepat.match(line)
        if not m: continue
        a=int(m[1],16); op=m[2];args=m[3]; fn=function(a)
        if fn!=cur:
            registers={};cur=fn
            if 0x10045d000<=a<0x10056e000: out.write('\nFUNCTION '+hex(fn)+'\n')
        extras=[]
        if op=='bl':
            target=re.match(r'0x([0-9a-f]+)',args)
            if target:
                t=int(target[1],16)
                if 0x10045d000<=t<0x10056e000: callers.setdefault(hex(t),[]).append({'at':hex(a),'function':hex(fn)})
                if t in stubmap: extras.append('SEL '+stubmap[t])
            for r in range(19): registers.pop(r,None)
        if not 0x10045d000<=a<0x10056e000: continue
        w=u32(a)
        if w&0x9f000000==0x90000000:
            registers[w&31]=(adrp(a,w),a)
        elif w&0xff000000==0x91000000:
            src=(w>>5)&31;dst=w&31
            if src in registers and a-registers[src][1]<40:
                addr=registers[src][0]+((w>>10)&4095)*(4096 if w&(1<<22) else 1)
                if addr in stringmap:
                    v=stringmap[addr]
                    extras.append('STRING '+v[:220]);xrefs.append({'at':hex(a),'function':hex(fn),'target':hex(addr),'text':v})
                registers[dst]=(addr,a)
            elif dst in registers: del registers[dst]
        elif w&0xffc00000 in (0xfd400000,0xbd400000): # scalar float literal through ADRP
            src=(w>>5)&31
            if src in registers and a-registers[src][1]<40:
                isdouble=w&0xffc00000==0xfd400000
                addr=registers[src][0]+((w>>10)&4095)*(8 if isdouble else 4)
                try: extras.append(('DOUBLE ' if isdouble else 'FLOAT ')+repr(struct.unpack_from('<d' if isdouble else '<f',b,off(addr))[0]))
                except (ValueError,struct.error): pass
        else:
            dest=re.match(r'[xw](\d+),',args)
            if dest and op not in ('str','stur','stp','cmp','cmn','tst','ccmp'):
                registers.pop(int(dest[1]),None)
        out.write(line.rstrip()+(' ; '+' ; '.join(extras) if extras else '')+'\n')
save('capture-string-xrefs.json',xrefs)
save('capture-function-callers.json',callers)
print(json.dumps({'selector_stubs':len(stubmap),'string_xrefs':len(xrefs),'callee_functions':len(callers)}))
