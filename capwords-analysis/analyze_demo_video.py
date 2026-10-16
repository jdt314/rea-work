"""Parse MP4 sample timing and assemble timestamped WinRT contact sheets."""
import hashlib,json,struct,sys
from pathlib import Path
from PIL import Image,ImageDraw
sys.stdout.reconfigure(encoding='utf-8')
root=Path(__file__).resolve().parent.parent
source=root/'m2.mp4'; out=root/'capwords-analysis/evidence/video/m2'
out.mkdir(parents=True,exist_ok=True)
data=source.read_bytes()
def boxes(lo,hi):
    while lo+8<=hi:
        size,typ=struct.unpack_from('>I4s',data,lo); header=8
        if size==1: size=struct.unpack_from('>Q',data,lo+8)[0];header=16
        if size==0:size=hi-lo
        if size<header or lo+size>hi:raise ValueError('Invalid box')
        yield typ.decode('latin1'),lo+header,lo+size
        lo+=size
def child(lo,hi,name): return next((a,b) for t,a,b in boxes(lo,hi) if t==name)
def u32(p):return struct.unpack_from('>I',data,p)[0]
moov=child(0,len(data),'moov'); tracks=[]
for typ,a,b in boxes(*moov):
    if typ!='trak':continue
    mdia=child(a,b,'mdia'); h,_=child(*mdia,'hdlr'); handler=data[h+8:h+12].decode('latin1')
    md,_=child(*mdia,'mdhd'); version=data[md];ts=u32(md+(20 if version else 12))
    dur=struct.unpack_from('>Q' if version else '>I',data,md+(24 if version else 16))[0]
    stbl=child(*child(*mdia,'minf'),'stbl'); stts,_=child(*stbl,'stts')
    runs=[struct.unpack_from('>II',data,stts+8+i*8) for i in range(u32(stts+4))]
    durations=[dt for n,dt in runs for _ in range(n)]
    offsets=[0]*len(durations)
    for ct,p,q in boxes(*stbl):
        if ct=='ctts':
            sign='i' if data[p]==1 else 'I';offsets=[]
            for i in range(u32(p+4)):
                n=u32(p+8+8*i);v=struct.unpack_from('>'+sign,data,p+12+8*i)[0];offsets.extend([v]*n)
    dts=0;samples=[]
    for i,dt in enumerate(durations):
        samples.append(dict(decode_index=i,dts=dts/ts,pts=(dts+offsets[i])/ts,duration=dt/ts));dts+=dt
    presentation=sorted(samples,key=lambda x:x['pts'])
    first=presentation[0]['pts'] if presentation else 0
    for i,s in enumerate(presentation):s.update(presentation_index=i,relative_pts=s['pts']-first)
    desc,_=child(*stbl,'stsd');codec=data[desc+12:desc+16].decode('latin1')
    track=dict(handler=handler,codec=codec,timescale=ts,media_duration=dur/ts,sample_count=len(samples),duration_runs=runs,
               average_samples_per_second=len(samples)/(sum(durations)/ts),first_pts=first)
    if handler=='vide':
        entry=desc+8;track.update(width=struct.unpack_from('>H',data,entry+32)[0],height=struct.unpack_from('>H',data,entry+34)[0])
        (out/'frame-timestamps.json').write_text(json.dumps(presentation,indent=2),encoding='utf-8')
    tracks.append(track)
meta=dict(source='m2.mp4',sha256=hashlib.sha256(data).hexdigest(),size=len(data),tracks=tracks,
          extraction='Windows MediaComposition.GetThumbnailAsync, NearestFrame; filenames denote requested seek times, not returned PTS')
(out/'metadata.json').write_text(json.dumps(meta,indent=2),encoding='utf-8')
print(json.dumps(meta,ensure_ascii=False,indent=2))
folders=[out]+[p for p in out.iterdir() if p.is_dir()]
for folder in folders:
    frames=sorted(folder.glob('t*.jpg'))
    if not frames:continue
    for start in range(0,len(frames),30):
        subset=frames[start:start+30];cw,ch=180,420
        sheet=Image.new('RGB',(cw*6,ch*5),(235,235,235));draw=ImageDraw.Draw(sheet)
        for j,p in enumerate(subset):
            im=Image.open(p).convert('RGB');im.thumbnail((cw,ch-24))
            x=(j%6)*cw;y=(j//6)*ch
            sheet.paste(im,(x+(cw-im.width)//2,y+24));draw.text((x+5,y+5),'seek %.3fs'%(int(p.stem[1:])/1000),fill='black')
        sheet.save(folder/('contact-%03d.jpg'%(start//30)),quality=90)
    print('contact sheets:',folder,len(frames))
