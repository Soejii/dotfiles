---
name: ticket
description: Work a Linear issue end to end in the current Flutter repo, from investigation through to a local commit.
disable-model-invocation: true
---

# Working a ticket

Invoked as `/ticket SDG-94 <what it is, in Suji's words>`.

The run ends at a **local commit on a ticket branch**. Nothing is pushed, no PR
is opened, and Linear stays read-only unless Suji says otherwise during the
session.

Flutter repos only. Every issue carries a `Web` or `Mobile` label; if it is
labelled `Web`, say so and stop. Web and mobile are routinely split into a pair
of near-identical issues (SDG-90/SDG-91, SDG-92/SDG-94), so check the label
rather than the title, and make sure you are on the mobile half.

## 1. Name the repo before reading anything

The repo is `$PWD`, because Suji starts cockpit inside the repo the ticket
belongs to. Open with one line naming it:

> Working SDG-36 in `karna` (CBT).

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

Read the issue with `get_issue`, passing `includeRelations: true` so blockers and
related issues come back, then `list_comments` separately: comments are a second
fetch in Linear, so pulling the issue is not the same as reading it. The
description also inlines cross-references as `<issue>` tags; follow them.

If the Linear tools are absent or refuse, the server needs its OAuth login: tell
Suji to run `/mcp` and pick `linear`, then continue. Do not fall back to guessing
the issue contents from the invocation line alone.

Bodies are Indonesian and templated, with emoji `##` headings. Match them on
meaning, not on the exact string: the template is young and already drifting
(`Informasi Requester` / `Tanggal Request` became `Informasi Issue` /
`Tanggal Ditemukan` within three days of the Linear move), so a heading that has
been reworded is the norm, not a sign you are on the wrong issue.

The shape is stable even where the wording is not. Both types open with tables of
requester, PIC, and platform. One of those earns its own step: the **platform
table's `Application` row** names the app (`Apps Walimurid`, `Apps Guru`,
`Flutter CBT`), which is your independent check on step 1's repo. If it disagrees
with the CWD, stop and say so.

Bugs then give the problem, steps to reproduce, expected vs actual behaviour,
impact, and testing notes. Stories give a user story, background, acceptance
criteria, and an explicit out-of-scope list. Both end in a work checklist
covering the whole delivery pipeline, most of which is not yours: this run ends
at a local commit.

**The ticket reports symptoms; the diagnosis is yours.** Reporters have no
repository access, so every causal claim in the body is a guess about code they
have never read. The testing notes and dependency list in particular assert how
the system behaves, and they are the reporter's model of it, not the code's. Mine
them for symptoms, then set them aside and work from source. Say so in the report
when they turn out wrong: SID-345, back in the Jira years, demanded a backend fix
for a transaction ID the backend already returned, when the defect was one missing
`extra:` on a mobile push.

Acceptance criteria and the out-of-scope list carry the outcome Suji is buying,
so they outrank any proposed fix, but they too are written without sight of the
code. Conflicts and cheap adjacent wins go to step 3, not straight into the kickoff.

Then find the code. For a bug, **diagnose it yourself**: root-cause analysis is
never delegated. Walk the actual code path until the symptom is explained by a
line you can point at.

Done when you can state three things in your own words: what the ticket asks
for, which files carry it, and for a bug, why it happens. Whatever you still
cannot answer from the repo, the API, or Linear becomes a question for step 3.
Nothing else does.

## 3. Grill

Run a `grilling` session on what step 2 left open.

Its output is the worker's kickoff, so the understanding has to survive being
written down for someone who was not in the room. Done when Suji confirms.

## 4. Delegation gate

Ask in plain text which worker, model, and effort, per `CLAUDE.md`. Suggest one
default with a one-sentence why, then wait for him to type his answer.

## 5. Spawn, monitor, verify

`cockpit spawn` with a self-contained kickoff built from step 3. Arm the Monitor
immediately, per `CLAUDE.md`.

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

Branch off current `HEAD` as `<issue-id>-<short-slug>`, e.g.
`SDG-94-nilai-desimal`, because these repos sit on different bases (`main`,
`master`, `dev-suji`). Linear links a branch to its issue on the identifier
alone, so this short form still associates; ignore the long `gitBranchName` it
suggests unless Suji asks for it. Commit there and stop.

Report: worker and model used, how many fix rounds it took, what peer review
flagged and what you did with each finding, and what remains open.
