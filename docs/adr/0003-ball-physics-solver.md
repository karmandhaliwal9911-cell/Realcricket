# ADR 0003 — Custom ball flight and contact solver

- **Status:** Accepted
- **Date:** 2026-11-22
- **Deciders:** Technical director, gameplay lead, physics programmer

## Context

Cricket realism depends on ball behaviour: swing in the air, seam movement and spin off the pitch,
variable bounce with ball age and pitch wear, and a contact model where bat timing and placement
produce believable edges, mishits and middles.

Unity's built-in `Rigidbody` + `PhysX` gives us gravity, drag, friction and restitution, but not
Magnus lift, seam-induced asymmetric boundary layer effects, a worn pitch surface, or a bat blade
that is a swing-driven plane rather than a static collider. Tuning PhysX material properties to
fake those produces unstable, unexplainable outcomes.

## Options considered

1. **PhysX everywhere** — fast to start; cannot model swing/spin/seam credibly; physics settings
   become a pile of magic numbers.
2. **Custom analytical solver in Core, Unity visuals only** — full control, deterministic, tunable
   from published aerodynamics; needs careful collision handling and validation.
3. **Third-party sports physics middleware** — no cricket-aware product exists; licensing cost.

## Decision

Option 2, with a hybrid approach:

- **Flight**: semi-implicit integration at 240 Hz of gravity + quadratic drag + Magnus force +
  seam-orientation asymmetry (conventional/reverse swing). Spin is integrated separately with
  spin-decay.
- **Pitch interaction**: swept-sphere contact against a heightfield surface carrying per-zone
  hardness, friction, seam and wear; bounce response computed from incidence angle, surface
  normal, ball age, spin axis and speed. Output: post-bounce velocity + deviation, not a PhysX
  collision.
- **Bat contact**: bat blade represented as a swept plane (with sweet-spot weighting) in the
  batter's local frame; contact resolves exit velocity from relative velocity, swing speed,
  restitution, timing offset and contact-point offset. This is where skill is expressed.
- **Stumps, fielders, boundary**: analytic capsule/sphere tests with CCD; no PhysX dependency in
  Core.
- **Unity Physics** is retained only for non-gameplay props (boundary boards, debris, crowd
  physics), where unpredictability is harmless.

## Consequences

**Positive**
- Swing, seam, spin, drift and bounce become parameters with physical meaning — coachable and
  explainable in tuning tools.
- Deterministic and replayable; regression tests can assert ball trajectories within tolerance.
- Contact model is the difficulty/skill dial without touching flight physics.

**Negative / mitigations**
- Must be validated against reality: capture reference trajectories from high-speed video of
  thrown balls at M0 and fit constants; keep a validation spreadsheet in `docs/`.
- Collision edge cases (thin edges, bat handle, pad contact) need a documented contact-priority
  order and dedicated tests.
- No free broadphase: fielders/pads/stumps are checked explicitly in a fixed order; profile the
  per-tick cost on the weakest Android tier at M0.
