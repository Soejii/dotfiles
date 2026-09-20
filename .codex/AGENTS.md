# Global Instructions

These preferences apply to ALL projects. Project-specific AGENTS.md files may add to but not override these.

This machine is **Arch Linux** (user `suji`, home `/home/suji`, shell `bash`). Code lives in `~/CODE`.

## Delegation routing

The top-level Codex session is the orchestrator. It owns scope, judgment,
verification, and final sign-off, even when implementation work is delegated.

### Delegation gate

Before starting any non-trivial implementation, fix, or change, ask Suji in
plain text what to delegate and which model and reasoning effort to use, then
wait for his typed reply. Suggest one sensible default with a one-sentence
reason, but leave the choice open. Suji's reply is authoritative. If he names a
model or effort, use exactly that choice.

Skip this gate for trivial work such as reads, lookups, one-line edits, and
answering questions. Also skip it when Suji says "just do it", "proceed", asks
the orchestrator to do the work itself, or pre-authorizes a model for the task
or session.

Use these tiers when suggesting a default:

- **The orchestrator**: debugging, root-cause analysis, security-sensitive
  code, architecture, ambiguous changes, high-risk changes, and any work Suji
  explicitly wants handled directly.
- **A fast worker**, normally `gpt-5.6-luna` at low or medium effort:
  mechanical and well-specified work such as scaffolding, repetitive edits,
  renames, formatting, and simple fixes.
- **A stronger worker**, normally `gpt-5.6-luna` or `gpt-5.6-terra` at high
  effort: multi-file or moderate-reasoning implementation that is still
  clearly specified.

Use Codex's native subagents for concrete, bounded tasks that can run
independently. Do not launch Cockpit, OpenCode, or another external agent
process unless Suji explicitly requests it. The orchestrator must inspect the
resulting diff, run the final verification itself, and report what was
delegated, to which model and effort, and any corrections made during sign-off.

### Never delegate

- Security-sensitive code, including authentication, cryptography, and input
  validation
- Debugging and root-cause analysis
- Final correctness review and sign-off

## Web research

Always use Hound for web searches. If Hound fails or cannot search the required source, ask Suji before using another web-search tool.

## Peer review

Peer review is opt-in. Use the `peer-review` skill only when Suji explicitly requests a review. You may remind him that review is available, but do not make it an automatic commit gate.

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

Use the `college-pdf-ingest` skill whenever Suji attaches, links, or points to a PDF, unless he explicitly says it is temporary, unrelated to college, or inspection-only. Ask for the course when it was not provided, even if the answer looks obvious.

Always run the local cache wrapper before reading a local PDF:

```bash
/home/suji/.local/bin/pdf-text-cache <file.pdf>
```

The wrapper uses `pdf-inspector` 1.17.0 selective OCR in `Auto` mode, caches by SHA-256 and package version, and prints the reusable Markdown path. Read only relevant cached sections. For retained sources, the skill creates a same-basename PDF and faithful Markdown transcript under `/home/suji/document/college`. Assignments do not require transcript twins. Tables remain review-sensitive, so visually inspect a table page before relying on its values.

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
