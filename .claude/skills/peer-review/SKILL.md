---
name: peer-review
description: Peer review of a code diff by an external model before committing. Use before every `git commit`, and whenever Suji asks to review or sanity-check a change.
---

# Peer review before commit

The reviewer is a **reader**. Its entire output is a findings list, and the code
is exactly as it was when it went in.

The default reviewer is the **codex CLI**, because it **fails loudly**: a
one-shot foreground command with no pane to babysit and no session to monitor,
which exits non-zero when the provider is out of capacity instead of retrying in
silence. Section 3b covers the opencode fallback.

Rules below carrying a date or a ticket id have an incident behind them in
[`INCIDENTS.md`](INCIDENTS.md). Read it before relaxing one, or when a run fails
in the way a rule was meant to prevent.

## 1. Pick the model

Ask in plain text, not the multiple-choice tool. One line, then wait:

> Reviewing with codex on `gpt-5.6-sol` at `medium`, unless you'd rather name
> another model or effort.

Whatever Suji types wins verbatim. "go", or a model pre-authorised for the
session, skips the question.

**The default is `gpt-5.6-sol` at `medium`**, set by Suji on 2026-08-03.
`~/.codex/config.toml` already pins both, but pass `-m` explicitly anyway so each
run states its own model instead of inheriting a config that may drift. Override
effort per-run with `-c model_reasoning_effort=high`.

**If the run dies within seconds, read the log before blaming the diff or the
brief.** Two unrelated failures look identical from the outside:

- `Selected model is at capacity` — switch to `gpt-5.6-luna` or `gpt-5.6-terra`,
  both verified working on 2026-07-30. `gpt-5.6-codex` is not a valid model id.
- `401 Unauthorized` on the websocket, or `refresh token was revoked` — codex
  auth is dead for **every** model, so switching model wastes time. Suji has to
  run `codex login` himself; it is interactive and cannot be done from here.

If he names an opencode model instead, read
[`OPENCODE-FALLBACK.md`](OPENCODE-FALLBACK.md) and dispatch from there.

## 2. Build the diff

Scope it to what is being committed, never the whole tree, which also holds
pre-existing unstaged work:

```bash
git diff HEAD -- <paths>          # or: git diff --staged
```

Write it to a temp `.md` in the scratchpad; a diff in the prompt positional hits
ARG_MAX.

Then extend it until the reviewer can see the **blast radius** without going to
look for it. Done when all three hold:

- Every caller of a changed signature is either included in full, or named with a
  one-line note saying why it is unaffected.
- Every interface the changed code implements or overrides is included.
- The tests covering the changed paths are included, along with a note where a
  changed path has none.

An absent item stated is fine; an absent item unstated is what sends a reviewer
hunting.

## 3a. Dispatch to codex (default)

`codex exec` appends piped stdin as a `<stdin>` block, so **pipe the diff rather
than giving it a path.** The content then arrives inline and the fence enforces
itself, because there is nothing left to go looking for:

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

Add `--skip-git-repo-check` only when `-C` is not inside a git repo.

- `-s read-only` is sufficient for a review and blocks edits outright, which is
  the guarantee section 5 depends on.
- `-o` writes just the final message. Read that file, and leave
  `codex-run.log` on disk unread; it carries the whole transcript.
- `-C` sets the root codex may read under.

Completion criterion: `exit=0` and the `-o` file contains findings. Anything else
is a dispatch failure, not a clean review.

There is also a native `codex exec review --uncommitted` (and `--base <branch>`)
which reads the working tree itself instead of a curated diff. Untried here, so
prefer the curated-diff path above for a real pre-commit review and treat the
native form as a quick sanity check at most.

## 3b. Fallback: an opencode worker

Read [`OPENCODE-FALLBACK.md`](OPENCODE-FALLBACK.md).

## 4. The brief

Self-contained; the reviewer has none of your context.

**Codex does not read `CLAUDE.md`.** On a Flutter repo, concatenate
[`HOUSE-RULES-FLUTTER.md`](HOUSE-RULES-FLUTTER.md) into the brief, or codex will
report correct house style as defects.

The brief is done when it carries all four of:

1. What the change is meant to do. A reviewer guessing at intent reviews the
   wrong thing.
2. Any API or contract facts you verified yourself, marked authoritative, so it
   does not go re-deriving them from the backend.
3. The fence, near the top where it cannot be missed.
4. The review request below, unedited.

### The fence

A reviewer that cannot immediately see the change goes looking for it, and
looking means `git branch` hunting, `gh api` calls, and reading backend source
whose behaviour you already handed it (SID-248):

> Do NOT run git, gh, or any repository exploration commands. Do NOT hunt for
> branches. Do NOT read backend or other-language source. Everything you need is
> in the file above. You may read files under `<repo>/lib` and `<repo>/test` if
> you need to see a caller in full, and only then.

Keep the fence on the codex path too. Piping the diff removes most of the
incentive to wander and `-s read-only` caps the damage, but a reviewer that goes
exploring still burns minutes and returns findings about code you never changed.

### The review request

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

Ask for findings only, never for files or diffs echoed back.

## 5. Triage the findings, then hand them to Suji

**Triage before he sees the list, fix nothing.** The reviewer is a second opinion
and will produce false positives; acting on a wrong one is worse than ignoring
it.

Verify every finding against the actual code, then give him one line each: what
it claims, your verdict, and the evidence behind that verdict. Verdicts are real
defect, false positive, or out of scope.

Then wait. He decides what gets fixed.

Handing him a list of things already fixed defeats the point. He is reading these
to know what was wrong with the code, which is the part that keeps his judgement
sharp while a model writes the diff.

## 6. Fix what he greenlights

Confirmed defects go back to the worker that wrote the code, unless the fix is
security-sensitive, needs root-cause debugging, or is one character. Re-review
after non-trivial fixes.

Then read the cleaned diff and reason about the logic yourself. A clean review is
not a sign-off (SID-246).

## 7. Report, then commit

Which model reviewed, what it flagged, what you accepted or rejected and why,
what was fixed, what stays open. If Suji says commit with findings open, commit
and name the ones being carried.
