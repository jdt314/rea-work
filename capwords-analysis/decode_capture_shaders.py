"""Extract retained Metal AIR bitcode and print LLVM IR with the existing Clang.

Clang rewrites the output target triple/data layout to its Windows default.
These .ll files are semantic inspection aids, not Apple-buildable originals.
The exact original bitcode is retained separately with SHA-256 digests.
"""
import hashlib,json,re,struct,subprocess
from pathlib import Path

P=Path(__file__).resolve().parent/'evidence'/'ipa'/'capture-flow'
data=(P/'default.metallib').read_bytes()
records=[]
for i,m in enumerate(re.finditer(b'\xde\xc0\x17\x0b',data)):
    at=m.start()
    magic,version,offset,size,cpu=struct.unpack_from('<IIIII',data,at)
    payload=data[at+offset:at+offset+size]
    if not payload.startswith(b'BC\xc0\xde') or len(payload)!=size:
        raise ValueError('Invalid bitcode wrapper at '+hex(at))
    bc=P/('shader-%02d.bc'%i)
    ll=bc.with_suffix('.ll')
    bc.write_bytes(payload)
    result=subprocess.run(['C:/Program Files/LLVM/bin/clang.exe','-S','-emit-llvm','-x','ir',str(bc),'-o',str(ll)],capture_output=True,text=True)
    if result.returncode: raise RuntimeError(result.stderr)
    text=ll.read_text(encoding='utf-8')
    records.append({'index':i,'wrapper_offset':hex(at),'size':size,
                    'bitcode_sha256':hashlib.sha256(payload).hexdigest(),
                    'source_filename':re.search(r'^source_filename = "(.*)"',text,re.M)[1],
                    'stderr':result.stderr})
(P/'metallib-bitcode-index.json').write_text(json.dumps(records,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps({'decoded':len(records),'modules':[r['source_filename'] for r in records]}))
