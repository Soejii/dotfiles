import React from "react";
import { AbsoluteFill, interpolate, useCurrentFrame } from "remotion";
import { C, ACCENTS, FONT, EASE } from "./theme";
import { Reveal, useBreath, useRamp, usePop } from "./motion";
import { Icon, Raka } from "./icons";

/* Every visual receives frames relative to its own start (Sequence-local). */

export type CardItem = { at: number; title: string; sub?: string; icon?: string; accent?: string };

const Kicker: React.FC<{ text: string; at?: number; color?: string }> = ({ text, at = 0, color = C.teal }) => (
  <Reveal at={at} rise={14}>
    <div
      style={{
        display: "inline-block",
        fontFamily: FONT,
        fontWeight: 700,
        fontSize: 26,
        letterSpacing: 3,
        textTransform: "uppercase",
        color,
        padding: "8px 18px",
        borderRadius: 999,
        background: `${color}14`,
        border: `2px solid ${color}40`,
      }}
    >
      {text}
    </div>
  </Reveal>
);

const Heading: React.FC<{ text: string; at?: number; size?: number }> = ({ text, at = 0, size = 64 }) => (
  <Reveal at={at + 4}>
    <div style={{ fontFamily: FONT, fontWeight: 800, fontSize: size, lineHeight: 1.08, color: C.ink, letterSpacing: -1 }}>
      {text}
    </div>
  </Reveal>
);

export const Card: React.FC<{ item: CardItem; index: number; dense?: boolean; highlight?: boolean }> = ({ item, index, dense, highlight }) => {
  const accent = item.accent ?? ACCENTS[index % ACCENTS.length];
  return (
    <Reveal at={item.at}>
      <div
        style={{
          display: "flex",
          alignItems: "center",
          gap: dense ? 20 : 26,
          background: C.card,
          borderRadius: 22,
          padding: dense ? "18px 26px" : "24px 30px",
          boxShadow: highlight ? `0 0 0 4px ${accent}, 0 14px 34px rgba(30,42,59,0.14)` : "0 10px 28px rgba(30,42,59,0.09)",
          borderLeft: `10px solid ${accent}`,
        }}
      >
        {item.icon && (
          <div
            style={{
              flex: "0 0 auto",
              width: dense ? 64 : 78,
              height: dense ? 64 : 78,
              borderRadius: 18,
              background: `${accent}18`,
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
            }}
          >
            <Icon name={item.icon} size={dense ? 40 : 48} color={accent} />
          </div>
        )}
        <div style={{ fontFamily: FONT }}>
          <div style={{ fontWeight: 750 as any, fontSize: dense ? 34 : 40, color: C.ink, lineHeight: 1.15 }}>{item.title}</div>
          {item.sub && (
            <div style={{ fontWeight: 500, fontSize: dense ? 25 : 28, color: C.muted, marginTop: 6, lineHeight: 1.25 }}>{item.sub}</div>
          )}
        </div>
      </div>
    </Reveal>
  );
};

/* A board: kicker + heading + stacked or gridded cards. Used for most beats. */
export const Board: React.FC<{
  kicker?: string;
  heading?: string;
  items: CardItem[];
  columns?: number;
  dense?: boolean;
  footer?: { at: number; text: string };
  tag?: { at: number; text: string };
  highlightFrom?: number;
  strip?: number;
  headingSize?: number;
}> = ({ kicker, heading, items, columns = 1, dense, footer, tag, highlightFrom, strip, headingSize }) => {
  const frame = useCurrentFrame();
  const hl = highlightFrom !== undefined && frame >= highlightFrom;
  return (
    <div style={{ display: "flex", flexDirection: "column", gap: 26, width: "100%" }}>
      {strip !== undefined && <BarrierStrip active={strip} />}
      {(kicker || tag) && (
        <div style={{ display: "flex", gap: 14, alignItems: "center" }}>
          {kicker && <Kicker text={kicker} />}
          {tag && <Kicker text={tag.text} at={tag.at} color={C.coral} />}
        </div>
      )}
      {heading && <Heading text={heading} size={headingSize} />}
      <div
        style={{
          display: "grid",
          gridTemplateColumns: `repeat(${columns}, 1fr)`,
          gap: dense ? 16 : 20,
          marginTop: 8,
        }}
      >
        {items.map((it, i) => (
          <Card key={i} item={it} index={i} dense={dense} highlight={hl} />
        ))}
      </div>
      {footer && (
        <Reveal at={footer.at}>
          <div
            style={{
              fontFamily: FONT,
              fontWeight: 700,
              fontSize: 36,
              color: C.card,
              background: C.ink,
              borderRadius: 18,
              padding: "18px 28px",
              alignSelf: "flex-start",
            }}
          >
            {footer.text}
          </div>
        </Reveal>
      )}
    </div>
  );
};

/* Opening title card. */
export const TitleCard: React.FC<{ topicsAt: number[] }> = ({ topicsAt }) => {
  const b = useBreath(200, 4);
  const topics = ["Kesehatan mental", "Kelompok dan komunitas", "Lintas budaya dan etnis"];
  return (
    <AbsoluteFill style={{ alignItems: "center", justifyContent: "center", fontFamily: FONT }}>
      <div style={{ textAlign: "center", transform: `translateY(${b - 40}px)` }}>
        <Kicker text="Kelompok 7 | Psikologi Konseling" />
        <Reveal at={6}>
          <div style={{ fontWeight: 800, fontSize: 118, color: C.ink, letterSpacing: -3, marginTop: 28 }}>Memahami Konseling</div>
        </Reveal>
        <Reveal at={14}>
          <div style={{ fontWeight: 500, fontSize: 50, color: C.muted, marginTop: 8 }}>Dari individu hingga budaya</div>
        </Reveal>
        <div style={{ display: "flex", gap: 18, justifyContent: "center", marginTop: 54 }}>
          {topics.map((t, i) => (
            <Reveal key={t} at={topicsAt[i]}>
              <div
                style={{
                  fontWeight: 700,
                  fontSize: 32,
                  color: "#fff",
                  background: ACCENTS[i],
                  padding: "14px 28px",
                  borderRadius: 999,
                }}
              >
                {t}
              </div>
            </Reveal>
          ))}
        </div>
      </div>
    </AbsoluteFill>
  );
};

/* One person -> group -> campus: the three "levels" of the opening hook. */
export const Levels: React.FC<{ at: number[] }> = ({ at }) => {
  const labels = [
    { icon: "person", t: "Pribadi" },
    { icon: "group", t: "Kelompok" },
    { icon: "campus", t: "Lingkungan dan budaya" },
  ];
  return (
    <div style={{ display: "flex", flexDirection: "column", gap: 26 }}>
      {labels.map((l, i) => (
        <Reveal key={l.t} at={at[i]}>
          <div style={{ display: "flex", alignItems: "center", gap: 28 }}>
            <div
              style={{
                width: 130 + i * 30,
                height: 130 + i * 30,
                borderRadius: "50%",
                background: `${ACCENTS[i]}1c`,
                border: `4px solid ${ACCENTS[i]}`,
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
              }}
            >
              <Icon name={l.icon} size={70 + i * 12} color={ACCENTS[i]} />
            </div>
            <div style={{ fontFamily: FONT, fontWeight: 750 as any, fontSize: 44, color: C.ink }}>{l.t}</div>
          </div>
        </Reveal>
      ))}
    </div>
  );
};

/* Raka + up to three question cards. */
export const RakaBoard: React.FC<{ label: string; labelAt?: number; items: CardItem[]; kicker?: string }> = ({ label, labelAt = 0, items, kicker }) => {
  const b = useBreath(160, 5);
  return (
    <div style={{ display: "flex", alignItems: "center", gap: 60, width: "100%" }}>
      <Reveal at={0}>
        <div style={{ display: "flex", flexDirection: "column", alignItems: "center", transform: `translateY(${b}px)` }}>
          <Raka size={300} />
          <Reveal at={labelAt + 6}>
            <div
              style={{
                fontFamily: FONT,
                fontWeight: 700,
                fontSize: 28,
                color: C.muted,
                background: C.card,
                padding: "10px 22px",
                borderRadius: 999,
                marginTop: 10,
                boxShadow: "0 6px 18px rgba(30,42,59,0.08)",
              }}
            >
              {label}
            </div>
          </Reveal>
        </div>
      </Reveal>
      <div style={{ flex: 1, display: "flex", flexDirection: "column", gap: 18 }}>
        {kicker && <Kicker text={kicker} />}
        {items.map((it, i) => (
          <Card key={i} item={it} index={i} dense />
        ))}
      </div>
    </div>
  );
};

/* Wellness: four linked domains around a centre. */
export const Wellness: React.FC<{ at: number; domAt?: number[] }> = ({ at, domAt }) => {
  const doms = [
    { t: "Fisik", icon: "body" },
    { t: "Emosi", icon: "heart" },
    { t: "Pikiran", icon: "mind" },
    { t: "Relasi", icon: "group" },
  ];
  const R = 250;
  const ring = useRamp(at, 30);
  return (
    <div style={{ position: "relative", width: 760, height: 700, margin: "0 auto" }}>
      <svg width={760} height={700} style={{ position: "absolute", inset: 0 }}>
        <circle
          cx={380}
          cy={350}
          r={R}
          fill="none"
          stroke={C.line}
          strokeWidth={6}
          strokeDasharray={2 * Math.PI * R}
          strokeDashoffset={(1 - ring) * 2 * Math.PI * R}
        />
      </svg>
      <Reveal at={at} style={{ position: "absolute", left: 380 - 130, top: 350 - 60, width: 260, textAlign: "center" }}>
        <div style={{ fontFamily: FONT, fontWeight: 800, fontSize: 52, color: C.ink }}>Wellness</div>
        <div style={{ fontFamily: FONT, fontWeight: 500, fontSize: 26, color: C.muted }}>saling berkaitan</div>
      </Reveal>
      {doms.map((d, i) => {
        const ang = -Math.PI / 2 + (i * Math.PI) / 2;
        const x = 380 + Math.cos(ang) * R;
        const y = 350 + Math.sin(ang) * R;
        return (
          <Reveal key={d.t} at={domAt ? domAt[i] : at + 10 + i * 6} style={{ position: "absolute", left: x - 90, top: y - 80, width: 180 }}>
            <div
              style={{
                width: 180,
                height: 160,
                borderRadius: 28,
                background: C.card,
                boxShadow: "0 10px 26px rgba(30,42,59,0.1)",
                borderTop: `8px solid ${ACCENTS[i]}`,
                display: "flex",
                flexDirection: "column",
                alignItems: "center",
                justifyContent: "center",
                gap: 8,
              }}
            >
              <Icon name={d.icon} size={56} color={ACCENTS[i]} />
              <div style={{ fontFamily: FONT, fontWeight: 750 as any, fontSize: 32, color: C.ink }}>{d.t}</div>
            </div>
          </Reveal>
        );
      })}
    </div>
  );
};

/* Group circle: facilitator + members; interaction lines draw on cue. */
export const GroupCircle: React.FC<{ linesAt: number; labels: CardItem[] }> = ({ linesAt, labels }) => {
  const n = 6;
  const R = 210;
  const cx = 300;
  const cy = 300;
  const pts = Array.from({ length: n }, (_, i) => {
    const a = -Math.PI / 2 + (i * 2 * Math.PI) / n;
    return [cx + Math.cos(a) * R, cy + Math.sin(a) * R];
  });
  const frame = useCurrentFrame();
  const pairs: [number, number][] = [];
  for (let i = 0; i < n; i++) for (let j = i + 1; j < n; j++) pairs.push([i, j]);
  return (
    <div style={{ display: "flex", alignItems: "center", gap: 60, width: "100%" }}>
      <div style={{ position: "relative", width: 600, height: 600, flex: "0 0 auto", margin: -60, transform: "scale(0.8)" }}>
        <svg width={600} height={600} style={{ position: "absolute", inset: 0 }}>
          {pairs.map(([a, b], k) => {
            const p = interpolate(frame, [linesAt + k * 2, linesAt + k * 2 + 16], [0, 1], {
              extrapolateLeft: "clamp",
              extrapolateRight: "clamp",
              easing: EASE,
            });
            const [x1, y1] = pts[a];
            const [x2, y2] = pts[b];
            return (
              <line key={k} x1={x1} y1={y1} x2={x1 + (x2 - x1) * p} y2={y1 + (y2 - y1) * p} stroke={C.teal} strokeOpacity={0.35} strokeWidth={4} />
            );
          })}
        </svg>
        {pts.map(([x, y], i) => (
          <Reveal key={i} at={4 + i * 4} style={{ position: "absolute", left: x - 50, top: y - 50 }}>
            <div
              style={{
                width: 100,
                height: 100,
                borderRadius: "50%",
                background: i === 0 ? C.coral : C.card,
                border: `4px solid ${i === 0 ? C.coral : C.sky}`,
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                boxShadow: "0 8px 20px rgba(30,42,59,0.1)",
              }}
            >
              <Icon name="person" size={56} color={i === 0 ? "#fff" : C.sky} />
            </div>
          </Reveal>
        ))}
        <Reveal at={30} style={{ position: "absolute", left: cx - 110, top: 12 - 60, width: 220, textAlign: "center" }}>
          <div style={{ fontFamily: FONT, fontWeight: 700, fontSize: 24, color: C.coral }}>fasilitator</div>
        </Reveal>
      </div>
      <div style={{ flex: 1, display: "flex", flexDirection: "column", gap: 18 }}>
        <Kicker text="Konseling kelompok" />
        {labels.map((it, i) => (
          <Card key={i} item={it} index={i} dense />
        ))}
      </div>
    </div>
  );
};

/* Nested ecology: Raka inside friends/family inside campus/services. */
export const Ecology: React.FC<{ at: number[]; programs?: CardItem[]; programsAt?: number }> = ({ at, programs, programsAt }) => {
  const rings = [
    { r: 300, t: "Kampus dan layanan", c: C.sky },
    { r: 205, t: "Teman dan keluarga", c: C.teal },
  ];
  const frame = useCurrentFrame();
  const shift = programsAt === undefined ? 0 : interpolate(frame, [programsAt, programsAt + 20], [0, 1], { extrapolateLeft: "clamp", extrapolateRight: "clamp", easing: EASE });
  return (
    <div style={{ display: "flex", alignItems: "center", width: "100%", gap: 40 }}>
      <div style={{ position: "relative", width: 640, height: 640, flex: "0 0 auto", transform: `scale(${1 - 0.18 * shift})`, transformOrigin: "left center" }}>
        {rings.map((g, i) => (
          <Reveal key={g.t} at={at[i + 1] ?? at[0]} style={{ position: "absolute", left: 320 - g.r, top: 320 - g.r }}>
            <div style={{ width: g.r * 2, height: g.r * 2, borderRadius: "50%", background: `${g.c}14`, border: `4px solid ${g.c}` }} />
            <div
              style={{
                position: "absolute",
                top: i === 0 ? 40 : 34,
                left: 0,
                width: g.r * 2,
                textAlign: "center",
                fontFamily: FONT,
                fontWeight: 700,
                fontSize: 24,
                color: g.c,
              }}
            >
              {g.t}
            </div>
          </Reveal>
        ))}
        <Reveal at={at[0]} style={{ position: "absolute", left: 320 - 105, top: 320 - 105 }}>
          <div
            style={{
              width: 210,
              height: 210,
              borderRadius: "50%",
              background: C.card,
              border: `4px solid ${C.coral}`,
              display: "flex",
              flexDirection: "column",
              alignItems: "center",
              justifyContent: "center",
              overflow: "hidden",
            }}
          >
            <div style={{ marginTop: 40 }}>
              <Raka size={120} />
            </div>
          </div>
        </Reveal>
      </div>
      {programs && (
        <div style={{ flex: 1, display: "flex", flexDirection: "column", gap: 18 }}>
          <Kicker text="Ilustrasi penerapan" at={programsAt ?? 0} color={C.coral} />
          {programs.map((p, i) => (
            <Card key={i} item={p} index={i} dense />
          ))}
        </div>
      )}
    </div>
  );
};

/* Acculturation: Raka between two overlapping culture circles. */
export const TwoCircles: React.FC<{ at: number; heading?: string; sub?: string; strip?: number }> = ({ at, heading, sub, strip }) => {
  const sep = useRamp(at, 26);
  const b = useBreath(140, 6);
  return (
    <div style={{ display: "flex", flexDirection: "column", gap: 18 }}>
    {strip !== undefined && <BarrierStrip active={strip} />}
    {heading && <Heading text={heading} size={56} />}
    {sub && <Reveal at={8}><div style={{ fontFamily: FONT, fontWeight: 500, fontSize: 32, color: C.muted }}>{sub}</div></Reveal>}
    <div style={{ position: "relative", width: 900, height: 560, margin: "0 auto", transform: "scale(0.86)", transformOrigin: "top center" }}>
      {[C.teal, C.coral].map((c, i) => (
        <Reveal key={i} at={at + i * 6} style={{ position: "absolute", top: 20, left: 450 - 260 + (i ? 1 : -1) * (80 + 70 * sep) - 180 + 180 }}>
          <div
            style={{
              width: 520,
              height: 520,
              borderRadius: "50%",
              background: `${c}16`,
              border: `4px solid ${c}`,
              transform: `translateX(${(i ? 1 : -1) * b}px)`,
            }}
          />
        </Reveal>
      ))}
      <Reveal at={at + 4} style={{ position: "absolute", left: 60, top: 250, fontFamily: FONT, fontWeight: 700, fontSize: 30, color: C.teal }}>
        Lingkungan asal
      </Reveal>
      <Reveal at={at + 10} style={{ position: "absolute", right: 60, top: 250, fontFamily: FONT, fontWeight: 700, fontSize: 30, color: C.coral }}>
        Lingkungan baru
      </Reveal>
      <Reveal at={at + 16} style={{ position: "absolute", left: 450 - 80, top: 150 }}>
        <Raka size={160} />
      </Reveal>
    </div>
    </div>
  );
};

/* Two speech bubbles with "?" for the language barrier. */
export const Bubbles: React.FC<{ at: number }> = ({ at }) => {
  const b = useBreath(120, 6);
  return (
    <div style={{ display: "flex", gap: 60, justifyContent: "center", alignItems: "flex-start" }}>
      {[C.sky, C.coral].map((c, i) => (
        <Reveal key={i} at={at + i * 8}>
          <div
            style={{
              width: 280,
              height: 190,
              borderRadius: 40,
              background: C.card,
              border: `5px solid ${c}`,
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              fontFamily: FONT,
              fontWeight: 800,
              fontSize: 110,
              color: c,
              transform: `translateY(${(i ? -1 : 1) * b + i * 60}px)`,
              boxShadow: "0 10px 28px rgba(30,42,59,0.1)",
            }}
          >
            ?
          </div>
        </Reveal>
      ))}
    </div>
  );
};

/* A single big question on paper, e.g. the closing line. */
export const BigLine: React.FC<{ text: string; sub?: string; kicker?: string }> = ({ text, sub, kicker }) => (
  <AbsoluteFill style={{ alignItems: "center", justifyContent: "center", padding: "0 180px", paddingBottom: 120 }}>
    <div style={{ textAlign: "center" }}>
      {kicker && <Kicker text={kicker} />}
      <Reveal at={4}>
        <div style={{ fontFamily: FONT, fontWeight: 800, fontSize: 84, color: C.ink, lineHeight: 1.12, marginTop: 26, letterSpacing: -1.5, textWrap: "balance", maxWidth: 1300, marginLeft: "auto", marginRight: "auto" } as React.CSSProperties}>{text}</div>
      </Reveal>
      {sub && (
        <Reveal at={14}>
          <div style={{ fontFamily: FONT, fontWeight: 500, fontSize: 36, color: C.muted, marginTop: 22 }}>{sub}</div>
        </Reveal>
      )}
    </div>
  </AbsoluteFill>
);

/* Barrier strip: five chips, the active one lit. */
export const BarrierStrip: React.FC<{ active: number; at?: number }> = ({ active, at = 0 }) => {
  const names = ["Pengukuran", "Overkulturalisasi", "Bahasa", "Rasisme", "Akulturasi"];
  return (
    <div style={{ display: "flex", gap: 12, flexWrap: "wrap" }}>
      {names.map((n, i) => {
        const on = active < 0 || i === active;
        return (
          <Reveal key={n} at={at + i * 3} rise={10}>
            <div
              style={{
                fontFamily: FONT,
                fontWeight: 700,
                fontSize: 24,
                padding: "10px 18px",
                borderRadius: 999,
                color: on ? "#fff" : C.muted,
                background: on ? ACCENTS[i] : C.paperDeep,
              }}
            >
              {i + 1}. {n}
            </div>
          </Reveal>
        );
      })}
    </div>
  );
};

export const usePopValue = usePop;

/* End cards. */
export const RefsCard: React.FC = () => (
  <AbsoluteFill style={{ alignItems: "center", justifyContent: "center", padding: "0 220px" }}>
    <div style={{ fontFamily: FONT, color: C.ink, width: "100%" }}>
      <Kicker text="Referensi utama" />
      <Reveal at={6}>
        <div style={{ fontSize: 46, fontWeight: 500, lineHeight: 1.4, marginTop: 34, paddingLeft: 60, textIndent: -60 }}>
          Gladding, S. T. (2018). <i>Counseling: A comprehensive profession</i> (8th ed.). Pearson.
        </div>
      </Reveal>
      <div style={{ display: "flex", flexDirection: "column", gap: 14, marginTop: 40 }}>
        {[
          "Bab 3: Counseling in a Multicultural Society",
          "Bab 9: Groups in Counseling",
          "Bab 18: Clinical Mental Health and Private Practice Counseling",
        ].map((t, i) => (
          <Reveal key={t} at={14 + i * 5}>
            <div style={{ fontSize: 34, fontWeight: 600, color: C.muted, borderLeft: `8px solid ${ACCENTS[i]}`, paddingLeft: 22 }}>{t}</div>
          </Reveal>
        ))}
      </div>
    </div>
  </AbsoluteFill>
);

export const CreditsCard: React.FC<{ names?: string[]; assets?: string }> = ({ names, assets }) => (
  <AbsoluteFill style={{ alignItems: "center", justifyContent: "center" }}>
    <div style={{ fontFamily: FONT, color: C.ink, textAlign: "center" }}>
      <Kicker text="Kelompok 7 | Psikologi Konseling" />
      <Reveal at={6}>
        <div style={{ fontSize: 40, fontWeight: 600, color: C.muted, marginTop: 34 }}>Disusun dan dipresentasikan oleh</div>
      </Reveal>
      <Reveal at={12}>
        <div style={{ fontSize: 50, fontWeight: 800, marginTop: 14, lineHeight: 1.4 }}>
          {names && names.length ? names.map((n) => <div key={n}>{n}</div>) : "Kelompok 7"}
        </div>
      </Reveal>
      <Reveal at={20}>
        <div style={{ fontSize: 30, fontWeight: 500, color: C.muted, marginTop: 44 }}>Contoh Raka merupakan ilustrasi fiktif.</div>
      </Reveal>
      {assets && (
        <Reveal at={24}>
          <div style={{ fontSize: 26, fontWeight: 500, color: C.muted, marginTop: 12 }}>{assets}</div>
        </Reveal>
      )}
    </div>
  </AbsoluteFill>
);

export const Chip: React.FC<{ text: string; len: number }> = ({ text, len }) => (
  <div style={{ position: "absolute", left: 70, top: 60 }}>
    <Reveal at={6} out={len}>
      <div
        style={{
          fontFamily: FONT,
          fontWeight: 700,
          fontSize: 30,
          color: "#fff",
          background: "rgba(30,42,59,0.82)",
          padding: "12px 24px",
          borderRadius: 999,
          letterSpacing: 0.5,
        }}
      >
        {text}
      </div>
    </Reveal>
  </div>
);

/* Lower-third name label when a presenter first appears. */
export const NameTag: React.FC<{ name: string; role?: string; len: number }> = ({ name, role, len }) => (
  <div style={{ position: "absolute", left: 70, bottom: 200 }}>
    <Reveal at={4} out={len} rise={16}>
      <div
        style={{
          fontFamily: FONT,
          background: "rgba(255,255,255,0.94)",
          borderLeft: `10px solid ${C.teal}`,
          borderRadius: 14,
          padding: "14px 26px",
          boxShadow: "0 10px 28px rgba(30,42,59,0.18)",
        }}
      >
        <div style={{ fontWeight: 800, fontSize: 40, color: C.ink }}>{name}</div>
        {role && <div style={{ fontWeight: 600, fontSize: 24, color: C.muted, marginTop: 2 }}>{role}</div>}
      </div>
    </Reveal>
  </div>
);
