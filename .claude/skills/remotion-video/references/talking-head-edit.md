# Editing recorded talking-head footage

Pipeline and lessons from editing 41 phone takes (3 presenters, ~21 min raw) into an 11-minute lecture explainer with subtitles and word-synced graphics. The working code is in `../templates/talking-head/`.

## Pipeline

1. **Ingest and log.** Give every clip a short id in chronological order (`c01`...) in a `manifest.json`. Extract 16 kHz mono WAVs. Make a contact sheet of mid-frames (`drawtext` the id on each, `tile=6x7`) to see who is who, framing, and lighting shifts at a glance.
2. **Transcribe.** `faster-whisper` in a uv venv (`uv venv -p 3.12`; Python 3.14 has no ctranslate2 wheels yet), model `large-v3-turbo`, `device="cpu", compute_type="int8"`, `word_timestamps=True`, the right `language=`, and an `initial_prompt` listing names and jargon. ~21 min of audio took ~10 min on 16 cores. Run it in the background and build graphics meanwhile.
3. **Pick takes.** Read the transcripts against the script. Complete and fluent wins; note false starts, laughter, chatter. Record choices as an edit decision list: `(clip, first words, last words)` per scene, several tuples when a scene needs a join.
4. **Cut** (`cut.py`). Locate the phrases by fuzzy word matching, pad 0.30 s in and 0.40 s out but never past the midpoint to the neighbouring word. One ffmpeg `filter_complex` per scene: `fps=30,scale,format=yuv420p` (phone footage is VFR HEVC), optional grade, `afade` 60-80 ms at each part's edges, `concat`, then `highpass=f=80,afftdn=nf=-28,loudnorm=I=-16:TP=-1.5:LRA=9`. Encode `-crf 17 -g 30` so OffthreadVideo seeks fast. Save each scene's words re-timed to the scene timeline.
5. **Subtitles** (`subs.py`). See below.
6. **Timeline** (`build.py`). Graphics are declared per scene with phrase cues (`"Dalam contoh Raka-0.2"`, `"@kesadaran diri"` inside props) and resolved to frames. Output one `timeline.json` the Remotion composition reads. Every later fix is an edit here plus a re-render, never a redo.
7. **QC**, then render, then contact-sheet the render.

## Traps (each one cost real time)

- **Whisper without VAD hides restarts.** It merged "Ada empat jenis dalam kelompok... ulang... ada... empat..." (8 s of stumbling) into ONE word with a 9.7 s duration, so the transcript looked clean. Detect: flag words longer than ~1.1 s and gaps over 1 s. Confirm: re-transcribe the region with `vad_filter=True`. Fix: hand-set the in-point.
- **Always re-transcribe the finished cuts** with `vad_filter=True` and diff against the expected subtitle words; report extra words in the audio. This caught a leaked "Oke," at a cut point. A short "Terima kasih." at the very end on silence (check RMS, e.g. -47 dB) is a Whisper hallucination, not speech.
- **Subtitles = what was said, spelled right.** Do not align blindly to the script: speakers deliberately change words ("simpulkan" for "bawa pulang"), and script-substitution would put words in their mouths. Instead keep Whisper's words and timing and apply a hand-reviewed per-scene list of `(heard, correct)` fixes for true mishearings ("Wedding" -> "Gladding", "konsuler" -> "konselor"). Review the full diff vs the script once, decide each item.
- **Cue chunking:** one sentence per cue when it fits (~84 chars, two lines of ~42); split long sentences into near-equal chunks preferring commas; never end a cue on a weak word (dan, di, yang, dengan, untuk, dari, ...); balance the two lines; hold 0.2 s after the last word but never overlap the next cue.
- **Fuzzy phrase matching needs care.** A loose threshold matched "Lalu yang keempat" to "Lalu yang ketiga". Rule that worked: take the first occurrence scoring >= 0.93, else the best-scoring occurrence; group adjacent hits as one occurrence.
- **Hide joins under full-screen boards.** A jump cut inside a side panel still shows. Put an opaque full-screen graphic over the join (start ~0.9 s before it, end ~0.8 s after). Keep the presenter at panel size while the board fades in; if the panel ramps back to full frame at the same moment, it visibly grows behind the board.
- **Colour match** clips shot under different light: sample a neutral wall region in each clip (`crop=...,scale=1:1:flags=area` to one RGB pixel), then `colorchannelmixer=rr=..:gg=..:bb=..` with ratios target/measured.
- **Audio levels** differ wildly between phones/distances; per-scene `loudnorm` to -16 LUFS gave an even result (final integrated -16.5 LUFS).
- **Crossfade overlap** between scenes (8 frames) is safe for audio because each scene carries ~0.3-0.4 s of silent padding at both ends.
- **Name lower-thirds** only while the presenter is full-frame; once they shrink into a panel the label no longer sits next to them.
- **Board timing:** a board should appear just before its first card, not at the start of the sentence, or the viewer stares at a lone heading for seconds.

## Layout that worked (1920x1080)

- Modes per graphic: `split` (presenter animates into a rounded panel at x=1200, y=80, 640x770; graphic on the left), `board` (full-screen graphic on opaque paper, presenter hidden, audio continues), `overlay` (chips, name tags; presenter untouched).
- Subtitles bottom-centre, 42 px semibold, dark 80% box, `whiteSpace: pre-line`. Citations bottom-right at `bottom: 196`, above the subtitle zone. Section chips top-left.
- Source footage was 720p; rendering at 1080p keeps graphics and text crisp.

## What the model cannot judge

Say so in the report: take energy/delivery beyond fluency, and how an audio join actually sounds. Give the user timestamps of every join to listen to.
