---
name: remotion-video
description: Create animated, code-rendered videos (intros, montages, title cards, lower-thirds, VS screens, highlight reels) and edit recorded talking-head footage (take selection, subtitles, synced explainer graphics) with Remotion + React, rendered to MP4 via headless Chromium and ffmpeg. Use when the user wants an animated video intro/outro, a motion-graphics title sequence, a montage that composites video clips with animated overlays, to edit a folder of recorded takes into a finished video, or to turn React/HTML/CSS into a video.
---

# Remotion video skill

Drives a persistent Remotion workspace to produce animated MP4s. Remotion = React components rendered frame-by-frame by a headless browser, then encoded by ffmpeg. Use this for the *animated graphics* layer (titles, transitions, callouts, VS screens). For purely concatenating raw gameplay clips back-to-back with no graphics, plain ffmpeg `concat` is lighter; the two combine well (Remotion intro, then ffmpeg-append the footage).

## Environment (already set up)
- Workspace: `/home/suji/CODE/remotion-studio`
- Entry: `src/index.ts` -> `src/Root.tsx` (registers every `<Composition>`)
- Node v26 + npm present; ffmpeg present.
- First render auto-downloads "Chrome Headless Shell" into the Remotion cache (one-time, needs network). No system Chromium required.
- Output goes to `out/`. Bundled static assets (video clips, audio, images, fonts) go in `public/` and are referenced with `staticFile("...")`.

## Workflow to make a new video
0. Storyboard first. If no script with scene-by-scene visual cues exists, write one and get it approved before any component code. A vague "make a video" prompt produces generic output; the storyboard is the quality gate.
1. Write the component in `src/<Name>.tsx` (a React FC taking typed props).
2. Register it in `src/Root.tsx` with a `<Composition id width height fps durationInFrames defaultProps>`.
3. Preview live (optional, opens a browser studio): `cd /home/suji/CODE/remotion-studio && npm run studio`
4. Render headless:
   ```bash
   cd /home/suji/CODE/remotion-studio
   npx remotion render src/index.ts <CompositionId> out/<name>.mp4
   ```
5. Verify before claiming done: `ffprobe` the output, then Read frames. For anything over ~30s, build a contact sheet (`ffmpeg -i out.mp4 -vf "fps=1/20,scale=480:-2" q%03d.jpg`, then `-vf tile=5x7`) and read it whole, not 2-3 stills. Before the long render, render `remotion still` frames at the busiest moments and fix layout there; stills cost seconds, a full render costs minutes. A render can "succeed" and still be visually wrong.

## Motion design rules (what separates designed from dev-made)
Distilled from people shipping good Claude + Remotion videos (2026 research). Apply by default.
- One easing curve everywhere: `Easing.bezier(0.22, 1, 0.36, 1)`. Consistent motion is most of "looks designed". Never raw linear ramps for moves; linear is fine only for opacity.
- Entrances animate 2-3 properties together (fade + rise + slight scale), via `spring`. A lone opacity fade looks cheap.
- Stagger: items enter a few frames apart, or better, each on the spoken word it illustrates.
- Exits exist and are faster than entrances.
- Crossfade between scenes (overlap a few frames) instead of hard cuts.
- One `theme.ts` for colours, fonts, easing; no inline colours. Load fonts with `@remotion/google-fonts` (install the version matching `remotion`).
- Idle held graphics get subtle sine-wave drift so they are not frozen.
- Restraint: music low, sound effects only on chapter changes. Overdone SFX is the top amateur tell. Cut any beat that does not earn its time.
- Film grain + vignette look good but a per-frame SVG `feTurbulence` filter is expensive at 1080p; drop it for long renders.
- Reserve a bottom strip for subtitles; graphics and citations stay above it.

## Useful render flags
- Override props per render (no code edit): `--props='{"title":"GRAND FINAL","player1":"A","player2":"B"}'`
- Pick a frame range: `--frames=0-120`
- Codec / quality: `--codec=h264` (default), `--crf=18` (lower = higher quality), `--codec=vp8`/`vp9` for webm, `--codec=gif` for a GIF.
- Concurrency: `--concurrency=4` (default auto).
- A single still: `npx remotion still src/index.ts <CompositionId> out/thumb.png --frame=30`

## Patterns / API cheat-sheet
- `useCurrentFrame()` is the clock. Inside a `<Sequence>`, it is LOCAL to that sequence (starts at 0); compute fade-in/out relative to the sequence length, not the global timeline.
- `interpolate(frame, [inStart,inEnd], [outStart,outEnd], {extrapolateLeft:"clamp", extrapolateRight:"clamp"})` for linear ramps (opacity, position). Always clamp or values shoot past the range.
- `spring({frame, fps, from, to, config:{damping,stiffness}})` for natural pops/slides. Lower damping = bouncier.
- `<Sequence from={f} durationInFrames={n}>` to schedule a scene on the timeline.
- `<AbsoluteFill>` = full-frame absolutely-positioned div; stack them for layers (background, content, flash).
- `useVideoConfig()` -> `{fps, width, height, durationInFrames}`.
- IMPORTANT: the composition's `durationInFrames` must cover all sequences, or later scenes get cut off.

## Adding real footage (montage)
Put clips in `public/clips/` and composite them:
```tsx
import { OffthreadVideo, staticFile, Sequence } from "remotion";
// Inside a <Sequence>, trim with startFrom/endAt (in frames):
<OffthreadVideo src={staticFile("clips/round1.mp4")} startFrom={30} endAt={150} />
```
- `OffthreadVideo` (preferred for rendering) extracts exact frames via ffmpeg; `<Video>` is for the live studio.
- For audio: `<Audio src={staticFile("music.mp3")} volume={0.6} />`, trim with `startFrom`/`endAt`, fade with a `volume={(f)=>interpolate(...)}` callback.
- Match each clip's segment length to its `<Sequence durationInFrames>`.
- Alternative for long raw montages: render the Remotion intro, then `ffmpeg` concat the gameplay clips after it (re-encode to a common codec/fps first so concat is clean).

## Editing recorded footage (talking-head / explainer)
For turning a folder of phone takes into a finished video with subtitles and synced graphics, read `references/talking-head-edit.md` first. It holds the pipeline and the traps (Whisper hiding restarts, subtitle correction, hiding joins, colour matching). A working pipeline to copy is in `templates/talking-head/` (first used for the Kelompok 7 Psikologi Konseling video, Sept 2026).

## Aspect ratios
Register a second `<Composition>` with `width=1080 height=1920` for vertical (Shorts/Reels/TikTok), `1920x1080` for landscape, `1080x1080` for square. Same component, different canvas; use `useVideoConfig()` to lay out responsively.

## Gotchas seen on this machine (Arch)
- npm here has an `allow-scripts` guard that blocks postinstall scripts. esbuild's native binary still arrives via its optional dep `@esbuild/linux-x64`, so Remotion bundling works without approving scripts. If a future dep truly needs its postinstall, run `npm approve-scripts <pkg>`.
- Use absolute paths; don't assume `cd` persisted between shells.
- Render speed: 11 min of 1080p30 with OffthreadVideo + graphics took ~13 min (16 cores). Plan re-renders accordingly; batch fixes into one render.
- Waiting on a background render: do not grep the log for `Output`, Remotion prints `Output  out/x.mp4` at the START. Wait for `Encoded N/N` or the final `+ out/x.mp4 <size>` line, or for the process to exit.
- `npx tsc --noEmit -p .` before rendering catches most mistakes in seconds.

## Starting template
`src/ExhibitionIntro.tsx` is a complete, working reference: animated gradient + speed-stripe background, springy title card, sliding VS name plates, impact flashes, and three clip-slot placeholders (showing where `OffthreadVideo` footage drops in). Copy it as the basis for new intros. Render it with:
```bash
npx remotion render src/index.ts ExhibitionIntro out/exhibition-demo.mp4
```
Override text without editing code, e.g.:
```bash
npx remotion render src/index.ts ExhibitionIntro out/ft10.mp4 \
  --props='{"game":"GUILTY GEAR STRIVE","title":"FIRST TO 10","player1":"SUJI","player2":"RIVAL","accent":"#3b82f6"}'
```
