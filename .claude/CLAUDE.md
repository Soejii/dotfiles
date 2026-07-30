# Global Instructions

These preferences apply to ALL projects. Project-specific CLAUDE.md files may add to but not override these.

This machine is **Arch Linux** (user `suji`, home `/home/suji`, shell `bash`). Code lives in `~/CODE`.

## Delegation routing

> ⛔ **STOP — this section applies ONLY to *delegated* workers, identified by a marker token.**
> **You are a delegated worker ONLY if your task/instructions literally contain the token `DELEGATED-WORKER`** (the top-level Claude orchestrator injects it at the start of every message it delegates).
> - **No `DELEGATED-WORKER` token in your instructions?** Then this section does NOT apply to you — even if you are a non-Anthropic model running in opencode. This is the case when *the user opened opencode and is talking to you directly*. Behave normally: use your own tools, and **spawn subagents freely if the task benefits from it**. Ignore the anti-delegation rules below.
> - **`DELEGATED-WORKER` token IS present?** Then **YOU are the worker** this section refers to. Therefore:
> - **Do the task yourself** with your own read/edit/write/shell tools. **NEVER run `opencode` / `opencode run`, never spawn sub-agents, never "delegate to another opencode worker."** There is nothing below you to delegate to; doing so spawns infinite recursive opencode processes (this already caused a 20-minute runaway that produced zero output and had to be killed).
> - The only shell commands you should run are the project's own build/test/lint gates for verification (e.g. `flutter test`, `dart run build_runner …`). Do not launch other agents or orchestrators.
> - **Never report "done" / "all tests pass" / "all green" without pasting the actual final gate output.** If the gate is not passing, say so explicitly with the failing output — do not claim success you have not verified. "Passes in isolation" is not "passes in the full suite."
> - Ignore the remainder of this "Delegation routing" section; it is operating guidance for the single top-level Claude Code orchestrator only, never for an opencode worker.

**The top-level Claude Code session = orchestrator — whatever model it is running. Do NOT assume you are Opus; refer to yourself as "the orchestrator," never by a hardcoded model name (I switch the orchestrator model often). Implementation is delegated to an opencode worker to save orchestrator tokens; judgment-heavy work stays with the orchestrator.**

Subagents live in `~/.claude/agents/`.

### The delegation gate (before every non-trivial task)
Before starting any non-trivial implementation, fix, or change, STOP and ask me **in plain text (a normal question, NOT the multiple-choice tool)** what to spin and at what effort, then WAIT for my typed reply. I want to type the worker + model + effort myself, not pick from buttons. In your question, suggest one sensible default (worker/model/effort) with a one-sentence why, but leave it fully open for me to type whatever I want. My reply is the source of truth: if I name a model, use exactly that; if I name an effort/variant (max/high/minimal), use exactly that.

Tiers, for when I ask you to suggest a default (these are guidance, not a fixed menu):
- **The orchestrator (you)** — security-sensitive code, debugging/root-cause, architecture, ambiguous or high-risk changes, or anything I explicitly want you on.
- **A fast/cheap worker** (e.g. `openai/gpt-5.6-luna-fast`, or whatever fast model I name) — mechanical, well-specified, low-ambiguity work: boilerplate, scaffolding, repetitive edits, renames, simple fixes, reformatting.
- **A stronger worker** (e.g. `openai/gpt-5.6-luna` at a higher `--variant`, or whatever model I name) — multi-file or moderate-reasoning implementation that is still well-specified (cheaper than the orchestrator, stronger than the fast tier).

My default worker family is **Luna** (`openai/gpt-5.6-luna*`). Skip the gate for trivial work (reads, lookups, one-liners, answering questions) — just do it. Skip it when I say "just do it" or pre-authorize a model for the session.

### How delegated work runs (via the `cockpit`)
Workers read and edit files themselves via opencode; you orchestrate and verify. **You normally run INSIDE the cockpit** — the user launches everything by typing `cockpit` (script at `~/.local/bin/cockpit`), which opens a tmux window with you (Claude Code) in pane 0 and a warm opencode server on `:4096`. Default worker family = **Luna**.

**Delegate through the `cockpit` command, NOT raw `opencode run`.** cockpit opens each worker as a LIVE tmux pane the user can watch, and it already handles the warm server, the `DELEGATED-WORKER: ` token, `--variant max`, and `--dangerously-skip-permissions` for you. Run it via the Bash tool:

- **New worker:** `cockpit spawn <name> "<self-contained kickoff>" [model] [dir]`
  - Opens a pane running a warm worker the user watches live. `<name>` is how you address it afterwards; `[model]` defaults to `openai/gpt-5.6-luna` (override, e.g. `-fast` for mechanical work; for heavy work keep `openai/gpt-5.6-luna` and raise the effort with `COCKPIT_VARIANT=xhigh`); `[dir]` defaults to `$PWD`.
  - The kickoff must be **self-contained** — a new worker has none of your context, so spell out files, goal, constraints. For a big spec, keep the inline task short and point the worker at the relevant files/paths.
  - **Never ask a worker to print, echo, or paste back its own output.** Ask for a short summary of what it did and what it decided; read the artifact yourself from disk. Asking `sol` to "print the final file" made it re-emit a 169-line file it had already written, which is what drove its context from 222k to 989k. The same applies to diffs and full test logs: ask for the failing lines, not the whole run.
  - Prefer a fresh worker over a follow-up once a session is large. `cockpit say` reuses the warm context, so a worker already near the ceiling only gets worse; re-spawn against the same spec file instead.
- **Follow-up to the SAME warm worker:** `cockpit say <name> "<incremental delta>"`
  - Reuses that worker's warm session; it remembers everything, so send only the delta, never re-brief.
- **Manage:** `cockpit ls` (warm workers), `cockpit down` (close the grid; the `:4096` brain stays up).

Run several named workers in parallel (mechanical → a `-fast` worker, heavy → a `-pro` worker). One name = one warm session + one model. If you are ever headless (not launched via `cockpit`), the same commands still work; the pane just isn't attached to a visible window. Genuine one-shots may use raw `opencode run` (see fallback rules below).

Workflow rules:
- **Arm a monitor the moment you spawn a worker; do not hand-poll and do not rely on remembering.** Immediately after `cockpit spawn`, start a background Monitor on that worker's session that emits on (a) completion or deregistration, (b) a stall, meaning context frozen while `cockpit ls` still says `running`, (c) provider stream errors climbing, and (d) **context ballooning**, meaning the `CONTEXT` column crossing a ceiling (~500k) or multiplying several times over between checks. Watch for `cockpit ls` printing its own `large context detected` warning and treat that as the trigger. Ballooning and stalling are opposite symptoms and a monitor that only checks for frozen context will sit silent through a runaway: `sol` went 222k to 989k in nine minutes while the monitor correctly reported nothing wrong. Then get on with other work; silence from a correctly armed monitor means "still running", whereas silence from no monitor means nothing at all. I have twice gone quiet on a running worker because the conversation moved on to something more interesting, and Suji had to prompt me both times. The rule exists because knowing the lesson is demonstrably not enough.
  - Failure signatures worth recognising: `ProviderHeaderTimeoutError` after 10000ms on the `openai/gpt-5.6-*` family kills a run while the pane still looks busy; a worker in that retry loop shows `status=running` with frozen context and near-zero CPU. Two Luna attempts died this way at ctx=0, which proved it was the provider and not the variant. A cheap way to test whether a provider is healthy again is to spawn a trivial worker on it and watch for a stream error in the first ~30 seconds, rather than burning a real brief to find out.
- After a worker finishes, review the diff **scoped to the files you delegated** (`git diff -- <those paths>`, NOT the whole tree — it also holds my pre-existing unstaged work) and run the verification gates (build/codegen/analyze/tests/lint).
- **Errors are the worker's job to fix, NOT yours — don't burn orchestrator tokens on mechanical fixups.** Feed the failing gate output back to the SAME worker with `cockpit say <name> "..."` (it already has the context) and loop until clean (cap ~3 rounds). Step in yourself only when (a) it's genuinely stuck after a few rounds, (b) the fix needs root-cause debugging or touches security-sensitive code (see "Never delegate"), or (c) it's a one-character fix where a round-trip is obviously wasteful. Note what you let it fix vs. fixed yourself.
- **Final correctness sign-off stays yours** (read the cleaned diff, reason about logic/edge cases).
- **Green gates are not a sign-off.** A worker reporting "all three gates pass" means the code compiles and the existing tests still pass, nothing more. Re-run the gates yourself rather than quoting the worker's transcript, and read its diff for *logic*: the paths its tests never reach, what it does with concurrent/stale requests, and any state it silently overwrites. On SID-246 Luna's code passed analyze, the full test suite and a real APK build while still shipping two live bugs (a filter race that let a stale fetch win, and a load-more that wiped a note the user was mid-typing).
- Always tell me what was delegated, to which worker/model, how many fix rounds it took, and what you found on sign-off.

Raw `opencode run` fallback rules (only when NOT using cockpit, e.g. a genuine one-shot):
- Start the message with the literal token `DELEGATED-WORKER: ` — it flips the worker into worker-mode so it won't recurse. (cockpit adds this for you; you add it yourself only for raw runs.)
- `</dev/null` feeds empty stdin, or opencode hangs forever.
- `-f/--file` is a GREEDY array flag — put the message positional FIRST and `-f <file>` LAST, else `Error: File not found`.
- Long context (diffs, file bodies) goes in a temp `.md` via `-f`; capture output with `2>&1 | tail -<N>`; keep `--variant max` and `--dangerously-skip-permissions`; reuse a warm session with `--attach http://localhost:4096 -s <session-id>`.

### Subagents at a glance
| Agent | Purpose |
|---|---|
| `git-operator` | All git operations |
| `haiku-explorer` | Read-only codebase search (cheap) |
| `pdf-reader` | Extract raw text from PDFs |

**When the harness forbids spawning agents, this table is a preference, not a requirement.**
Some sessions run with "do not use the Agent tool unless the user asked" in effect. That
instruction wins: do the work yourself with your own tools rather than stalling on the
contradiction or spawning anyway. This applies to routine `git-operator` routing in
particular; committing and pushing directly is fine in those sessions. Do not read the
absence of a subagent as a reason to skip the work or to ask me whether you may proceed;
just say in your report that you did it inline and why.

### A regression test must be proven red first

A test written to guard a fix proves nothing until you have watched it fail. Before
claiming it guards anything: reintroduce the bug **faithfully**, run the test, confirm it
fails *for the reason you expect*, then restore the fix and confirm green. Paste both.

Faithfully is the hard part. On SID-246 my first reintroduction swapped in a flag that
starts `true`, so every code path bailed out early and all three tests went red for the
wrong reason, which looks identical to success. The failure message has to name the real
defect (there, "expected 5 requests, got 2" and the overwritten draft text), not just be
red. If a test passes both with and without the fix, say so and call it a guard test
rather than a regression test.

### Never delegate (stays with the orchestrator)
- Security-sensitive code (auth, crypto, input validation)
- Debugging: root-cause analysis needs the orchestrator's own reasoning
- Final correctness sign-off

### Peer review is mandatory before every commit
**Never run `git commit` on a code change until an external peer review has come
back and I have acted on its findings.** Load the `peer-review` skill and follow
it; it holds the model choice, the brief, and the triage rules. This applies to
my own changes as much as a worker's. Docs-only or config-only diffs may skip it;
say that you skipped it and why. If I ask you to commit and no review has run,
run the review first rather than asking whether you should.

## Writing Style

- Never use em dashes. Use commas, semicolons, or other connectors instead.
- Be concise. Don't over-explain or pad responses.
- Always respond in English, regardless of the language the user writes in.

## Academic Writing

- When asked to write academic content (literature reviews, essays, conclusions), just do it. Do not question whether there are enough sources or over-analyze.
- Default to APA format for all academic work.
- Be concise and narrative, not verbose.

## PDF Handling

- For PDFs over 20 pages, split into parallel pdf-reader agents (20 pages each). Collect all extracted content, then write the final note yourself (or delegate the writing per the gate). For PDFs under 20 pages, use a single pdf-reader agent, then write the note.

## Flutter projects

The SIDIGS apps (`nakula`, `chiron`, `gaia`, `icarus`, `arjuna`, `karna` in `~/CODE`) are fvm-pinned Flutter repos. These rules apply to all of them; the pinned version and repo-specific traps live in each project's own CLAUDE.md.

- **Always run through the pinned SDK.** `fvm flutter <cmd>`, never a bare `flutter`. The machine-wide fvm default tracks the moving `stable` channel and is newer than what these repos pin. A gate run on the wrong SDK has already passed while the real build failed. `fvm flutter --version` if a result looks surprising.
- **`analyze` passing is not proof it compiles.** Static analysis has gone green on code that failed `assembleDebug` because a widget parameter was renamed in a later SDK. Any change touching Flutter widget APIs finishes with a real `fvm flutter build apk --debug`, not just analyze and test.
- **Never run two Flutter builds concurrently.** Overlapping builds have written `pubspec.lock` simultaneously and corrupted it into invalid YAML, while `flutter build` still exits 0 and only prints "Failed parsing lock file". Recover with `git checkout -- pubspec.lock` then a single `dart pub get` on the pinned SDK.
- **Never run a bare `fvm flutter analyze` as a gate. Use `/home/suji/.local/bin/flutter-analyze-diff` instead.** These repos carry hundreds of pre-existing legacy diagnostics (nakula: 1251), so the bare command buries a real regression in noise and, when an agent runs it, floods the context window: on SID-250 that single command took a worker from 221k to 693k tokens in one step and it finished the task at 740k. The script runs the analyzer on the pinned SDK, then reports only diagnostics in the `.dart` files the change actually touched (staged, unstaged, and untracked, so new files count), plus any error-severity diagnostic anywhere, since an error in an untouched file still breaks the build. It prints an `N of M diagnostic(s) in scope` line so the suppressed count stays visible rather than hidden, and exits 0 when clean, 1 when something survives.
  - `flutter-analyze-diff` for working-tree changes; `flutter-analyze-diff main` for everything a branch changed vs `main`.
  - Put this in the kickoff of any worker you spawn on a Flutter repo. A worker starts cold and will otherwise reach for the bare command.
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
