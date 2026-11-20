"""Helpers: load word timings, find phrases, align to script text."""
import json, re, difflib, unicodedata

def norm(w):
    w = unicodedata.normalize("NFKC", w).lower()
    return re.sub(r"[^0-9a-zà-ÿ]+", "", w)

def words(cid):
    segs = json.load(open(f"/home/suji/CODE/k7-video/transcripts/{cid}.json"))
    out = []
    for s in segs:
        for w in s["words"]:
            t = w["w"].strip()
            if norm(t):
                out.append({"w": t, "n": norm(t), "s": w["s"], "e": w["e"]})
    return out

def find(ws, phrase, after=0.0, last=False):
    """Return index of first word of `phrase` (fuzzy) in ws starting at time >= after."""
    toks = [norm(t) for t in phrase.split() if norm(t)]
    hits = []
    for i in range(len(ws) - len(toks) + 1):
        if ws[i]["s"] < after - 0.01:
            continue
        sc = sum(difflib.SequenceMatcher(None, ws[i + j]["n"], toks[j]).ratio() for j in range(len(toks))) / len(toks)
        if sc > 0.8:
            hits.append((i, sc))
    if not hits:
        raise ValueError(f"phrase not found: {phrase!r} after {after}")
    # a run of neighbouring indices is one occurrence; take its best-scoring index
    groups = []
    for i, sc in hits:
        if groups and i - groups[-1][-1][0] <= 1:
            groups[-1].append((i, sc))
        else:
            groups.append([(i, sc)])
    best = [max(g, key=lambda x: x[1]) for g in groups]
    if last:
        return best[-1][0]
    # first near-exact occurrence; otherwise the closest match anywhere
    for i, sc in best:
        if sc >= 0.93:
            return i
    return max(best, key=lambda x: x[1])[0]

def t_start(ws, phrase, after=0.0, last=False):
    return ws[find(ws, phrase, after, last)]["s"]

def t_end(ws, phrase, after=0.0, last=False):
    toks = [t for t in phrase.split() if norm(t)]
    i = find(ws, phrase, after, last)
    return ws[i + len(toks) - 1]["e"]

def align(spoken, script_text):
    """spoken: list of word dicts (times already on the output timeline).
    Returns list of (display_word, s, e): script spelling where the speaker matched or
    whisper plainly misheard, spoken word where the speaker added words."""
    sc = script_text.split()
    a = [w["n"] for w in spoken]
    b = [norm(t) for t in sc]
    sm = difflib.SequenceMatcher(None, a, b, autojunk=False)
    out = []
    for op, i1, i2, j1, j2 in sm.get_opcodes():
        if op == "equal":
            for k in range(i2 - i1):
                w = spoken[i1 + k]
                out.append((sc[j1 + k], w["s"], w["e"]))
        elif op == "replace":
            n_sp, n_sc = i2 - i1, j2 - j1
            if n_sp == n_sc:
                for k in range(n_sp):
                    w = spoken[i1 + k]
                    out.append((sc[j1 + k], w["s"], w["e"]))
            else:
                # spread script words over the spoken span
                s0, e0 = spoken[i1]["s"], spoken[i2 - 1]["e"]
                for k in range(n_sc):
                    out.append((sc[j1 + k], s0 + (e0 - s0) * k / n_sc, s0 + (e0 - s0) * (k + 1) / n_sc))
        elif op == "insert":
            pass  # script words not spoken
        elif op == "delete":
            for k in range(i1, i2):
                w = spoken[k]
                out.append((w["w"], w["s"], w["e"]))
    return out
