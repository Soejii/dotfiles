import React from "react";
import { C } from "./theme";

type P = { size?: number; color?: string; stroke?: number };

const Svg: React.FC<P & { children: React.ReactNode }> = ({ size = 64, color = C.ink, stroke = 3.2, children }) => (
  <svg width={size} height={size} viewBox="0 0 48 48" fill="none" stroke={color} strokeWidth={stroke} strokeLinecap="round" strokeLinejoin="round">
    {children}
  </svg>
);

export const ICONS: Record<string, React.FC<P>> = {
  person: (p) => (
    <Svg {...p}>
      <circle cx="24" cy="15" r="7" />
      <path d="M10 41c1.5-8 7-12 14-12s12.5 4 14 12" />
    </Svg>
  ),
  group: (p) => (
    <Svg {...p}>
      <circle cx="24" cy="13" r="5" />
      <circle cx="11" cy="22" r="4.5" />
      <circle cx="37" cy="22" r="4.5" />
      <path d="M15 40c1-6 4.5-9 9-9s8 3 9 9" />
      <path d="M3 38c.8-5 3.6-7.5 8-7.5 2 0 3.6.5 4.8 1.5" />
      <path d="M45 38c-.8-5-3.6-7.5-8-7.5-2 0-3.6.5-4.8 1.5" />
    </Svg>
  ),
  campus: (p) => (
    <Svg {...p}>
      <path d="M5 18 24 7l19 11" />
      <path d="M9 18v19M17 18v19M31 18v19M39 18v19" />
      <path d="M5 41h38" />
    </Svg>
  ),
  book: (p) => (
    <Svg {...p}>
      <path d="M24 12c-4-3-10-4-17-3v28c7-1 13 0 17 3 4-3 10-4 17-3V9c-7-1-13 0-17 3z" />
      <path d="M24 12v28" />
    </Svg>
  ),
  chat: (p) => (
    <Svg {...p}>
      <path d="M8 10h24a4 4 0 0 1 4 4v12a4 4 0 0 1-4 4H18l-8 6v-6H8a4 4 0 0 1-4-4V14a4 4 0 0 1 4-4z" />
      <path d="M40 18a4 4 0 0 1 4 4v10a4 4 0 0 1-4 4h-1v5l-6-5h-9" />
    </Svg>
  ),
  layers: (p) => (
    <Svg {...p}>
      <path d="M24 6 4 16l20 10 20-10z" />
      <path d="m4 24 20 10 20-10" />
      <path d="m4 32 20 10 20-10" />
    </Svg>
  ),
  list: (p) => (
    <Svg {...p}>
      <rect x="8" y="6" width="32" height="36" rx="4" />
      <path d="m14 17 3 3 5-6M26 17h8M14 29l3 3 5-6M26 29h8" />
    </Svg>
  ),
  shield: (p) => (
    <Svg {...p}>
      <path d="M24 5 8 11v11c0 10 7 17 16 21 9-4 16-11 16-21V11z" />
      <path d="m17 24 5 5 9-10" />
    </Svg>
  ),
  heart: (p) => (
    <Svg {...p}>
      <path d="M24 41S6 30 6 17a9 9 0 0 1 18-3 9 9 0 0 1 18 3c0 13-18 24-18 24z" />
    </Svg>
  ),
  body: (p) => (
    <Svg {...p}>
      <path d="M24 42V26M24 26l-9 10M24 26l9 10M13 18h22" />
      <circle cx="24" cy="10" r="5" />
      <path d="M24 15v11" />
    </Svg>
  ),
  mind: (p) => (
    <Svg {...p}>
      <path d="M26 42v-7h5a4 4 0 0 0 4-4v-5l4-2-4-6c0-8-6-12-13-12S9 11 9 19c0 5 2 8 5 11v12" />
      <path d="M19 18a4 4 0 0 1 7-2" />
    </Svg>
  ),
  link: (p) => (
    <Svg {...p}>
      <circle cx="14" cy="24" r="8" />
      <circle cx="34" cy="24" r="8" />
    </Svg>
  ),
  meter: (p) => (
    <Svg {...p}>
      <path d="M6 34a18 18 0 0 1 36 0" />
      <path d="M24 34 32 20" />
      <circle cx="24" cy="34" r="2.5" />
    </Svg>
  ),
  wallet: (p) => (
    <Svg {...p}>
      <rect x="5" y="12" width="38" height="28" rx="5" />
      <path d="M5 18h30M33 28h4" />
      <path d="M11 12 31 5l3 7" />
    </Svg>
  ),
  bus: (p) => (
    <Svg {...p}>
      <rect x="8" y="6" width="32" height="30" rx="6" />
      <path d="M8 24h32M14 36v5M34 36v5" />
      <circle cx="15" cy="30" r="1.5" />
      <circle cx="33" cy="30" r="1.5" />
    </Svg>
  ),
  bubble: (p) => (
    <Svg {...p}>
      <path d="M9 9h30a4 4 0 0 1 4 4v16a4 4 0 0 1-4 4H22l-9 7v-7H9a4 4 0 0 1-4-4V13a4 4 0 0 1 4-4z" />
      <path d="M20 17a4 4 0 1 1 5 4c-1 .5-1 1.2-1 2.5M24 28h.01" />
    </Svg>
  ),
  structure: (p) => (
    <Svg {...p}>
      <rect x="18" y="5" width="12" height="9" rx="2" />
      <rect x="5" y="34" width="12" height="9" rx="2" />
      <rect x="31" y="34" width="12" height="9" rx="2" />
      <path d="M24 14v10M11 34v-6h26v6" />
    </Svg>
  ),
  info: (p) => (
    <Svg {...p}>
      <rect x="6" y="8" width="36" height="28" rx="4" />
      <path d="M24 17h.01M24 22v8M16 42h16M24 36v6" />
    </Svg>
  ),
  hand: (p) => (
    <Svg {...p}>
      <path d="M6 30h8l8 4h8a3 3 0 0 0 0-6h-6" />
      <path d="m14 30 10-10 6 4 10-6" />
      <path d="M6 26v12" />
    </Svg>
  ),
  eye: (p) => (
    <Svg {...p}>
      <path d="M3 24s8-13 21-13 21 13 21 13-8 13-21 13S3 24 3 24z" />
      <circle cx="24" cy="24" r="6" />
    </Svg>
  ),
  tool: (p) => (
    <Svg {...p}>
      <path d="M29 8a9 9 0 0 0-8 12L8 33a3.5 3.5 0 0 0 5 5l13-13a9 9 0 0 0 12-8l-6 3-5-5 3-6z" />
    </Svg>
  ),
  question: (p) => (
    <Svg {...p}>
      <circle cx="24" cy="24" r="18" />
      <path d="M19 19a5 5 0 1 1 6.5 4.8c-1 .4-1.5 1.2-1.5 2.4v1.3M24 33h.01" />
    </Svg>
  ),
  swap: (p) => (
    <Svg {...p}>
      <path d="M8 16h30l-7-7M40 32H10l7 7" />
    </Svg>
  ),
};

export const Icon: React.FC<P & { name: string }> = ({ name, ...p }) => {
  const I = ICONS[name] ?? ICONS.question;
  return <I {...p} />;
};

// Neutral, deliberately generic student figure for the fictional "Raka".
// No ethnic markers, no extreme expression (script's instruction).
export const Raka: React.FC<{ size?: number }> = ({ size = 320 }) => (
  <svg width={size} height={size * 1.25} viewBox="0 0 200 250">
    <ellipse cx="100" cy="240" rx="70" ry="8" fill={C.ink} opacity="0.08" />
    {/* backpack */}
    <rect x="52" y="112" width="96" height="96" rx="26" fill={C.teal} opacity="0.9" />
    {/* body */}
    <path d="M58 236c0-58 18-92 42-92s42 34 42 92z" fill={C.sky} />
    <path d="M80 146l20 26 20-26" fill="none" stroke="#fff" strokeWidth="5" strokeLinejoin="round" />
    {/* straps */}
    <path d="M72 150c-2 30-2 60 0 86M128 150c2 30 2 60 0 86" stroke={C.teal} strokeWidth="8" fill="none" strokeLinecap="round" />
    {/* neck + head */}
    <rect x="90" y="118" width="20" height="22" rx="8" fill="#C99A78" />
    <circle cx="100" cy="92" r="36" fill="#D8AA88" />
    <path d="M64 88c0-24 16-38 36-38s36 12 36 34c-10-8-22-12-36-12-14 0-26 6-36 16z" fill={C.ink} />
    <circle cx="87" cy="96" r="3.4" fill={C.ink} />
    <circle cx="113" cy="96" r="3.4" fill={C.ink} />
    <path d="M91 112c6 4 12 4 18 0" stroke={C.ink} strokeWidth="3" fill="none" strokeLinecap="round" />
    {/* book held in front */}
    <g transform="rotate(-8 100 190)">
      <rect x="70" y="170" width="60" height="42" rx="5" fill={C.gold} />
      <path d="M100 172v38" stroke="#fff" strokeWidth="3" />
    </g>
  </svg>
);
