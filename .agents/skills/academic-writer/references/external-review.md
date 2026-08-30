# Fresh-context external review

## When review runs

Run external review only after the complete canonical Markdown assignment has been assembled, or when Suji explicitly invokes review mode on a complete draft. Section drafts receive internal editorial review and user acceptance, not a headless external reviewer.

Before dispatch, ask Suji to specify the exact reviewer model and reasoning effort unless both were already supplied for this review. Do not recommend, infer, replace, or silently fall back to another model.

- A Claude model must run through headless Claude Code.
- A Codex model must run through headless Codex.
- A failed dispatch is not a clean review.

## Reviewer access and boundaries

Run from the assignment folder. The reviewer may inspect the complete assignment folder in read-only mode. It receives fresh context and may not edit any file.

Create a self-contained review prompt that identifies:

- the assignment and assessment criteria;
- the canonical final file;
- section ownership and read-only group contributions;
- the confirmed purpose, central position, and document map;
- citation and formatting rules;
- authoritative local sources and working ledgers;
- deliberate choices that should not be rediscovered as errors;
- the findings-only review request below.

The packet or prompt tells the reviewer where the evidence lives. It does not pre-argue that the draft is correct.

## Dispatch

Use explicit paths for executables and output files. Redirect stdin from the review prompt so the complete request reaches the reviewer without shell argument limits.

### Headless Codex

Run with the assignment folder as the working directory:

```bash
/home/suji/.local/bin/codex exec \
  -m <exact-model> \
  -c model_reasoning_effort=<exact-effort> \
  -s read-only \
  -C <assignment-folder> \
  --ephemeral \
  -o <review-findings.md> \
  < <review-prompt.md> \
  > <review-run.log> 2>&1
```

Add `--skip-git-repo-check` only when the assignment folder is outside a Git repository. Completion requires exit code 0 and a nonempty findings file.

### Headless Claude Code

Run with the assignment folder as the working directory:

```bash
/home/suji/.local/bin/claude -p \
  --model <exact-model> \
  --effort <exact-effort> \
  --restricted \
  --permission-mode plan \
  --tools "Read,Glob,Grep" \
  --no-session-persistence \
  --output-format text \
  < <review-prompt.md> \
  > <review-findings.md> 2> <review-run.log>
```

Completion requires exit code 0 and a nonempty findings file. The restricted, read-only tool set and lack of session persistence preserve the review boundary and fresh context.

If either command fails, inspect the run log, report the actual failure, and wait for direction. Do not treat missing findings as approval.

## Findings-only review request

Include this substance in the review prompt:

```text
Review the complete Indonesian academic assignment as an independent reader.
Return findings only. Do not rewrite the paper and do not edit files.

Evaluate:
1. Whether the document fulfills the assignment and each section performs its intended rhetorical job.
2. Whether the central position develops coherently across sections.
3. Whether claims follow from the cited evidence without overstating population, method, certainty, or causality.
4. Whether citations and references are accurate, complete, and mutually reconciled.
5. Whether definitions, terminology, and scope remain consistent.
6. Whether adjacent sections repeat, contradict, or fail to hand off logically.
7. Whether Indonesian sentences and paragraphs are logical, direct, clear, economical, formal, and precise.
8. Whether exact passages exhibit formulaic model patterns such as repeated paragraph machinery, empty signposting, rephrased repetition, automatic closure, forced grouping, generic filler, or excessive structural polish.

For each finding, provide the exact location, the problem, evidence from the assignment or sources, why it matters, and the direction of a correction. Distinguish demonstrable defects from subjective preferences. Order findings by impact. If no material findings exist, say so in one line.
```

Do not ask for an AI-generated probability or detector score.

## Triage and revision

The primary writer verifies every external finding against the assignment and its sources. Present each to Suji with one verdict:

- **Valid:** supported and relevant.
- **False positive:** contradicted by the assignment or source evidence.
- **Subjective preference:** reasonable but not required.
- **Outside scope:** concerns text or decisions not authorized for change.

Give the evidence for the verdict. Fix nothing before Suji decides.

Address accepted findings one affected section at a time. Reopen that section, run focused `grilling`, revise only its authorized text, obtain acceptance, and merge it into the canonical final file. A cross-section concern is decomposed into section-specific changes unless Suji grants a broader authorization.

After revisions, run the internal document checks and citation reconciliation again. Repeat external review only if Suji requests it.
