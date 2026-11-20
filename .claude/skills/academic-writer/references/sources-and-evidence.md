# Sources and evidence

## Evidence standard

Model knowledge may suggest questions, concepts, search terms, possible explanations, and candidate sources. It does not establish an academic claim.

A substantive factual, theoretical, historical, statistical, or empirical claim is usable only when the exact supporting source has been inspected. The evidence must support the sentence at the level of certainty, population, setting, timeframe, and causal force actually written.

Ordinary connective reasoning does not need a citation, but its factual premises do. Avoid both unsupported claims and citation clutter.

## Research sequence

### 1. Inventory local material

Inspect the assignment folder before searching. Identify instructions, lecturer material, readings, existing bibliography, datasets, group contributions, and earlier drafts. Record which sources are authoritative for the assignment.

For local PDFs, run:

```bash
/home/suji/.local/bin/pdf-text-cache <file.pdf>
```

The wrapper runs `pdf-inspector detect` and stores text-based output under `/home/suji/.local/share/pdf-inspector/extracted/<sha256>/`. Search only the needed cached sections with Grep, then Read only those ranges. Never create extracted Markdown beside the PDF, even though the global CLAUDE.md PDF routine does. If the wrapper reports OCR-required pages and exits 3, read only those pages visually with the Read tool's `pages` parameter, at most 20 pages per call. Inspect tables the same way before using their values because extracted columns can be reordered or flattened.

A retained source in the college repository (`/home/suji/document/college`) already has a faithful transcript twin, `<basename>.md`, beside its PDF. Read that twin instead of re-extracting. Its `CLAUDE.md` loads its `AGENTS.md` rules only when Claude Code runs inside that repository. From anywhere else, read `AGENTS.md` yourself before moving or renaming anything there.

Treat Downloads as an inbox. Move a retained assignment source into the assignment's established source or reference folder. Once the paper's title, author form, and year have been verified from the paper itself or authoritative bibliographic metadata, rename it with:

```bash
/home/suji/.local/bin/pdf-text-cache --rename-to 'Title - (In-text citation, Year)' <file.pdf>
```

Use `&` for two authors and `FirstAuthor et al.` for three or more. Replace `/` in a title with `-` because it cannot appear in a Linux filename. Do not derive citation identity from an unverified download filename. Record the renamed PDF as the source access path in the ledger. The cached Markdown is a reading aid, not the cited source.

### 2. Define the evidence gap

Write the missing proposition before searching. A useful gap is specific, such as "recent Indonesian evidence connecting academic self-efficacy with career help-seeking among senior high-school students." A topic label such as "self-efficacy sources" is too broad.

### 3. Search through Hound MCP

Use Hound independently when local material does not close the gap. Its tools are deferred, so load them first with ToolSearch `select:mcp__hound__mcp_smart_search,mcp__hound__mcp_smart_fetch`.

1. Use `mcp__hound__mcp_smart_search` to discover candidates.
2. Prefer primary research for empirical claims and official institutional sources for rules or definitions owned by an institution.
3. Fetch the best candidates with `mcp__hound__mcp_smart_fetch`, using `focus` for a targeted question or `pages` for a PDF page range when useful.
4. Check `content_ok` before trusting content and follow `next_action` when Hound requests pagination, another fetch method, or a different source.
5. Record promising inaccessible sources as candidates, not evidence.

Search snippets, result titles, generated summaries, abstracts, citation metadata, and another paper's description of a source do not prove claims located in the full source.

### 4. Handle inaccessible sources

When a remembered or discovered source appears important but its relevant content cannot be inspected:

1. Record its title, authors, year, DOI, and stable link when available.
2. Mark it `needs-user-copy` in the working ledger.
3. Ask Suji to download or provide the exact source.
4. Continue researching other claims that are not blocked.
5. Replace the source, narrow the claim, or omit the claim if it remains inaccessible.

Never reconstruct a result from memory or imply that an abstract supports a detailed claim it does not contain.

## Claim-to-source verification

For every planned substantive claim, record:

- the exact proposition the prose will make.
- complete source identity.
- a concise account of the actual supporting passage or result.
- an exact locator.
- whether the source is primary, secondary, or institutional.
- whether the planned use is quotation, paraphrase, synthesis, definition, or data.
- verification status.

Verification asks:

- Does the source study or discuss the same construct?
- Does it concern the same population and setting claimed?
- Is the result correlational, predictive, explanatory, or causal?
- Is a limitation or condition omitted from the planned sentence?
- Is the claim the source author's conclusion or the current writer's interpretation?
- Does a secondary source point to an original that should be obtained? For a foundational claim, check that the cited source is about the concept rather than an application of it (see "Cite the right kind of source for foundational claims").

When several sources support a synthesis, record what each contributes. Do not attach a string of citations to a sentence if some merely discuss the topic.

## Source selection

Select sources by fitness for the claim, not by a universal prestige ladder.

- Use primary empirical studies for specific findings.
- Use systematic reviews or meta-analyses for the state of evidence when their scope matches.
- Use foundational works when the history or original formulation matters.
- Use current official documents for institutional rules, statistics, standards, and policy.
- Use scholarly books for established theory and disciplinary explanation.
- Use course material when the assignment explicitly depends on the lecturer's framing.

Blogs and unsourced summaries may suggest search terms but normally do not enter the academic evidence base. Recency matters when the claim can change. Age alone does not invalidate a foundational source.

### Cite the right kind of source for foundational claims

A claim about what a method, theory, framework, construct, or named criterion *is* must cite a work that is an authority on that topic: the originator, or a methodological or theoretical work about it (a methods book, methods paper, theoretical review). Never cite an empirical study that merely applies the method for what the method is. The test: if a lecturer asks "why didn't you cite X instead?", the citation must still be defensible.

- Before citing a source for what a method or concept is, ask whether the source is *about* that method or only *uses* it. A study that uses it is the wrong source, so find a work about it.
- An application paper may still be cited for its own design choices, procedures, and findings, worded as such ("seperti pada", "mengikuti penerapan").
- Do not use secondary citation ("as cited in", "sebagaimana dikutip dalam") for the basis of a study, even though APA allows it. Suji does not accept it. Cite a source you read that is fit for the claim.
- If the prose names a concept's originator ("model X dari ..."), cite that originator or a work about the model, not a paper that borrowed it.

Example from the scrolling proposal (2026-10-23): IPA's idiography, double hermeneutic, and sample size were credited to Karhulahti et al. (2022), a gaming-disorder study that applied IPA. The fix was Eatough and Smith (2017), the IPA authors' own account. Neubauer et al. (2019) for what phenomenology is and Korstjens and Moser (2018) for trustworthiness criteria are acceptable, because each is a methods paper about that topic.

## Quotation and paraphrase

Quote only when the source's exact wording has analytical value or the assignment requires it. A paraphrase must change both wording and sentence structure while preserving the original scope and emphasis. Never paraphrase from a citation alone.

Keep the source open while drafting the evidence note, then draft prose from the verified note rather than performing cosmetic synonym replacement on the source sentence. Mark the writer's inference as an inference.

## Citation and reference integrity

The assignment, lecturer, journal, or institutional style overrides all defaults. Use APA 7 only when no explicit style exists.

Before accepting a section:

- every in-text citation resolves to one reference-list entry.
- every reference-list entry is cited in the text unless the required style explicitly allows a bibliography.
- author names, year, title, container, volume, issue, pages, DOI, and URL match the inspected source.
- page or paragraph locators are present where required.
- the cited source supports the exact sentence beside it.
- citations copied from another source have been checked against the original before use.

Formatting correctness never compensates for unsupported content.
