# ADR 0001 — Game engine and render pipeline

- **Status:** Accepted
- **Date:** 2026-11-22
- **Deciders:** Technical director, gameplay lead, art director
- **Supersedes:** none

## Context

RealCricket targets Android and Windows PC from one team and one content pipeline, with a 5 GB
install budget and a "maximum realistic quality" graphics target that must still be playable on
mid-range phones. The hard problems are rules, ball behaviour, animation blending and AI — not
rendering research.

## Options considered

1. **Unreal Engine 5.x** — best PC fidelity; Nanite/Lumen unusable on target phones; large binaries;
   C++/Blueprint split increases cost for logic-heavy gameplay.
2. **Unity 6.3 LTS + URP** — same shader/material set on both platforms with quality tiers; strong
   mobile profiling; C# for the simulation core; Addressables for content splitting.
3. **Godot 4.x** — lean, but 3D mobile renderer, animation retargeting and middleware ecosystem are
   below what a realistic sports title needs.
4. **Custom engine** — unacceptable schedule and staffing risk; no benefit for this genre.

## Decision

Use **Unity 6.3 LTS (6000.3.x)** with **URP** as the only render pipeline, locked to a specific
patch at project creation and upgraded only between milestones.

## Consequences

**Positive**
- One material/shader authoring path for both platforms; quality tiers are profile swaps.
- C# + NUnit lets the rules and physics core be unit-tested without entering play mode.
- Mature Android export (IL2CPP, AAB, Play Asset Delivery) and profiling.
- Addressables gives us the per-stadium/per-team content split the 5 GB budget requires.

**Negative / mitigations**
- URP's ceiling is below path-traced PC rendering. Mitigate with authored lighting, high-quality
  PBR materials, post-processing (bloom, AO, colour grading, upscaling), and dense crowd/venue art
  rather than chasing ray-traced realism.
- Unity licensing terms must be confirmed against projected revenue before commercial release;
  budget review at M1 and M4.
- Engine upgrades can break shaders and packages: pin the version, upgrade deliberately, keep a
  regression scene and a device smoke test.

## Review trigger

Revisit if (a) Android becomes out of scope, or (b) URP cannot hit the frame budgets in
`05-performance-and-size-budget.md` after M2 optimisation.
