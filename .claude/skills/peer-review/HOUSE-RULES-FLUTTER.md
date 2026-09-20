# House rules for the SIDIGS Flutter repos

Codex never reads `CLAUDE.md`. Without these it reports correct house style as
defects. Concatenate this file into the brief whenever the diff touches
`nakula`, `chiron`, `gaia`, `icarus`, `arjuna`, or `karna`.

Add whatever else the diff touches; this list is a floor, not a ceiling.

---

House rules for this repo. Code following these is correct, not a defect:

- The SDK is pinned via fvm. Judge the code against the pinned version, not the
  latest Flutter release.
- `withValues`, not the deprecated `withOpacity`.
- `DropdownButtonFormField` takes `value:` here.
- Sizes use screenutil extensions: `.w`, `.h`, `.sp`, `.r`.
- UI copy is in Indonesian on purpose. Do not report it as untranslated.
- No `_buildXxx()` widget helper methods; extract a widget class instead.
- Data fetching goes in `onReady`, not `onInit`.
