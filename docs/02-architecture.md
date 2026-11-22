# 02 — Architecture

This document is the technical contract for RealCricket. It defines the layers, the assembly
graph, the simulation model, and the rules that keep the codebase testable for a multi-year
project. It deliberately contains no gameplay implementation.

---

## 1. Architectural principles

1. **The simulation is the game; rendering is a view of it.** Anything that can change a score,
   a stat, or a career exists in the engine-agnostic core.
2. **Fixed-step, seeded, deterministic.** Same inputs + same seed = same match, at any frame rate,
   on any device. Replays, simulations and tests all depend on this.
3. **One-way dependencies.** Core knows nothing. Simulation knows Core. Gameplay knows Simulation.
   Presentation knows Gameplay and Core *read-only*. Nothing ever points back up.
4. **Data over code for content.** New stadiums, teams, shots, tournaments and difficulty curves
   are data assets; adding them must not require touching systems code.
5. **Everything is budgeted.** Every system that allocates per-frame has an owned memory budget;
   every shader and asset has an install-size budget.
6. **Instrument before optimising.** The simulation has a headless harness and the game has a
   device overlay; "feels heavy" is not a bug report.

---

## 2. Layer model

```
┌──────────────────────────────────────────────────────────────────────────┐
│  PRESENTATION (Unity)                                                    │
│  Cameras · Animators/IK · VFX · Audio · UI Toolkit · Replay playback     │
│  reads state, plays events, never mutates the match                      │
└───────────────▲──────────────────────────────────────────┬───────────────┘
                │ Core events (immutable payloads)         │ player intents
┌───────────────┴──────────────────────────────────────────▼───────────────┐
│  GAMEPLAY (Unity)  MatchDirector · input mapping · mode/session flow     │
│  quality settings · pause/time-scale · save orchestration                │
└───────────────▲──────────────────────────────────────────┬───────────────┘
                │ MatchState / commands                    │
┌───────────────┴──────────────────────────────────────────▼───────────────┐
│  SIMULATION (Unity adapter, thin)                                        │
│  Fixed-step driver · BallView interpolation · field/fielder binding      │
│  animation-event translation · trajectory prediction for AI & cameras    │
└───────────────▲──────────────────────────────────────────┬───────────────┘
                │ pure state and events                    │
┌───────────────┴──────────────────────────────────────────▼───────────────┐
│  CORE (pure C#, no UnityEngine)                                          │
│  RulesEngine · MatchState · BallSolver · ContactResolver · AI decision   │
│  CareerProgression · RNG · tuning parameters · serialization models      │
└──────────────────────────────────────────────────────────────────────────┘
```

**Hard rule enforced in CI:** `RealCricket.Core.dll` must not reference `UnityEngine*`. A small
CI step inspects the compiled assembly's references and fails the build otherwise.

---

## 3. Assembly graph

| Assembly (asmdef) | Depends on | Contents |
|---|---|---|
| `RealCricket.Core` | *nothing* | Rules, match state, ball/contact solver, AI policy, career math, RNG, save DTOs |
| `RealCricket.Data` | Core | ScriptableObject definitions, tuning assets, catalogs, ID registry |
| `RealCricket.Simulation` | Core, Data | Fixed-step driver, ball/fielder/field bindings, prediction service |
| `RealCricket.AI` | Core, Data | Unity-side AI runtime (think scheduler, perception adapters) |
| `RealCricket.Gameplay` | Core, Data, Simulation, AI | MatchDirector, session/mode flow, input→intent mapping, career loop |
| `RealCricket.Services` | Core, Data | Save, settings/quality, content (Addressables), input, localization, telemetry |
| `RealCricket.Presentation` | Core, Data, Simulation, Gameplay | Cameras, animation, VFX, audio, field visuals |
| `RealCricket.UI` | Gameplay, Services | All UI Toolkit screens and HUD |
| `RealCricket.Editor` | all | Importers, validators, budget checks, build scripts |
| `RealCricket.Tests.EditMode` | Core, Data | Rules/physics/career unit tests, golden replays |
| `RealCricket.Tests.PlayMode` | all | Scene-level integration, input, save round-trips |

Rules:
- Presentation may **read** `MatchState` but only through read-only views (`IMatchView`,
  `IBallView`). Mutating simulation state from a visual is a review-blocking defect.
- UI never calls Core directly except through a `GameplayFacade` — this keeps screens testable and
  the HUD independent of simulation internals.
- `Data` must stay passive (definitions + validation), no runtime behaviour.

---

## 4. Core domain model

### 4.1 Identity and state

```
MatchState
├── MatchFormat         (T20 | ODI | Test | Custom: overs, innings, sessions, follow-on, DRS)
├── ConditionsState     (weather, temperature, humidity, wind, time of day, pitch type/wear, outfield)
├── InningsState[]      (battingTeam, bowlingTeam, runs, wickets, overs, extras, target, declarations)
│   ├── BatterState     (runs, balls, 4s, 6s, status: not-out/out/retired, dismissal)
│   ├── BowlerState     (overs, maidens, runs, wickets, stamina, deliveries bowled)
│   ├── PartnershipState
│   └── OverState       (ball index, free hit, powerplay, fielding restrictions)
├── FieldState          (fielders: id, role, position, assigned zone, energy)
├── BallState           (position, velocity, spin axis+rate, seam orientation, age, roughness)
└── RngStreams          (match, career, cosmetic — seeded and serialized)
```

`MatchState` is a plain serializable graph (structs where hot, classes where referenced) with
explicit `Clone()`/snapshot support so AI can evaluate hypotheticals and the replay system can
scrub. It carries a monotonically increasing `Tick` and a `Version` for save migration.

### 4.2 Match flow (state machine)

```
PreMatch → Toss → InningsStart → OverStart → DeliverySetup
   → RunUp → Release → BallInPlay → Outcome → (next ball | OverEnd | InningsEnd)
   → InningsBreak → (next innings | MatchEnd) → Presentation → Save/Exit
```

`MatchDirector` (Gameplay) drives the Unity-facing flow; `RulesEngine` (Core) owns legal
transitions (e.g. innings ends on 10 wickets, target reached, overs exhausted, declaration,
follow-on decision). Any rule question must be answered by a Core method with a unit test, never
by an `if` in a MonoBehaviour.

### 4.3 Event model

Core emits immutable, ordered events consumed by visuals and UI:

```
BallReleased(bowlerId, deliveryType, releasePoint, initialBallState)
BallPassedBatter(tick, line, length, deviation)
BatContact(contactQuality, timingOffset, pointOffset, exitVelocity, shotId)
BallBounced(zone, impactSpeed, deviation, surfaceWear)
KeeperCollected / FielderIntercepted / CatchAttempt(quality, result)
Wicket(dismissalType, batter, bowler, fielders[])
RunsScored(count, source: bat|bye|legbye|overthrow|penalty)
OverCompleted / InningsCompleted / MatchCompleted
```

Events are replayed in order with their tick stamps; presentation subscribes and must never
synchronously re-enter the simulation.

### 4.4 Randomness

- Named `RngStream` instances, each a PCG/xorshift implementation with its own seed and cursor.
- Only Core draws from them. AI uses the `match` stream so AI choices replay identically.
- Cosmetic randomness (crowd, camera shake, grass sway) uses a presentation-only RNG and may
  differ per device — it can never affect the match.

---

## 5. Time and tick model

| Loop | Rate | Owner | Notes |
|---|---|---|---|
| Simulation tick | **240 Hz** fixed | Simulation | Ball flight integration, contact tests, rule evaluation |
| AI think | 10 Hz + event-driven | AI | Batting read/reaction, bowling plan, fielding re-assignment |
| Animation | per frame | Presentation | Animator update, IK solve, root-motion consumption |
| Render | per platform target | Presentation | 30/45/60/120/144 Hz per quality tier |

- The driver accumulates real time and runs fixed ticks with a max catch-up count (clamped) so a
  hitch never changes physics outcomes.
- Render interpolates between the last two simulation snapshots for the ball and fielders, so a
  30 fps phone sees the same trajectory as a 144 fps PC.
- Pause, replays and cutscenes freeze simulation ticks; UI animations run on unscaled time.
- Time scale for "skip to next ball" is implemented as *tick batching* (run N ticks without
  rendering), not as `Time.timeScale`.

---

## 6. Ball physics pipeline

**State:** position, velocity, angular velocity (spin axis + rate), seam orientation, age
(0–80 overs), surface condition, plus per-delivery release parameters.

Per tick:

```
1. Forces      F = m·g + ½ρ·Cd(Re, rough)·A·|v−w|·(v−w) + ½ρ·Cl(S)·A·|v−w|²·(ω̂ × v̂)
               + seamAsymmetry(seamAngle, v, roughness)      ← swing / reverse swing
2. Integrate   semi-implicit Euler (documented; RK4 optional for validation builds)
3. Spin        ω decays with rate k; precession ignored
4. Surfaces    swept-sphere test vs pitch heightfield, stumps, bat blade, pads, fielders
5. Response    bounce: normal restitution from surface hardness + ball age; tangential impulse
               from friction and surface normal; deviation from seam angle & spin axis
6. Events      emit ordered contact/bounce outcomes, then continue (overthrow, deflections)
```

**Pitch surface** is a coarse authored heightfield (bounce map) per stadium zone with hardness,
friction and wear curves. Deliveries are evaluated against it, so a length ball on a dry fifth-day
pitch behaves measurably differently from a fresh green seamer — a data change, not a code path.

**Bat contact** is resolved in the batter's anatomical frame:

```
contact = batPlane.Intersect(ballSweep)           // swept plane vs swept sphere
quality = f(contactPointVsSweetSpot, timingOffset, batSpeed, ballSpeed, shotType)
exit    = batNormal·(restitution·relativeSpeed) + spinTransfer + shotLaunchBias
```

Timing offset is derived from player intent vs the actual arrival tick; footwork changes the bat
plane origin, which changes both reachable line/height and contact quality. Edges and misses fall
out of geometry rather than a random table.

**Validation:** M0 produces reference data (high-speed video of thrown/spun balls) and a tuning
notebook; regression tests assert ball trajectories, bounce heights and deviation within
documented tolerances.

---

## 7. Gameplay systems

### 7.1 Batting

- Input produces a `ShotIntent { shotId, footwork, aimZone, powerModifier, timingOffset }` at or
  before the contact window; the simulation resolves the outcome.
- Assist levels change the *size* of the timing/aim windows and the amount of input smoothing —
  never the physics constants or the shot table.
- Running between wickets is a separate command layer (`RunCommand { call, commitment }`), with
  optional auto-run assist for lower difficulties.

### 7.2 Bowling

- `DeliveryIntent { deliveryType, line, length, speedEffort, seamDirection, followThrough }`
  chosen before the run-up; a run-up timing/release minigame modulates accuracy and pace.
- Delivery types are `DeliveryDef` data assets: release point offset, seam/spin axis, speed range,
  accuracy scatter, stamina cost, required skill.
- Stamina, workload and ball age feed the solver, so a fifth-day spell is physically different.

### 7.3 Fielding AI

Three cooperating layers, all in Core, all deterministic:

1. **Assignment** — an auction/greedy solver assigns each ball-in-play to the best fielder by
   predicted intercept time and throw value; prevents "everyone chases the ball".
2. **Interception** — trajectory prediction produces intercept point/time; fielder steering
   (arrive-by-time with acceleration limits, dive/slide triggers) runs in Simulation.
3. **Decision** — throw to which end, relay or direct, cut-off positioning, backing up, catching
   technique selection. Utility scoring with role weights (slip vs cover vs boundary rider).

Fielders use a purpose-built steering model with capsule avoidance, **not** NavMesh pathfinding on
the field (NavMesh is used only for walk-on/walk-off and stadium interior transitions).

### 7.4 Umpiring and reviews

`UmpireModel` in Core evaluates lbw/edge/no-ball/catch with explicit uncertainty per difficulty
and emits a reviewable decision record, so DRS presentation is a view of simulation truth plus
modelled error — not a separate guess.

### 7.5 Career

Core owns a `CareerState`: calendar, contracts, selection, form/fitness, skill trees, records and
stat aggregation. It is format-agnostic and simulation-driven; a "simulate match" call runs the
same Core match loop headlessly at maximum tick batch. Presentation only shows it.

### 7.6 Modes and sessions

`MatchDirector` composes: `MatchConfig` (format, teams, venue, conditions, rules toggles) →
`SessionState` (pause, replay, exit, save) → result. Tournaments and career are *schedulers* over
`MatchConfig`, so T20 leagues, bilateral series and World-Cup-style events share one engine.

---

## 8. Presentation architecture

| System | Design |
|---|---|
| **Animation** | Per-role Animator controllers (batter stance/footwork/swing, bowler action, fielder locomotion/dive/throw, keeper). Mocap base clips + Animation Rigging IK (bat grip, foot planting, ball-tracking head/torso) so a clip meets a ball at any line. Additive layers for fatigue, confidence, pain reactions. |
| **Cameras** | `CameraDirector` with named rigs (broadcast, bowler-behind, batter-eye, field, replay, presentation) and a blend graph; replay camera derives from recorded ball/fielder state, not from live transforms. |
| **VFX** | Ball trail (line/length readability), pitch dust, seam shine, sweat/breath (PC tier), crowd reactions via GPU-instanced cards/vertex animation. |
| **Audio** | Bus layout (Master/Music/SFX/Commentary/Crowd/StumpMic/UI); crowd intensity parameter driven by match tension; commentary triggered by Core events with cooldowns and context tags. |
| **UI** | UI Toolkit: single `UIDocument` per screen group, data-bound to view models from `GameplayFacade`; HUD (score, over, batter/bowler cards, mini-field, replay controls) scales by safe-area and DPI tier. |
| **Accessibility** | Colour-blind-safe palettes, scalable HUD, optional ball highlighting, timing-assist visualisation, subtitles for commentary. |

---

## 9. Data and content architecture

- **Definitions (ScriptableObjects)** — `PlayerDef`, `TeamDef`, `StadiumDef`, `DeliveryDef`,
  `ShotDef`, `BowlingActionDef`, `TournamentDef`, `DifficultyDef`, `WeatherPreset`, `KitDef`,
  `CommentaryBankDef`. Each has a **stable string ID** (`player.ind.rav-01`), never a scene path.
- **Tuning tables (JSON)** — physics constants, AI weights, career curves. Hot-reloadable in dev
  builds; shipped as read-only text in builds so balance patches are possible without art rebuilds.
- **Catalogs** — a generated `ContentCatalog` maps IDs → Addressables keys, with a validator that
  fails the build on missing IDs, duplicate IDs, or references from a save to non-existent content.
- **Saves store IDs, not asset references.** Deleting a team must fail validation loudly, not
  silently corrupt a career.
- **Addressables groups** — `Core`, `Stadium.<id>`, `Team.<id>`, `Commentary.<lang>`,
  `Localization.<lang>`, `UI`. See `06-asset-and-content-pipeline.md` for pack-to-store mapping.

---

## 10. Save, replay and simulation services

**Save (`SaveGameService`)**
- Snapshot = versioned JSON header (metadata, checksum, schema version) + compressed binary body
  (MatchState/CareerState DTOs) written atomically (`*.tmp` → fsync → rename) to
  `Application.persistentDataPath`.
- Migration pipeline `ISaveMigration` chain: v1→v2→…; a save from any shipped version must load.
- Slots: career slot(s), quick match autosave, settings profile. Autosave triggers at over end,
  innings end, match end, and app pause.
- Corruption handling: keep last-known-good copy, surface a clear error, never silently reset.

**Replay (`ReplayService`)**
- Stores seed + ordered `PlayerCommand`s + rules config; replay re-runs Core ticks and feeds the
  same event stream to presentation. Optional compressed keyframe snapshots every N overs for
  scrubbing. Typical replay for a T20 is hundreds of kilobytes, not video.

**Headless simulation (`SimulationHarness`)**
- Runs Core-only matches at maximum speed for: career "simulate", tournaments, balance sweeps,
  golden-replay tests, and long-run soak tests of the rules engine.

---

## 11. Cross-cutting services

| Service | Responsibility |
|---|---|
| `QualityService` | Detects device tier (GPU/CPU/RAM/thermal), selects a `QualityProfile`, applies URP asset + render scale + shadow/VFX/audio budgets at runtime; exposes overrides in settings. Never alters simulation. |
| `InputService` | Input System actions → `ShotIntent`/`DeliveryIntent`/`RunCommand`; context stacks (match, replay, menu); rebinding; touch gesture recognition (swipe for shots, taps for timing). |
| `ContentService` | Addressables load/release by handle, ref-counted per session, preloading per match config, memory-pressure eviction. |
| `LocalizationService` | Locale selection, string tables, commentary localisation variants, number/date formats. |
| `AudioService` | Mixer snapshots per context (menu/match/replay), ducking for commentary, voice limits by tier. |
| `TelemetryService` | **Opt-in only**, offline buffer, batch upload if enabled; never required for play. |
| `DebugOverlay` (dev) | Tick rate, sim/render ms, ball state, AI assignments, memory, quality tier, seed. |

---

## 12. Threading and performance rules

- Core is single-threaded by contract; multi-core use happens only in **Burst jobs** for pure math
  (ball integration batches for AI prediction, fielder assignment cost matrices, trajectory
  sampling) and in async Addressables loading.
- No allocation in per-tick or per-frame hot paths: pooled event objects, struct payloads,
  pre-sized buffers, `NativeArray` for prediction scratch.
- Animation: at most one full-body IK pass per visible character per frame; distant fielders use
  cheap look-at only, or are culled to lower update rates by tier.
- Crowd: GPU-instanced, no per-agent `GameObject`s; density is a tier parameter.
- Every system ships with a documented budget in `05-performance-and-size-budget.md`.

---

## 13. Testing and quality gates

| Gate | What it proves |
|---|---|
| EditMode unit tests (Core) | Rules correctness (all dismissal types, extras, follow-on, target math), physics invariants (energy/drag bounds, bounce monotonicity), career arithmetic |
| Golden replay tests | Fixed seed + command log → identical scorecard and ball trace hash across runs/platforms |
| Physics validation scene | Ball trajectories vs reference data within tolerance |
| PlayMode integration | Input→intent→event→animation path, save/load round-trip, mode transitions |
| Device smoke tests | Android mid/low tier + Windows: 30-minute match, frame time, thermal, memory, no GC spikes |
| Content validation | Addressables/ID/catalog integrity, missing references, size budgets |

CI runs the first six on every merge to `develop`; device tests run nightly on the physical device
rack and are the release gate.

---

## 14. Extensibility notes (not v1 scope)

The layering deliberately leaves room for: online asynchronous modes (Core is already authoritative
and deterministic), additional formats (The Hundred-style, 10-over), console ports (Core is
engine-agnostic), and user-shared custom teams (catalog + ID model already supports stable IDs).
None of these are implemented in v1.0, and no v1 system should be built speculatively for them.
