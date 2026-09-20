---
name: commit
description: Split a change into atomic commits, one intent each. Use when Suji asks to commit, to commit a particular change or file, or to stage and commit work.
---

# Commit

Every commit is **atomic**: one intent, standing on its own, revertable without
taking anything else with it. One commit sweeping the whole working tree is the
failure this skill exists to prevent.

"Commit this" or "commit that" names the **scope** — which changes are in play.
It never says how many commits that scope becomes. A scope holding one intent is
one commit; a scope holding five is five.

## 1. Survey the whole surface

`git status --short`, then the diff of every path it lists, untracked files
included. Read the diffs. A file list does not tell you how many intents live in
a file.

Done when every changed path is accounted for and you can name the intent behind
each hunk.

## 2. Partition

Group the hunks into commits, one intent each. Two tests, both true of every
commit:

- Its subject names one change and needs no "and".
- Reverting it alone undoes that one change and leaves the tree coherent.

A single file often carries two intents — a bug fix, plus a rename that touched
the same function. Those are two commits; sharing a file does not make them one.
Reformatting and generated output get their own commit, away from behaviour.

Then order them so each stands on its own: the refactor before the feature that
uses it, the model before the widget that reads it.

Every hunk lands in exactly one commit. Anything you deliberately leave
uncommitted is named in step 3, not silently dropped.

## 3. Show the plan, then wait

A numbered list, one line each: subject, the paths, and which hunks where a file
is split. Then wait for Suji. He may merge, split or reorder them, and his call
wins.

## 4. Optional peer review

Do not load [`peer-review`](../peer-review/SKILL.md) automatically. Load and complete it only when Suji explicitly requests a review. You may remind him once that review is available, but its absence is not a commit blocker.

## 5. Stage and commit, one at a time

`git add -p` and `git add -i` are interactive and unavailable here. Two
non-interactive routes:

- Whole files: `git add <paths>`.
- Part of a file: write that file's diff to the scratchpad, keep only this
  commit's hunks, and apply the rest to the index.

```bash
git diff -- <file> > "$SCRATCH/part.patch"   # then edit it down to this commit's hunks
git apply --cached "$SCRATCH/part.patch"
```

An untracked file needs `git add -N <file>` first, or its content never appears
in `git diff`.

Before each `git commit`, read `git diff --staged` and confirm it is exactly the
intent you are about to describe. Commit, then move to the next one.

Messages follow the repo's own log (`git log --oneline -15`). In the SIDIGS repos
that is `type(scope): imperative subject`, carrying the ticket id in parens when
there is one: `fix(epkl): paginate every PKL list (SID-244)`. Add a body when the
reason is invisible in the diff.

## 6. Verify and report

`git log --oneline -<n>` and `git status --short`. Done when each new commit
reads as one intent, and the tree is either clean or holds only the leftovers you
named in step 3.

Report what each commit contains, what stayed uncommitted and why, and any requested review findings.
