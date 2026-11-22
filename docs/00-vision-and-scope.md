# 00 — Vision and Scope

## 1. Product statement

RealCricket is a single-player, offline cricket simulation that aims at the *feel* of televised
cricket: a ball that behaves like a cricket ball, batters who play recognisable shots with real
timing and footwork, bowlers with distinct actions and skills, fielders who read the game, and
matches that produce believable scorecards over five days or twenty overs.

The two hard constraints shape every decision:

1. **It must run on Android phones** — including mid-range hardware — without the PC version
   looking like a mobile port.
2. **It must ship inside 5 GB.** Realism is therefore delivered through *systems and animation
   quality* first, and texture resolution second.

## 2. Design pillars

| Pillar | What it means in practice | How we protect it |
|---|---|---|
| **The ball is the star** | Flight, seam, swing, spin, bounce, wear and conditions are simulated, not scripted. Outcomes emerge from the ball model plus player/batter attributes. | Deterministic physics core with tunable, testable parameters; no "random wicket" events. |
| **Timing over timing bars** | Batting is decided by footwork, shot selection, and contact timing/placement — not by a single contextual button press. | Contact model resolves bat plane vs ball sphere; input maps to pre-contact intent, never to the result. |
| **Readable realism** | Every frame must communicate line, length, seam and swing early enough for a skilled player to react. | Camera, lighting, ball trail and commentary designed as *information*, reviewed in every milestone. |
| **Authentic formats** | Test cricket has to feel like Test cricket: sessions, follow-on, declarations, new ball, deteriorating pitch. | Rules engine covers formats as data-driven configurations, not three forks of the code. |
| **Scalable fidelity** | One content set, three quality profiles, no gameplay divergence between platforms. | Quality tiers only affect rendering/audio/AI think-rate — never physics or rules. |
| **Own everything** | 100% original code, models, animation and audio; fictional teams and players. | Asset provenance log; no ripped or scraped content; no real-player likenesses. |

## 3. Feature scope

### 3.1 In scope for v1.0

**Match simulation**
- Ball-by-ball simulation with full Laws coverage that matters to play: no-balls, wides, byes,
  leg byes, overthrows, free hits, dead ball, DRS-style reviews (limited), powerplays, fielding
  restrictions, follow-on, declarations, innings/target logic, super over, DLS-style revised
  targets for interrupted limited-overs games (optional, see risk R7).
- Formats: **T20**, **ODI**, **Test** (5 days, sessions), plus custom overs/innings settings.
- Modes: **Career**, **Test**, **ODI**, **T20**, **Tournaments** (league + knockout templates),
  **Custom match** (team, venue, overs, conditions, difficulty, rules toggles).

**On-field play**
- Batting: front/back foot, line-aware footwork, ~24 shot families (drives, cuts, pulls, hooks,
  sweeps, glance, defense, lofted variants, unorthodox), timing + placement + power modifiers,
  edge and miss outcomes, running between wickets with manual/assisted calling.
- Bowling: pace, swing, seam, off-spin, leg-spin, left-arm variations; delivery type, line,
  length, speed and seam/spin direction chosen pre-run-up; run-up and release timing minigame;
  stamina and workload.
- Fielding: 9 fielders + keeper with role-based positioning, anticipation, chase/intercept,
  sliding, throwing, relay, catching (with difficulty scaled by catch quality), stumpings and
  run-outs.
- Wicketkeeping: dedicated stance/footwork animation set, catch/collect logic, stumping AI.
- Conditions: weather presets, time-of-day, humidity/temperature affecting swing and stamina,
  pitch type and wear over a match, outfield speed, day/night with dew.

**Progression and customisation**
- Career: create a player, domestic → international pathway, season calendar, form/fitness/
  morale, skill trees per discipline, contracts and selection, awards, records, stat history.
- Team/player editor: names, kits, colours, bats, gloves, helmets, accessories, batting stance,
  bowling action, attributes; fictional generated squads with editable identity.
- Difficulty: assist levels for batting/bowling/fielding plus AI skill scaling; no difficulty
  setting may change the physics model.

**Presentation**
- 12–16 licensed-style but **original** stadiums with distinct dimensions, outfield, climate and
  crowd character; broadcast, player, behind-bowler, fielding and replay cameras.
- Animation-driven cutscenes for toss, milestones, wickets, presentations; replay system driven
  by deterministic simulation logs.
- Commentary system (recorded lines, context-driven selection), crowd/ambience layers, stump mic.

### 3.2 Explicit non-goals for v1.0

- Online multiplayer, cloud saves, accounts, live services, seasons-as-a-service.
- Microtransactions, ads, loot boxes, battle passes.
- Real player names, likenesses, real board/league trademarks, real broadcast branding.
- VR/AR, console ports, macOS/Linux builds (architecture must not preclude them).
- Full ball-tracking broadcast hardware integration, Hawkeye-style predictive graphics beyond a
  stylised review presentation.
- User-generated content sharing/upload; editors are local-only.

## 4. Content plan (v1.0 targets)

| Content | Target | Notes |
|---|---|---|
| Stadiums | 14 | 6 marquee (full crowd, 4K-PC texture set), 8 standard (shared crowd tech) |
| National teams | 12 fictional | 15-player squads, ~180 players authored |
| Domestic/club teams | 16 fictional | Used by career mode; 16-player squads |
| Player faces | 60 authored heads + parametric blending | Shared 4K body/kit atlases keep size low |
| Bowling actions | 18 mocap bases × parameter variation | Left/right, pace/spin, slingy/upright |
| Batting shot clips | ~120 mocap clips + additive layers | Layered IK adapts clips to ball line/height |
| Fielding/catching clips | ~90 | Dives, slides, relay throws, close catches |
| Commentary lines | ~6,000 (per-language) | Context-tagged; streamed, not in base bundle |
| Audio | Ambience, SFX, crowd reactions, stump mic, music | Music is menu/scorecard only |

## 5. Legal and originality posture

- All code, models, textures, animation, audio and commentary are created in-house or commissioned
  with full transfer of rights. No asset-store content without a licence review recorded in the
  asset provenance log (`docs/06-asset-and-content-pipeline.md §7`).
- Teams, leagues, players and stadiums are fictional. Any resemblance to real entities is
  incidental; names are checked against a trademark screening list before content lock.
- Animations are captured or keyframed by us, not retargeted from third-party motion libraries
  that forbid game use. Retargeting tools are fine; the *source motion* must be ours.
- The physics constants are our own tuning of published aerodynamics literature; no proprietary
  ball-tracking data is embedded in the game.

## 6. Success criteria for v1.0

- A full T20 on a mid-tier Android device holds its frame target for 95% of frames during play,
  with no thermal degradation below the tier's floor within a 30-minute session.
- A Test match can be played to a result, saved and resumed, with scorecards matching the Laws
  and the simulation log replaying identically.
- Batting feels skill-expressive: an expert player reliably out-scores a novice by a wide margin
  on the same difficulty, and *why* they out-score them is explainable (timing, shot choice).
- Install size ≤ 5 GB on both platforms, with the base install playable offline.
- Zero usage of third-party assets lacking recorded provenance.
