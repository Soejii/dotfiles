import React from "react";
import { AbsoluteFill, OffthreadVideo, Sequence, interpolate, staticFile, useCurrentFrame } from "remotion";
import { C, FONT, EASE, W, H } from "./theme";
import { Reveal } from "./motion";
import {
  Board,
  TitleCard,
  Levels,
  RakaBoard,
  Wellness,
  GroupCircle,
  Ecology,
  TwoCircles,
  Bubbles,
  BigLine,
  BarrierStrip,
  RefsCard,
  CreditsCard,
  Chip,
  NameTag,
} from "./visuals";
import timeline from "./timeline.json";

type Visual = { from: number; to: number; mode: "split" | "board" | "overlay"; kind: string; props: any };
type Scene = {
  id: string;
  src: string | null;
  start: number;
  frames: number;
  visuals: Visual[];
  cites: { from: number; to: number; text: string }[];
  grade?: string;
};
type Sub = { from: number; to: number; text: string };
type TL = { total: number; overlap: number; scenes: Scene[]; subs: Sub[] };

const T = timeline as unknown as TL;
const clamp = { extrapolateLeft: "clamp", extrapolateRight: "clamp" } as const;

const CAM = { x: 0, y: 0, w: W, h: H, r: 0 };
const PANEL = { x: 1200, y: 80, w: 640, h: 770, r: 36 };

const RENDER: Record<string, React.FC<any>> = {
  board: Board,
  title: TitleCard,
  levels: Levels,
  raka: RakaBoard,
  wellness: Wellness,
  group: GroupCircle,
  ecology: Ecology,
  two: TwoCircles,
  bubbles: Bubbles,
  bigline: BigLine,
  barriers: BarrierStrip,
  refs: RefsCard,
  credits: CreditsCard,
  chip: Chip,
  name: NameTag,
};

/* How far the presenter has moved from full-frame towards the panel (0..1) and how visible it is. */
const presenterState = (f: number, visuals: Visual[]) => {
  let k = 0;
  let hide = 0;
  for (const v of visuals) {
    const inR = interpolate(f, [v.from, v.from + 16], [0, 1], { ...clamp, easing: EASE });
    const outR = interpolate(f, [v.to - 14, v.to], [1, 0], { ...clamp, easing: EASE });
    const a = Math.min(inR, outR);
    if (v.mode === "split") k = Math.max(k, a);
    else if (v.mode === "board") hide = Math.max(hide, a);
  }
  return { k, hide };
};

const lerp = (a: number, b: number, t: number) => a + (b - a) * t;

const SceneLayer: React.FC<{ s: Scene; overlap: number }> = ({ s, overlap }) => {
  const f = useCurrentFrame();
  const { k, hide } = presenterState(f, s.visuals);
  const rect = {
    x: lerp(CAM.x, PANEL.x, k),
    y: lerp(CAM.y, PANEL.y, k),
    w: lerp(CAM.w, PANEL.w, k),
    h: lerp(CAM.h, PANEL.h, k),
    r: lerp(CAM.r, PANEL.r, k),
  };
  // crossfade in at the head of every scene except the first
  const fadeIn = s.start === 0 ? 1 : interpolate(f, [0, overlap], [0, 1], clamp);
  const graphicsOpacity = (v: Visual) =>
    Math.min(
      interpolate(f, [v.from, v.from + 10], [0, 1], clamp),
      interpolate(f, [v.to - 10, v.to], [1, 0], clamp),
    );
  return (
    <AbsoluteFill style={{ opacity: fadeIn }}>
      <AbsoluteFill style={{ background: C.paper }} />
      {s.visuals.map((v, i) => {
        if (v.mode === "overlay") return null;
        const Comp = RENDER[v.kind];
        const board = v.mode === "board";
        return (
          <Sequence key={i} from={v.from} durationInFrames={v.to - v.from} layout="none">
            <AbsoluteFill style={{ opacity: graphicsOpacity(v), background: board ? C.paper : undefined }}>
              {["title", "bigline", "refs", "credits"].includes(v.kind) ? (
                <Comp {...v.props} />
              ) : (
                <div
                  style={{
                    position: "absolute",
                    left: board ? 140 : 110,
                    top: board ? 90 : 90,
                    width: board ? W - 280 : PANEL.x - 110 - 70,
                    height: 780,
                    display: "flex",
                    alignItems: "center",
                    justifyContent: board ? "center" : "flex-start",
                  }}
                >
                  <Comp {...v.props} />
                </div>
              )}
            </AbsoluteFill>
          </Sequence>
        );
      })}
      {s.src && (
        <div
          style={{
            position: "absolute",
            left: rect.x,
            top: rect.y,
            width: rect.w,
            height: rect.h,
            borderRadius: rect.r,
            overflow: "hidden",
            opacity: 1 - hide,
            boxShadow: k > 0.01 ? `0 20px 50px rgba(30,42,59,${0.22 * k})` : "none",
          }}
        >
          <OffthreadVideo
            src={staticFile(s.src)}
            style={{ width: "100%", height: "100%", objectFit: "cover", filter: s.grade }}
          />
        </div>
      )}
      {s.visuals.map((v, i) =>
        v.mode === "overlay" ? (
          <Sequence key={"o" + i} from={v.from} durationInFrames={v.to - v.from} layout="none">
            {React.createElement(RENDER[v.kind], { ...v.props, len: v.to - v.from })}
          </Sequence>
        ) : null,
      )}
      {s.cites.map((c, i) => (
        <Sequence key={"c" + i} from={c.from} durationInFrames={c.to - c.from} layout="none">
          <Cite text={c.text} len={c.to - c.from} />
        </Sequence>
      ))}
    </AbsoluteFill>
  );
};

const Grain: React.FC = () => {
  const f = useCurrentFrame();
  return (
    <AbsoluteFill style={{ opacity: 0.05, mixBlendMode: "multiply" }}>
      <svg width={W} height={H}>
        <filter id="n">
          <feTurbulence type="fractalNoise" baseFrequency="0.9" numOctaves="2" seed={f % 12} />
        </filter>
        <rect width={W} height={H} filter="url(#n)" />
      </svg>
    </AbsoluteFill>
  );
};

const Cite: React.FC<{ text: string; len: number }> = ({ text, len }) => {
  const f = useCurrentFrame();
  const o = Math.min(interpolate(f, [0, 12], [0, 1], clamp), interpolate(f, [len - 10, len], [1, 0], clamp));
  return (
    <div
      style={{
        position: "absolute",
        right: 70,
        bottom: 196,
        opacity: o,
        fontFamily: FONT,
        fontWeight: 600,
        fontSize: 24,
        color: "#fff",
        background: "rgba(30,42,59,0.78)",
        padding: "8px 16px",
        borderRadius: 10,
      }}
    >
      {text}
    </div>
  );
};

const Subtitles: React.FC = () => {
  const f = useCurrentFrame();
  const s = T.subs.find((x) => f >= x.from && f < x.to);
  if (!s) return null;
  return (
    <AbsoluteFill style={{ justifyContent: "flex-end", alignItems: "center", paddingBottom: 54 }}>
      <div
        style={{
          maxWidth: 1480,
          textAlign: "center",
          fontFamily: FONT,
          fontWeight: 600,
          fontSize: 42,
          lineHeight: 1.3,
          color: "#fff",
          background: "rgba(20,26,36,0.80)",
          padding: "10px 26px",
          borderRadius: 14,
          whiteSpace: "pre-line",
        }}
      >
        {s.text}
      </div>
    </AbsoluteFill>
  );
};

export const K7Video: React.FC = () => {
  const f = useCurrentFrame();
  const fade = Math.min(interpolate(f, [0, 12], [0, 1], clamp), interpolate(f, [T.total - 24, T.total], [1, 0], clamp));
  return (
    <AbsoluteFill style={{ background: "#000" }}>
    <AbsoluteFill style={{ background: C.paper, opacity: fade }}>
      {T.scenes.map((s) => (
        <Sequence key={s.id} from={s.start} durationInFrames={s.frames} name={s.id}>
          <SceneLayer s={s} overlap={T.overlap} />
        </Sequence>
      ))}
      <Subtitles />
    </AbsoluteFill>
    </AbsoluteFill>
  );
};

export { Reveal };
