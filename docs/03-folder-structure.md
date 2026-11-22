# 03 — Folder Structure

## 1. Repository root

```
RealCricket/
├── Assets/                  Unity project assets (see §2)
├── Packages/                manifest.json + packages-lock.json (committed)
├── ProjectSettings/         committed, Force Text serialization, visible meta files
├── docs/                    Architecture, roadmap, ADRs, tuning notebooks
├── tools/                   Build scripts, CI helpers, content validators, DCC exporters
├── reference/               Git-ignored: high-speed video, reference photos, mocap raw
├── .gitattributes           Git LFS rules for binaries
├── .gitignore               Unity + OS + IDE ignores
└── README.md
```

`reference/` is deliberately git-ignored: raw mocap and reference footage are large and are stored
on the studio NAS, with only derived/licensed-clear assets entering `Assets/`.

## 2. Unity project layout

Numbered top-level folders keep the Project window readable and make "where does this go?"
answerable without a meeting.

```
Assets/
├── RealCricket/
│   ├── 00_Settings/
│   │   ├── Rendering/            URP assets per quality tier, renderer features, volume profiles
│   │   ├── Quality/              QualityProfile assets (Low/Medium/High/Ultra), device tier map
│   │   ├── Input/                Input System action assets, control schemes, rebinding
│   │   ├── Audio/                Mixer assets, snapshots, groups
│   │   └── Localization/         Locale settings, string tables
│   │
│   ├── 01_Scenes/
│   │   ├── Bootstrap.unity       Persistent services + first-load flow
│   │   ├── MainMenu.unity
│   │   ├── Match.unity           The one gameplay scene; stadium is additive content
│   │   ├── StadiumAuthoring/     Per-stadium authoring scenes (dev only, not shipped)
│   │   └── Dev/                  PhysicsLab, AnimationLab, AIFieldLab, SaveLab
│   │
│   ├── 02_Code/
│   │   ├── Core/                 RealCricket.Core.asmdef — pure C#, no UnityEngine
│   │   │   ├── Rules/            MatchState, RulesEngine, formats, dismissals, extras
│   │   │   ├── Physics/          BallState, BallSolver, ContactResolver, PitchSurface
│   │   │   ├── Fielding/         Assignment solver, interception math, throw decisions
│   │   │   ├── Ai/               BattingBrain, BowlingPlan, FieldingBrain, utility scoring
│   │   │   ├── Career/           CareerState, progression, calendar, records
│   │   │   ├── Random/           RngStream, seeds
│   │   │   ├── Serialization/    Save DTOs, schema versions, migrations
│   │   │   └── Math/             Engine-free vector/scalar helpers, fixed-point where needed
│   │   ├── Data/                 RealCricket.Data.asmdef — ScriptableObject defs, catalogs
│   │   ├── Simulation/           RealCricket.Simulation.asmdef — tick driver, view bindings
│   │   ├── AI/                   RealCricket.AI.asmdef — think scheduler, perception adapters
│   │   ├── Gameplay/             RealCricket.Gameplay.asmdef — MatchDirector, modes, sessions
│   │   ├── Services/             RealCricket.Services.asmdef — save, quality, content, input…
│   │   ├── Presentation/         RealCricket.Presentation.asmdef
│   │   │   ├── Animation/        Animator drivers, IK rigs, animation events
│   │   │   ├── Camera/           CameraDirector, rigs, blends, replay cameras
│   │   │   ├── Vfx/              Ball trail, dust, seam shine, crowd reactions
│   │   │   └── Audio/            Commentary trigger, crowd intensity, SFX emitters
│   │   ├── UI/                   RealCricket.UI.asmdef — screens, HUD, view models
│   │   └── Editor/               RealCricket.Editor.asmdef — importers, validators, builds
│   │
│   ├── 03_Art/
│   │   ├── Characters/           Base bodies, heads, kits, equipment (bat, pads, gloves, helmet)
│   │   ├── Stadiums/             Per-stadium models, stands, crowds, dressing rooms
│   │   ├── Props/                Sight screens, scoreboards, boundary boards, cameras
│   │   ├── Materials/            Shared PBR materials, trim sheets, decals
│   │   ├── Textures/             Shared atlases; per-platform resolution variants
│   │   ├── VFX/                  Particle graphs, flipbooks, shaders
│   │   └── UI/                   Icons, badges, kit patterns, UI sprites
│   │
│   ├── 04_Animation/
│   │   ├── Controllers/          Animator controllers per role
│   │   ├── Clips/                Batting, bowling, fielding, keeping, cutscenes, locomotion
│   │   ├── Rig/                  Animation Rigging rig prefabs and constraint setups
│   │   └── Retarget/             Avatar masks, retarget definitions for shared skeletons
│   │
│   ├── 05_Audio/
│   │   ├── Commentary/           Per-language banks (Addressable, streamed)
│   │   ├── Crowd/                Loops, reactions, tiers
│   │   ├── Sfx/                  Bat, ball, stumps, gloves, shoes, ambience
│   │   └── Music/                Menu/scorecard only
│   │
│   ├── 06_Data/
│   │   ├── Players/  Teams/  Leagues/  Tournaments/  Stadiums/
│   │   ├── DeliveryTypes/  ShotTypes/  BowlingActions/  Difficulties/
│   │   ├── Weather/  Pitches/  Kits/
│   │   └── Tuning/               JSON physics/AI/career tuning tables + schemas
│   │
│   ├── 07_Localization/          String tables, localized assets, font assets
│   │
│   ├── 08_Content/               Addressables groups, labels, profiles
│   │
│   └── 09_Tests/
│       ├── EditMode/             Core rules/physics/career, golden replays
│       └── PlayMode/             Scene integration, save/load, input
│
├── ThirdParty/                   Vetted packages/fonts/plugins + licences (see §7)
└── Plugins/                      Native plugins (Android .aar, Windows .dll) if unavoidable
```

### Why one gameplay scene

`Match.unity` contains no stadium geometry. A stadium is loaded additively from an Addressable
bundle and bound by a `StadiumDef`. This keeps the scene small, makes every venue a data swap,
avoids per-stadium scene drift, and lets device tiers load lower-detail variants of the same
venue without a second scene.

## 3. Code file conventions

```
Assets/RealCricket/02_Code/Core/Physics/BallSolver.cs        // one public type per file
Assets/RealCricket/02_Code/Core/Physics/BallSolver.Swing.cs  // partial: grouped by concern
Assets/RealCricket/02_Code/Core/Tests/...                    // tests live in 09_Tests, not here
```

- Namespace mirrors folder: `RealCricket.Core.Physics`.
- `public` is a decision, not a default: assembly boundaries are the API surface, so internal
  helpers stay `internal`.
- No `MonoBehaviour` in Core/Data/AI policy code. MonoBehaviours exist only in Simulation,
  Gameplay, Presentation, UI.
- Interfaces for services; concrete classes for simulation state (structs where hot).
- Configuration via injected data objects, not `[SerializeField]` singletons.

## 4. Asset naming

| Type | Pattern | Example |
|---|---|---|
| Model | `SM_<Category>_<Name>_<Variant>` | `SM_Bat_Willow_Pro01` |
| Rig | `SK_<Role>_<Name>` | `SK_Fielder_BaseMale` |
| Material | `M_<Category>_<Name>` | `M_Pitch_DryCracked` |
| Texture | `T_<Category>_<Name>_<Map>` | `T_Stadium_Wankhede_Albedo` |
| Animator | `AC_<Role>` | `AC_Batter` |
| Animation clip | `A_<Role>_<Action>_<Variant>` | `A_Batter_CoverDrive_Front` |
| ScriptableObject | `SO_<Type>_<Name>` | `SO_Player_Rav-01` |
| Prefab | `PF_<Category>_<Name>` | `PF_Ball_RedLeather` |
| Scene | `SC_<Name>` | `SC_Match` |
| Audio | `SFX_` / `AMB_` / `VO_` / `MUS_` + name | `SFX_Bat_Edge_Soft01` |

Stable content IDs are lower-kebab, namespaced by category (`player.ind.rav-01`,
`stadium.marq-01`, `delivery.pace.outswing`). IDs are permanent; display names are localised and
freely editable.

## 5. Where new work goes (decision table)

| I am adding… | It goes in |
|---|---|
| A new shot type | `06_Data/ShotTypes` + animation clip + `ShotDef`; Core only if new physics behaviour |
| A new stadium | `03_Art/Stadiums/<id>`, authoring scene, `SO_Stadium_<id>`, Addressable group |
| A new rule variant | Core `Rules/` + format data asset + unit test |
| A new UI screen | `02_Code/UI/Screens` + UXML/USS in `03_Art/UI` |
| A new tunable constant | JSON tuning table + schema + loader, not a magic number in code |
| A new third-party package | ADR first, then `Packages/manifest.json`, licence in `ThirdParty/` |

## 6. Coding standards (short form)

- C# conventions: `PascalCase` types/methods, `_camelCase` private fields, `I`-prefixed interfaces.
- One behaviour per class; 400 lines is a smell, not a limit to defend.
- No `Find`, no `SendMessage`, no string-keyed lookups in runtime code; inject or bind.
- No `Update()` in gameplay logic; systems are driven by the tick driver or explicit schedulers.
- Logging through `ILog` with categories; `Debug.Log` in shipped code is a review defect.
- Every public Core method that changes score has a test in the same milestone.
- Comments explain *why* (physics rationale, rule citation), not *what*.
- Formatting enforced by `.editorconfig` + CI `dotnet format` check.

## 7. Third-party intake

Any external code, font, sound or model requires: licence file in `ThirdParty/<name>/LICENSE`,
an entry in the asset provenance log (see `06-asset-and-content-pipeline.md §7`), and a note in the
ADR log if it becomes a runtime dependency. No exceptions, including "free for personal use"
assets — those are not free for a commercial game.
