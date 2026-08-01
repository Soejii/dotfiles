---
name: peer-review
description: External peer review of a code diff before committing. Pipes the diff to the codex CLI, which maps the change's blast radius, edge cases, and correctness, then reports findings. Use before every `git commit`, and when asked to peer-review, code-review, or sanity-check changes.
---

# Peer review before commit

The reviewer is a reader. Its entire output is a findings list, and the code is
exactly as it was when it went in.

**The default reviewer is the codex CLI, not an opencode worker** (changed
2026-07-30). Codex did a 92KB review in a few minutes that three opencode `sol`
workers failed to produce at all, and it found a real defect the orchestrator had
personally got wrong.

The reason to prefer it is **not** that it has a healthier route to the provider -
it hits the same capacity limits, as section 1 shows. It is that codex is a
one-shot foreground command that **fails loudly**: no pane to babysit, no session
to monitor, and when the provider is out of capacity it says so and exits non-zero
instead of retrying in silence until you give up. The opencode path is kept in
section 3b as a fallback.

## 1. Pick the model

Ask in plain text, not the multiple-choice tool. One line, then wait:

> Reviewing with codex on `gpt-5.6-luna`, unless you'd rather name another model
> or effort.

Whatever Suji types wins verbatim. "go", or a model pre-authorised for the
session, skips the question. If he names an opencode model instead, use section 3b.

**Pass `-m` explicitly; do not rely on the codex default.** `~/.codex/config.toml`
pins `model = "gpt-5.6-sol"`, and on 2026-07-30 `sol` was at capacity and failed
every request. Verified that day: `gpt-5.6-luna` and `gpt-5.6-terra` both work,
`gpt-5.6-sol` returns `ERROR: Selected model is at capacity. Please try a
different model.` and exits 1, and `gpt-5.6-codex` is not a valid model id.
Reasoning effort comes from `model_reasoning_effort` in that config (currently
`medium`); override per-run with `-c model_reasoning_effort=high`.

Codex at least **fails loudly** here, which is the whole reason it is the default:
it prints that capacity error and exits non-zero in seconds, where opencode
swallows the identical condition and retries in silence for as long as you let it.
If a review dies instantly, read the run log for that error and switch model,
rather than assuming the diff or the brief was at fault.

## 2. Build the diff

Scope it to what is being committed, never the whole tree, which also holds
pre-existing unstaged work:

```bash
git diff HEAD -- <paths>          # or: git diff --staged
```

Write it to a temp `.md` in the scratchpad; a diff in the prompt positional hits
ARG_MAX. Include what the reviewer needs to see the blast radius: callers of the
changed code, the interfaces it implements, the tests covering those paths. Keep
the absolute path to hand, because section 3 delivers it differently depending on
how you dispatch.

## 3a. Dispatch to codex (default)

`codex exec` appends piped stdin as a `<stdin>` block, so **pipe the diff rather
than giving it a path.** The content then arrives inline and the "do not explore"
fence enforces itself, because there is nothing left to go looking for:

```bash
S=/path/to/scratchpad
cat "$S/review.md" | /home/suji/.local/bin/codex exec "$(cat "$S/brief.txt")" \
  -m gpt-5.6-luna \
  -s read-only \
  -C /home/suji/CODE/<repo> \
  -o "$S/codex-findings.md" \
  >"$S/codex-run.log" 2>&1
echo "exit=$?"                    # non-zero usually means a capacity error
```

Verified working end to end on 2026-07-30: the diff arrives inside a `<stdin>`
block, codex answers questions about its contents, and the findings land in `-o`.
Add `--skip-git-repo-check` only when `-C` is not inside a git repo.

- `-s read-only` is sufficient for a review and blocks edits outright, which is
  the guarantee section 5 depends on.
- `-o` writes just the final message. Read that file, not the run log, which
  carries the whole transcript.
- Redirect the run log to disk. Letting a full codex transcript into the
  orchestrator's context is the same mistake as asking a worker to echo files back.
- `-C` matters: it sets the root codex may read under.

**Codex does not read `CLAUDE.md`.** The brief must carry the house rules itself
or it will flag correct house style as defects; see section 4.

There is also a native `codex exec review --uncommitted` (and `--base <branch>`)
which reads the working tree itself instead of a curated diff. Untried here. The
curated-diff path above is the proven one, so prefer it for a real pre-commit
review and treat the native form as a quick sanity check at most.

## 3b. Fallback: dispatch to an opencode worker

Use when Suji names an opencode model, or when codex is unavailable.

**`cockpit spawn` does not take `-f`.** Its signature is
`cockpit spawn <name> "<kickoff>" [model] [dir]`, so a trailing `-f <file>` is
swallowed as a stray positional and the reviewer starts with no diff at all. It
will not say so. Put the absolute path *inside* the brief and open by telling it
to read that file:

```bash
COCKPIT_VARIANT=medium cockpit spawn rev1 "Read this file and review what is in it:
/abs/path/to/diff.md

<rest of brief>" openai/gpt-5.6-luna
```

Only the headless form takes `-f`, message positional first and `-f` last:

```bash
opencode run "DELEGATED-WORKER: <brief>" -m openai/gpt-5.6-luna \
  --variant medium --dangerously-skip-permissions \
  </dev/null -f <diff.md> 2>&1 | tail -80
```

Then arm a Monitor per CLAUDE.md, but set the ceiling at about **250k**, not the
500k used for implementation workers. A focused review of one diff lands well
under that. Past it the worker is exploring rather than reviewing, and the fix is
to kill and re-spawn, not to wait it out.

**Prefer `luna` over `sol` on this path.** On 2026-07-30 three `sol` reviewers sat
in a silent provider-overload retry loop, one killed at 25 minutes having produced
nothing, while `luna` completed the identical review. If a reviewer goes silent
with frozen context, run `cockpit errors` before concluding anything: opencode logs
provider errors only to its own log, so a retry loop and deep thinking look
identical in the pane.

## 4. The brief

Self-contained; the reviewer has none of your context. Say what the change is
meant to do, since a reviewer guessing at intent reviews the wrong thing.

Then fence it, near the top where it cannot be missed. A reviewer that cannot
immediately see the change goes looking for it, and looking means `git branch`
hunting, `gh api` calls, and reading backend source whose behaviour you already
handed it:

> Do NOT run git, gh, or any repository exploration commands. Do NOT hunt for
> branches. Do NOT read backend or other-language source. Everything you need is
> in the file above. You may read files under `<repo>/lib` and `<repo>/test` if
> you need to see a caller in full, and only then.

List any API or contract facts you verified yourself as authoritative, so it does
not go re-deriving them from the backend.

**On the codex path, add the house rules**, because codex never sees `CLAUDE.md`
and without them it reports correct house style as defects. For the Flutter repos
that means at least: the pinned SDK version, `withValues` not `withOpacity`,
`DropdownButtonFormField` takes `value:`, screenutil `.w/.h/.sp/.r`, Indonesian UI
copy is intentional, no `_buildXxx()` helpers, fetch in `onReady` not `onInit`.
Add whatever else the diff touches. Then:

> Review this diff as an external engineer who wasn't involved in writing it.
> Your entire output is a findings list.
>
> Map the **blast radius** first: everything outside this diff that the change
> reaches. Callers of changed signatures, implementers of changed interfaces,
> shared state, and assumptions other files make about this one.
>
> Then, inside the diff:
> - **Correctness.** Does it do what it claims? Inverted conditions, off-by-one,
>   wrong operator, misread API contract.
> - **Edge cases.** Empty, null, zero, negative, huge, unicode. Stale responses
>   beating fresh ones, double-fire, races. What happens when the network or the
>   parse fails. State silently overwritten, including input the user is
>   mid-edit on.
> - **Tests.** Which changed paths have no coverage, and which tests would still
>   pass if the change were reverted.
>
> Each finding: file:line, what breaks, and a concrete input or sequence that
> triggers it. Most severe first. Label opinions as opinions. If the diff is
> clean, say so in one line.

Ask for findings only. A worker asked to echo files back is what took one session
from 222k to 989k context.

Both halves of this are load-bearing, and SID-248 proved it on the opencode path.
sol at `medium`, dispatched with a trailing `-f` that cockpit swallowed and no
fence in the brief, spent 15 minutes and 412k context on `git branch` hunting and
Laravel helper source without producing one finding. Re-spawned with the path
inside the brief and the fence in place, the same model at the same effort read the
file and was working in under a minute. When a reviewer wanders, suspect your
dispatch before you blame the model.

Keep the fence on the codex path too. Piping the diff removes most of the
incentive to wander, and `-s read-only` caps the damage, but a reviewer that goes
exploring still burns minutes and returns findings about code you never changed.

## 5. Bring the findings to Suji before changing any code

Verify each finding against the actual code first. The reviewer is a second
opinion and will produce false positives; acting on a wrong one is worse than
ignoring it.

Then show him the list and wait. One line per finding: what it claims, your
verdict, and the evidence behind that verdict. Real defect, false positive, or
out of scope. He decides what gets fixed.

Handing him a list of things already fixed defeats the point. He is reading these
to know what was wrong with the code, which is the part that keeps his judgement
sharp while a model writes the diff.

## 6. Fix what he greenlights

Confirmed defects go back to the worker that wrote the code, unless the fix is
security-sensitive, needs root-cause debugging, or is one character. Re-review
after non-trivial fixes.

Then read the cleaned diff and reason about the logic yourself. On SID-246, green
gates plus a clean review still shipped a filter race and a wiped draft.

## 7. Report, then commit

Which model reviewed, what it flagged, what you accepted or rejected and why,
what was fixed, what stays open. If Suji says commit with findings open, commit
and name the ones being carried.
