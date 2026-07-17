# Screen mockups

Static HTML mockups of the five core screens from [`../DESIGN.md`](../DESIGN.md) §7. A visual
reference for building the real SwiftUI screens in `ProRoundsDesignSystem` — **not** shipped code.

## Files

| File         | What it is                                                                 |
|--------------|----------------------------------------------------------------------------|
| `index.html` | Gallery of all five screens in iPhone frames, with a light/dark toggle.    |
| `tokens.css` | The semantic design tokens (DESIGN.md §2–§4) the mockups are built on.      |

## Viewing

Double-click `index.html` — it's fully self-contained (only references `tokens.css` beside it),
no build step or server needed. Use the header toggle to check the light-mode inversion (§3.2).

## Screens (→ DESIGN.md §7)

1. **Configurations** — Timer tab root (§7.1)
2. **Config editor** — create / edit (§7.2)
3. **Workout (running)** — the hero screen, round phase (§7.3)
4. **Performance** — training volume over time (§7.4)
5. **Settings** — sound · display · appearance (§7.5)

## Relationship to the source of truth

`DESIGN.md` remains canonical (its header: "When code and this doc disagree, this doc wins").
These mockups *illustrate* that spec — if the two ever diverge, DESIGN.md is right and the
mockups should be updated to match.

Authored in Open Design (project `ProRounds Screens`); this is a version-controlled copy.
