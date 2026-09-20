---
name: merge-pr
description: Merge a pull request and delete its branch on both sides. Use when Suji says to merge a PR, merge it, or merge a branch.
---

# Merge a PR

Deleting the merged branch is part of merging, not a favour on top of it. Delete
it every time unless Suji says to keep it. The repos are set
`deleteBranchOnMerge: false`, so nothing removes it for you and dead branches
pile up — nakula still carries two SID-249 branches for exactly this reason.

## 1. Check it is mergeable

```bash
gh pr view <n> --json number,title,state,mergeable,mergeStateStatus,reviewDecision,statusCheckRollup,headRefName,baseRefName
```

Merge when `state` is `OPEN`, `mergeable` is `MERGEABLE`, and the checks are
green. On anything else — `CONFLICTING`, `BLOCKED`, a red check, a pending review
— stop and report to Suji, naming the field that blocks it. Conflicts get
resolved on the branch; the merge waits.

With no PR number given, `gh pr status` finds the current branch's PR. State
which PR you are about to merge before you merge it.

## 2. Match the repo's merge method

`git log --merges --oneline -5` on the base branch. Subjects reading `Merge pull
request #N from ...` mean merge commits (`--merge`); one squashed subject per PR
means `--squash`. Follow what is already there, and ask only when the history
shows neither.

## 3. Merge, and delete the branch

```bash
gh pr merge <n> --merge --delete-branch
```

`--delete-branch` takes the remote branch and the local one. The single case that
drops the flag is Suji naming the branch as a keeper ("merge it but keep the
branch").

If the local branch survives — gh cannot delete the branch you are standing on —
switch to the base branch and `git branch -d <headRefName>`. Keep it at `-d`: it
refuses to drop commits that never landed, and a refusal is a finding to report,
not a reason to reach for `-D`.

## 4. Sync and prune

```bash
git checkout <baseRefName> && git pull && git remote prune origin
```

## 5. Report

Which PR merged, by which method, and that the branch is gone from both sides —
or which side still holds it, and why.
