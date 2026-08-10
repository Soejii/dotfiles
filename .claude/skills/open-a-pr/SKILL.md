---
name: open-a-pr
description: Write the pull request body for a stranger, in ASD-STE100 Simplified Technical English. Use when the user asks to open, create, or raise a pull request, or to write or rewrite a PR description or PR body.
---

# Open a PR

The reader is a **stranger**. They did not watch this session. They have no chat
log, they may have no access to the ticket, and English may be their second
language. Everything the stranger needs is in the body you write.

## Write the prose in ASD-STE100 Simplified Technical English

Prose only. Tables, code blocks, logs, stack traces and diffs stay as they are.

- Write one idea per sentence. Keep a sentence to 20 words or fewer.
- Write in the active voice. "The mapper rejects the date", not "the date is
  rejected".
- Use the present tense for how the code behaves.
- Keep the articles. Write "the pill", not "pill".
- Use one word for one meaning. Pick the term once, then repeat it. A synonym
  reads as a second thing.
- Replace an `-ing` form with a verb. Write "the code that parses the month",
  not "the month parsing code".
- Keep technical names exactly as they appear in the code: `BillNestedModel`,
  `bill/get-detail`, `statusArray`.

## Give the stranger what they lack

Expand every acronym, ticket id and internal short name the first time you use
it. "SID-360" alone tells the stranger nothing. "SID-360, which adds the billing
month to the bill card" tells them enough to keep reading.

Open with the problem in the user's words, not the code's. A stranger reads "a
parent cannot tell two bills apart" faster than "the card lacks a period
discriminator".

Then state what changed, and what proves it. Give each verified claim its
measurement: "11 of 141 rows", not "some rows". Say which claims you measured
and which you inferred.

## Done when

A stranger answers three questions from the body alone: what was wrong, what
this changes, and what proves it works. Every acronym and internal name is
expanded on first use. Every prose sentence carries one idea in the active
voice.
