import json,sys
from faster_whisper import WhisperModel
m=WhisperModel("large-v3-turbo",device="cpu",compute_type="int8",cpu_threads=16)
man=json.load(open("manifest.json"))
prompt="Kelompok 7, Psikologi Konseling, Gladding, Raka, psikoedukasi, overkulturalisasi, akulturasi, wellness, multikultural."
for c in man:
    segs,info=m.transcribe(f"audio/{c['id']}.wav",language="id",word_timestamps=True,initial_prompt=prompt,vad_filter=False,beam_size=5)
    out=[]
    for s in segs:
        out.append({"start":s.start,"end":s.end,"text":s.text,"words":[{"w":w.word,"s":w.start,"e":w.end,"p":w.probability} for w in s.words]})
    json.dump(out,open(f"transcripts/{c['id']}.json","w"),ensure_ascii=False)
    print(c["id"],"done",flush=True)
