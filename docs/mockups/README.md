# Screen mockups

Static HTML mockups of the five core screens from [`../DESIGN.md`](../DESIGN.md) §7. A visual
reference for building the real SwiftUI screens in `ProRoundsDesignSystem` — **not** shipped code.

## Files

| File            | What it is                                                                   |
|-----------------|------------------------------------------------------------------------------|
| `index.html`    | Gallery of all five core screens in iPhone frames, with a light/dark toggle.  |
| `coaching.html` | The assisted-coaching screens (post-MVP), plus its four open questions.        |
| `tokens.css`    | The semantic design tokens (DESIGN.md §2–§4) both galleries are built on.      |

## Viewing

Double-click `index.html` (or `coaching.html`) — each is fully self-contained (only references
`tokens.css` beside it), no build step or server needed. Use the header toggle to check the
light-mode inversion (§3.2).

## Screens (→ DESIGN.md §7)

1. **Configurations** — Timer tab root (§7.1)
2. **Config editor** — create / edit (§7.2)
3. **Workout (running)** — the hero screen, round phase (§7.3)
4. **Performance** — training volume over time (§7.4)
5. **Settings** — sound · display · appearance (§7.5)

## Assisted coaching (`coaching.html`)

Post-MVP feature, spec'd in [`../COACHING_UX_BRIEF.md`](../COACHING_UX_BRIEF.md). Two sections:

- **A — the coached flow (7 screens):** configurations w/ coach badge · config editor Coaching section ·
  ready screen w/ `Coach ▾` chip · coaching sheet · running w/ dual-convention ticker · minimal screen ·
  Settings coaching group.
- **B — the four open questions** the brief left to this stage, as side-by-side variants: chip placement,
  ConfigCard badge, ticker scale + fade, and the scope of "minimal screen". **All four were settled on
  2026-09-07** — the chosen option carries a red marker and section A is drawn to match; the rejected
  variants stay for their trade-offs.

Nothing here is spec'd yet — these answers feed the coach-script stage, then an OpenSpec change.

## Relationship to the source of truth

`DESIGN.md` remains canonical (its header: "When code and this doc disagree, this doc wins").
These mockups *illustrate* that spec — if the two ever diverge, DESIGN.md is right and the
mockups should be updated to match.

Authored in Open Design (project `ProRounds Screens`); this is a version-controlled copy.
