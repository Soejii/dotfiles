import json
tl=json.load(open("/home/suji/CODE/remotion-studio/src/k7/timeline.json"))
def ts(f):
    ms=round(f/30*1000); h,ms=divmod(ms,3600000); m,ms=divmod(ms,60000); s,ms=divmod(ms,1000)
    return f"{h:02d}:{m:02d}:{s:02d},{ms:03d}"
with open("out/k7-subtitle.srt","w") as o:
    for i,c in enumerate(tl["subs"],1):
        o.write(f"{i}\n{ts(c['from'])} --> {ts(c['to'])}\n{c['text']}\n\n")
print(len(tl["subs"]))
