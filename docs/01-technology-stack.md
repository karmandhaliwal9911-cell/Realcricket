# 01 — Technology Stack

## 1. Decision summary

| Concern | Choice | Why |
|---|---|---|
| Engine | **Unity 6.3 LTS (6000.3.x)** | One codebase for Android + Windows, mature mobile tooling, URP scales from mid-range phones to high-end PC, C# + Burst/Jobs for simulation performance, Addressables for the 5 GB content budget. |
| Render pipeline | **URP** (Universal Render Pipeline) | Runs on all target Android GPUs; supports Forward+/Deferred+, real-time shadow tuning, post-processing stack and upscaling. HDRP is PC-only — rejected. |
| Scripting | **C# 9 / .NET Standard 2.1**, IL2CPP on both platforms | IL2CPP for Android arm64 and Windows x64; Burst-compiled jobs for hot math. |
| Language/API baselines | Android 10 (API 29) minimum, arm64 only; Windows 10 21H2+, DX12 or Vulkan | Covers the practical device fleet without legacy baggage. |
| UI | **UI Toolkit** (runtime), UXML/USS | Resolution-independent, cheaper than uGUI for stat-heavy screens, single style system. |
| Input | **Input System 1.8+** with generated action assets | One abstraction over touch, gamepad, keyboard/mouse; rebinding support. |
| Animation | **Animator + Animation Rigging** (IK layers), Timeline for cutscenes | Mocap clips + procedural IK is the only practical way to make shots meet the ball at arbitrary lines/heights. |
| Content streaming | **Addressables** + **Play Asset Delivery** (Android) / optional components (Windows) | Keeps base install small; asset packs per stadium/team/commentary. |
| Data authoring | **ScriptableObjects** + JSON tuning tables | Designer-editable, diffable, version-controllable; JSON for fast iteration on physics/AI constants. |
| Persistence | Custom versioned save service (JSON header + binary payload, atomic write) | Full control over migration, checksums, slot management, no third-party lock-in. |
| Localization | **Unity Localization** package | String tables, smart strings, per-locale asset variants. |
| Audio | Unity Audio + **FMOD** (evaluate at M0) | FMOD's adaptive crowd/commentary system is a large win for cricket ambience; fallback is Unity Audio with a custom mixer. |
| Physics | **Custom deterministic ball solver** in Core; Unity Physics only for non-gameplay props | Predictable, tunable, replayable; `Rigidbody` cannot model swing/spin/seam credibly. |
| AI | Custom utility/behaviour-tree hybrid in `RealCricket.AI` | Cricket AI is role-specific and needs trajectory prediction, not generic navmesh agents. |
| DCC | **Blender** (models, UVs, stadium kitbash), **Substance Painter** (textures), **Maya/MotionBuilder or Blender + Rokoko/optical mocap** | Original assets, PBR pipeline, predictable export to Unity. |
| Version control | **Git + Git LFS**, Unity `Force Text` serialization, visible meta files | Standard studio workflow; LFS for FBX/PSD/WAV/EXR. |
| CI | GitHub Actions (or equivalent) self-hosted runner: EditMode tests + Android/Windows IL2CPP builds nightly | Catches platform breakage early; device builds are the real gate. |
| Analytics/crash | Optional, **opt-in**, offline-buffered (Unity Cloud Diagnostics or self-hosted Sentry) | Gameplay is offline; telemetry must never gate play. |

## 2. Why Unity and not Unreal / Godot

**Unreal Engine 5** gives the highest ceiling on PC (Nanite, Lumen, MetaHuman), but:
- Nanite/Lumen are effectively unavailable on the Android devices we must support; the mobile
  renderer is a different, weaker path, so "maximum realism" would only exist on one platform.
- Binary size and shader compilation cost work against a 5 GB, phone-friendly package.
- C++ iteration plus Blueprint/C++ split raises cost for a gameplay-logic-heavy, animation-heavy
  sports game whose hard problems are rules, AI and ball behaviour — not rendering.
Unreal remains the right choice for a PC-only photoreal cricket game. It is the wrong choice for
"same game, phone and PC, 5 GB".

**Godot 4** is lean and pleasant, but the 3D mobile rendering path, large-scene tooling, animation
retargeting/I K ecosystem and third-party middleware support are not yet at the level a realistic
sports title needs.

**Unity 6.3 LTS** is the compromise with the least downside: the same URP shaders and materials
run on both platforms with different quality profiles, animation tooling is strong, mobile
profiling is mature, and C# makes the rules/AI/physics core fast to build and test.

> Version policy: lock the editor to the newest **6000.3.x LTS** patch at project creation, record
> it in `ProjectSettings/ProjectVersion.txt`, and upgrade only between milestones after a full
> regression pass. Unity 6.0 LTS support ended October 2026 — do not start there.

## 3. Unity packages (initial set)

| Package | Use | Status |
|---|---|---|
| `com.unity.render-pipelines.universal` | Rendering | Required |
| `com.unity.inputsystem` | Input abstraction | Required |
| `com.unity.addressables` | Content groups / asset packs | Required |
| `com.unity.animation.rigging` | Bat/glove IK, look-at, foot IK | Required |
| `com.unity.timeline` | Cutscenes, replays, presentations | Required |
| `com.unity.ui` (UI Toolkit) | All runtime UI | Required |
| `com.unity.localization` | Strings, locales | Required |
| `com.unity.burst` + `com.unity.collections` + `com.unity.mathematics` | Ball solver, fielding math jobs | Required |
| `com.unity.test-framework` | EditMode/PlayMode tests | Required |
| `com.unity.probuilder` | Greyboxing stadiums | Optional |
| `com.unity.cinemachine` | Camera rigs (broadcast/replay) | Optional |
| `com.unity.memoryprofiler` / `profiling` | Budget verification | Dev only |
| FMOD for Unity | Adaptive audio | Evaluate at M0 |

Rule: **no package without an owner and a removal plan.** Every added dependency is recorded in
the ADR log with the reason and the exit cost.

## 4. Build and distribution

| Target | Format | Notes |
|---|---|---|
| Android | **AAB** with Play Asset Delivery (install-time + fast-follow packs), arm64-v8a, IL2CPP, Vulkan preferred with GLES3 fallback | Base module under Play's limit; stadium/commentary packs split out; 5 GB total across packs. |
| Windows | x64 standalone + installer (Inno Setup or similar) with optional 4K texture component | Player can skip the 4K pack to save ~1.2 GB. |
| Development | Windows/macOS editor, one shared `develop` branch + short-lived feature branches | Trunk-based with milestone tags. |

Verify current store limits (base module size, per-pack size, total download) against Google Play
policy before content lock — these change, and the asset-pack split is designed around them.

## 5. Tooling for the team

- **Blender 4.x** — modelling, UV, stadium kitbash, animation blocking.
- **Substance Painter / Designer** — PBR texturing and trim-sheet materials.
- **Mocap**: in-house optical or Rokoko-class suit, 60 fps, cleaned in MotionBuilder/Blender.
- **Audacity/Reaper + iZotope** — SFX and commentary edit; FMOD for implementation.
- **Jira/Linear + Confluence/Notion** — tasks and living design docs.
- **Perforce not required**; Git LFS is sufficient at this team size with disciplined binary
  ownership (one owner per asset category).
