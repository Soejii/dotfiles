import { Easing } from "remotion";
import { loadFont } from "@remotion/google-fonts/PlusJakartaSans";

const { fontFamily } = loadFont("normal", {
  weights: ["400", "500", "600", "700", "800"],
  subsets: ["latin"],
});

export const FONT = fontFamily;

export const C = {
  paper: "#F4EFE6",
  paperDeep: "#EAE2D4",
  card: "#FFFFFF",
  ink: "#1E2A3B",
  muted: "#5B6576",
  line: "#DDD3C2",
  teal: "#1F7A6D",
  coral: "#D9694F",
  gold: "#D9A42B",
  sky: "#3D7EA6",
  plum: "#7A5C99",
};

export const ACCENTS = [C.teal, C.coral, C.sky, C.gold, C.plum];

// One curve for every eased move, so the motion reads as one system.
export const EASE = Easing.bezier(0.22, 1, 0.36, 1);

export const FPS = 30;
export const W = 1920;
export const H = 1080;

// Reserved strip at the bottom for subtitles; graphics stay above it.
export const SUB_ZONE = 190;
