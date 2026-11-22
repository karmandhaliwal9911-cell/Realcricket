# 06 — Asset and Content Pipeline

## 1. Principles

- **Original first.** Everything is authored in-house or commissioned with full rights transfer.
- **Budgeted at creation.** Every asset has a size and performance budget before it is modelled.
- **One asset, many tiers.** No duplicated content per platform; resolution and LOD variants are
  derived, not re-authored.
- **Data over scenes.** Venues and teams are Addressable content bound by definitions, not scenes
  copied per variant.

## 2. Character pipeline

1. **Base meshes** — shared male/female body meshes at LOD0–LOD3 (target 45k / 22k / 9k / 3k tris).
   Single skeleton, humanoid avatar, consistent bone naming.
2. **Heads** — 60 authored heads sharing one 4K head atlas per 15 heads; parametric blendshapes
   for face shape, plus a small expression set (effort, celebration, disappointment).
3. **Kits** — layered material system: body → base kit → trim → number/name decals. Teams are
   material/pattern variations on shared meshes, so 400 players cost near-zero extra mesh memory.
4. **Equipment** — bats, pads, gloves, helmets, spikes as attachment prefabs with LODs.
5. **Export** — FBX, Y-up, metres, applied transforms, no animation on skinned exports except
   dedicated clip FBX files; materials as URP Lit/Shader Graph only.

Texture policy: 4K for marquee hero assets on PC, 2K max for mobile variants, 1K for props,
512 for crowd cards. Albedo/normal/mask packed into the URP mask map where possible. Streaming
mips enabled; crunch/compression per platform (ASTC 6x6 mobile, BC7 desktop).

## 3. Stadium pipeline

- Greybox in Unity ProBuilder from real dimensions (22-yard pitch, boundary radii per venue
  archetype), approved by gameplay before art.
- Modular kit: stands, roofs, floodlights, sightscreens, ad boards, boundary rope, dugouts, crowd
  zones. Kitbash per venue; unique hero geometry only where the venue's identity demands it.
- Lighting: baked lightmaps for static geometry (mobile-safe), mixed mode for D3 with real-time sun
  and cascaded shadows; one authored time-of-day set per venue (day, dusk, night).
- Crowd: GPU-instanced card/vertex-animation system with 3 density tiers, driven by a
  tension parameter from the match state.
- Per-venue data asset: boundary dimensions, pitch offset, outfield friction, climate preset,
  crowd zones, camera anchor points, commentary venue tags.

## 4. Animation and mocap pipeline

- **Capture**: 60 fps optical/Rokoko session; T-pose calibration; per-take slate with shot name.
- **Cleanup**: retarget to our skeleton, foot-lock, remove drift, trim; naming per §4 of the folder
  doc; loop-safe for locomotion.
- **Layering**: base clips (stance, footwork, swing, action, dive, throw) + additive layers
  (fatigue, confidence, injury, celebration) + procedural IK (bat grip, foot plant, ball tracking).
- **Compression**: keyframe reduction (tolerance documented per clip type), 30 fps for background
  roles, 60 fps for batter/bowler/keeper hero clips.
- **Validation**: every clip reviewed in `AnimationLab` against the ball at three lines and three
  lengths; clips that cannot reach a legal ball are rejected rather than fixed with IK stretch.

## 5. Audio pipeline

| Category | Format | Notes |
|---|---|---|
| Commentary | Opus/Vorbis, mono, streamed | Context-tagged; ~6,000 lines English; per-language optional packs |
| Crowd | Loops + one-shots, stereo | Intensity layers crossfaded by match tension |
| SFX | Mono/stereo one-shots | Bat/ball/stumps/gloves/shoes/umpire; distance attenuation via mixer sends |
| Music | Vorbis, streamed | Menu/scorecard only; no in-match music |

Loudness normalised to −16 LUFS integrated for music/commentary, −18 LUFS for SFX beds; true peak
≤ −1 dBTP. All implemented through mixer groups with per-tier voice limits.

## 6. Content packaging (Addressables)

| Group | Contents | Android pack | Windows |
|---|---|---|---|
| `Core` | Bootstrap, UI, core shaders, one minimal stadium, default kits | Base module | Installer core |
| `Stadium.<id>` | Venue geometry, lightmaps, crowd variants, venue audio | Install-time asset pack (grouped by region) | Installer component |
| `Team.<id>` | Squad definitions, kit materials, head/equipment overrides | Install-time asset pack | Installer core |
| `Commentary.<lang>` | Voice banks | Fast-follow pack | Installer component / optional |
| `Localization.<lang>` | Fonts, string tables | Fast-follow pack | Installer component |
| `UI.Extra` | Cutscene timeline assets, presentation video | Base or fast-follow | Installer core |

Rules: no group may exceed its declared size budget; load by handle with ref-counting; preload the
next match's venue while the scorecard is showing; unload the previous venue after a match.
Addressables profiles: `Dev`, `Staging`, `Release-Android`, `Release-Windows`.

## 7. Asset provenance log

`docs/provenance.csv` (created at M0) tracks every externally sourced item:

```
asset_id,path,type,author,vendor,licence,licence_file,commercial_ok,date_added,notes
```

Build validation fails if a file under `Assets/ThirdParty/` has no matching row. This is the audit
trail for store submissions and any future IP review. Assets with "free for personal use" or
unclear licences are rejected outright.

## 8. Import and validation tooling

Custom `AssetPostprocessor`s and an Editor validation suite enforce:

- Model scale/orientation, missing UVs, non-manifold hero meshes, LOD naming and screen heights.
- Texture max size, compression per platform, mip streaming, sRGB correctness, power-of-two atlases.
- Material slot counts ≤ 3 per character, ≤ 4 per stadium module.
- Animation clip naming, loop flags, root motion policy, event markers.
- ScriptableObject ID uniqueness, required references, localization keys present.
- Addressables group membership and size budgets; duplicate asset detection.

`Tools > RealCricket > Validate Content` runs the suite locally; CI runs it headlessly and fails the
build on errors.

## 9. Build and release flow

```
feature branch ──PR──► develop ──nightly──► Android AAB + Windows build + tests + size report
                          │
                          └──milestone tag──► release candidate ──► device matrix QA ──► store
```

- Version scheme: `MAJOR.MINOR.PATCH` + build number, displayed in the settings screen and embedded
  in saves for support.
- Every build writes `BuildManifest.json` (commit hash, Unity version, package versions, content
  group hashes, size report) into the build folder and the milestone notes.
- Reproducible builds: same tag + same Unity patch + same LFS state must produce the same content
  hashes.
- Android: IL2CPP, arm64 only, AAB + asset packs, symbols uploaded for crash deobfuscation.
  Windows: IL2CPP x64, signed installer, optional 4K component.
