# Assignment artifacts

## File contract

Every assignment has:

1. One working Markdown file for each authorized section.
2. One canonical Markdown file containing the complete submission-ready assignment.
3. Optional derived exports, such as DOCX or PDF, only when required.

Create these files automatically. Do not ask whether a working file is wanted.

Use the assignment's existing naming convention when one is clear. Otherwise use:

```text
working/<Section Name>.working.md
<Assignment Name>.md
```

For a single-section task, `working/<Assignment Name>.working.md` is sufficient. For a multi-section task, create a separate working file from the beginning for each section Suji owns. If an initially small working file becomes difficult to navigate, state the concern and recommend a split before moving its contents. Never split the canonical final file.

Do not create duplicate final files such as `final-v2.md`, `final-revised.md`, or `really-final.md`. Revision history belongs in Git or the working files. A required non-Markdown submission is derived from the canonical final Markdown file and does not replace it.

## Working-file schema

Use only the headings needed by the active assignment, while preserving the information below.

```markdown
# Working: <Section Name>

## Assignment context
- Assignment:
- Course:
- Audience:
- Instructions and rubric:
- Citation and format rules:
- Section owner:

## Confirmed document decisions
- Central question or position:
- Scope:
- Relevant document map:

## Section contract
- Rhetorical job:
- Required progression:
- Evidence needs:
- Boundary with adjacent sections:
- Completion condition:

## Source ledger
| ID | Claim or use | Source | Exact support | Location | Access | Status |
|---|---|---|---|---|---|---|

## Evidence gaps

## Argument plan

## Draft

## Revision and review notes

## Status
Planned | Authorized | Drafted | Revised | Accepted
```

The ledger's `Exact support` field contains a concise evidence note or a short quotation needed to verify the planned paraphrase. `Location` records a page, section, table, figure, timestamp, or stable locator. `Access` records the local path, DOI, or stable URL. `Status` distinguishes candidate, accessible, verified, rejected, and needs-user-copy.

Do not use a candidate or `needs-user-copy` entry in final prose.

## Canonical final file

The final Markdown file contains only material intended for submission:

- assignment identity required by the lecturer;
- accepted title and section structure;
- accepted prose;
- tables, figures, and captions;
- in-text citations;
- one reconciled reference list;
- required appendices.

Do not leak source-ledger notes, reviewer findings, search notes, drafting instructions, uncertainty markers, or internal status labels into the final file.

## Group assignments

Record ownership in each working file and in the document map. Text owned by another group member is read-only unless Suji authorizes a specific edit. It may be placed into the canonical file as supplied.

Do not imitate another member's weak or different prose. Preserve the established quality of Suji's section. Build transitions inside the authorized section where possible, then state a concern if the assembled paper has a visible mismatch. Propose, but do not apply, edits to another member's text.
