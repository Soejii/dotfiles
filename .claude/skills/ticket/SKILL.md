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

### Start the Nexora timer and claim the PIC

Right after that line, before reading the issue, start Suji's time tracking.
Nexora is the team's time tracker for Linear issues, reached through the
`nexora` MCP.

**Every write to Suji's time log needs his yes first.** Before
`nexora_start_timer`, `nexora_stop_timer`, `nexora_log_time`,
`nexora_update_entry` or `nexora_delete_entry`, state the exact action in one
line (ticket, note, and times for a manual entry) and wait for a clear yes. If
he says no, leave Nexora alone; never substitute a different entry, such as a
backfilled manual one. Read-only calls (`nexora_status`, `nexora_list_entries`,
`nexora_get_pics`) need no confirmation. (Set 2026-10-31 on SDG-255, after an
unasked offer to backfill time drew "dont log it like that".)

1. Call `nexora_status`.
2. Already running on this ticket (a resumed run): leave it.
3. Running on another ticket: propose stopping it with `nexora_stop_timer`.
   Only one timer runs at a time, and the new ticket is the work now.
4. Propose starting it with `nexora_start_timer` on this ticket's ID. Ask
   steps 3 and 4 together in one line, e.g. `Stop the timer on SDG-12 and
   start one on SDG-36?`
5. Make Suji the PIC Development. Call `nexora_get_pics` on the ticket:
   - `DEVELOPMENT` empty: `nexora_set_pic` with role `DEVELOPMENT`, user `me`.
   - Already Suji: leave it.
   - Someone else: leave it and say who in the opener. Setting it also moves
     the Linear assignee, so never take it over unasked.

Put the timer question in the opener, and keep investigating while you wait;
start the timer once he says yes. Report the PIC in the same opener, such as
`PIC Development set.`

Time tracking never blocks the ticket. If the `nexora` tools are missing or
fail, say so in one line and carry on. "Sign in again" means Suji's Nexora
session in Firefox has expired; he fixes that by logging in to Nexora in
Firefox.

If the run stops early (the issue is labelled `Web`, or the platform check
in step 2 disagrees with the repo), ask to stop the timer before you stop.

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

Grill with docs on what step 2 left open: load both `grilling` (the interview)
and `domain-modeling` (the repo's `GLOSSARY.md` and ADRs), then run the session.
Load the two directly; `grill-with-docs` is the same pair but is user-only and
refuses a model invocation. Terms resolved here are written to the glossary as
they settle; most tickets add none, and that is fine.

Its output is the worker's kickoff, so the understanding has to survive being
written down for someone who was not in the room. Done when Suji confirms.

## 4. Delegation gate

Ask in plain text which worker, model, and effort, per `CLAUDE.md`. Suggest one
default with a one-sentence why, then wait for him to type his answer.

## 5. Spawn, monitor, verify

`cockpit spawn` with a self-contained kickoff built from step 3. If the repo has
a `GLOSSARY.md`, tell the worker to read it and use its terms in names and
comments. Arm the Monitor immediately, per `CLAUDE.md`.

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
`android-emulator-drive`. In a remote run this step is on by default; see
Remote runs.

## 8. Commit, then stop

Branch off current `HEAD` as `<issue-id>-<short-slug>`, e.g.
`SDG-94-nilai-desimal`, because these repos sit on different bases (`main`,
`master`, `dev-suji`). Linear links a branch to its issue on the identifier
alone, so this short form still associates; ignore the long `gitBranchName` it
suggests unless Suji asks for it. Commit there and stop. Glossary or ADR changes
from step 3 are their own commit, separate from the fix.

Then ask to stop the timer with `nexora_stop_timer`, showing the note
`Branch <branch>, commit <short hash>`, and stop it on his yes. If Suji asks
for more work in this session afterwards, ask whether to start it again on the
same ticket before doing the work.

Report: worker and model used, how many fix rounds it took, what peer review
flagged and what you did with each finding, the time the timer tracked, and
what remains open.

## Remote runs

A run started by `ticket-start` (Suji sends `/ticket` to Hermes on Telegram)
says "remote run" in its invocation. Suji drives it from the Claude app on
his phone through Remote Control. Every step above still applies, with these
changes.

- **Write for a phone.** Short messages and plain sentences. In the grill,
  ask one question at a time. Put paths in `code`; avoid wide tables.
- **Step 1:** the launcher chose the repo from the ticket's `Application`
  row. If step 2's platform check disagrees, stop and say so.
- **Step 4:** still ask. Suggest Luna `xhigh` as the default; he types the
  answer from his phone.
- **Step 7 is on by default** when the change touches anything a user sees.
  Load `android-emulator-drive`, drive the fixed flow, and record it:

  ```bash
  mkdir -p ~/.cache/ticket-evidence
  adb shell screenrecord --time-limit 60 /sdcard/SDG-26.mp4 &   # then drive the flow
  adb pull /sdcard/SDG-26.mp4 ~/.cache/ticket-evidence/SDG-26.mp4
  ```

  Keep it under 60 s and the file under 45 MB (Telegram bots stop at 50 MB).
  For a change with nothing visible, skip it and say why.
- **Step 8, after the commit:** send the evidence to Telegram, then report
  in the session as usual. Gate lines quote only gates you ran yourself.

  ```bash
  hermes send -t telegram "SDG-26 done: <one-line summary>
  Branch SDG-26-short-slug, commit abc1234
  Gates: <analyze result>, <test result>, <apk build result>
  Peer review: <n> findings, <what happened to them>
  Time: <duration the timer tracked>
  MEDIA:/home/suji/.cache/ticket-evidence/SDG-26.mp4"
  ```

  Ask to stop the timer before this message, so the `Time` line is final.
  If he says no, send the duration so far and say the timer is still running.

  Check that it exits 0. Never put angle brackets in the sent text; replace
  every placeholder above with the real value.
- **Ending:** first stop every worker this run spawned with
  `cockpit stop <name>` (never `cockpit down` or `cockpit-nuke`: other work
  may be running in that grid). Then, when Suji has nothing more, tell him
  to send `/exit` in the app. That closes the session and frees the launcher for the next ticket.
  Waiting on him is fine: after 90 idle minutes the PC may sleep, but the
  run stays open and he wakes it with Wake-PC. When the run ends, the
  launcher tells him on Telegram, so do not send an "ended" message yourself.
- **Timer:** `ticket-awake` handles idle time. After 90 idle minutes it
  stops the timer and trims the entry back to the run's last activity; when
  he replies, it starts a new timer on the same ticket. So a long wait for
  his answer is not logged, and the ticket can end up with several entries.
  If the run ends before step 8 (a crash, an early `/exit`), it stops a timer
  still on this ticket and says so in its Telegram message. Do not start or
  stop the timer yourself around waits; only at the points the steps name.
