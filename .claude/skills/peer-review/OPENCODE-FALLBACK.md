# Fallback: dispatch the review to an opencode worker

Use when Suji names an opencode model, or codex is unavailable. Everything in
`SKILL.md` still applies; only the dispatch changes. Build the diff per section
2 and write the brief per section 4 first, then come here.

**Prefer `luna` over `sol`.** See the 2026-07-30 entry in `INCIDENTS.md`.

## Put the diff path inside the brief

`cockpit spawn` does not take `-f`. Its signature is
`cockpit spawn <name> "<kickoff>" [model] [dir]`, so a trailing `-f <file>` is
swallowed as a stray positional and the reviewer starts with no diff at all. It
will not say so.

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

Completion criterion: the worker quotes something from the diff in its first
message. A reviewer that opens by describing the repo never received the file.

## Monitor at a 250k ceiling

Arm a Monitor per `CLAUDE.md`, but set the ceiling at about **250k**, not the
500k used for implementation workers. A focused review of one diff lands well
under that. Past it the worker is exploring rather than reviewing; kill and
re-spawn rather than waiting it out.

A reviewer that goes silent with frozen context needs `cockpit errors` before you
conclude anything, because opencode logs provider errors only to its own log.
