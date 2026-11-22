# Architecture Decision Records

One file per decision that is expensive to reverse. An ADR is written **before** the work it
governs, and is never deleted — it is superseded by a newer ADR that links back to it.

Format: context → options considered → decision → consequences (positive and negative) →
review trigger.

| # | Decision | Status |
|---|---|---|
| [0001](0001-game-engine.md) | Unity 6.3 LTS + URP as engine and render pipeline | Accepted |
| [0002](0002-deterministic-simulation-core.md) | Engine-agnostic, fixed-step, seeded simulation core | Accepted |
| [0003](0003-ball-physics-solver.md) | Custom ball flight, bounce and bat-contact solver | Accepted |

## Planned decisions (to be written when the work starts)

| Topic | Milestone | Why it matters |
|---|---|---|
| Animation strategy: mocap base + IK vs. fully procedural | M0 | Determines rig spec, clip count and the whole animation budget |
| Audio middleware: FMOD vs. Unity Audio | M0 | Runtime dependency, licence cost, crowd/commentary architecture |
| Save format and migration policy (binary vs. JSON-only) | M1 | Career longevity and support burden |
| Android asset-pack partitioning and store limits | M2 | Install size, patch size, review compliance |
| Commentary triggering: rule-based vs. weighted context model | M2 | Localisation cost and file size |
| Difficulty model: input assist vs. AI skill scaling vs. both | M1 | Fairness and replayability; must not touch physics constants |
