# 04 — Development Roadmap

## 1. Shape of the plan

Work proceeds in **milestones**, each ending in a playable, measurable build. No milestone is
"infrastructure only": the vertical slice comes first, then breadth, then depth.

```
Phase 0  Architecture & planning      (this task)      — docs, decisions, budgets
M0       Technical foundation + slice  weeks 1–6        — prove the ball, one venue, one over
M1       Core match loop               weeks 7–16       — full formats, rules, fielding v1
M2       Content & modes               weeks 17–28      — venues, teams, tournaments, saves
M3       Career mode                   weeks 29–38      — progression, calendar, records
M4       Polish & optimisation         weeks 39–48      — animation depth, audio, device targets
M5       Beta, certification, launch   weeks 49–56      — store builds, device matrix, fixes
```

Assumes a core team of **9** (see §5). Timeline is deliberately honest: a realistic cricket game
with four formats is a ~12-month project for this team size, not a 3-month one.

---

## M0 — Technical foundation and vertical slice (weeks 1–6)

**Goal:** prove that the riskiest parts work before art production commits.

Deliverables
- Unity 6.3 LTS project at repo root: URP, assembly definitions, `.editorconfig`, CI (EditMode
  tests + Android/Windows IL2CPP builds), Git LFS configured, `ProjectVersion.txt` locked.
- `RealCricket.Core` skeleton: tick clock, `MatchState`, seeded RNG, ball state + solver,
  pitch surface, contact resolver — with unit tests and a headless harness.
- `PhysicsLab` dev scene: fire deliveries with tunable parameters, draw trajectories, log
  bounce/deviation tables; compare against reference capture data.
- One greybox stadium with correct dimensions; broadcast camera rig; ball trail.
- One bowler run-up + release animation, one batter stance + front-foot drive, placeholder
  fielders, a single over playable end-to-end with a real scorecard event.
- Quality tiers defined and profiled: low/mid Android device + a mid Windows PC.
- Save/load of a single match state; replay of that over from a seed + command log.

Exit criteria
- A 6-ball over plays start-to-finish on a mid-tier Android device at ≥30 fps with the debug
  overlay on, and on Windows at ≥60 fps.
- Ball trajectories and bounce behaviour pass the validation scene tolerances (documented).
- Replaying the saved over reproduces the exact same event log (hash match).
- CI green on both platforms.

Explicitly not in M0: career, tournaments, final art, commentary, more than one stadium.

---

## M1 — Core match loop (weeks 7–16)

**Goal:** a rules-complete, genuinely playable match in all three formats, with placeholder art.

Deliverables
- Rules engine complete for T20/ODI/Test: all dismissal types, extras, free hits, powerplays,
  follow-on, declarations, innings/target logic, super over, result determination; formatting of
  scorecards; ~200 unit tests.
- Batting: 12 shot families with footwork and aim; timing/placement model; edges, misses, pad
  contact; running between wickets with manual call + assist.
- Bowling: 6 delivery families (pace swing/seam, off-spin, leg-spin, left-arm variations), line/
  length/speed selection, run-up timing minigame, stamina.
- Fielding AI v1: assignment solver, interception steering, dive/slide/throw, catching with
  quality model; keeper collection and stumping.
- Field placement UI + 9 preset field plans per format; fielding restriction enforcement.
- Umpiring model + basic DRS review flow.
- Broadcast camera director, HUD, scorecard, over summary, pause/settings, match save/resume.
- AI batting and bowling opponents at three difficulty levels; "simulate rest of match" from any
  point using the same Core loop.
- Animation: functional placeholder mocap for all roles (blocking quality acceptable).

Exit criteria
- A full T20 and a full ODI can be played to completion, saved mid-innings, reloaded, and finished;
  scorecard reconciles with the event log to the run.
- A 3-day Test session can be played and resumed with correct session/session-break handling.
- AI vs AI matches complete without rule deadlocks across 200 headless runs (soak test).
- Frame targets hold on the mid Android tier during a match with 11 fielders + crowd placeholder.

---

## M2 — Content, venues and modes (weeks 17–28)

**Goal:** the game looks and feels like a product, and all non-career modes exist.

Deliverables
- 14 stadiums: 6 marquee (full art, crowd, dressing rooms) + 8 standard; per-stadium dimensions,
  pitch types and conditions; day/night and weather variants.
- 12 national + 16 domestic fictional squads authored; player creator/editor; kit editor; bat/
  glove/helmet customisation; ~60 authored heads with parametric blending.
- Batting animations expanded to ~120 clips with IK adaptation; bowling actions ~18 bases;
  fielding/keeping set ~90 clips.
- Tournament mode: league + knockout templates, group stages, points tables, NRR, finals.
- Custom match flow: teams, venue, overs, conditions, difficulty, rules toggles.
- Audio pass 1: crowd system, SFX, stump mic, music, commentary framework with 2,000 lines.
- Addressables content split + Android asset packs + Windows optional 4K component; install-size
  budget verified with real builds.
- Localization framework + English complete, one additional language for UI strings.

Exit criteria
- All modes reachable from the menu and playable end-to-end.
- Every stadium loads on the low Android tier within 8 s and holds frame budget.
- Install sizes within budget (see `05-performance-and-size-budget.md`); no missing-addressable
  errors in a full-content validation run.
- Tournament and custom match saves survive app kill and resume.

---

## M3 — Career mode (weeks 29–38)

**Goal:** the long-form single-player experience that gives the game its lifespan.

Deliverables
- Player creation → domestic debut → international pathway; selection based on form, fitness,
  reputation and team needs.
- Season calendar across formats; contracts, renewals, transfers/auctions for league seasons;
  injuries and workload management; training/skill trees per discipline.
- Full stat history: career/test/ODI/T20 splits, milestones, records, awards, hall of fame.
- Simulate/play/simulate-to-here match control using the headless Core loop.
- Career UI suite: hub, calendar, inbox/news, stats, skills, contracts, records.
- Save migration v1→v2 with a tested upgrade path for pre-career saves.

Exit criteria
- A 10-season career can be simulated headlessly in < 90 s on a mid PC without state corruption.
- Playing one full season (≈ 25 matches, mix of played and simulated) leaves consistent stats
  across all screens and saves.
- Save/load at every career screen boundary; corrupted-save recovery path demonstrated.

---

## M4 — Polish and optimisation (weeks 39–48)

**Goal:** meet the quality bar and the hardware budgets on the full device matrix.

Deliverables
- Animation depth pass: fatigue/confidence layers, reaction and celebration variants, cutscenes
  (toss, milestones, presentations), replay camera package.
- Commentary expanded to ~6,000 lines with context rules and cooldown tuning; crowd intensity
  driven by match tension.
- Lighting/post pass per tier: authored time-of-day, bloom/AO/colour grading, upscaling on PC,
  mobile-safe alternatives.
- Optimisation: LOD/culling audit, texture streaming, animation update throttling, GC elimination,
  shader variant stripping, load-time reduction, thermal soak testing.
- Accessibility pass: colour-blind palettes, HUD scaling, subtitles, assist options.
- Difficulty and balance sweep using headless simulation data (run rates, wicket distributions,
  edge rates by difficulty).

Exit criteria
- 5% low frame-time percentile within budget on every tier; 30-minute thermal soak without
  dropping below the tier floor.
- Memory within budget on the 4 GB Android reference device.
- No per-frame GC allocations in match play (verified by profiler captures).
- Balance targets met: T20 scores, Test session run rates and wicket types within designed ranges.

---

## M5 — Beta, certification and launch (weeks 49–56)

**Goal:** ship.

Deliverables
- Closed beta (200–500 players) with feedback triage; crash-free session target ≥ 99.5%.
- Store assets, privacy policy, age ratings, licences file, opt-in telemetry disclosure.
- Android AAB with asset packs through Play Console internal → closed → production tracks;
  Windows installer with code signing and optional 4K component.
- Final QA matrix across ~12 Android devices (3 tiers) and 4 Windows GPU configurations.
- Day-one patch plan and known-issues list; post-launch balance patch process via JSON tuning.

Exit criteria
- Both store submissions approved; signed builds reproducible from a tagged commit.
- Zero P0/P1 defects open; documented known issues only.
- A new player can complete the tutorial/first match without external help (usability test, n≥5).

---

## 3. Dependency map (what blocks what)

```
Core tick + ball solver ──► batting/bowling feel ──► AI difficulty tuning
        │                          │
        ├──► rules engine ─────────┴──► formats/modes ──► tournaments ──► career
        │                                                    │
        └──► fielding assignment ──► fielding animation ─────┘
Save/replay ──► career persistence ──► certification requirements
Content pipeline ──► stadium/team production ──► size budget ──► store limits
```

Anything on the left that slips moves the whole plan. That is why M0 is a spike, not a setup phase.

---

## 4. Risk register

| # | Risk | Impact | Mitigation |
|---|---|---|---|
| R1 | Ball feel never becomes fun/readable, despite correct physics | Fatal | `PhysicsLab` from week 1; weekly playtests from M0; readability (trail, camera, release cues) treated as a feature with acceptance criteria |
| R2 | Android thermal throttling in long sessions | High | Tiered quality with dynamic resolution; 30-min soak tests from M1; crowd/VFX budgets per tier |
| R3 | Animation volume (≈ 230 clips) exceeds schedule | High | Mocap batch plan in M0; clip reuse via IK/additive layers; outsource cleaning with our rig spec |
| R4 | 5 GB budget exceeded once art lands | High | Per-asset budgets in `05-performance-and-size-budget.md`; size check in every CI build; shared atlases and trim sheets by policy |
| R5 | Test-cricket rules edge cases (follow-on, declarations, DRS, tie/super over) | Medium | Rules engine unit-tested against Laws checklist; soak tests; a cricket-savvy consultant reviews the rules matrix |
| R6 | Rights/trademark exposure from realistic-looking teams or venues | Medium | Fictional names/leagues; trademark screen before content lock; provenance log |
| R7 | DLS/rain interruption scope creep | Medium | Ships as a simplified "revised target" model, clearly labelled; full DLS only if schedule allows |
| R8 | Unity version/package churn mid-production | Medium | Version pinned at M0; upgrades only between milestones with regression pass |
| R9 | Team knowledge concentration in physics/AI | Medium | ADRs + tuning notebooks + pair review; Core has tests as executable documentation |
| R10 | Store policy changes (asset pack limits, data-safety forms) | Low–Medium | Verify limits at M2 and M5; content split designed to be re-partitionable |

---

## 5. Staffing plan (core team of 9)

| Role | FTE | Primary milestones |
|---|---|---|
| Technical director / architect | 1 | All; owns Core boundaries and ADRs |
| Gameplay/physics programmer | 1 | M0–M4: ball solver, contact, fielding math |
| AI/gameplay programmer | 1 | M1–M4: batting/bowling/fielding AI, difficulty |
| Tools/UI programmer | 1 | M1–M4: UI Toolkit, editors, content validators, save/migration |
| Animator (mocap + technical) | 2 | M1–M4: shot/bowling/fielding sets, IK rigs, cutscenes |
| Environment/character artist | 2 | M2–M4: stadiums, players, kits, props |
| Audio designer / composer | 0.5 | M2–M5: crowd, SFX, commentary integration, music |
| QA / release engineer | 0.5 | M3–M5: device matrix, automation, store submissions |
| Producer | 0.5 | All: schedule, risk, external vendors |

Contract additions: mocap session crew (M0–M2), commentary voice talent + writer (M2–M4),
cricket rules consultant (M1–M2), outsource texture artists (M2–M3).

---

## 6. Definition of done (applies to every milestone)

A feature is done when: it works on both platforms at tier targets; it has tests where it touches
Core; it is localised (no hard-coded strings); it is saved/loaded correctly if it holds state; it
has no new GC allocation in hot paths; it is documented in the relevant `docs/` file if it changes
architecture; and it passed a playtest by someone other than its author.
