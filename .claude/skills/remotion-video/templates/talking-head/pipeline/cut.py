"""Cut each scene from its takes: trim, join, grade, clean audio. Writes public/k7/sNN.mp4
and words/sNN.json (word timings on the scene's own timeline)."""
import json, os, subprocess, sys
from lib import words, find, norm
from scenes import EDL, WARM

SRC = os.path.expanduser("~/Downloads/tugas video")
OUT = "/home/suji/CODE/remotion-studio/public/k7"
os.makedirs(OUT, exist_ok=True)
os.makedirs("words", exist_ok=True)
man = {m["id"]: m for m in json.load(open("manifest.json"))}
PAD_IN, PAD_OUT = 0.30, 0.40
# hand-set in-points where Whisper's word timing was unreliable (seconds in the clip)
IN_OVERRIDE = {("s06", "c18"): 11.40}

only = set(sys.argv[1:])
for sid, segs in EDL.items():
    if only and sid not in only:
        continue
    parts, outwords, t0 = [], [], 0.0
    for cid, a, b in segs:
        ws = words(cid)
        i = find(ws, a)
        j = find(ws, b, after=ws[i]["s"]) + len([t for t in b.split() if norm(t)]) - 1
        prev_e = ws[i - 1]["e"] if i > 0 else 0.0
        next_s = ws[j + 1]["s"] if j + 1 < len(ws) else man[cid]["dur"]
        s = max(ws[i]["s"] - PAD_IN, (prev_e + ws[i]["s"]) / 2, 0.0)
        e = min(ws[j]["e"] + PAD_OUT, (ws[j]["e"] + next_s) / 2, man[cid]["dur"])
        s = IN_OVERRIDE.get((sid, cid), s)
        parts.append((cid, s, e))
        for w in ws[i : j + 1]:
            outwords.append({**w, "s": w["s"] - s + t0, "e": w["e"] - s + t0, "clip": cid})
        t0 += e - s
    # build ffmpeg graph
    cmd = ["ffmpeg", "-v", "error", "-y"]
    for cid, s, e in parts:
        cmd += ["-ss", f"{s:.3f}", "-t", f"{e - s:.3f}", "-i", os.path.join(SRC, man[cid]["file"])]
    fl = []
    for k, (cid, s, e) in enumerate(parts):
        d = e - s
        grade = ",colorchannelmixer=rr=1.034:gg=1.072:bb=1.122" if cid in WARM else ""
        fl.append(f"[{k}:v]fps=30,scale=1280:720,setsar=1,format=yuv420p{grade},settb=AVTB,setpts=PTS-STARTPTS[v{k}]")
        fl.append(
            f"[{k}:a]aresample=48000,asetpts=PTS-STARTPTS,afade=t=in:d=0.06,afade=t=out:st={d - 0.08:.3f}:d=0.08[a{k}]"
        )
    n = len(parts)
    fl.append("".join(f"[v{k}][a{k}]" for k in range(n)) + f"concat=n={n}:v=1:a=1[v][a0]")
    fl.append("[a0]highpass=f=80,afftdn=nf=-28,loudnorm=I=-16:TP=-1.5:LRA=9,aresample=48000[a]")
    cmd += ["-filter_complex", ";".join(fl), "-map", "[v]", "-map", "[a]",
            "-c:v", "libx264", "-crf", "17", "-preset", "medium", "-g", "30",
            "-c:a", "aac", "-b:a", "192k", "-ar", "48000", "-movflags", "+faststart", f"{OUT}/{sid}.mp4"]
    subprocess.run(cmd, check=True)
    dur = float(subprocess.check_output(["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", f"{OUT}/{sid}.mp4"]))
    json.dump({"dur": dur, "parts": parts, "words": outwords}, open(f"words/{sid}.json", "w"), ensure_ascii=False)
    print(sid, f"{dur:.1f}s", [(c, round(s, 2), round(e, 2)) for c, s, e in parts], flush=True)
