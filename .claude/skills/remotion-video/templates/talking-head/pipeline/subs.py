"""Subtitle text = what was actually said, with Whisper's mishearings corrected by hand."""
import json
from lib import norm

# (heard, correct) per scene; matched on normalized tokens in order of appearance.
FIX = {
    "s01": [("berubah", "berupa")],
    "s02": [("pengalaman yang", "pengalamannya"), ("mempengaruhi", "memengaruhi")],
    "s03": [("lakar", "latar"), ("kebutuhanannya.", "kebutuhannya.")],
    "s04": [("tersiar", "tersier"), ("koncep", "konsep"), ("raka", "Raka")],
    "s05": [("pengecehan", "pemecahan"), ("antara anggota", "antaranggota"), ("dari pengalaman yang", "dari pengalamannya"), ("menaik", "mengenai")],
    "s06": [("supaya", "Supaya"), ("membahas 4", "membahas empat"), ("ketampilan", "keterampilan"),
            ("berkempang tinggi.", "bertumpang tindih."), ("terbagi,", "berbagi,")],
    "s07": [("Wedding", "Gladding"), ("contoh, Raka,", "contoh Raka,"), ("kerjasama", "kerja sama")],
    "s08": [("konsuling", "konseling"), ("konsuling", "konseling"), ("konsuler", "konselor"), ("konsesi", "sesi"),
            ("keunyekan", "keunikan"), ("konsuler", "konselor"), ("bersanya", "bertanya"), ("bekal,", "peka,")],
    "s09": [("Oke", "Oke,"), ("kesedaran", "kesadaran"), ("kelayan.", "klien."), ("kesedaran", "kesadaran"),
            ("ketidakpandirian.", "ketidakmandirian."), ("menerapi diri.", "menilai perilaku.")],
    "s10": [("5", "lima"), ("respon", "respons"), ("membangun.", "membaur."), ("sebagai salah", "sebagai masalah")],
    "s11": [("non-fermal", "nonverbal"), ("menanggap", "menganggap"), ("dia mendapat", "diam dapat"),
            ("konteksi.", "konteksnya."), ("privilege", "privilese"), ("non-dominal.", "nondominan."),
            ("diperlihatkan", "terlihat"), ("diambilkan,", "diabaikan,")],
    "s12": [("dan lingkungan baru", "di lingkungan baru"), ("sampai", "sambil")],
    "s13": [("sekarang", "Sekarang"), ("kepada kita.", "kepada Raka."), ("dari kehidupan", "dalam kehidupan"),
            ("mengahami", "memahami"), ("konteks layanan.", "konteks klien.")],
    "s14": [("sembuhkan.", "simpulkan."), ("mencangkup", "mencakup"), ("pintas", "lintas"), ("sekedar", "sekadar")],
}

MAXC = 84  # two lines of ~42
# never end a cue on these
WEAK = {"dan", "di", "yang", "atau", "dengan", "untuk", "pada", "dari", "serta", "ke", "sebagai", "bahwa", "dalam", "juga", "tidak", "bisa"}


def spoken_words(sid):
    ws = json.load(open(f"words/{sid}.json"))["words"]
    out = []
    for w in ws:
        t = w["w"].strip()
        if t.startswith("-") and out:  # whisper splits "sehari -hari"
            out[-1]["w"] += t
            out[-1]["e"] = w["e"]
        else:
            out.append({"w": t, "s": w["s"], "e": w["e"]})
    pos = 0
    for heard, right in FIX.get(sid, []):
        h = [norm(x) for x in heard.split()]
        for i in range(pos, len(out) - len(h) + 1):
            if [norm(out[i + k]["w"]) for k in range(len(h))] == h:
                s, e = out[i]["s"], out[i + len(h) - 1]["e"]
                new = right.split()
                rep = [{"w": t, "s": s + (e - s) * k / len(new), "e": s + (e - s) * (k + 1) / len(new)} for k, t in enumerate(new)]
                out[i : i + len(h)] = rep
                pos = i + len(new)
                break
        else:
            raise ValueError(f"{sid}: fix not found: {heard}")
    return out


def cues(ws):
    """One sentence (or a pause-delimited run) at a time; long ones are cut into
    near-equal chunks, preferring breaks after commas. Each chunk <= ~84 chars."""
    import math
    runs, cur = [], []
    for k, w in enumerate(ws):
        cur.append(w)
        nxt = ws[k + 1] if k + 1 < len(ws) else None
        if nxt is None or w["w"][-1] in ".?!" or nxt["s"] - w["e"] > 0.6:
            runs.append(cur)
            cur = []
    res = []
    for run in runs:
        text_len = len(" ".join(w["w"] for w in run))
        n = max(1, math.ceil(text_len / MAXC))
        if n == 1:
            chunks = [run]
        else:
            cum, acc = [], 0
            for w in run:
                acc += len(w["w"]) + 1
                cum.append(acc)
            cuts, last = [], 0
            for q in range(1, n):
                target = text_len * q / n
                best = min(
                    range(last + 1, len(run) - 1),
                    key=lambda i: abs(cum[i] - target) - (20 if run[i]["w"][-1] in ",:;" else 0)
                    + (14 if norm(run[i]["w"]) in WEAK else 0),
                )
                cuts.append(best + 1)
                last = best + 1
            bounds = [0] + cuts + [len(run)]
            chunks = [run[bounds[i] : bounds[i + 1]] for i in range(len(bounds) - 1)]
        for c in chunks:
            res.append({"s": c[0]["s"], "e": c[-1]["e"], "text": " ".join(w["w"] for w in c)})
    for c in res:
        t = c["text"]
        if len(t) > 44:
            mid = len(t) // 2
            cands = [i for i, ch in enumerate(t) if ch == " "]
            ok = [i for i in cands if i <= 46 and len(t) - i - 1 <= 46]
            pool = ok or cands
            i = min(pool, key=lambda i: abs(i - mid) - (8 if t[i - 1] in ",:;" and ok else 0))
            c["text"] = t[:i] + "\n" + t[i + 1 :]
    return res


if __name__ == "__main__":
    import sys
    for sid in sys.argv[1:] or FIX:
        for c in cues(spoken_words(sid)):
            print(f"{sid} {c['s']:6.2f}-{c['e']:6.2f} | {c['text']!r}")
