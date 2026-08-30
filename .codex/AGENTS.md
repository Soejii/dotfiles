# Global Instructions

These preferences apply to ALL projects. Project-specific AGENTS.md files may add to but not override these.

This machine is **Arch Linux** (user `suji`, home `/home/suji`, shell `bash`). Code lives in `~/CODE`.

## Operating mode

Complete every task directly in the current Codex session. Do not hand work to other agents or processes.

## A regression test must be proven red first

A test written to guard a fix proves nothing until you have watched it fail. Before
claiming it guards anything: reintroduce the bug **faithfully**, run the test, confirm it
fails *for the reason you expect*, then restore the fix and confirm green. Paste both.

Faithfully is the hard part. On SID-246 my first reintroduction swapped in a flag that
starts `true`, so every code path bailed out early and all three tests went red for the
wrong reason, which looks identical to success. The failure message has to name the real
defect (there, "expected 5 requests, got 2" and the overwritten draft text), not just be
red. If a test passes both with and without the fix, say so and call it a guard test
rather than a regression test.

## Writing Style

- Never use em dashes. Use commas, semicolons, or other connectors instead.
- Be concise. Don't over-explain or pad responses.
- Always respond in English, regardless of the language the user writes in.

## Academic Writing

- When asked to write academic content (literature reviews, essays, conclusions), just do it. Do not question whether there are enough sources or over-analyze.
- Default to APA format for all academic work.
- Be concise and narrative, not verbose.

## PDF Handling

**Always run `/home/suji/.local/bin/pdf-text-cache <file.pdf>` first. Never open a
local PDF with the Read tool before checking whether it has a real text layer.** The
wrapper runs `pdf-inspector detect`, caches a text-based extraction by the PDF's
SHA-256 content hash, and prints the reusable Markdown path. The vision path pushes
every page through a model's context; `pdf-inspector` is a local native binary that
costs zero tokens. Installed 2026-08-02 at
`/home/suji/.npm-global/bin/pdf-inspector` (npm `@firecrawl/pdf-inspector`, prebuilt
Rust/napi binary, no toolchain needed).

Note the CLI differs from the GitHub README, which documents an abandoned `cargo`
path: the crates.io crate is stuck at 0.1.0 while npm ships 1.11.2. There is no
`pdf2md` or `detect-pdf` command. It is:

```bash
/home/suji/.local/bin/pdf-text-cache <file.pdf>  # detect, extract once, and print the cached Markdown path
/home/suji/.local/bin/pdf-text-cache --rename-to 'The Many Levels of Inquiry - (Banchi & Bell, 2008)' <file.pdf>
/home/suji/.npm-global/bin/pdf-inspector <file.pdf> --pages 1,3,5  # narrow direct inspection when needed
```

The routing rule:

1. Run `/home/suji/.local/bin/pdf-text-cache`. A successful run prints the extraction under
   `/home/suji/.local/share/pdf-inspector/extracted/<sha256>/`. Never create an
   extracted `.md` beside the PDF. Search or read only the relevant cached sections;
   do not read the whole Markdown by reflex. A 36-page document is about 10k tokens.
2. If the wrapper reports scanned or OCR-required pages and exits 3, use OCR or vision
   only for those pages, 20 pages at a time for anything over 20.
   Photocopied course packs and photographed handouts land here; publisher journal
   PDFs generally do not.
3. Once an academic paper's title, author form, and year have been verified from the
   source, rename it with the wrapper using `Title - (In-text citation, Year).pdf`.
   Use `&` for two authors and `FirstAuthor et al.` for three or more. Replace a `/`
   in a title with `-` because `/` cannot appear in a Linux filename. Never infer the
   citation identity from an unverified download filename.
4. Treat Downloads as an inbox. Move a source being retained into the project's
   established source or reference folder. The content-hash cache remains reusable
   if the PDF is renamed or moved. Cite the original PDF, never the cached Markdown.

**Known weakness, verified not assumed: tables degrade.** On a real 36-page proposal
the prose, headings, and in-text citations came out clean, but `Tabel 1.1` lost its
header row to an `###` heading, flattened three rows into running paragraphs with the
columns interleaved, and split the remainder into two pipe tables with mismatched
column counts. So when a specific table's values matter, read those pages visually with
`--pages` narrowing first; do not quote figures straight out of the extracted markdown.

## Flutter projects

The SIDIGS apps (`nakula`, `chiron`, `gaia`, `icarus`, `arjuna`, `karna` in `~/CODE`) are fvm-pinned Flutter repos. These rules apply to all of them; the pinned version and repo-specific traps live in each project's own AGENTS.md.

- **Always run through the pinned SDK.** `fvm flutter <cmd>`, never a bare `flutter`. The machine-wide fvm default tracks the moving `stable` channel and is newer than what these repos pin. A gate run on the wrong SDK has already passed while the real build failed. `fvm flutter --version` if a result looks surprising.
- **`analyze` passing is not proof it compiles.** Static analysis has gone green on code that failed `assembleDebug` because a widget parameter was renamed in a later SDK. Any change touching Flutter widget APIs finishes with a real `fvm flutter build apk --debug`, not just analyze and test.
- **Never run two Flutter builds concurrently.** Overlapping builds have written `pubspec.lock` simultaneously and corrupted it into invalid YAML, while `flutter build` still exits 0 and only prints "Failed parsing lock file". Recover with `git checkout -- pubspec.lock` then a single `dart pub get` on the pinned SDK.
- **Never run a bare `fvm flutter analyze` as a gate. Use `/home/suji/.local/bin/flutter-analyze-diff` instead.** These repos carry hundreds of pre-existing legacy diagnostics (nakula: 1251), so the bare command buries a real regression in noise and floods the context window. The script runs the analyzer on the pinned SDK, then reports only diagnostics in the `.dart` files the change actually touched (staged, unstaged, and untracked, so new files count), plus any error-severity diagnostic anywhere, since an error in an untouched file still breaks the build. It prints an `N of M diagnostic(s) in scope` line so the suppressed count stays visible rather than hidden, and exits 0 when clean, 1 when something survives.
  - `flutter-analyze-diff` for working-tree changes; `flutter-analyze-diff main` for everything a branch changed vs `main`.
- To see a screen actually run on an emulator, use the `android-emulator-drive` skill rather than improvising adb commands.

## Linux / Arch Shell Rules

This is Arch Linux (user `suji`, home `/home/suji`, shell `bash`). Follow these to avoid silent failures:

- **File operations** (check if exists, list, search, read): use Glob, Grep, Read, Write tools — never `ls`/`find`/`grep` via Bash. These tools bypass the shell entirely.
- **Running commands**: use the **Bash tool**. Use normal Linux paths (`/home/suji/...`), never `C:\` or `/c/Users/...`.
- **Packages**: official repos via `sudo pacman -S --needed`, AUR via `yay -S`. Don't run `makepkg` as root.
- **Hooks run with a minimal PATH** — user-installed binaries are not on the hook PATH. Always use full absolute paths in hook commands and in any subprocess they call:
  - Python: `/usr/bin/python3`
  - Flutter / Dart (fvm global): `/home/suji/fvm/default/bin/flutter`, `/home/suji/fvm/default/bin/dart`
  - node / npm-global bins: `/home/suji/.npm-global/bin/...`

## SLSsteam / ACCELA / Headcrab (Steam DRM tooling)

User runs SLSsteam (`~/.config/SLSsteam/config.yaml`, unlocks unowned Steam games/DLC) alongside ACCELA (depot downloader, `~/.local/share/ACCELA`) and the "Headcrab" ecosystem (`~/enter-the-wired`, `~/.local/share/applications/headcrab.desktop`) which pins/patches the Steam client for compatibility. Headcrab's updater is a live, unpinned `curl|bash` from `Deadboy666/h3adcr-b` using `sudo pacman` for deps; it patches SLSsteam's config once, guarded by `~/.config/SLSsteam/.headcrabd`. Investigated 2026-07-05: appears to be genuine actively-maintained community tooling (100+ stars, routine commit history, established maintainer accounts), not malware — but it's a standing trust bet (no checksums, sudo use, several pseudonymous maintainers) worth re-auditing if config/behavior changes unexpectedly again.

@RTK.md
