"""Assemble src/k7/timeline.json: scene order, graphics on their trigger words, citations, subtitles."""
import json, re
from lib import find, norm
from subs import spoken_words, cues

FPS = 30
OVERLAP = 8
OUT = "/home/suji/CODE/remotion-studio/src/k7/timeline.json"


def F(t):
    return int(round(t * FPS))


class Scene:
    def __init__(self, sid):
        self.sid = sid
        d = json.load(open(f"words/{sid}.json"))
        self.dur = d["dur"]
        self.parts = d["parts"]
        self.ws = spoken_words(sid)
        for w in self.ws:
            w["n"] = norm(w["w"])
        self.visuals, self.cites = [], []

    def t(self, phrase, after=0.0):
        return self.ws[find(self.ws, phrase, after)]["s"]

    def splice(self, k=1):
        """time on the scene timeline where part k starts"""
        return sum(e - s for _, s, e in self.parts[:k])

    def resolve(self, x):
        if isinstance(x, (int, float)):
            return float(x)
        if x == "end":
            return self.dur
        m = re.match(r"^(.*?)([+-]\d+(\.\d+)?)?$", x)
        base, off = m.group(1).strip(), float(m.group(2) or 0)
        return (self.dur if base == "end" else self.t(base)) + off

    def add(self, kind, mode, frm, to, **props):
        a, b = self.resolve(frm), self.resolve(to)
        self.visuals.append({"kind": kind, "mode": mode, "a": a, "b": b, "props": props})
        return self

    def cite(self, text, frm, secs=7.0):
        a = self.resolve(frm)
        self.cites.append({"from": F(a), "to": F(min(a + secs, self.dur)), "text": text})
        return self

    def chip(self, text, secs=4.5):
        return self.add("chip", "overlay", 0.3, 0.3 + secs, text=text)

    def build(self):
        vis = sorted(self.visuals, key=lambda v: v["a"])
        out = []
        for v in vis:
            a = v["a"]

            def cue(x):
                if isinstance(x, str) and x.startswith("@"):
                    return F(self.resolve(x[1:]) - a)
                return x

            def walk(o):
                if isinstance(o, dict):
                    return {k: walk(val) for k, val in o.items()}
                if isinstance(o, list):
                    return [walk(val) for val in o]
                return cue(o)

            out.append({"kind": v["kind"], "mode": v["mode"], "from": F(a), "to": F(v["b"]), "props": walk(v["props"])})
        # keep the presenter in its panel while a board covers it, so it never "grows" behind the board
        main = [v for v in out if v["mode"] != "overlay"]
        for x, y in zip(main, main[1:]):
            if x["mode"] == "split" and y["mode"] == "board" and abs(y["from"] - x["to"]) <= 6:
                x["to"] = y["from"] + 18
            if x["mode"] == "board" and y["mode"] == "split" and abs(y["from"] - x["to"]) <= 6:
                y["from"] = x["to"] - 18
        return out


def C(at, title, sub=None, icon=None):
    d = {"at": at, "title": title}
    if sub:
        d["sub"] = sub
    if icon:
        d["icon"] = icon
    return d


S = {}

s = S["s01"] = Scene("s01")
s.add("name", "overlay", 0.5, "Ada persoalan-0.3", name="Rafi Mahadika Sujianto", role="Kelompok 7")
s.add("levels", "split", "Ada persoalan-0.2", "Kami dari-0.1", at=["@secara pribadi", "@dalam kelompok", "@dipengaruhi lingkungan"])
s.add("title", "board", "Kami dari-0.1", "end", topicsAt=["@kesehatan mental", "@kelompok dan komunitas", "@lintas budaya"])

s = S["s02"] = Scene("s02")
s.add("raka", "split", "Ia mahasiswa-0.2", "end", label="Raka: contoh fiktif", kicker="Tiga pertanyaan",
      items=[C("@Apa kebutuhan", "Kebutuhan pribadi", icon="person"),
             C("@Dukungan apa", "Dukungan sosial", icon="hand"),
             C("@bagaimana latar", "Konteks budaya", icon="campus")])

s = S["s03"] = Scene("s03")
s.chip("Bagian 1 · Konseling kesehatan mental")
s.add("board", "split", "Ada dua fokus-0.2", "Konselor perlu", kicker="Konseling kesehatan mental klinis",
      items=[C("@mencegah masalah", "Pencegahan dan promosi", "mencegah masalah, meningkatkan kesehatan mental", "shield"),
             C("@menangani masalah yang", "Penanganan masalah", "menangani masalah yang sudah muncul", "hand")],
      footer={"at": "@bukan hanya gangguan", "text": "Bukan hanya gangguan"})
s.add("raka", "split", "Dalam contoh Raka-0.2", "Menebak diagnosis", label="Raka", kicker="Memahami kebutuhan",
      items=[C("@apa yang membuatnya", "Apa yang dialami?", icon="question"),
             C("@bagaimana kesehariannya", "Bagaimana dampaknya?", icon="eye"),
             C("@dukungan apa yang sudah", "Dukungan apa yang tersedia?", icon="hand")])
s.cite("Gladding, 2018, Bab 18, hlm. 410–411", "Dalam bab 18+0.5", 8)

s = S["s04"] = Scene("s04")
s.add("board", "split", "pencegahan primer-0.3", "Selain itu", kicker="Tiga tingkat pencegahan",
      items=[C("@primer", "Primer", "sebelum masalah muncul", "shield"),
             C("@sekunder", "Sekunder", "masalah mulai muncul", "eye"),
             C("@tersier", "Tersier", "mencegah masalah serius menjadi kronis", "hand")])
s.add("wellness", "split", "Selain itu", "Karena itu, memahami", at=6,
      domAt=["@kondisi fisik", "@emosi", "@cara berpikir", "@hubungan sosial"])
s.cite("Gladding, 2018, Bab 18, hlm. 411, 415–417", "pencegahan primer", 8)

s = S["s05"] = Scene("s05")
sp = s.splice(1)
s.chip("Bagian 2 · Kelompok dan komunitas")
s.add("name", "overlay", 0.4, "dukungan interpersonal-1.3", name="Nuryana Dwi Karina", role="Kelompok 7")
s.add("group", "split", "dukungan interpersonal-1.0", sp - 0.9, linesAt="@Interaksi antaranggota",
      labels=[C("@dukungan interpersonal", "Dukungan interpersonal", icon="hand"),
              C("@pemecahan masalah", "Pemecahan masalah", icon="tool"),
              C("@Interaksi antaranggota", "Interaksi antaranggota", icon="chat")])
s.add("raka", "board", sp - 0.9, "Tetapi, berkumpul-0.2", label="Raka", kicker="Contoh kelompok",
      items=[C("@kesulitan penyesuaian", "Kesulitan penyesuaian", "di lingkungan pendidikan", "campus"),
             C("@serupa", "Pengalaman serupa", icon="link"),
             C("@berbeda", "sekaligus berbeda", icon="swap")])
s.cite("Gladding, 2018, Bab 9, hlm. 210", "Dalam bab 9+0.5", 8)

s = S["s06"] = Scene("s06")
s.add("board", "split", "Gladding membahas-0.2", "Jadi, seminar-0.2", kicker="Empat jenis kelompok", columns=2, dense=True,
      items=[C("@psikoedukasi", "Psikoedukasi", "belajar dan pencegahan", "book"),
             C("@Kedua", "Konseling", "persoalan hidup dan relasi", "chat"),
             C("@Ketiga", "Psikoterapi", "persoalan psikologis mendalam", "layers"),
             C("@Keempat", "Tugas / kerja", "mencapai tujuan kerja", "list")],
      footer={"at": "@tujuan utamanya", "text": "Kenali tujuan kelompok"}, highlightFrom="@tujuan utamanya")
s.cite("Gladding, 2018, Bab 9, hlm. 209–211", "Gladding membahas", 8)

s = S["s07"] = Scene("s07")
sp = s.splice(1)
s.add("ecology", "split", "Di sini-0.2", "Dalam contoh Raka-0.2", at=[0, "@kondisi lingkungan", "@dukungan sosial"])
s.add("ecology", "board", "Dalam contoh Raka-0.2", sp + 0.8, at=[-40, -40, -40], programsAt=0,
      programs=[C("@program penyambutan", "Orientasi mahasiswa baru", icon="campus"),
                C("@informasi layanan", "Akses informasi bantuan", icon="info"),
                C("@kerja sama", "Lingkungan yang mendukung", icon="hand")])
s.cite("Gladding, 2018, Bab 18, hlm. 412, 414–415", "Gladding sendiri", 8)

s = S["s08"] = Scene("s08")
s.chip("Bagian 3 · Konseling lintas budaya dan etnis", 5)
s.add("name", "overlay", 0.5, 6.0, name="Rachel Riatta Vanesia Manurung", role="Kelompok 7")
s.add("board", "split", "memahami masalah-1.0", "Tetapi, mengetahui-0.2", kicker="Budaya memengaruhi", dense=True,
      items=[C("@memahami masalah", "Cara memahami masalah", icon="mind"),
             C("@berkomunikasi", "Cara berkomunikasi", icon="chat"),
             C("@memaknai bantuan", "Cara memaknai bantuan", icon="hand"),
             C("@Nilai keluarga", "Nilai keluarga dan pengalaman sosial", icon="group")])
s.add("bigline", "board", "Gladding mengingatkan-0.2", "Pengetahuan tentang-0.2", kicker="Gladding mengingatkan",
      text="Setiap klien memiliki pengalaman yang unik")
s.cite("Gladding, 2018, Bab 3, hlm. 57–59", "Dalam konseling lintas", 8)

s = S["s09"] = Scene("s09")
s.add("board", "split", "Yang pertama-0.2", "Misalnya, jika Raka-0.2", kicker="Tiga bekal konselor",
      items=[C("@pengetahuan", "Pengetahuan", "cara pandang dan konteks budaya klien", "book"),
             C("@kesadaran diri", "Kesadaran diri", "nilai dan prasangka yang kita bawa", "eye"),
             C("@keterampilan", "Keterampilan", "menerapkan pemahaman dalam konseling", "tool")])
s.add("raka", "split", "Sikap yang lebih-0.2", "end", label="Raka", kicker="Contoh pertanyaan",
      items=[C(8, "“Apa arti keluarga dalam keputusanmu?”", icon="bubble"),
             C("@dukungan seperti apa", "“Dukungan seperti apa yang kamu butuhkan?”", icon="bubble")])
s.cite("Gladding, 2018, Bab 3, hlm. 57–59", "Yang pertama", 8)

s = S["s10"] = Scene("s10")
s.add("board", "split", 0.2, "Lalu yang kedua-0.2", kicker="Kendala konseling multikultural", strip=0,
      heading="Pengukuran kompetensi", headingSize=54,
      items=[C("@alat ukur", "Dukungan statistik dan ketepatan ukur", "masih menjadi persoalan", "meter"),
             C("@Rasa percaya diri", "Percaya diri ≠ kompetensi", icon="question")])
s.add("board", "split", "Lalu yang kedua-0.2", "Jika semuanya-0.2", strip=1, heading="Overkulturalisasi", headingSize=54,
      items=[C("@keliru menganggap", "Kemiskinan atau diskriminasi", "keliru dianggap sebagai pola budaya", "swap"),
             C("@biaya transportasi", "Biaya transportasi", "bukan sifat kelompok asal", "bus")])
s.cite("Gladding, 2018, Bab 3, hlm. 56", 0.5, 8)

s = S["s11"] = Scene("s11")
s.add("board", "split", 0.2, "Lalu yang keempat-0.2", strip=2, heading="Bahasa dan komunikasi", headingSize=54,
      items=[C("@memeriksa pemahamannya", "Periksa makna", "jangan langsung menafsirkan", "bubble"),
             C("@Dalam contoh sederhana", "Diam pun bisa bermakna beragam", "pahami melalui konteksnya", "chat")])
s.add("board", "split", "Lalu yang keempat-0.2", "Karena itu-0.2", strip=3, heading="Rasisme", headingSize=54,
      items=[C("@kekuasaan", "Kekuasaan dan privilese", "terhadap kelompok nondominan", "structure"),
             C("@interaksi individu", "Interaksi individu", icon="person"),
             C("@struktur sosial", "Struktur sosial", icon="structure")])
s.cite("Gladding, 2018, Bab 3, hlm. 56", 0.5, 8)

s = S["s12"] = Scene("s12")
s.add("two", "split", 0.2, "Konselor perlu-0.2", at="@Dalam proses ini", strip=4, heading="Akulturasi",
      sub="menyesuaikan diri di antara pengaruh budaya")
s.add("board", "split", "Tujuannya bukan-0.2", "end", kicker="Lima kendala konseling multikultural", dense=True,
      items=[C(0, "Pengukuran", icon="meter"), C(4, "Overkulturalisasi", icon="swap"), C(8, "Bahasa", icon="bubble"),
             C(12, "Rasisme", icon="structure"), C(16, "Akulturasi", icon="link")])
s.cite("Gladding, 2018, Bab 3, hlm. 56–58", "Dalam proses ini", 8)

s = S["s13"] = Scene("s13")
sp = s.splice(1)
s.chip("Sintesis")
items3 = [C("@Dari sudut kesehatan", "Kesehatan mental", "fokus kebutuhan", "heart"),
          C("@Dari sudut kelompok", "Kelompok", "bentuk layanan", "group"),
          C("@dari sudut komunitas", "Komunitas", "lingkungan dan akses", "campus")]
s.add("raka", "split", "Dari sudut kesehatan-0.2", sp - 0.9, label="Raka", kicker="Kembali kepada Raka", items=items3)
s.add("raka", "board", sp - 0.9, "Ketiga pembahasan-0.2", label="Raka", kicker="Kembali kepada Raka",
      items=[C(-40, "Kesehatan mental", "fokus kebutuhan", "heart"), C(-40, "Kelompok", "bentuk layanan", "group"),
             C(-40, "Komunitas", "lingkungan dan akses", "campus"),
             C("@kepekaan multikultural", "Multikultural", "pemahaman konteks", "link")])
s.cite("Sintesis: Gladding, 2018, Bab 3, 9, dan 18", "Dari sudut kesehatan", 8)

s = S["s14"] = Scene("s14")
s.chip("Penutup")
s.add("board", "split", "Pertama-0.2", "Saat ketiganya-0.2", kicker="Tiga kesimpulan",
      items=[C("@Pertama", "Pencegahan, penanganan, kesejahteraan", icon="shield"),
             C("@Kedua", "Dukungan sosial dan lingkungan", icon="group"),
             C("@Ketiga", "Kepekaan terhadap konteks budaya", icon="campus")])
s.add("bigline", "board", "Sekian-0.1", "end", kicker="Kelompok 7 | Psikologi Konseling", text="Terima kasih",
      sub="Apakah layanan memahami orang yang dibantu?")

scenes, t0 = [], 0
for sid, sc in S.items():
    frames = F(sc.dur)
    scenes.append({"id": sid, "src": f"k7/{sid}.mp4", "start": t0, "frames": frames, "visuals": sc.build(), "cites": sc.cites})
    t0 += frames - OVERLAP
# end cards: references then credits
REF, CRED = 15 * FPS, 10 * FPS
scenes.append({"id": "s15", "src": None, "start": t0, "frames": REF + CRED,
               "visuals": [{"kind": "refs", "mode": "board", "from": 0, "to": REF, "props": {}},
                           {"kind": "credits", "mode": "board", "from": REF, "to": REF + CRED,
                            "props": {"names": ["Rafi Mahadika Sujianto", "Nuryana Dwi Karina", "Rachel Riatta Vanesia Manurung"]}}],
               "cites": []})
total = t0 + REF + CRED

subs = []
for sc in scenes[:-1]:
    for c in cues(S[sc["id"]].ws):
        subs.append({"from": sc["start"] + F(c["s"]), "to": sc["start"] + F(c["e"]) + 6, "text": c["text"]})
for a, b in zip(subs, subs[1:]):
    a["to"] = min(a["to"], b["from"])
json.dump({"total": total, "overlap": OVERLAP, "scenes": scenes, "subs": subs}, open(OUT, "w"), ensure_ascii=False, indent=1)
print(f"total {total} frames = {total / FPS / 60:.2f} min, {len(subs)} subtitle cues")
for sc in scenes:
    print(sc["id"], sc["start"], sc["frames"], [(v["kind"], v["mode"], v["from"], v["to"]) for v in sc["visuals"]])
