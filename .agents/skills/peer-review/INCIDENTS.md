# Incidents behind the rules

Every dated rule in `SKILL.md` came from one of these. Read this before
relaxing a rule, or when a run fails in the way a rule was meant to prevent.

Do not add a rule here without the observation that produced it, and delete an
entry once its rule is gone.

## 2026-07-30 — codex replaced opencode as the default reviewer

Three opencode `sol` workers failed to produce a review at all. Codex produced a
92KB review in a few minutes and found a real defect the orchestrator had
personally got wrong.

The reason to prefer codex is **not** a healthier route to the provider; it hits
the same capacity limits. It is that codex is a one-shot foreground command that
fails loudly. No pane to babysit, no session to monitor, and when the provider is
out of capacity it says so and exits non-zero rather than retrying in silence
until you give up.

## 2026-07-30 — `sol` at capacity on both clients

Verified that day:

- `gpt-5.6-luna` and `gpt-5.6-terra` both work.
- `gpt-5.6-sol` returns `ERROR: Selected model is at capacity. Please try a
  different model.` and exits 1.
- `gpt-5.6-codex` is not a valid model id.

The same day, three `sol` reviewers on the opencode path sat in a silent
provider-overload retry loop; one was killed at 25 minutes having produced
nothing, while `luna` completed the identical review. opencode logs provider
errors only to its own log, so a retry loop and deep thinking look identical in
the pane. `cockpit errors` is what tells them apart.

**Recheck before trusting this.** If `sol` recovers, the model guidance in
`SKILL.md` is stale rather than wrong-headed.

## 2026-08-03 — `sol` made the default by Suji; capacity unverified

Suji set `gpt-5.6-sol` at `medium` as the review default, superseding the
2026-07-30 guidance above.

An attempt to probe whether `sol` had recovered was **inconclusive**: codex
failed before reaching the model, with `401 Unauthorized` on
`wss://chatgpt.com/backend-api/codex/responses` and
`Your access token could not be refreshed because your refresh token was
revoked.` That is an auth failure affecting every model, not a capacity signal.

So the question "does `sol` have capacity again?" is still open, and the first
real review on this default is what answers it. If it dies instantly, check the
log for which of the two errors it is before switching model.

## 2026-08-03 — codex auth expired

`codex exec` returns exit 1 for every model until `codex login` is run
interactively. The websocket 401 repeats several times before the revoked-token
error, so the log looks like a network problem at first glance.

## 2026-07-30 — the codex dispatch was verified end to end

The diff arrives inside a `<stdin>` block, codex answers questions about its
contents, and the findings land in the `-o` file.

## SID-248 — dispatch failure looked like model failure

`sol` at `medium`, dispatched with a trailing `-f` that `cockpit spawn` silently
swallowed, and no fence in the brief. It spent 15 minutes and 412k context
hunting `git branch` and reading Laravel helper source, and produced zero
findings.

Re-spawned with the diff path inside the brief and the fence in place, the same
model at the same effort read the file and was working in under a minute.

When a reviewer wanders, suspect the dispatch before blaming the model.

## SID-246 — a clean review is not a sign-off

Green gates plus a clean peer review still shipped a filter race that let a stale
fetch win, and a load-more that wiped a note the user was mid-typing.

## The 989k session — never ask for content back

A worker asked to echo files back drove one session from 222k to 989k context.
This is why briefs ask for findings only, and why codex run logs are redirected
to disk rather than read into the orchestrator.
