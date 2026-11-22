# tools/

Scripts and helpers that support the project but are not part of the shipped game.
Nothing here runs inside the Unity player.

| Path | Purpose | Milestone |
|---|---|---|
| `build/` | Build entry points (`build-android.sh`, `build-windows.ps1`) wrapping Unity `-executeMethod` | M0 |
| `ci/` | CI pipeline definitions and helpers: test run, content validation, size report, artifact upload | M0 |
| `content/` | Catalog generator, ID uniqueness checker, Addressables size-budget checker, provenance validator | M0–M1 |
| `dcc/` | Blender/Maya export scripts and the Unity import preset exporter | M1 |
| `tuning/` | JSON schema generator and a headless balance sweep runner over the simulation harness | M1–M4 |
| `analysis/` | Notebooks/scripts for score distributions, wicket types, edge rates from headless match logs | M4 |

Conventions:
- Every script is non-interactive, takes explicit arguments, exits non-zero on failure, and prints
  a one-line summary. CI depends on this.
- No script writes into `Assets/` unless it is a documented, idempotent generator (e.g. the catalog).
- Python tooling uses a project-local virtual environment and a pinned `requirements.txt`.
