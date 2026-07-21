# CLAUDE.md — ProRounds iOS App

Swift 6 / SwiftUI iOS app (iOS 17+): a **local-first boxing round-timer**. No login, no backend — all state
(configurations, sessions, settings) persists on-device via SwiftData / `UserDefaults`. The defining component
is a **deterministic, clock-injected round-timer engine**; audio cues, charts, and a black/red cinematic
theme (light + dark) sit around it. Product spec: [`prorounds_app_prompt.md`](prorounds_app_prompt.md).

## Architecture guide — read before feature work

The full engineering guide (layered modules under mandatory TDD, mechanically enforced by the SwiftPM package
graph) lives in **[`docs/ARCHITECTURE_GUIDE.md`](docs/ARCHITECTURE_GUIDE.md)**.

**Before scaffolding a package, building a feature, or changing any boundary (the timer engine, a repository,
audio, the biometric seam, a view model), read `docs/ARCHITECTURE_GUIDE.md` end-to-end.** It is the source of
truth for the layering, file-suffix conventions, the timer/audio/persistence boundaries, the testing strategy,
and the anti-patterns list. The summary below does not replace it.

## Non-negotiable ProRounds invariants (guide §0.6)

These sit above everything else when they conflict:

- **Local-first, no backend, no login.** All data on-device (SwiftData / `UserDefaults`); no network calls in the
  MVP; no server code path for core features, and none is to be added.
- **Timer correctness is the product.** The workout clock is **monotonic-deadline-based, never a tick
  accumulator** — accurate across pause/resume, reset, phase transitions, backgrounding, and audio
  interruptions. It never drifts, double-fires a cue, or loses/adds a round.
- **The configured sequence is honoured exactly.** `prep → (round → rest) × N`, **no rest after the final
  round**, and the warning fires at exactly the configured lead time (and not at all when it's 0).
- **Graceful under interruption.** Backgrounding, a call, or a route change degrades gracefully — the workout is
  never silently corrupted.
- **Privacy & minimal data.** No PII, no activity analytics, no trackers. **(Phase 2)** WHOOP/HealthKit
  biometrics are sensitive health data — on-device only, never logged, explicit revocable consent.
- **Both appearances, accessible.** Light and dark are both first-class; the theme meets contrast/Dynamic
  Type/VoiceOver expectations.

## Operating principles — apply on every cycle (guide §0)

Behaviours, not architecture. They govern every task regardless of whether the full guide is open.

1. **Ask, never assume (§0.1).** Ambiguous timer rule, config field range, navigation flow, or which layer owns
   a responsibility → stop and ask via `AskUserQuestion`. Don't guess transition rules or interruption states.
2. **Validate every assumption (§0.2).** Read the type/protocol, run the test, and **actually run the timer** in
   the simulator (start, pause, background, resume, let a round end) before *and* after. A timer bug is
   invisible in a screenshot.
3. **Every change updates the README (§0.3).** Any change to how the app is built, run, configured, or tested
   updates `README.md` in the same change set.
4. **DRY · KISS · SOLID, Swift-idiomatically (§0.4).** Single source of truth (one total-duration/auto-name
   calc); simplest design; rule of three before abstracting; **constructor injection only** (no
   singletons/globals); value types + composition. Don't over-build — this is a timer app.
5. **Runnable + testable locally (§0.5).** The suite is hermetic — everything with side effects (time, audio,
   persistence, Phase-2 biometrics) sits behind a protocol seam with an in-memory fake. If a change breaks that,
   add the seam + fake alongside it.

## TDD is mandatory (guide §14)

Red → green → refactor on every feature, fix, and behaviour-affecting change. The inner loop is **Swift Testing
against fakes** — fast, hermetic, no real clock. The **`RoundTimerEngine` is written test-first**, driven by an
injected `FakeTimeSource` so an entire workout is verified deterministically in microseconds, with the exact cue
order asserted. XCUITest covers flows; snapshot tests cover the design system. ≥90% coverage gate
(views/app-entry/generated/platform-edge excluded — **the engine is never excluded**).

## Where to find it in the guide

| Need | Section |
|------|---------|
| **ProRounds invariants + the privacy/correctness boundaries mapped onto every section** | **§0.6** |
| Layered modules, the SwiftPM package graph, naming, file-suffix conventions | §1–§2 |
| Presentation — dumb views, `@Observable` view models, navigation, count-up/down as display | §3 |
| Concurrency — Swift 6 strict, actors, `@MainActor` | §4 |
| Dependency injection + the composition root | §5 |
| Data layer — repositories, SwiftData, entity↔domain mapping, settings store | §6 |
| **The Round Timer engine — the core boundary (monotonic deadlines, `TimeSource` seam, cues)** | **§7** |
| Audio & background behaviour — `AudioCuePlayer`, `AVAudioSession`, background audio, interruptions | §8 |
| Biometrics / WHOOP boundary (Phase 2, forward-looking) | §9 |
| Error handling + interruption resilience | §10 |
| Configuration validation | §11 |
| Observability (OSLog, no PII/biometrics) | §12 |
| Design system — black/red theme, light+dark, Swift Charts, snapshot tests | §13 |
| TDD & testing strategy (Swift Testing, `FakeTimeSource`, coverage) | §14 |
| Tooling, build & quality gates (XcodeGen, SwiftLint, CI) | §15 |
| Security & privacy hardening | §16 |
| Anti-patterns to refuse | §17 |
| New-feature bootstrap checklist | §18 |

## Module naming

```
ProRounds<Layer><Feature>
e.g. ProRoundsFeatureTimer, ProRoundsDataSessions, ProRoundsFoundationTiming, ProRoundsDesignSystem
```
