# ADR 0002 — Engine-agnostic deterministic simulation core

- **Status:** Accepted
- **Date:** 2026-11-22
- **Deciders:** Technical director, gameplay lead

## Context

The game is offline and single-player, so there is no server authority to hide behind. But the
match simulation is the product: scorecards, career stats, replays, "simulate to my next match",
and difficulty tuning all depend on it. If simulation state lives inside `MonoBehaviour`s and
`Rigidbody`s, it becomes untestable, frame-rate dependent, and impossible to replay.

## Options considered

1. **Unity-coupled simulation** — `MonoBehaviour` state, `Rigidbody` ball, `Update()`-driven.
   Fastest to start, impossible to unit test or reproduce.
2. **Engine-agnostic core assembly** — pure C# (`RealCricket.Core`), fixed-step, seeded RNG, no
   `UnityEngine` reference, driven by a thin Unity adapter that renders its output.
3. **External simulation service** — absurd for an offline game.

## Decision

Adopt option 2.

- `RealCricket.Core` has **no reference to UnityEngine** (enforced by assembly definition + a CI
  check that the compiled assembly has no Unity reference).
- All gameplay state that affects the score exists in Core: ball state, batter/bowler state,
  match state, rules, RNG, career progression arithmetic.
- Time advances in **fixed 1/240 s simulation ticks**, independent of render frame rate.
- Randomness comes only from seeded, explicitly-owned RNG streams (`match`, `career`, `cosmetic`)
  so a match replay reproduces exactly.
- Unity layer (`RealCricket.Simulation`, `RealCricket.Gameplay`) converts input intents into Core
  commands and Core events into animation/VFX/audio/camera.

## Consequences

**Positive**
- Rules and physics are unit-testable in milliseconds (EditMode tests, headless CI).
- Replays and "simulate remaining overs" are free: store the seed + command log.
- Tuning is data, not prefab edits; balance passes are diffable JSON.
- Future console/other-engine ports keep the same simulation.

**Negative / mitigations**
- Two representations of the ball (Core state, Unity visual) require interpolation and explicit
  sync. Mitigate with one `BallView` binder and a debug overlay that draws both.
- Designers cannot tweak gameplay from the inspector alone; they use ScriptableObject tuning
  assets that export to Core parameters — extra tooling in M0.
- Determinism must be protected: forbid `float`-order-dependent aggregates where it matters, use
  a documented `Mathf`-free math helper set in Core, and keep golden-replay tests green in CI.
