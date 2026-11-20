# Talking-head edit template

Copied from the Kelompok 7 Psikologi Konseling edit (Sept 2026). Read `../../references/talking-head-edit.md` first.

- `pipeline/`: Python, run from a work dir that holds `manifest.json`, `audio/`, `transcripts/`, `words/`.
  - `transcribe.py` (Whisper per clip), `scenes.py` (edit decision list + warm-light clips), `cut.py` (trim/join/grade/audio into `remotion-studio/public/<proj>/`), `subs.py` (per-scene mishearing fixes + cue chunking), `build.py` (graphics on phrase cues -> `timeline.json`), `srt.py`, `qc_transcribe.py` (VAD re-transcription of finished cuts).
  - Paths, the scene plan in `build.py`, and the FIX lists in `subs.py` are project-specific: replace them.
- `remotion/`: drop into `remotion-studio/src/<proj>/`. `K7Video.tsx` is the composition (presenter panel, boards, overlays, citations, subtitles, crossfades); `visuals.tsx` holds Board, TitleCard, RakaBoard, Wellness, GroupCircle, Ecology, TwoCircles, BigLine, BarrierStrip, RefsCard, CreditsCard, Chip, NameTag. Register with `durationInFrames={timeline.total}`.
