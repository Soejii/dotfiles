import json,subprocess,sys
from faster_whisper import WhisperModel
m=WhisperModel("large-v3-turbo",device="cpu",compute_type="int8",cpu_threads=16)
ids=sys.argv[1:] or [f"s{i:02d}" for i in range(1,15)]
for sid in ids:
    subprocess.run(["ffmpeg","-v","error","-y","-i",f"/home/suji/CODE/remotion-studio/public/k7/{sid}.mp4","-ac","1","-ar","16000",f"audio/{sid}.wav"],check=True)
    segs,_=m.transcribe(f"audio/{sid}.wav",language="id",vad_filter=True,vad_parameters={"min_silence_duration_ms":300},word_timestamps=True)
    out=[{"s":s.start,"e":s.end,"text":s.text} for s in segs]
    json.dump(out,open(f"qc/{sid}.json","w"),ensure_ascii=False)
    print(sid,"ok",flush=True)
