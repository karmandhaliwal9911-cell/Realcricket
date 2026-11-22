# RealCricket

An original, offline, realistic 3D cricket game for **Android** and **Windows PC**, built on a
single Unity codebase with scalable quality tiers.

| | |
|---|---|
| **Codename** | RealCricket |
| **Engine** | Unity 6.3 LTS (6000.3.x) — URP |
| **Platforms** | Android (arm64, Vulkan/GLES3), Windows x64 (DX12/Vulkan) |
| **Modes** | Career, Test, ODI, T20, Tournaments, Custom matches |
| **Connectivity** | Fully offline. No servers, no accounts, no runtime downloads required |
| **Install budget** | 5 GB maximum across content, split per platform |
| **Status** | **Phase 0 — Architecture & planning.** No gameplay code yet. |

## Where things stand

This repository currently contains the **pre-production deliverables**: the technical
architecture, the technology decisions and their rationale, the target folder structure, and the
milestone roadmap. Gameplay implementation begins at milestone **M0** in
[docs/04-roadmap.md](docs/04-roadmap.md).

The Unity editor project itself is created at the start of M0 (`Packages/manifest.json`,
`ProjectSettings/`, `.asmdef`s). Until then `Assets/RealCricket/` holds the agreed folder skeleton,
kept in version control with `.gitkeep` files.

## Documentation

| Document | Contents |
|---|---|
| [docs/00-vision-and-scope.md](docs/00-vision-and-scope.md) | Product pillars, feature scope, explicit non-goals, content plan, rights/legal posture |
| [docs/01-technology-stack.md](docs/01-technology-stack.md) | Engine and package choices, third-party tooling, alternatives considered |
| [docs/02-architecture.md](docs/02-architecture.md) | Layer model, assembly graph, simulation design, ball physics model, AI, data, save/replay |
| [docs/03-folder-structure.md](docs/03-folder-structure.md) | Repository and Unity project layout, naming rules, what lives where |
| [docs/04-roadmap.md](docs/04-roadmap.md) | Milestones M0–M5, deliverables, exit criteria, staffing, risks |
| [docs/05-performance-and-size-budget.md](docs/05-performance-and-size-budget.md) | Device tiers, frame budgets, memory budgets, the 5 GB install budget |
| [docs/06-asset-and-content-pipeline.md](docs/06-asset-and-content-pipeline.md) | DCC pipeline, mocap, materials/LODs, Addressables, build & release flow |
| [docs/adr/](docs/adr/) | Architecture Decision Records — one file per irreversible decision |

## Reading order for a new team member

1. `00-vision-and-scope.md` — what we are making and what we are not.
2. `02-architecture.md` — how the game is put together, and the rules that keep it that way.
3. `03-folder-structure.md` — where your files go.
4. `04-roadmap.md` — what is being built next and what "done" means.

## Repository conventions

- Unity project lives at the repository root (`Assets/`, `Packages/`, `ProjectSettings/`).
- Binary assets are tracked with **Git LFS** (see `.gitattributes`). Force text serialization,
  visible meta files, assembly definitions everywhere.
- Code style and review rules: [docs/03-folder-structure.md §6](docs/03-folder-structure.md).
- Every significant technical decision gets an ADR before implementation, not after.
