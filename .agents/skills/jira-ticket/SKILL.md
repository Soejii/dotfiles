---
name: jira-ticket
description: Work a SID ticket end to end in the current Flutter repo, from investigation through to a local commit.
disable-model-invocation: true
---

# Working a SID ticket

Invoked as `/jira-ticket SID-290 <what it is, in Suji's words>`.

The run ends at a **local commit on a ticket branch**. Nothing is pushed, no PR
is opened, and Jira stays read-only unless Suji says otherwise during the
session.

Flutter repos only. If the ticket is a web ticket, say so and stop.

## 1. Name the repo before reading anything

The repo is `$PWD`, because Suji starts cockpit inside the repo the ticket
belongs to. Open with one line naming it:

> Working SID-290 in `nakula` (live Guru app).

| repo | product | state |
|---|---|---|
| gaia | Murid | live, migration complete |
| arjuna | Murid | retired, superseded by gaia |
| icarus | Walimurid | migration target, in prod QC/QA |
| sadewa | Walimurid | live |
| chiron | Guru | migration target, in progress |
| nakula | Guru | live |
| anusapati | Kepsek | outside the migration |
| karna | CBT | outside the migration |

The wayang-named repos are Suji's originals; the Greek-named ones are the
rewrites. A wrong CWD fails silently and costs a whole worker spawn, so this
line exists to let him catch it in one word.

Fixes land in the CWD repo only. If a migration sibling needs the same fix, he
will say so.

## 2. Investigate before asking anything

Read the ticket with `jira_get_issue`, comments included, and follow linked
issues. Bodies are Indonesian and templated: bugs carry Steps to Reproduce,
Expected vs Actual, and usually a `Kemungkinan root cause` guess under Notes;
stories and tasks carry Acceptance Criteria and a QC checklist.

**The ticket reports symptoms; the diagnosis is yours.** Reporters have no
repository access, so `Kemungkinan root cause` and `Proposed Solution` are
guesses about code they have never read. Mine them for symptoms, then set them
aside and work from source. Say so in the report when they turn out wrong:
SID-345 demanded a backend fix for a transaction ID the backend already
returned, when the defect was one missing `extra:` on a mobile push.

Acceptance Criteria carry the outcome Suji is buying, so they outrank the
proposed fix, but they too are written without sight of the code. Conflicts and
cheap adjacent wins go to step 3, not straight into the kickoff.

Then find the code. For a bug, **diagnose it yourself**: root-cause analysis is
never delegated. Walk the actual code path until the symptom is explained by a
line you can point at.

Done when you can state three things in your own words: what the ticket asks
for, which files carry it, and for a bug, why it happens. Whatever you still
cannot answer from the repo, the API, or Jira becomes a question for step 3.
Nothing else does.

## 3. Grill

Run a `grilling` session on what step 2 left open.

Its output is the worker's kickoff, so the understanding has to survive being
written down for someone who was not in the room. Done when Suji confirms.

## 4. Delegation gate

Ask in plain text which worker, model, and effort, per `AGENTS.md`. Suggest one
default with a one-sentence why, then wait for him to type his answer.

## 5. Spawn, monitor, verify

`cockpit spawn` with a self-contained kickoff built from step 3. Arm the Monitor
immediately, per `AGENTS.md`.

Gates are `/home/suji/.local/bin/flutter-analyze-diff` and `fvm flutter test`,
plus a real `fvm flutter build apk --debug` when the change touches widget APIs,
since analyze passing is not proof it compiles. Put the `flutter-analyze-diff`
path in the kickoff itself: a cold worker reaches for a bare `fvm flutter
analyze`, which buries the regression in legacy noise and floods its own context.

Gate failures go back to the same worker with `cockpit say`, capped around three
rounds. Step in yourself only when it is stuck, when the fix is
security-sensitive or needs root-cause debugging, or when a round-trip costs
more than the one-character fix.

Done when the gates pass on a run **you** performed. A worker reporting green is
not a gate.

## 6. Peer review

Load the `peer-review` skill and follow it. Findings reach Suji for triage
before anything is fixed.

## 7. Emulator, only on request

Suji checks the app himself by default. If he asks, load
`android-emulator-drive`.

## 8. Commit, then stop

Branch off current `HEAD` as `SID-XXX-<short-slug>`, because these repos sit on
different bases (`main`, `master`, `dev-suji`). Commit there and stop.

Report: worker and model used, how many fix rounds it took, what peer review
flagged and what you did with each finding, and what remains open.
