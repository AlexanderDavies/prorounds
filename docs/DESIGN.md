# DESIGN.md — ProRounds Design System

The visual and interaction source of truth for **ProRounds**. `ProRoundsDesignSystem`
([`ARCHITECTURE_GUIDE.md`](ARCHITECTURE_GUIDE.md) §13) *implements* this document — tokens, components, and
screen specs below are the canonical values. When code and this doc disagree, this doc wins; change it here
first, then the tokens. Product scope lives in [`prorounds_app_prompt.md`](../prorounds_app_prompt.md).

Every value here resolves for **both light and dark mode** (invariant §0.6.6) and is expressed as a **semantic
token**, never a raw hex in a feature.

---

## 1. Design philosophy

ProRounds should feel like a **premium fight-timer**: focused, confident, and cinematic — the calm of a corner
between rounds and the intensity of the bell. We borrow Netflix's design language, not its brand.

**Five principles, applied on every screen:**

1. **Dark-first and cinematic.** Black is the canvas; content and a single hot red are the light. Generous
   negative space, edge-to-edge surfaces, no chrome that doesn't earn its place. Light mode is a faithful,
   high-contrast inversion — not an afterthought (§3.2).
2. **One hot accent, used sparingly.** Red is energy: the active round, the primary action, the live moment. If
   everything is red, nothing is. Rest and idle states cool down and recede so the working round dominates.
3. **The number is the hero.** During a workout the countdown is the largest, boldest element on screen,
   readable across a gym at a glance. Everything else supports it.
4. **Bold, tight typography.** Heavy weights, tight tracking on large type, monospaced digits so the timer never
   jitters. Confident, not decorative.
5. **Motion with intent.** Smooth, weighted transitions (ease, not bounce); a pulse when it matters (final
   seconds, the bell); haptics reinforce every phase change. Never gratuitous, always honoring Reduce Motion.

**Anti-goals:** no gradients-for-decoration, no drop-shadow soup, no more than one accent hue competing for
attention, no skeuomorphic boxing clip-art. Sleek = restraint.

---

## 2. Foundations

### 2.1 The 8-pt grid

All spacing, sizing, and layout snap to an 8-pt grid (4 pt for fine tuning). Token → value:

| Token       | Value | Typical use                                   |
|-------------|-------|-----------------------------------------------|
| `space.2xs` | 4     | icon-to-label, hairline gaps                  |
| `space.xs`  | 8     | intra-component padding                       |
| `space.sm`  | 12    | list-row internal padding                     |
| `space.md`  | 16    | default screen gutter / card padding          |
| `space.lg`  | 24    | between grouped elements                      |
| `space.xl`  | 32    | section separation                            |
| `space.2xl` | 48    | around the timer hero                         |
| `space.3xl` | 64    | top/bottom breathing room on focused screens  |

**Screen gutter:** `space.md` (16) left/right by default; the workout screen centers its hero with `space.2xl`
vertical rhythm.

### 2.2 Radius

| Token         | Value | Use                                  |
|---------------|-------|--------------------------------------|
| `radius.sm`   | 8     | chips, small controls                |
| `radius.md`   | 12    | buttons, inputs                      |
| `radius.lg`   | 16    | cards, sheets                        |
| `radius.xl`   | 24    | large containers, the chart card     |
| `radius.pill` | ∞     | pill buttons, badges, the tab bar    |

### 2.3 Elevation

Dark mode conveys elevation with **lighter surfaces**, not shadows (shadows are invisible on black). Light mode
uses **soft, low shadows**. Never both.

| Token        | Dark                     | Light                                  |
|--------------|--------------------------|----------------------------------------|
| `elev.base`  | `surface.base`           | `surface.base`, no shadow              |
| `elev.raised`| `surface.raised`         | `surface.base` + shadow y2 blur8 8%    |
| `elev.overlay`| `surface.overlay`       | `surface.base` + shadow y8 blur24 12%  |

### 2.4 Hit targets & focus

- Minimum touch target **44×44 pt** (primary transport controls are far larger — §4.3).
- Visible focus/pressed state on every interactive element: 8% white overlay (dark) / 6% black overlay (light),
  plus scale 0.97 on press for primary actions.

---

## 3. Color

Color is **semantic**. Features reference roles (`color.accent`, `color.textPrimary`), never the raw palette.
The raw palette exists only inside the design system, mapped to roles per appearance.

### 3.1 Raw palette (design-system internal)

| Name           | Hex        | Notes                                        |
|----------------|------------|----------------------------------------------|
| `red/600`      | `#E50914`  | **Signature red** — the brand accent         |
| `red/500`      | `#FF1E27`  | Brighter — active round ring, live emphasis  |
| `red/700`      | `#B00610`  | Pressed / darker accent                      |
| `ink/900`      | `#000000`  | True black (OLED canvas, dark)               |
| `ink/850`      | `#0A0A0B`  | Near-black base (dark)                        |
| `ink/800`      | `#141416`  | Raised surface (dark)                         |
| `ink/700`      | `#1F1F22`  | Overlay surface (dark)                        |
| `ink/600`      | `#2C2C30`  | Hairline / border (dark)                      |
| `grey/500`     | `#8E8E93`  | Secondary text                               |
| `grey/400`     | `#A1A1AA`  | Tertiary / disabled                          |
| `paper/0`      | `#FFFFFF`  | White (light canvas, dark text-on-accent)    |
| `paper/50`     | `#F7F7F8`  | Base (light)                                 |
| `paper/100`    | `#EFEFF1`  | Raised surface (light)                       |
| `paper/200`    | `#E3E3E6`  | Hairline / border (light)                    |
| `amber/500`    | `#F5A623`  | Prepare phase                                |
| `teal/500`     | `#17C3B2`  | Rest phase (cool, recedes vs. red)           |

### 3.2 Semantic roles (light + dark)

| Role                  | Dark             | Light            | Use                                             |
|-----------------------|------------------|------------------|-------------------------------------------------|
| `color.canvas`        | `ink/850`        | `paper/50`       | App background                                  |
| `color.surface.base`  | `ink/850`        | `paper/0`        | Cards, list background                          |
| `color.surface.raised`| `ink/800`        | `paper/0`+shadow | Raised cards, tab bar                           |
| `color.surface.overlay`| `ink/700`       | `paper/0`+shadow | Sheets, menus                                   |
| `color.border`        | `ink/600`        | `paper/200`      | Hairlines, dividers, input outline              |
| `color.accent`        | `red/600`        | `red/600`        | Primary action, brand, live round               |
| `color.accent.bright` | `red/500`        | `red/500`        | Active-round ring, final-seconds pulse          |
| `color.accent.pressed`| `red/700`        | `red/700`        | Pressed primary                                 |
| `color.onAccent`      | `paper/0`        | `paper/0`        | Text/icon on a red fill (always white)          |
| `color.textPrimary`   | `#F5F5F7`        | `ink/850`        | Headlines, the timer numeral                    |
| `color.textSecondary` | `grey/500`       | `grey/500`       | Labels, subtitles                               |
| `color.textTertiary`  | `grey/400`       | `#B8B8BE`        | Hints, disabled                                 |
| `color.phase.prepare` | `amber/500`      | `#D98A00`        | Prepare state                                   |
| `color.phase.round`   | `red/500`        | `red/600`        | Working round                                   |
| `color.phase.rest`    | `teal/500`       | `#0E9C8E`        | Rest between rounds                             |
| `color.phase.finished`| `#F5F5F7`        | `ink/850`        | Completed workout                               |
| `color.trackDim`      | `ink/700`        | `paper/200`      | The un-filled portion of the timer ring         |
| `color.success`       | `teal/500`       | `#0E9C8E`        | Saved / confirmations                           |
| `color.danger`        | `red/600`        | `red/600`        | Destructive (delete a config)                   |

**Reconciling Netflix + light mode.** Netflix's identity is dark-cinematic; light mode keeps the same *bones* —
one hot red on a near-neutral field, bold type, generous space — but inverts to crisp white with soft shadows.
It reads clean and premium, not "the dark theme with the lights off." The accent red is deliberately unchanged
across appearances so the brand moment is constant.

**Phase color is never the only signal** (§9): every phase also carries a text label and an icon, so it's
legible to color-blind users and in bright sunlight.

---

## 4. Typography

**Type family:** system **SF Pro** — `SF Pro Display` for ≥20 pt, `SF Pro Text` below, tabular/monospaced digits
for anything counting. (SF is the closest high-quality stand-in for Netflix Sans and ships free with iOS; no
custom font bundling in the MVP.) Large type uses **Heavy/Bold** with tight tracking for the Netflix punch.

| Token          | Size/Weight            | Tracking | Use                                          |
|----------------|------------------------|----------|----------------------------------------------|
| `type.timer`   | 96 / Bold, mono-digit  | −2%      | The running countdown numeral (hero)         |
| `type.timerSm` | 56 / Bold, mono-digit  | −1%      | Compact/landscape timer, total-time readout  |
| `type.display` | 34 / Bold              | −1%      | Screen titles ("ProRounds", "Performance")   |
| `type.title`   | 28 / Bold              | 0        | Card titles, config name in editor           |
| `type.headline`| 20 / Semibold          | 0        | Row titles, section headers                  |
| `type.body`    | 17 / Regular           | 0        | Body copy, settings labels                   |
| `type.bodyEmph`| 17 / Semibold          | 0        | Emphasized body, selected values             |
| `type.subhead` | 15 / Regular           | 0        | Secondary row text                           |
| `type.caption` | 13 / Medium            | +2%      | Metadata, chart axis labels                  |
| `type.overline`| 11 / Bold, uppercase   | +8%      | Phase badge ("ROUND 3 / 12"), eyebrow labels |

**Rules:**
- The timer numeral uses **monospaced digits** so it never reflows as digits change.
- **Dynamic Type**: body/subhead/caption/headline scale with the user's setting. The timer numeral scales too,
  but within a clamped range (min ~64 pt, max fills the ring) so it never breaks the hero layout.
- Uppercase is reserved for `type.overline`. Don't uppercase body or titles.

---

## 5. Iconography

- **SF Symbols**, weight matched to adjacent text (`.semibold` default), rendered in `color.textSecondary` or
  `color.accent` when active.
- **Tab bar:** Timer = `timer`, Performance = `chart.line.uptrend.xyaxis` (the "chart outline" from the prompt),
  Settings = `gearshape`.
- **Transport:** play `play.fill`, pause `pause.fill`, reset `arrow.counterclockwise`.
- **Config:** add `plus`, edit `pencil`, delete `trash`, workout types map to symbols (Shadow Boxing
  `figure.boxing`, Skipping `figure.jumprope`, Heavy Bag `figure.kickboxing`, Speed Ball `circle.circle`,
  Sparring `figure.martial.arts`) — confirm final glyphs during build (availability varies by iOS version).
- Warning sounds get a small glyph in the picker (`hands.clap`, `horn`, `bell`).

---

## 6. Core components

Each is a `ProRoundsDesignSystem` component (guide §13.2), takes injected/pre-formatted inputs, and is
snapshot-tested in light + dark + Dynamic Type.

### 6.1 Buttons

| Variant       | Fill / border                 | Text            | Use                                  |
|---------------|-------------------------------|-----------------|--------------------------------------|
| Primary       | `color.accent` fill, pill     | `color.onAccent`, `type.bodyEmph` | Start, Save                |
| Secondary     | transparent, 1.5pt `color.border` | `color.textPrimary`          | Cancel, Edit               |
| Tertiary/text | none                          | `color.accent`  | Inline actions, "Add new"            |
| Destructive   | transparent, `color.danger` text | `color.danger` | Delete config                        |
| Icon          | circular, 44pt, `color.surface.raised` | symbol | Toolbar, secondary transport         |

Height 52 pt (standard), pill radius, press → scale 0.97 + `color.accent.pressed`. Disabled → 40% opacity, no
press feedback.

### 6.2 TimerRing (hero)

A circular progress ring — the centerpiece of the workout screen.

- **Diameter:** min(screen width − 2·`space.2xl`, 340) pt.
- **Track:** `color.trackDim`, stroke 14 pt, full circle.
- **Progress arc:** stroke 14 pt, rounded cap, colored by **current phase** (`color.phase.*`), starting at 12
  o'clock, depleting clockwise as the phase counts down.
- **Center stack:** phase badge (overline) → the timer numeral (`type.timer`) → a small total-remaining readout
  (`type.caption`, `color.textSecondary`).
- **States:** running (arc animates linearly, ~10–20 Hz for smoothness), paused (arc + numeral at 60% opacity, a
  "PAUSED" overline replaces the phase), final 3 s (numeral + arc pulse in `color.accent.bright`, §8), finished
  (full ring in `color.phase.finished`, checkmark + "DONE").
- Count-up vs count-down changes only the **numeral value**, not the ring (ring always shows phase progress).

### 6.3 PhaseBadge

Pill, `type.overline`, phase color at 16% as fill + phase color text/icon. Content: `PREPARE`, `ROUND 3 / 12`,
`REST`, `DONE`. Always paired with its ring so color + text agree.

### 6.4 TransportControls

The play/pause/reset cluster below the ring.

- **Primary (play/pause):** 72 pt circular, `color.accent` fill, white glyph — the biggest tap target on screen.
- **Reset:** 52 pt circular icon button, secondary style, left of primary. Disabled (dimmed) before a workout
  starts and after reset.
- Layout: reset — primary centered — (optional skip, Phase 2) mirrored right. Symmetric around the primary.
- Haptic on every press (§8.3).

### 6.5 ConfigCard / list row

Represents a saved configuration in the list.

- `color.surface.raised`, `radius.lg`, `space.md` padding.
- **Left:** workout-type icon in an accent-tinted circle.
- **Body:** config name (`type.headline`) + a metadata line (`type.subhead`, `color.textSecondary`) —
  "12 × 3:00 · 1:00 rest · 15:00 total".
- **Right:** total-time chip + chevron. Trailing swipe → Edit / Delete.
- Tap → workout screen (or a brief detail). Whole row is one hit target.

### 6.6 Stepper / value field (config editor)

Each config field (rounds, round time, rest, prep, warning lead) is a labeled row with a large tappable value
and −/+ steppers, plus a wheel/duration picker on tap for coarse changes. Values use `type.bodyEmph`,
monospaced for durations. Live-updating **total time** and **auto-name preview** sit at the top of the editor.

### 6.7 Tab bar

Three tabs (Timer · Performance · Settings), `color.surface.raised`, hairline top border. Active tab: icon +
label in `color.accent`; inactive: `color.textTertiary`. Labels `type.caption`. Translucent over the canvas in
dark mode.

### 6.8 Chart card (Performance)

See §7.4. A `radius.xl` surface holding a Swift Charts line chart with a legend and a range control.

### 6.9 Sound-option row & toggle

Settings rows: leading glyph, label (`type.body`), trailing checkmark (selected, `color.accent`) or a native
toggle for the theme switch. Tapping a sound row plays a preview.

---

## 7. Screen specs

Three tabs. Timer is the default tab and the heart of the app.

### 7.1 Configurations (Timer tab root)

Entry point: pick a saved configuration or create one.

```
┌─────────────────────────────┐
│  ProRounds            [ + ]  │  ← type.display title, add button top-right
│                             │
│  ┌───────────────────────┐  │
│  │ 🥊  Heavy Bag Blast   │  │  ← ConfigCard (§6.5)
│  │ 12 × 3:00 · 1:00 rest │  │
│  │              15:00  › │  │
│  └───────────────────────┘  │
│  ┌───────────────────────┐  │
│  │ 🥊  Quick Shadow      │  │
│  │ 3 × 2:00 · 0:30 rest  │  │
│  └───────────────────────┘  │
│                             │
│ [ Timer ] [ Perf ] [ ⚙ ]    │  ← tab bar
└─────────────────────────────┘
```

- **Empty state:** centered `figure.boxing` glyph, "No rounds yet", "Create your first workout" primary button.
- **Ordered most-recent first** (most recently created/run at top). `+` → Config editor (create).

### 7.2 Config editor (create / edit)

- Title: config name field (auto-name preview if blank), with the **live total-time** readout beneath.
- Fields (in this order, per the prompt): **Workout type** (segmented / menu of the 5 types, in spec order) →
  **Rounds** → **Round time** → **Rest time** → **Prep time** → **Round-end warning lead** (with an "off"
  position at 0).
- Primary **Save** (pinned bottom), Cancel secondary. Delete (destructive) shown when editing an existing one.
- Validation (guide §11) inline: e.g. warning lead can't exceed round time; rounds ≥ 1.

### 7.3 Workout (running) — the hero screen

```
┌─────────────────────────────┐
│                    Heavy Bag │  ← config name, quiet (type.caption)
│                             │
│          ╭─────────╮        │
│         ╱  ROUND    ╲       │  ← PhaseBadge (overline), phase-colored ring
│        │   3 / 12    │      │
│        │   01:23     │      │  ← type.timer, monospaced, the hero
│        │  12:40 left │      │  ← total remaining (caption)
│         ╲           ╱       │
│          ╰─────────╯        │
│                             │
│        ⟲        ▶︎/⏸        │  ← TransportControls (reset · primary)
│                             │
│ [ Timer ] [ Perf ] [ ⚙ ]    │
└─────────────────────────────┘
```

- **Background tints subtly** toward the phase color (≤8% over canvas) so the room "feels" the phase without
  drowning the numeral.
- **Prep:** amber ring + "PREPARE" + count to round 1. **Round:** red. **Rest:** teal + "REST" + next-round hint.
- **Round-end warning window** (last `warningLead` seconds): a soft edge-glow in `color.accent.bright` pulses in
  time with the warning sound; final 3 s the numeral pulses.
- **Finished:** ring completes to `color.phase.finished`, "DONE" + a one-line session summary (rounds, total
  time, type) with a "Done" action returning to the config list; the session is saved automatically (guide §7.4).
- Screen stays awake for the whole workout (guide §3.5). Pause dims the hero and swaps the badge to "PAUSED".

### 7.4 Performance (chart tab)

Per the prompt: training volume over time, a line per workout type plus a total aggregate.

- Title `type.display`, a **range control** (Week / Month / All) as a segmented control.
- **Chart card (§6.8):** Swift Charts multi-line — one line per workout type in a categorical palette (§7.5),
  plus a heavier **Total** line in `color.textPrimary`. X = time, Y = **total active minutes** (sum of round
  time per session/period; rest and prep excluded — it measures time under work).
- **Legend** below, tappable to isolate/toggle a series. Summary tiles above the chart (this week's active
  minutes, session count, rounds completed).
- **Empty state:** "Complete a workout to see your trends" with the chart-outline glyph.

Follow the **dataviz skill** when implementing this chart (categorical palette, axes, legend, light/dark).

### 7.5 Settings tab

- **Warning sound** — three selectable rows (Wooden clap · Electronic horn · Buzzer), tap to select + preview.
- **Timer display** — Count down / Count up (segmented or two rows).
- **Appearance** — Light / Dark / **System** (three-way control). **System is the default** and follows the
  phone; Light and Dark override it. Persisted via the `SettingsStore` and applied at the app root
  (`preferredColorScheme`, guide §6.4 / §13.1).
- Grouped sections with `type.overline` headers, `color.surface.raised` rows, hairline dividers.
- (Phase 2 placeholder, disabled/"Coming soon": WHOOP connection.)

**Chart categorical palette** (workout-type series — desaturated so no single line fights the brand red except
where red *is* a series): Shadow Boxing `#E50914`, Skipping `#17C3B2`, Heavy Bag `#F5A623`, Speed Ball `#5B8DEF`,
Sparring `#B06BF2`. Total line = `color.textPrimary`, heavier stroke. Validate contrast/order via the dataviz
skill at build time.

---

## 8. Motion & haptics

**Character:** weighted and smooth — Netflix-like ease, never playful bounce.

| Moment                    | Motion                                                        | Duration/curve            |
|---------------------------|--------------------------------------------------------------|---------------------------|
| Ring depletion            | Linear arc + numeral tick                                    | continuous, ~10–20 Hz     |
| Phase transition          | Ring color cross-fade + background-tint shift + badge swap   | 400 ms ease-in-out        |
| Round start ("bell")      | Numeral scale 1.0→1.06→1.0                                    | 300 ms spring (low bounce)|
| Warning window            | Edge-glow pulse synced to the warning sound                  | per-cue, ease-in-out      |
| Final 3 seconds           | Numeral + arc pulse in `color.accent.bright`                 | 1 Hz                      |
| Pause / resume            | Hero opacity 100%↔60%, controls settle                       | 200 ms ease               |
| Finish                    | Ring completes + checkmark draw-on + summary rises           | 500 ms ease-out           |
| Screen / tab transitions  | Standard push / cross-fade                                   | system default            |

**Haptics (`UIFeedbackGenerator`):** round start = `.heavy` impact; warning = `.warning` notification (or ticks
across the window); round end / rest start = `.light` impact; workout complete = `.success` notification;
button press = `.selection`/`.light`.

**Reduce Motion:** replace pulses/scales with a simple opacity or color change; the ring still updates but
without the pulse. Never gate information on motion alone.

---

## 9. Accessibility

Non-negotiable (invariant §0.6.6):

- **Contrast:** text meets WCAG AA (≥4.5:1 body, ≥3:1 large ≥24 pt / bold ≥19 pt) in **both** themes. `color.onAccent`
  white on `red/600` passes for large/bold; verify each pairing at build time.
- **Never color alone.** Every phase carries a text label + icon alongside its color (§3.2, §6.3).
- **Dynamic Type** across all text tokens; the timer numeral scales within a clamped range (§4).
- **VoiceOver:** the ring is one element announcing "Round 3 of 12, 1 minute 23 seconds remaining"; transport
  buttons have clear labels ("Pause workout", "Reset"); phase changes post an accessibility announcement.
- **Hit targets** ≥44 pt (§2.4); primary transport far larger.
- **Sound is never the only cue:** the warning and phase changes are always mirrored visually + haptically, so
  the app is usable muted or by a hard-of-hearing user.
- Honor **Reduce Motion** and **Reduce Transparency** (fall back the translucent tab bar to opaque).

---

## 10. Assets

- **Sound files** for the three warning options + the round bell, bundled and preloaded (guide §8.3). Pick a
  consistent loudness/length; keep them short and punchy.
- **App icon:** black field, single red mark (a stylized ring/bell or "PR" monogram) — bold and legible at small
  sizes; provide light/dark/tinted variants (iOS 18 icon set) if targeting them.
- No remote images; everything ships in the bundle (local-first, §0.6.1).

---

## 11. Decisions log

These forks are **settled** — recorded here so they aren't re-litigated. Change one here first, then the tokens
and screens that depend on it.

| Decision | Choice | Where |
|----------|--------|-------|
| **Signature accent red** | `#E50914` (Netflix red), constant across light/dark | §3.1 `red/600`, §3.2 `color.accent` |
| **Rest-phase color** | Teal `#17C3B2` — cools rest so red owns "work" (Prepare stays amber) | §3.2 `color.phase.rest` |
| **Appearance control** | Light / Dark / **System** (three-way, System default) | §7.5 |
| **Performance chart Y-metric** | **Total active minutes** (sum of round time; rest/prep excluded) | §7.4 |
| **Config-list ordering** | Most-recent first (created/run) | §7.1 |

Still genuinely open (safe to defer to build time, guide §0.1): the exact **SF Symbol glyph** per workout type
(availability varies by iOS version, §5), and final **sound-asset** selection/loudness (§10).
```

