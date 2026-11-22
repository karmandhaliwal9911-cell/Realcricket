# 05 — Performance and Size Budget

## 1. Device tiers

Quality is selected once at first launch (GPU/CPU/RAM probe + benchmark scene), stored in settings,
and overridable by the player.

| Tier | Reference hardware | Render target | Target FPS | URP asset |
|---|---|---|---|---|
| **T0 Low** (Android) | 4 GB RAM, Adreno 610 / Mali-G52 class, 2020-era mid-range | 720p internal, dynamic resolution 0.7–1.0 | 30 locked | MobileLow |
| **T1 Medium** (Android) | 6–8 GB RAM, Adreno 730 / Mali-G710 class | 1080p, dynamic resolution 0.8–1.0 | 45–60 | MobileHigh |
| **T2 High** (Android flagship / tablet) | 8+ GB, Adreno 740+ | 1080p–1440p | 60 | MobileHigh+ |
| **D1 Desktop** (Windows min spec) | GTX 1060 / RX 580, 4-core, 8 GB | 1080p native, FSR2 quality | 60 | Desktop |
| **D2 Desktop Recommended** | RTX 3060 / RX 6600 XT, 6-core, 16 GB | 1440p + upscaling, high settings | 60–144 | DesktopHigh |
| **D3 Desktop Ultra** | RTX 4070+ | 1440p–4K, max settings | 60+ | DesktopUltra |

The simulation is identical on every tier. Tiers change resolution, shadows, crowd density,
post-processing, VFX counts, animation update rate, texture mips and audio voice counts — never
physics, rules or AI outcomes.

## 2. Frame budgets (16.7 ms @ 60 fps; scale proportionally for other targets)

| Subsystem | T0 (33 ms) | T1 (16.7 ms) | D2 (16.7 ms) | D3 (11 ms) |
|---|---|---|---|---|
| Simulation (240 Hz, amortised) | 3.0 ms | 3.0 ms | 3.0 ms | 3.0 ms |
| AI think (10 Hz, amortised) | 1.0 ms | 1.0 ms | 1.0 ms | 1.0 ms |
| Animation + IK | 5.0 ms | 5.5 ms | 6.0 ms | 6.0 ms |
| Rendering (CPU submit) | 5.0 ms | 6.0 ms | 6.0 ms | 7.0 ms |
| Physics (props only) | 1.0 ms | 1.0 ms | 1.0 ms | 1.0 ms |
| Audio | 1.5 ms | 1.5 ms | 1.5 ms | 1.5 ms |
| UI | 1.5 ms | 1.5 ms | 1.5 ms | 1.5 ms |
| Headroom (GC, OS, spikes) | 15.0 ms | 7.0 ms | 6.5 ms | 3.0 ms |

Rules of engagement:
- The ball simulation is **not** allowed to exceed 3 ms/60 fps-equivalent on T0; if it does, reduce
  AI prediction batch size, not physics fidelity.
- Animation update throttling: full-rate for batter, bowler, keeper, nearest 3 fielders; half-rate
  beyond; T0 caps active full-rate characters at 6.
- No `GC.Alloc` in steady-state match play on any tier (verified by profiler capture per milestone).

## 3. Rendering budgets

| Metric | T0 | T1 | D2 | D3 |
|---|---|---|---|---|
| Draw calls | ≤ 180 | ≤ 320 | ≤ 900 | ≤ 1400 |
| Triangles on screen | ≤ 1.2 M | ≤ 2.5 M | ≤ 8 M | ≤ 15 M |
| Real-time shadow casters | 2 (sun + one) | 3 | 4 (cascaded 4-split) | 4 + contact shadows |
| Shadow map | 1024 | 2048 | 4096 | 4096 |
| Crowd | Billboard/vertex-anim cards, 6k visible | 12k | 25k instanced | 45k instanced |
| Post FX | Bloom, grading | + SSAO, FXAA | + TAA/FSR2, DOF in cutscenes | + SSR (marquee venues), high-quality bloom |
| Texture budget (streamed) | 700 MB | 1.2 GB | 2.5 GB | 3.5 GB |
| Particles (max concurrent) | 250 | 600 | 2000 | 3000 |

## 4. Memory budgets (peak, in-match)

| Platform | Total app memory | Texture | Mesh | Animation | Audio | Managed heap |
|---|---|---|---|---|---|---|
| T0 Android | ≤ 1.5 GB | 700 MB | 150 MB | 60 MB | 50 MB | ≤ 120 MB |
| T1 Android | ≤ 2.5 GB | 1.2 GB | 250 MB | 80 MB | 70 MB | ≤ 150 MB |
| D2 Windows | ≤ 5.0 GB | 2.5 GB | 500 MB | 120 MB | 120 MB | ≤ 250 MB |

Android low-memory callback: drop non-essential mips, unload crowd variants, reduce particle pools,
release previous stadium's bundle. Never unload the active match's Core state.

## 5. The 5 GB install budget

Total across everything, per platform, with headroom. Numbers are *caps*, tracked in CI.

| Bucket | Windows | Android | Notes |
|---|---|---|---|
| Engine runtime, scripts, shaders, plugins | 150 MB | 120 MB | IL2CPP + URP; shader variant stripping |
| UI, fonts, localization | 80 MB | 80 MB | Fonts subset; strings are tiny |
| Player characters (meshes, textures, LODs, kits) | 700 MB | 420 MB | Shared 4K body/kit atlases; 60 heads; per-tier texture variants |
| Animation | 180 MB | 150 MB | Compressed mocap clips, shared skeletons |
| Stadiums (6 marquee + 8 standard) | 1,300 MB | 750 MB | Marquee 4K textures on PC, 2K on mobile; shared crowd/stand kit |
| Props, VFX, materials, decals | 200 MB | 140 MB | Trim sheets and atlases by policy |
| Audio (crowd, SFX, music) | 350 MB | 220 MB | Vorbis/Opus; streamed music |
| Commentary (English) | 500 MB | 400 MB | Streamed, compressed speech; extra languages = optional packs |
| Career/cutscene content, UI video, misc | 250 MB | 180 MB | |
| Save data, cache, logs, patch headroom | 250 MB | 300 MB | Reserve for store patch delta |
| **Total** | **≈ 3.96 GB** | **≈ 2.76 GB** | Both under 5 GB with margin |

Distribution: Android ships a lean base module + **install-time** stadium/character pack and
**fast-follow** commentary packs; Windows installer offers a "standard" (2K) install and an optional
4K texture component (~1.2 GB) so low-end PCs stay well inside budget. Network downloads are not
required to play.

**Enforcement**
- Every Addressables group declares a size budget; a build step fails if the produced bundle
  exceeds it by > 10%.
- A size report is generated on every CI build and committed to the milestone notes.
- Adding a marquee stadium means proving the budget still holds, or trading textures elsewhere.

## 6. Load-time budgets

| Event | T0 | T1 | D2 |
|---|---|---|---|
| Cold start → main menu | ≤ 12 s | ≤ 8 s | ≤ 5 s |
| Stadium load (match start, from install) | ≤ 9 s | ≤ 6 s | ≤ 4 s |
| Return to menu | ≤ 3 s | ≤ 2 s | ≤ 1.5 s |
| Save write (autosave, over break) | ≤ 120 ms, async | ≤ 80 ms | ≤ 50 ms |

Loading is a real screen with a progress bar and a cancel path, never a frozen frame. Save writes
are off the main thread with atomic replace.

## 7. Measurement protocol

1. `DebugOverlay` in every dev build: tick ms, sim ms, render ms, draw calls, triangles, memory,
   quality tier, seed.
2. Per-milestone capture set: one full T20 innings on each reference device, 30 minutes, profiled
   with Unity Profiler (deep) and platform GPU tools (Adreno/Mali profilers, RenderDoc/PIX).
3. Results recorded in the milestone notes with the build hash; regressions > 10% block the merge
   that caused them.
4. Thermal soak: 30-minute continuous play on T0/T1; frame time must not degrade below the tier
   floor, and the device must not exceed a documented surface-temperature threshold.
