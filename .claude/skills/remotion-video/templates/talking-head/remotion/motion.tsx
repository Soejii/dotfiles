import React from "react";
import { interpolate, spring, useCurrentFrame, useVideoConfig } from "remotion";
import { EASE } from "./theme";

const clamp = { extrapolateLeft: "clamp", extrapolateRight: "clamp" } as const;

// 0 -> 1 over `len` frames starting at `at`, on the shared curve.
export const useRamp = (at: number, len = 14) => {
  const frame = useCurrentFrame();
  return interpolate(frame, [at, at + len], [0, 1], { ...clamp, easing: EASE });
};

export const usePop = (at: number) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  return spring({ frame: frame - at, fps, config: { damping: 18, stiffness: 140, mass: 0.8 } });
};

// Entrance = fade + rise + slight scale, all together. Exit is faster than entrance.
export const Reveal: React.FC<{
  at: number;
  out?: number;
  rise?: number;
  style?: React.CSSProperties;
  children: React.ReactNode;
}> = ({ at, out, rise = 28, style, children }) => {
  const frame = useCurrentFrame();
  const p = usePop(at);
  const o = interpolate(frame, [at, at + 10], [0, 1], clamp);
  const x = out === undefined ? 1 : interpolate(frame, [out - 8, out], [1, 0], { ...clamp, easing: EASE });
  return (
    <div
      style={{
        opacity: o * x,
        transform: `translateY(${(1 - p) * rise + (1 - x) * -10}px) scale(${0.96 + 0.04 * p})`,
        ...style,
      }}
    >
      {children}
    </div>
  );
};

// Gentle idle drift so held graphics are not frozen.
export const useBreath = (period = 150, amp = 3) => {
  const frame = useCurrentFrame();
  return Math.sin((frame / period) * Math.PI * 2) * amp;
};
