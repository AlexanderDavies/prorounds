## Context

Post-MVP polish from hands-on use. Two independent visual fixes; no behavior change.

## Goals / Non-Goals

**Goals:** an on-brand app icon; button styles that don't look cramped when hugging content.

**Non-Goals:** any logic/behaviour change; the App-Store icon flatten (noted as a follow-up).

## Decisions

- **Icon via a committed SwiftUI renderer.** `scripts/gen-icon.swift` renders the "Ring + PR" mark to
  a 1024 PNG with the real system font (matching the Open Design reference) — deterministic and
  reproducible, like `gen-audio.sh`. DESIGN.md §10 is the icon's source of truth, so there is no
  OpenSpec capability for it.
- **Padding before the width frame.** In `PrimaryButtonStyle`/`SecondaryButtonStyle`, `.padding(.horizontal, Spacing.lg)`
  is applied to the label *before* `.frame(maxWidth: .infinity)`. For a full-width button the padding
  is inert; for a `fixedSize` (hug-content) button the intrinsic width includes the padding, fixing the
  cramped pill. One change fixes the "Done", "Create your first workout", and "Retry" buttons.

## Risks / Trade-offs

- **Snapshot churn** → re-record the button and affected screen snapshots; verify each still reads well.
- **Icon alpha channel** → acceptable for dev/simulator; flatten before submission.
